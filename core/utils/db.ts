import { Sequelize } from "sequelize";
import loadDataFromDB from "./loadFromDb";
import logger from "./logger";

const db = new Sequelize({
  dialect: "sqlite",
  storage: "./buzzine.db",
  logging: (msg) => logger.debug(msg),
});

async function initDatabase() {
  try {
    await db.authenticate();
    logger.info(`Connected to the database`);
    await db.sync();
  } catch (err) {
    logger.error(`Cannot connect to the database`, err);
    //TODO: Maybe throw an error?
  }
}

export default db;
export { initDatabase };
