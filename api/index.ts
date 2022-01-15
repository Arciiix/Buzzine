import express from "express";
import { io } from "socket.io-client";
import dotenv from "dotenv";
import logger from "./utils/logger";
import bodyParser from "body-parser";
import axios from "axios";
import guardRouter, { checkQRCode } from "./guard";
import { initDatabase } from "./utils/db";
import cdn from "./utils/cdn";

//Load environment variables from file
dotenv.config();
const PORT = process.env.PORT || 1111;
const AUDIO_URL = process.env.AUDIO_URL || "http://localhost:7777"; //DEV TODO: Change it

const app = express();
app.use(bodyParser.json());

app.get("/", (req, res) => {
  res.send({ error: false, currentVersion: "v1", timestamp: new Date() });
});
//REST API
const api = express.Router();
app.use("/v1", api);
api.use("/guard", guardRouter);
app.use("/cdn", cdn);

api.post("/addAlarm", async (req, res) => {
  logger.http(`POST /addAlarm with data: ${JSON.stringify(req.body)}`);

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
      if (
        req.body?.sound?.filename &&
        req.body.sound.filename !== "default.mp3"
      ) {
        try {
          //Associate the alarm with given sound
          await axios.put(`${AUDIO_URL}/v1/changeAlarmSound`, {
            alarmId: response?.id,
            audioFilename: req.body.sound.filename,
          });
        } catch (err) {
          res.status(err?.response?.status).send(err?.response?.data);
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

api.put("/cancelAlarm", async (req, res) => {
  logger.http(`PUT /cancelAlarm with data: ${JSON.stringify(req.body)}`);

  await cancelAlarm(req, res);
});

api.put("/cancelAlarmSecured", async (req, res, next) => {
  logger.http("PUT /cancelAlarmSecured");

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
  logger.http(`PUT /toogleAlarm with data: ${JSON.stringify(req.body)}`);

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
  logger.http(
    `PUT /cancelNextInvocation with data: ${JSON.stringify(req.body)}`
  );

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
  logger.http(`PUT /snoozeAlarm with data: ${JSON.stringify(req.body)}`);

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
  logger.http(`DELETE /deleteAlarm with data: ${JSON.stringify(req.body)}`);

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
  logger.http(`POST /updateAlarm with data: ${JSON.stringify(req.body)}`);

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
      if (
        req.body?.sound?.filename &&
        req.body.sound.filename !== "default.mp3"
      ) {
        try {
          //Associate the alarm with given sound
          await axios.put(`${AUDIO_URL}/v1/changeAlarmSound`, {
            alarmId: response?.id,
            audioFilename: req.body.sound.filename,
          });
        } catch (err) {
          res.status(err?.response?.status).send(err?.response?.data);
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

api.get("/getUpcomingAlarms", (req, res) => {
  logger.http(`GET /getUpcomingAlarms`);

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
  logger.http(`GET /getAllAlarms`);

  socket.emit("CMD/GET_ALL_ALARMS", async (response) => {
    if (response.error) {
      res.status(500).send(response);
      logger.warn(
        `Response error when getting all alarms: ${JSON.stringify(response)}`
      );
    } else {
      //Fetch the assigned audio to each alarm
      //Set the default one by default
      response = response.map((elem) => {
        return {
          ...elem,
          ...{
            sound: {
              filename: "default.mp3",
              friendlyName: "Domyślna",
            },
          },
        };
      });

      //Fetch the alarms audios
      try {
        let audiosReq = await axios.get(`${AUDIO_URL}/v1/getAlarmSoundList`);
        if (!audiosReq.data.error) {
          let audiosRes = audiosReq.data.data;
          audiosRes.forEach((element) => {
            //Match the audios with the alarms
            let alarmIndex = response.findIndex(
              (e) => e.id === element.alarmId
            );
            if (alarmIndex > -1) {
              response[alarmIndex].sound = {
                filename: element.filename,
                friendlyName:
                  element?.AudioNameMapping?.friendlyName ?? element.filename,
              };
            }
          });
        }
      } catch (err) {
        logger.error(
          `Error while getting alarms audios, when getting all alarms: ${err.toString()} - ${JSON.stringify(
            err?.response?.data
          )} with status ${err?.response?.status}`
        );
      }

      res.status(200).send({ error: false, response });
      logger.info(
        `Got all alarms successfully. Response: ${JSON.stringify(response)}`
      );
    }
  });
});

api.get("/getRingingAlarms", (req, res) => {
  logger.http(`GET /getRingingAlarms`);

  socket.emit("CMD/GET_RINGING_ALARMS", async (response) => {
    if (response.error) {
      res.status(500).send(response);
      logger.warn(
        `Response error when getting currently ringing alarms: ${JSON.stringify(
          response
        )}`
      );
    } else {
      //Fetch the assigned audio to each alarm
      //Set the default one by default
      response = response.map((elem) => {
        return {
          ...elem,
          ...{
            sound: {
              filename: "default.mp3",
              friendlyName: "Domyślna",
            },
          },
        };
      });

      //Fetch the alarms audios
      try {
        let audiosReq = await axios.get(`${AUDIO_URL}/v1/getAlarmSoundList`);
        if (!audiosReq.data.error) {
          let audiosRes = audiosReq.data.data;
          audiosRes.forEach((element) => {
            //Match the audios with the alarms
            let alarmIndex = response.findIndex(
              (e) => e.id === element.alarmId
            );
            if (alarmIndex > -1) {
              response[alarmIndex].sound = {
                filename: element.filename,
                friendlyName:
                  element?.AudioNameMapping?.friendlyName ?? element.filename,
              };
            }
          });
        }
      } catch (err) {
        logger.error(
          `Error while getting alarms audios, when getting ringing alarms: ${JSON.stringify(
            err?.response?.data
          )} with status ${err?.response?.status}`
        );
      }

      res.status(200).send({ error: false, response });
      logger.info(
        `Got ringing alarms successfully. Response: ${JSON.stringify(response)}`
      );
    }
  });
});

api.get("/getActiveSnoozes", (req, res) => {
  logger.http(`GET /getActiveSnoozes`);

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
  logger.http(`PUT /cancelAllAlarms`);

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

api.get("/getSoundList", async (req, res) => {
  logger.http("GET /getSoundList");

  //It's just the same request sent to the audio microservice
  try {
    let audiosReq = await axios.get(`${AUDIO_URL}/v1/getSoundList`);
    if (audiosReq.status != 200) {
      logger.warn(
        `Error while getting audios: ${JSON.stringify(audiosReq.data)}`
      );
    }
    res.status(audiosReq.status).send(audiosReq.data);
  } catch (err) {
    logger.error(
      `Error while getting audios: ${JSON.stringify(
        err?.response?.data
      )} with status ${err?.response?.status}`
    );
    res.status(err?.response?.status).send(err?.response?.data);
  }
});

api.delete("/deleteSound", async (req, res) => {
  logger.http(`DELETE /deleteSound with data ${JSON.stringify(req.body)}`);

  if (!req.body.filename) {
    res.send({ error: true, errorCode: "MISSING_FILENAME" });
    return;
  }

  //It's just the same request sent to the audio microservice
  try {
    let deleteReq = await axios.delete(`${AUDIO_URL}/v1/deleteSound`, {
      data: {
        filename: req.body.filename,
      },
    });
    res.status(deleteReq.status).send(deleteReq.data);
    logger.info(
      `Delete request is complete with response ${deleteReq.data} and status ${deleteReq.status}`
    );
  } catch (err) {
    logger.warn(
      `Error while deleting audio ${req.body.filename}: ${JSON.stringify(
        err?.response?.data
      )} with status ${err?.response?.status}`
    );
    res.status(500).send({ error: true });
  }
});

api.put("/tempMuteAudio", async (req, res) => {
  logger.http(`PUT /tempMuteAudio with body ${JSON.stringify(req.body)}`);

  //It's just the same request sent to the audio microservice
  try {
    let audioReq = await axios.put(`${AUDIO_URL}/v1/tempMuteAudio`, {
      duration: req.body?.duration,
    });
    res.status(audioReq.status).send(audioReq.data);
  } catch (err) {
    logger.warn(
      `Error while temp-muting the current audio: ${JSON.stringify(
        err?.response?.data
      )} with status ${err?.response?.status}`
    );
    res
      .status(err?.response?.status)
      .send({ ...err?.response?.data, ...{ error: true } });
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
}

init();
export { io };
