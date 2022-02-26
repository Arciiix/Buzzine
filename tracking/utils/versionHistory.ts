import { Op } from "sequelize";
import { ITrackingEntryObject } from "..";
import TrackingVersionHistoryModel from "../models/TrackingVersionHistory";
import { VERSION_HISTORY_MAX_DAYS } from "./constants";
import { toDateTimeString } from "./formatting";
import logger from "./logger";

async function saveVersionHistory(
  entryId: string,
  date: Date,
  oldValues: ITrackingEntryObject,
  newValues: ITrackingEntryObject
): Promise<void> {
  let fieldsCounter = 0;
  for await (const [key, value] of Object.entries(newValues)) {
    if (!value) continue;
    if (
      key === "updatedAt" ||
      key === "createdAt" ||
      key === "entryId" ||
      key === "date"
    )
      continue;
    let safeValue;
    if (value instanceof Date) {
      safeValue = value.toISOString();
    } else {
      safeValue = value.toString();
    }
    if (oldValues[key] !== safeValue) {
      await TrackingVersionHistoryModel.create({
        entryId: entryId,
        date: date,
        fieldName: key,
        value: safeValue,
      });
      fieldsCounter++;
    }
  }

  logger.info(
    `Saved version history for ${fieldsCounter} field(s) of date ${toDateTimeString(
      date
    )}`
  );
}

async function clearOldVersionHistory(): Promise<void> {
  let minDate: Date = new Date(
    new Date().getTime() - VERSION_HISTORY_MAX_DAYS * 1000 * 60 * 60 * 24
  );

  await TrackingVersionHistoryModel.destroy({
    where: {
      date: {
        [Op.lt]: minDate,
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
