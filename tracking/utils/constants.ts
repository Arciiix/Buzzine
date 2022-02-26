import dotenv from "dotenv";
import { parseHHmm } from "./formatting";
dotenv.config();

const PORT = process.env.PORT || 4444;
const VERSION_HISTORY_MAX_DAYS =
  parseInt(process.env.VERSION_HISTORY_MAX_DAYS) || 7;
const TRACKER_DAY_START_TEXT = process.env.TRACKER_DAY_START ?? "20:00";
const TRACKER_DAY_START = parseHHmm(TRACKER_DAY_START_TEXT, {
  hour: 20,
  minute: 0,
});

const STATS_REFRESH_TIME_TEXT = process.env.STATS_REFRESH_TIME ?? "15:00";
const STATS_REFRESH_TIME = parseHHmm(STATS_REFRESH_TIME_TEXT, {
  hour: 15,
  minute: 0,
});

export {
  PORT,
  VERSION_HISTORY_MAX_DAYS,
  TRACKER_DAY_START,
  STATS_REFRESH_TIME,
};
