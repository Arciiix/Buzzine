import { PrismaClient } from "@prisma/client";
import logger from "./logger";

const db = new PrismaClient();

async function initDatabase() {
  await db.$connect();
  logger.info(`Connected to the database`);

  //Logging
  db.$use(async (params, next) => {
    const before = Date.now();
    const result = await next(params);
    const after = Date.now();

    logger.debug(
      `Query ${params.model}.${params.action} took ${after - before}ms`
    );

    return result;
  });
}

export default db;
export { initDatabase };
