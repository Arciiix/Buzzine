import dotenv from "dotenv";
dotenv.config();

const PORT = process.env.PORT || 4444;
const VERSION_HISTORY_MAX_DAYS =
  parseInt(process.env.VERSION_HISTORY_MAX_DAYS) || 7;

export { PORT, VERSION_HISTORY_MAX_DAYS };
