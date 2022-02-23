import { ITrackingEntryObject } from "..";
import { VERSION_HISTORY_MAX_DAYS } from "./constants";
import db from "./db";
import { toDateString, toDateTimeString } from "./formatting";
import logger from "./logger";

async function saveVersionHistory(
  day: Date,
  oldValues: ITrackingEntryObject,
  newValues: ITrackingEntryObject
): Promise<void> {
  for await (const [key, value] of Object.entries(newValues)) {
    if (!value) continue;
    if (new Date(oldValues[key]).getTime() !== new Date(value).getTime()) {
      await db.trackingVersionHistory.create({
        data: {
          day: day,
          fieldName: key,
          value: new Date(value), //To fit the data type - it has to be date. When it comes to the rate for example, it can be stored as a date - because it's convereted to the unix timestamp anyway, so it'll be stored as a number
        },
      });
    }
  }

  logger.info(`Saved version history for date ${toDateString(day)}`);
}

async function clearOldVersionHistory(): Promise<void> {
  let minDate: Date = new Date(
    new Date().getTime() - VERSION_HISTORY_MAX_DAYS * 1000 * 60 * 60 * 24
  );

  await db.trackingVersionHistory.deleteMany({
    where: {
      day: {
        lt: minDate,
      },
    },
  });

  logger.info(
    `Cleared old version history to entries before date ${toDateTimeString(
      minDate
    )} (${VERSION_HISTORY_MAX_DAYS} day(s))`
  );
}

export { saveVersionHistory, clearOldVersionHistory };
