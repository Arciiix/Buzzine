import express from "express";
import socketio from "socket.io-client";
import dotenv from "dotenv";
import logger from "./logger";
import axios from "axios";
import schedule from "node-schedule";

dotenv.config();

const PORT = process.env.PORT ?? 2222;
const TASMOTA_URL: string = process.env.TASMOTA_URL ?? "http://192.168.0.130";
const RELAY_INDEX: number = parseInt(process.env.RELAY_INDEX ?? "1");
const CORE_URL: string = process.env.CORE_URL ?? "http://localhost:3333";
const HEARTBEAT_CRONJOB = process.env.HEARTBEAT_CRONJOB ?? "*/3 * * * *";
const TEMPERATURE_CRONJOB = process.env.TEMPERATURE_CRONJOB ?? "*/15 * * * *";

let heartbeatsJob: schedule.Job, temperaturesJob: schedule.Job;

const app = express();
const api = express.Router();
app.use("/v1", api);
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

api.get("/getTemperature", async (req, res) => {
  let temperature = await fetchTemperature();
  res.send({ error: false, temperature });
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
  turnOnEmergencyDevice();
});

async function turnOnEmergencyDevice() {
  logger.info("Turning on the emergency device...");

  try {
    await axios.get(`${TASMOTA_URL}/cm?cmnd=Power${RELAY_INDEX}%201`);
    logger.info("Turned on the emergency device");
  } catch (err) {
    logger.error(
      `Error while trying to turn on the emergency device: ${
        err?.response?.status
      } with data: ${JSON.stringify(err?.response?.data)}}`
    );
  }
}

async function sendHeartbeat() {
  try {
    //The heartbeat is Timer1 600 command (setting timer 1 for 600 seconds). Timer1 is a timer which turns on the emergency device.
    await axios.get(`${TASMOTA_URL}/cm?cmnd=Timer1%20600`);
    logger.info("Sent the heartbeat to Tasmota");
  } catch (err) {
    logger.error(
      `Error while trying to send the heartbeat to Tasmota: ${
        err?.response?.status
      } with data: ${JSON.stringify(err?.response?.data)}}`
    );
  }
}

async function fetchTemperature(): Promise<number> {
  try {
    let response = await axios.get(`${TASMOTA_URL}/cm?cmnd=Status%2010`);
    let temperature: number = parseFloat(
      response.data.StatusSNS.DS18B20.Temperature
    );
    logger.info(`Got the temperature: ${temperature}`);
    return temperature;
  } catch (err) {
    logger.error(
      `Error while trying to send the heartbeat to Tasmota: ${
        err?.response?.status
      } with data: ${JSON.stringify(err?.response?.data)}}`
    );
  }
}

function init() {
  heartbeatsJob = schedule.scheduleJob(HEARTBEAT_CRONJOB, sendHeartbeat);
  temperaturesJob = schedule.scheduleJob(TEMPERATURE_CRONJOB, fetchTemperature);
}

app.listen(PORT, () => {
  logger.info(`Adapter API has started on port ${PORT}`);
});

init();
