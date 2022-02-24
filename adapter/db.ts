import { PrismaClient } from "@prisma/client";
import logger from "./logger";

const db = new PrismaClient();

async function initDatabase() {
  await db.$connect();
  logger.info(`Connected to the database`);
}

export default db;
export { initDatabase };
