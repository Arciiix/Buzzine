import { Sequelize } from "sequelize";
import logger from "./logger";

const db = new Sequelize({
  dialect: "sqlite",
  storage: "./buzzineAdapter.db",
  logging: (msg) => logger.debug(msg),
});

async function initDatabase() {
  try {
    await db.authenticate();
    logger.info(`Connected to the API database`);
    //await db.sync({ force: true });
    await db.sync();
  } catch (err) {
    logger.error(`Cannot connect to the database`, err);
    throw err;
  }
}

export default db;
export { initDatabase };
