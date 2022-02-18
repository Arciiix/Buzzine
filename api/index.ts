import express from "express";
import { io } from "socket.io-client";
import dotenv from "dotenv";
import logger, { logHTTPEndpoints } from "./utils/logger";
import bodyParser from "body-parser";
import axios, { Method } from "axios";
import guardRouter, { checkQRCode } from "./guard";
import { initDatabase } from "./utils/db";
import cdn from "./utils/cdn";
import weatherRouter from "./weather";

//Load environment variables from file
dotenv.config();
const PORT = process.env.PORT || 1111;
const AUDIO_URL = process.env.AUDIO_URL || "http://localhost:7777"; //DEV TODO: Change it
const ADAPTER_URL = process.env.ADAPTER_URL || "http://localhost:2222"; //DEV TODO: Change it

const app = express();
app.use(bodyParser.json());

app.get("/", (req, res) => {
  res.send({ error: false, currentVersion: "v1", timestamp: new Date() });
});

const audioRouter = express.Router();
const emergencyRouter = express.Router();

const uptime = new Date();

//This variable has each microservices useful safe (without API keys etc.) environment variables, such as MUTE_AFTER from core which is used to specify max emergencyAlarmTimeoutSeconds value
//Set the variables to its default
let servicesConstants: IServicesConstants;

//REST API
const api = express.Router();
api.use(logHTTPEndpoints);

app.use("/v1", api);
api.use("/guard", guardRouter);
app.use("/cdn", cdn);
api.use("/weather", weatherRouter);
api.use("/audio", audioRouter);
api.use("/emergency", emergencyRouter);
api.use("/temperature", emergencyRouter);

api.get("/ping", async (req, res) => {
  let now = new Date();
  let services = {
    api: {
      success: true,
      delay: null,
      uptimeSeconds: Math.floor(
        (new Date().getTime() - uptime.getTime()) / 1000
      ),
    },
    core: {
      success: false,
      delay: null,
    },
    audio: {
      success: false,
      delay: null,
    },
    adapter: {
      success: false,
      delay: null,
    },
  };

  if (
    !req.query.timestamp ||
    isNaN(new Date(req.query.timestamp as string).getTime())
  ) {
    logger.warn(
      `Invalid/no timestamp provided in the ping request: ${req.query.timestamp}`
    );
  } else {
    services.api.delay =
      now.getTime() - new Date(req.query.timestamp as string).getTime();
  }

  await new Promise((resolve: any, reject) => {
    //Ping the core
    logger.info("Pinging the core...");
    socket.emit("CMD/PING", null, (response) => {
      if (!response.error) {
        logger.info("Pinged the core successfully");
        services.core.success = true;
        if (response.timestamp) {
          services.core.delay =
            new Date(response.timestamp).getTime() - now.getTime();
        }
      } else {
        logger.error(
          `Error while pinging the core service: ${JSON.stringify(response)}`
        );
      }
      resolve();
    });
  });

  //Reset the now date
  now = new Date();
  await new Promise(async (resolve: any, reject) => {
    //Ping the audio
    logger.info("Pinging the audio...");
    try {
      let response = await axios.get(`${AUDIO_URL}/v1/ping`);
      logger.info(`Pinged the audio service successfully`);
      services.audio.success = true;
      if (response.data.timestamp) {
        services.audio.delay =
          new Date(response.data.timestamp).getTime() - now.getTime();
      }
    } catch (err) {
      logger.error(`Error while pinging the audio service`);
    }

    resolve();
  });

  //Reset the now date
  now = new Date();
  await new Promise(async (resolve: any, reject) => {
    //Ping the adapter
    logger.info("Pinging the adapter...");
    try {
      let response = await axios.get(`${ADAPTER_URL}/v1/ping`);
      logger.info(`Pinged the adapter successfully`);
      services.adapter.success = true;
      if (response.data.timestamp) {
        services.adapter.delay =
          new Date(response.data.timestamp).getTime() - now.getTime();
      }
    } catch (err) {
      logger.error(`Error while pinging the adapter`);
    }

    resolve();
  });

  let isError = false;
  //If any of the services ping failed
  if (Object.values(services).find((e) => !e.success)) {
    res.status(502);
    isError = true;
  }
  res.send({ error: isError, response: services });
});

api.get("/getConstants", async (req, res) => {
  res.send({ error: false, response: await getServicesConstants() });
});

async function getServicesConstants(): Promise<IServicesConstants> {
  let newServicesConstants: IServicesConstants = {
    core: { MUTE_AFTER: 10 },
    api: {},
    audio: {},
    adapter: {},
  };
  //Core
  await new Promise((resolve: any, reject) => {
    socket.emit("CMD/GET_CONSTANTS", (response) => {
      if (response.error) {
        logger.warn(
          `Response error when getting the constants from the core: ${JSON.stringify(
            response
          )}`
        );
        reject(response);
      } else {
        logger.info(
          `Got the core constants. Response: ${JSON.stringify(response)}`
        );
        newServicesConstants.core = response.response;
        resolve();
      }
    });
  });

  servicesConstants = newServicesConstants;
  return newServicesConstants;
}
async function fetchAlarmsAudio(response): Promise<any> {
  //Fetch the assigned audio to each nap
  //Set the default one by default
  response = response.map((elem) => {
    return {
      ...elem,
      ...{
        sound: {
          audioId: "default",
          filename: "default.mp3",
          friendlyName: "Domyślna",
        },
      },
    };
  });

  //Fetch the naps audios
  try {
    let audiosReq = await axios.get(`${AUDIO_URL}/v1/getAlarmSoundList`);
    let audiosRes = audiosReq.data.data;
    response.forEach((element) => {
      //Match the audios with the naps
      let audioIndex = audiosRes.findIndex((e) => e.alarmId === element.id);
      if (audioIndex > -1) {
        response[response.indexOf(element)].sound = {
          audioId: audiosRes[audioIndex].audioId,
          filename: audiosRes[audioIndex].filename,
          friendlyName:
            audiosRes[audioIndex]?.AudioNameMapping?.friendlyName ??
            element.filename,
        };
      }
    });
  } catch (err) {
    logger.error(
      `Error while getting alarm audios: ${err.toString()} - ${JSON.stringify(
        err?.response?.data
      )} with status ${err?.response?.status}`
    );
  }

  return response;
}

api.get("/getEmergencyStatus", async (req, res) => {
  let emergencyStatus: object = await new Promise((resolve, reject) => {
    socket.emit("CMD/GET_EMERGENCY_STATUS", (response) => {
      if (response.error) {
        logger.warn(
          `Response error when getting the emergency status: ${JSON.stringify(
            response
          )}`
        );
        resolve(null);
      } else {
        logger.info(
          `Got the emergency status constants. Response: ${JSON.stringify(
            response
          )}`
        );
        resolve(response.response);
      }
    });
  });

  let error = false;
  try {
    let emergencyDeviceStatus = await axios.get(`${ADAPTER_URL}/v1/getStatus`);
    emergencyStatus = {
      ...emergencyStatus,
      ...emergencyDeviceStatus.data.response,
    };
    logger.info(
      `Got the emergency status: ${JSON.stringify(
        emergencyDeviceStatus.data.response
      )}`
    );
  } catch (err) {
    logger.warn(
      `Error while trying to get the emergency status: ${JSON.stringify(
        err?.response?.data
      )} with status ${err?.response?.status}`
    );
    error = true;
  }

  res.send({ error: error, response: emergencyStatus });
});

api.put("/cancelEmergencyAlarm", async (req, res) => {
  socket.emit("CMD/CANCEL_EMERGENCY_ALARM", (response) => {
    if (response.error) {
      res.status(500).send(response);
      logger.warn(
        `Response error when cancelling (cancelling) the emergency alarm: ${JSON.stringify(
          response
        )}`
      );
    } else {
      res.status(200).send(response);
      logger.info(
        `Cancelled the emergency alarm successfully. Response: ${JSON.stringify(
          response
        )}`
      );
    }
  });
});

api.post("/addAlarm", async (req, res) => {
  if (!req.body)
    return res.status(400).send({ error: true, errorCode: "EMPTY_PAYLOAD" });

  //Validate the payload
  if (
    req.body.hour === null ||
    req.body.minute === null ||
    isNaN(req.body.hour) ||
    isNaN(req.body.minute)
  ) {
    return res.status(400).send({ error: true, errorCode: "WRONG_TIME" });
  }

  socket.emit("CMD/CREATE_ALARM", req.body, async (response) => {
    if (response.error) {
      res.status(400).send(response);
      logger.warn(
        `Response error when creating the alarm: ${JSON.stringify(response)}`
      );
    } else {
      if (req.body?.sound?.audioId && req.body.sound.audioId !== "default") {
        try {
          //Associate the alarm with given sound
          await axios.put(`${AUDIO_URL}/v1/changeAlarmSound`, {
            alarmId: response?.id,
            audioId: req.body.sound.audioId,
          });
        } catch (err) {
          res.status(err?.response?.status ?? 500).send(err?.response?.data);
          logger.error(
            `Error when trying to associate an audio with an alarm. ${JSON.stringify(
              err?.response?.data ?? ""
            )} with status ${err?.response?.status}`
          );
          return;
        }
      }
      res.status(201).send({ error: false, response });
      logger.info(
        `Created alarm successfully. Response: ${JSON.stringify(response)}`
      );
    }
  });
});

api.post("/addNap", async (req, res) => {
  if (!req.body)
    return res.status(400).send({ error: true, errorCode: "EMPTY_PAYLOAD" });

  //Validate the payload
  if (
    req.body.hour === null ||
    req.body.minute === null ||
    req.body.second === null ||
    isNaN(req.body.hour) ||
    isNaN(req.body.minute) ||
    isNaN(req.body.second)
  ) {
    return res.status(400).send({ error: true, errorCode: "WRONG_TIME" });
  }

  socket.emit("CMD/CREATE_NAP", req.body, async (response) => {
    if (response.error) {
      res.status(400).send(response);
      logger.warn(
        `Response error when creating a nap: ${JSON.stringify(response)}`
      );
    } else {
      if (req.body?.sound?.audioId && req.body.sound.audioId !== "default") {
        try {
          //Associate the alarm with given sound
          await axios.put(`${AUDIO_URL}/v1/changeAlarmSound`, {
            alarmId: response?.id,
            audioId: req.body.sound.audioId,
          });
        } catch (err) {
          res.status(err?.response?.status ?? 500).send(err?.response?.data);
          logger.error(
            `Error when trying to associate an audio with a nap. ${JSON.stringify(
              err?.response?.data ?? ""
            )} with status ${err?.response?.status}`
          );
          return;
        }
      }
      res.status(201).send({ error: false, response });
      logger.info(
        `Created nap successfully. Response: ${JSON.stringify(response)}`
      );
    }
  });
});

api.put("/cancelAlarm", async (req, res) => {
  await cancelAlarm(req, res);
});

api.put("/cancelAlarmSecured", async (req, res, next) => {
  if (!req.body.data) {
    res.status(400).send({ error: true, errorCode: "MISSING_QR_DATA" });
    return;
  }

  if (!(await checkQRCode(req.body.data))) {
    res.status(400).send({ error: true, errorCode: "WRONG_QR_CODE" });
    return;
  }

  await cancelAlarm(req, res);
});

async function cancelAlarm(req, res) {
  if (!req.body)
    return res.status(400).send({ error: true, errorCode: "EMPTY_PAYLOAD" });

  //Validate the payload
  if (!req.body.id) {
    return res.status(400).send({ error: true, errorCode: "MISSING_ID" });
  }

  socket.emit("CMD/TURN_ALARM_OFF", req.body, (response) => {
    if (response.error) {
      res.status(400).send(response);
      logger.warn(
        `Response error when cancelling the alarm: ${JSON.stringify(response)}`
      );
    } else {
      res.status(200).send({ error: false, response });
      logger.info(
        `Cancelled alarm ${
          req.body.id
        } successfully. Response: ${JSON.stringify(response)}`
      );
    }
  });
}

api.put("/toogleAlarm", async (req, res) => {
  if (!req.body)
    return res.status(400).send({ error: true, errorCode: "EMPTY_PAYLOAD" });

  //Validate the payload
  if (!req.body.id) {
    return res.status(400).send({ error: true, errorCode: "MISSING_ID" });
  }
  if (!req.body.hasOwnProperty("status")) {
    return res
      .status(400)
      .send({ error: true, errorCode: "MISSING_ALARM_STATUS" });
  }

  socket.emit("CMD/TOOGLE_ALARM", req.body, (response) => {
    if (response.error) {
      res.status(400).send(response);
      logger.warn(
        `Response error when toogling the alarm: ${JSON.stringify(response)}`
      );
    } else {
      res.status(200).send({ error: false, response });
      logger.info(
        `Toogled alarm ${
          req.body.status ? "on" : "off"
        } successfully. Response: ${JSON.stringify(response)}`
      );
    }
  });
});
api.put("/cancelNextInvocation", (req, res) => {
  if (!req.body)
    return res.status(400).send({ error: true, errorCode: "EMPTY_PAYLOAD" });

  //Validate the payload
  if (!req.body.id) {
    return res.status(400).send({ error: true, errorCode: "MISSING_ID" });
  }

  socket.emit("CMD/CANCEL_NEXT_INVOCATION", req.body, (response) => {
    if (response.error) {
      res.status(400).send(response);
      logger.warn(
        `Response error when canceling the invocation: ${JSON.stringify(
          response
        )}`
      );
    } else {
      res.status(200).send({ error: false, response });
      logger.info(
        `Cancelled next invocation of alarm ${
          req.body.id
        } successfully. Response: ${JSON.stringify(response)}`
      );
    }
  });
});

api.put("/snoozeAlarm", (req, res) => {
  if (!req.body)
    return res.status(400).send({ error: true, errorCode: "EMPTY_PAYLOAD" });

  //Validate the payload
  if (!req.body.id) {
    return res.status(400).send({ error: true, errorCode: "MISSING_ID" });
  }

  socket.emit("CMD/SNOOZE_ALARM", req.body, (response) => {
    if (response.error) {
      res.status(400).send(response);
      logger.warn(
        `Response error when snoozing an alarm: ${JSON.stringify(response)}`
      );
    } else {
      if (response.didSnooze) {
        res.status(200).send({ error: false, response });
        logger.info(
          `Snoozed alarm ${
            req.body.id
          } successfully. Response: ${JSON.stringify(response)}`
        );
      } else {
        res.status(400).send({ error: false, response });
        logger.info(
          `Didn't snooze alarm ${req.body.id}. Response: ${JSON.stringify(
            response
          )}`
        );
      }
    }
  });
});

api.delete("/deleteAlarm", (req, res) => {
  if (!req.body)
    return res.status(400).send({ error: true, errorCode: "EMPTY_PAYLOAD" });

  //Validate the payload
  if (!req.body.id) {
    return res.status(400).send({ error: true, errorCode: "MISSING_ID" });
  }

  socket.emit("CMD/DELETE_ALARM", req.body, (response) => {
    if (response.error) {
      res.status(400).send(response);
      logger.warn(
        `Response error when deleting an alarm: ${JSON.stringify(response)}`
      );
    } else {
      if (response.error) {
        res.status(400).send(response);
        logger.warn(
          `Response error when deleting an alarm: ${JSON.stringify(response)}`
        );
      } else {
        res.status(200).send({ error: false, response });
        logger.info(
          `Deleted alarm ${req.body.id}. Response: ${JSON.stringify(response)}`
        );
      }
    }
  });
});

api.post("/updateAlarm", async (req, res) => {
  if (!req.body)
    return res.status(400).send({ error: true, errorCode: "EMPTY_PAYLOAD" });

  //Validate the payload
  if (!req.body.id) {
    return res.status(400).send({ error: true, errorCode: "MISSING_ID" });
  }

  if (
    req.body.hour === null ||
    req.body.minute === null ||
    isNaN(req.body.hour) ||
    isNaN(req.body.minute)
  ) {
    return res.status(400).send({ error: true, errorCode: "WRONG_TIME" });
  }

  if (!req.body.hasOwnProperty("isActive")) {
    return res.send(400).send({ error: true, errorCode: "MISSING_ISACTIVE" });
  }

  socket.emit("CMD/UPDATE_ALARM", req.body, async (response) => {
    if (response.error) {
      res.status(400).send(response);
      logger.warn(
        `Response error when updating an alarm ${req.body.id}: ${JSON.stringify(
          response
        )}`
      );
    } else {
      if (req.body?.sound?.audioId && req.body.sound.audioId !== "default") {
        try {
          //Associate the alarm with given sound
          await axios.put(`${AUDIO_URL}/v1/changeAlarmSound`, {
            alarmId: response?.id,
            audioId: req.body.sound.audioId,
          });
        } catch (err) {
          res.status(err?.response?.status ?? 500).send(err?.response?.data);
          logger.error(
            `Error when trying to associate an audio with an alarm. ${err.toString()}; response: ${JSON.stringify(
              err?.response?.data ?? ""
            )}`
          );
          return;
        }
      }
      res.status(200).send({ error: false, response });
      logger.info(
        `Updated alarm successfully. Response: ${JSON.stringify(response)}`
      );
    }
  });
});

api.post("/updateNap", async (req, res) => {
  if (!req.body)
    return res.status(400).send({ error: true, errorCode: "EMPTY_PAYLOAD" });

  //Validate the payload
  if (!req.body.id) {
    return res.status(400).send({ error: true, errorCode: "MISSING_ID" });
  }

  if (
    req.body.hour === null ||
    req.body.minute === null ||
    req.body.second === null ||
    isNaN(req.body.hour) ||
    isNaN(req.body.minute) ||
    isNaN(req.body.second)
  ) {
    return res.status(400).send({ error: true, errorCode: "WRONG_TIME" });
  }

  socket.emit("CMD/UPDATE_NAP", req.body, async (response) => {
    if (response.error) {
      res.status(400).send(response);
      logger.warn(
        `Response error when updating a nap ${req.body.id}: ${JSON.stringify(
          response
        )}`
      );
    } else {
      if (req.body?.sound?.audioId && req.body.sound.audioId !== "default") {
        try {
          //Associate the alarm with given sound
          await axios.put(`${AUDIO_URL}/v1/changeAlarmSound`, {
            alarmId: response?.id,
            audioId: req.body.sound.audioId,
          });
        } catch (err) {
          res.status(err?.response?.status ?? 500).send(err?.response?.data);
          logger.error(
            `Error when trying to associate an audio with a nap. ${err.toString()}; response: ${JSON.stringify(
              err?.response?.data ?? ""
            )}`
          );
          return;
        }
      }
      res.status(200).send({ error: false, response });
      logger.info(
        `Updated nap successfully. Response: ${JSON.stringify(response)}`
      );
    }
  });
});

api.get("/getUpcomingAlarms", (req, res) => {
  socket.emit("CMD/GET_UPCOMING_ALARMS", (response) => {
    if (response.error) {
      res.status(500).send(response);
      logger.warn(
        `Response error when getting upcoming alarms: ${JSON.stringify(
          response
        )}`
      );
    } else {
      res.status(200).send({ error: false, response });
      logger.info(
        `Got upcoming alarms successfully. Response: ${JSON.stringify(
          response
        )}`
      );
    }
  });
});

api.get("/getAllAlarms", (req, res) => {
  socket.emit("CMD/GET_ALL_ALARMS", async (response) => {
    if (response.error) {
      res.status(500).send(response);
      logger.warn(
        `Response error when getting all alarms: ${JSON.stringify(response)}`
      );
    } else {
      let alarmsAudios = await fetchAlarmsAudio(response.alarms);
      let napsAudios = await fetchAlarmsAudio(response.naps);
      response = { alarms: alarmsAudios, naps: napsAudios };

      res.status(200).send({ error: false, response });
      logger.info(
        `Got all alarms successfully. Response: ${JSON.stringify(response)}`
      );
    }
  });
});

api.get("/getRingingAlarms", (req, res) => {
  socket.emit("CMD/GET_RINGING_ALARMS", async (response) => {
    if (response.error) {
      res.status(500).send(response);
      logger.warn(
        `Response error when getting currently ringing alarms: ${JSON.stringify(
          response
        )}`
      );
    } else {
      let alarmsAudios = await fetchAlarmsAudio(response.alarms);
      let napsAudios = await fetchAlarmsAudio(response.naps);
      response = { alarms: alarmsAudios, naps: napsAudios };

      res.status(200).send({ error: false, response });
      logger.info(
        `Got ringing alarms successfully. Response: ${JSON.stringify(response)}`
      );
    }
  });
});

api.get("/getActiveSnoozes", (req, res) => {
  socket.emit("CMD/GET_ACTIVE_SNOOZES", async (response) => {
    if (response.error) {
      res.status(500).send(response);
      logger.warn(
        `Response error when getting active snoozes: ${JSON.stringify(
          response
        )}`
      );
    } else {
      res.status(200).send({ error: false, response });
      logger.info(
        `Got active snoozes successfully. Response: ${JSON.stringify(response)}`
      );
    }
  });
});

api.put("/cancelAllAlarms", async (req, res) => {
  socket.emit("CMD/CANCEL_ALL_ALARMS", (response) => {
    if (response.error) {
      res.status(500).send(response);
      logger.warn(
        `Response error when turning (cancelling) all alarms off: ${JSON.stringify(
          response
        )}`
      );
    } else {
      res.status(200).send(response);
      logger.info(
        `Turned (cancelled) all alarms off successfully. Response: ${JSON.stringify(
          response
        )}`
      );
    }
  });
});

audioRouter.put("/tempMuteAudio", async (req, res) => {
  //It's just the same request sent to the audio microservice
  try {
    let audiosReq = await axios.put(`${AUDIO_URL}/v1/tempMuteAudio`, {
      duration: req.body.duration,
    });
    logger.info(
      `Made audio request /tempMuteAudio with response ${JSON.stringify(
        audiosReq.data
      )}`
    );

    //Mute the emergency alarm as well (if it's active now)
    let emergencyReq = await axios.put(`${ADAPTER_URL}/v1/tempMute`, {
      duration: req.body.duration,
    });
    logger.info(
      `Made emergency request PUT /tempMute with response ${JSON.stringify(
        emergencyReq.data
      )}`
    );

    res.status(audiosReq.status).send(audiosReq.data);
  } catch (err) {
    logger.warn(
      `Error while making emergency request PUT /tempMute: ${JSON.stringify(
        err?.response?.data
      )} with status ${err?.response?.status}`
    );
    res.status(err?.response?.status ?? 502).send(err?.response?.data);
  }
});

audioRouter.all("*", async (req, res) => {
  //It's just the same request sent to the audio microservice
  try {
    let audiosReq = await axios({
      url: `${AUDIO_URL}/v1${req.path}`,
      method: req.method as Method,
      data: req.body,
      params: req.query,
    });
    logger.info(
      `Made audio request ${req.path} with response ${JSON.stringify(
        audiosReq.data
      )}`
    );
    res.status(audiosReq.status).send(audiosReq.data);
  } catch (err) {
    logger.warn(
      `Error while making audio request: ${JSON.stringify(
        err?.response?.data
      )} with status ${err?.response?.status}`
    );
    res.status(err?.response?.status ?? 502).send(err?.response?.data);
  }
});

emergencyRouter.all("*", async (req, res) => {
  //It's just the same request sent to the adapter
  try {
    let emergencyReq = await axios({
      url: `${ADAPTER_URL}/v1${req.path}`,
      method: req.method as Method,
      data: req.body,
      params: req.query,
    });
    logger.info(
      `Made emergency request ${req.path} with response ${JSON.stringify(
        emergencyReq.data
      )}`
    );
    res.status(emergencyReq.status).send(emergencyReq.data);
  } catch (err) {
    logger.warn(
      `Error while making emergency request: ${JSON.stringify(
        err?.response?.data
      )} with status ${err?.response?.status}`
    );
    res.status(err?.response?.status ?? 502).send(err?.response?.data);
  }
});

const socket = io(process.env.CORE_URL || "http://localhost:3333"); //DEV - to be changed with Docker

socket.on("connect", () => {
  logger.info(
    `Made a connection with the core, waiting for the initial message...`
  );
});

socket.on("hello", () => {
  logger.info(`Successfully connected to the core`);
});
const server = app.listen(PORT, () => {
  logger.info(`API has started on port ${PORT}`);
});

async function init() {
  await initDatabase();
  await getServicesConstants();
}

interface IServicesConstants {
  core: { MUTE_AFTER: number };
  api: {};
  audio: {};
  adapter: {};
}

init();
export { io };
