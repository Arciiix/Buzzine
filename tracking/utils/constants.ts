import dotenv from "dotenv";
import { parseHHmm } from "./formatting";
dotenv.config();

const PORT = process.env.PORT || 4444;
const VERSION_HISTORY_MAX_DAYS =
  parseInt(process.env.VERSION_HISTORY_MAX_DAYS) || 7;
const TRACKER_DAY_START_TEXT = process.env.TRACKER_DAY_START ?? "20:00";
const TRACKER_DAY_START = parseHHmm(TRACKER_DAY_START_TEXT, {
  hour: 16,
  minute: 0,
});

export { PORT, VERSION_HISTORY_MAX_DAYS, TRACKER_DAY_START };
