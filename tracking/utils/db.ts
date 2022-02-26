import { Sequelize } from "sequelize";
import TrackingEntryModel from "../models/TrackingEntry";
import logger from "./logger";

const db = new Sequelize({
  dialect: "sqlite",
  storage: "./buzzineTracking.db",
  // logging: (msg) => logger.debug(msg),
  logging: (msg) => null,
});

async function initDatabase() {
  try {
    await db.authenticate();
    logger.info(`Connected to the tracking database`);
    // await db.sync({ force: true });
    await db.sync();
  } catch (err) {
    logger.error(`Cannot connect to the database: `, err);
    throw err;
  }
}

export default db;
export { initDatabase };
