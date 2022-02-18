import bodyParser from "body-parser";
import express from "express";
import socketio from "socket.io-client";
import logger, { logHTTPEndpoints } from "./logger";
import axios from "axios";
import schedule from "node-schedule";
import { initDatabase } from "./db";
import {
  calculateCurrentTemperatureData,
  calculateTemperatureDataForDay,
  fetchTemperature,
  ICurrentTemperatureData,
  ITemperatureData,
  saveTemperature,
} from "./temperature";
import {
  CORE_URL,
  HEARTBEAT_CRONJOB,
  PORT,
  PROTECTION_DELAY,
  RELAY_INDEX,
  TASMOTA_URL,
  TEMPERATURE_CRONJOB,
} from "./constants";
import TemperatureModel from "./models/Temperature";

let heartbeatsJob: schedule.Job, temperaturesJob: schedule.Job;
let isProtectionTurnedOn = true;

const app = express();
app.use(bodyParser.json());
const api = express.Router();
app.use("/v1", api);
api.use(logHTTPEndpoints);
const socket = socketio(CORE_URL);

app.get("/", async (req, res) => {
  let now = new Date();
  let isTasmotaAvailable = false;
  try {
    await axios.get(TASMOTA_URL);
    isTasmotaAvailable = true;
    logger.info("Pinged Tasmota");
  } catch (err) {
    logger.error("Error while pinging Tasmota");
  }
  if (!isTasmotaAvailable) res.status(502);
  res.send({
    error: !isTasmotaAvailable,
    timestamp: new Date(),
    currentVersion: "v1",
    Tasmota: {
      isAvailable: isTasmotaAvailable,
      delay: new Date().getTime() - now.getTime(),
    },
  });
});

api.get("/ping", (req, res) => {
  res.send({ error: false, timestamp: new Date() });
});

api.get("/getTemperature", async (req, res) => {
  let temperature = await fetchTemperature();
  res.send({ error: false, temperature });
});

api.get("/getCurrentTemperatureData", async (req, res) => {
  let temperatureData: ICurrentTemperatureData =
    await calculateCurrentTemperatureData();
  res.send({ error: false, response: temperatureData });
});

api.get("/getHistoricalDailyTemperatureData", async (req, res) => {
  if (!req.query.date) {
    res.status(400).send({ error: true, errorCode: "MISSING_DATE" });
    return;
  }

  if (isNaN(new Date(req.query.date as string)?.getTime())) {
    res.status(400).send({ error: true, errorCode: "WRONG_DATE" });
    return;
  }

  let temperatureData: ITemperatureData = await calculateTemperatureDataForDay(
    new Date(req.query.date as string)
  );
  res.send({ error: false, response: temperatureData });
});

api.get("/getStatus", async (req, res) => {
  res.send({
    error: false,
    response: {
      isRelayOn: await getRelayStatus(),
      isProtectionTurnedOn,
    },
  });
});

api.put("/toogleEmergency", async (req, res) => {
  //Don't check if user provided the isTurnedOn param - the default is to turn on
  let success = await toogleEmergencyDevice(
    Boolean(req.body.isTurnedOn ?? true)
  );

  res.send({ error: !success });
});

api.put("/toogleProtection", async (req, res) => {
  if (req.body.isTurnedOn === undefined || req.body.isTurnedOn === null) {
    res.status(400).send({ error: true, errorCode: "MISSING_IS_TURNED_ON" });
    return;
  }

  try {
    if (req.body.isTurnedOn) {
      await sendHeartbeat();
      //Signal the change by shorter signal
      await axios.get(`${TASMOTA_URL}/cm?cmnd=RuleTimer3%201`);
      isProtectionTurnedOn = true;
    } else {
      //Turn off the RuleTimer
      await axios.get(`${TASMOTA_URL}/cm?cmnd=RuleTimer1%200`);
      //Signal the change by longer signal
      await axios.get(`${TASMOTA_URL}/cm?cmnd=RuleTimer4%201`);
      isProtectionTurnedOn = false;
    }
    res.send({ error: false });
  } catch (err) {
    logger.error(
      `Error while trying to turn the protection ${
        req.body.isTurnedOn ? "on" : "off"
      }: ${err?.response?.status} with data: ${JSON.stringify(
        err?.response?.data
      )}`
    );
    res.status(502).send({ error: true, errorCode: err?.response?.data });
  }
});

api.put("/tempMute", async (req, res) => {
  if (!req.body.duration) {
    res.status(400).send({ error: true, errorCode: "MISSING_DURATION" });
    logger.warn(`Tried to temp-mute but duration is missing`);
    return;
  }
  let duration = parseInt(req.body.duration);

  if (isNaN(duration)) {
    res.status(400).send({ error: true, errorCode: "WRONG_DURATION" });
    logger.warn(`Tried to temp-mute but duration is wrong`);
    return;
  }

  //Check if the device is turned on
  let relayStatus = await getRelayStatus();
  if (relayStatus) {
    //If the device is turned on, turn it off temporary
    try {
      await axios.get(
        `${TASMOTA_URL}/cm?cmnd=Backlog%20Power${RELAY_INDEX}%200%3BRuleTimer1%20${req.body.duration}`
      );
    } catch (err) {
      logger.error(
        `Error while trying to temp-mute: ${
          err?.response?.status
        } with data: ${JSON.stringify(err?.response?.data)}`
      );
    }
  }
});

socket.on("connect", () => {
  logger.info(
    `Made a connection with the core, waiting for the initial message...`
  );
});
socket.on("hello", () => {
  logger.info(`Successfully connected to the core`);
});
socket.on("EMERGENCY_ALARM", async (data) => {
  toogleEmergencyDevice(true);
});
socket.on("TOOGLE_EMERGENCY_DEVICE", async (data) => {
  toogleEmergencyDevice(data.isTurnedOn ?? true);
});
socket.on("EMERGENCY_ALARM_CANCELLED", async (data) => {
  toogleEmergencyDevice(false);
});

async function getRelayStatus(): Promise<boolean | null> {
  try {
    let response = await axios.get(
      `${TASMOTA_URL}/cm?cmnd=Power${RELAY_INDEX}`
    );
    let isRelayOn = response.data["POWER" + RELAY_INDEX] === "ON";
    return isRelayOn;
  } catch (err) {
    logger.error(
      `Error while trying to get the relay status: ${
        err?.response?.status
      } with data: ${JSON.stringify(err?.response?.data)}`
    );
    return null;
  }
}

async function toogleEmergencyDevice(isTurnedOn: boolean): Promise<boolean> {
  logger.info(`Turning ${isTurnedOn ? "on" : "off"} the emergency device...`);

  try {
    await axios.get(
      `${TASMOTA_URL}/cm?cmnd=Power${RELAY_INDEX}%20${isTurnedOn ? "1" : "0"}`
    );
    logger.info(`Turned ${isTurnedOn ? "on" : "off"} the emergency device`);
    await sendHeartbeat();
    return true;
  } catch (err) {
    logger.error(
      `Error while trying to turn ${
        isTurnedOn ? "on" : "off"
      } the emergency device: ${
        err?.response?.status
      } with data: ${JSON.stringify(err?.response?.data)}`
    );
    return false;
  }
}

async function sendHeartbeat() {
  try {
    //The heartbeat is Timer1 *DELAY* command (setting timer 1 for *DELAY* seconds). Timer1 is a timer which turns on the emergency device.
    await axios.get(
      `${TASMOTA_URL}/cm?cmnd=RuleTimer1%20${
        isProtectionTurnedOn ? PROTECTION_DELAY.toString() : "0"
      }`
    );
    logger.info("Sent the heartbeat to Tasmota");
  } catch (err) {
    logger.error(
      `Error while trying to send the heartbeat to Tasmota: ${
        err?.response?.status
      } with data: ${JSON.stringify(err?.response?.data)}}`
    );
  }
}

async function init() {
  await initDatabase();
  heartbeatsJob = schedule.scheduleJob(HEARTBEAT_CRONJOB, sendHeartbeat);
  temperaturesJob = schedule.scheduleJob(TEMPERATURE_CRONJOB, saveTemperature);
}

app.listen(PORT, () => {
  logger.info(`Adapter API has started on port ${PORT}`);
});

init();
