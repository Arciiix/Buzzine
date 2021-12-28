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
    //await db.sync({ force: true });
    await db.sync();
  } catch (err) {
    logger.error(`Cannot connect to the database`, err);
    throw err;
  }
}

export default db;
export { initDatabase };
