import dotenv from "dotenv";
dotenv.config();

const PORT = process.env.PORT ?? 2222;
const TASMOTA_URL: string = process.env.TASMOTA_URL ?? "http://192.168.0.130";
const RELAY_INDEX: number = parseInt(process.env.RELAY_INDEX ?? "1");
const CORE_URL: string = process.env.CORE_URL ?? "http://localhost:3333";
const HEARTBEAT_CRONJOB = process.env.HEARTBEAT_CRONJOB ?? "*/3 * * * *";
const TEMPERATURE_CRONJOB = process.env.TEMPERATURE_CRONJOB ?? "*/15 * * * *";

export {
  PORT,
  TASMOTA_URL,
  RELAY_INDEX,
  CORE_URL,
  HEARTBEAT_CRONJOB,
  TEMPERATURE_CRONJOB,
};
