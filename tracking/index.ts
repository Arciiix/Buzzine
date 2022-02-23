import express from "express";
import { PORT } from "./utils/constants";
import db, { initDatabase } from "./utils/db";
import { dateTimeToDateOnly, toDateString } from "./utils/formatting";
import logger, { logHTTPEndpoints } from "./utils/logger";
import {
  clearOldVersionHistory,
  saveVersionHistory,
} from "./utils/versionHistory";

const app = express();
const api = express.Router();
app.use(express.json());
app.use(logHTTPEndpoints);
app.use("/v1", api);

api.get("/getDataForDay", async (req, res) => {
  if (!req.query.day || isNaN(new Date(req.query.day as string)?.getTime())) {
    res.status(400).send({ error: true, errorCode: "WRONG_DAY" });
    return;
  }

  let data = await db.trackingEntry.findFirst({
    where: {
      day: dateTimeToDateOnly(new Date(req.query.day as string)),
    },
  });

  res.send({ error: false, response: data });
  logger.info(
    `Sent data for date ${toDateString(new Date(req.query.day as string))}`
  );
});

api.put("/updateDataForDay", async (req, res) => {
  if (!req.body.day || isNaN(new Date(req.body.day)?.getTime())) {
    res.status(400).send({ error: true, errorCode: "WRONG_DAY" });
    return;
  }
  if (!req.body.updateObject || typeof req.body.updateObject !== "object") {
    res.status(400).send({ error: true, errorCode: "WRONG_UPDATE_OBJECT" });
    return;
  }

  let updateObject: ITrackingEntryObject = {
    bedTime: req.body.updateObject.bedTime,
    sleepTime: req.body.updateObject.sleepTime,
    firstAlarmTime: req.body.updateObject.firstAlarmTime,
    wakeUpTime: req.body.updateObject.wakeUpTime,
    getUpTime: req.body.updateObject.getUpTime,
    rate: req.body.updateObject.rate,
  };

  let dbObject = await db.trackingEntry.upsert({
    where: {
      day: dateTimeToDateOnly(new Date(req.body.day)),
    },
    update: {},
    create: {
      day: dateTimeToDateOnly(new Date(req.body.day)),
      ...updateObject,
    },
  });

  let oldValues: ITrackingEntryObject = {
    bedTime: dbObject.bedTime,
    sleepTime: dbObject.sleepTime,
    firstAlarmTime: dbObject.firstAlarmTime,
    wakeUpTime: dbObject.wakeUpTime,
    getUpTime: dbObject.getUpTime,
    rate: dbObject.rate,
  };

  await saveVersionHistory(
    dateTimeToDateOnly(new Date(req.body.day)),
    oldValues,
    updateObject
  );

  await db.trackingEntry.update({
    where: {
      day: dateTimeToDateOnly(new Date(req.body.day)),
    },
    data: updateObject,
  });

  clearOldVersionHistory();

  logger.info(`Updated data for day ${toDateString(new Date(req.body.day))}`);

  res.send({
    error: false,
    response: await db.trackingEntry.findUnique({
      where: { day: dateTimeToDateOnly(new Date(req.body.day)) },
    }),
  });
});

api.put("/updateDataForDayIfDoesntExist", async (req, res) => {
  if (!req.body.day || isNaN(new Date(req.body.day)?.getTime())) {
    res.status(400).send({ error: true, errorCode: "WRONG_DAY" });
    return;
  }
  if (!req.body.updateObject || typeof req.body.updateObject !== "object") {
    res.status(400).send({ error: true, errorCode: "WRONG_UPDATE_OBJECT" });
    return;
  }

  let updateObject: ITrackingEntryObject = {
    bedTime: req.body.updateObject.bedTime,
    sleepTime: req.body.updateObject.sleepTime,
    firstAlarmTime: req.body.updateObject.firstAlarmTime,
    wakeUpTime: req.body.updateObject.wakeUpTime,
    getUpTime: req.body.updateObject.getUpTime,
    rate: req.body.updateObject.rate,
  };

  let dbObject = await db.trackingEntry.upsert({
    where: {
      day: dateTimeToDateOnly(new Date(req.body.day)),
    },
    update: {},
    create: {
      day: dateTimeToDateOnly(new Date(req.body.day)),
      ...updateObject,
    },
  });

  let oldValues: ITrackingEntryObject = {
    bedTime: dbObject.bedTime,
    sleepTime: dbObject.sleepTime,
    firstAlarmTime: dbObject.firstAlarmTime,
    wakeUpTime: dbObject.wakeUpTime,
    getUpTime: dbObject.getUpTime,
    rate: dbObject.rate,
  };

  for await (const [key, value] of Object.entries(updateObject)) {
    if (!value) continue;
    if (
      !oldValues[key] &&
      new Date(oldValues[key]).getTime() !== new Date(value).getTime()
    ) {
      await db.trackingEntry.update({
        where: {
          day: dateTimeToDateOnly(new Date(req.body.day)),
        },
        data: {
          [key]: value,
        },
      });
      await saveVersionHistory(
        dateTimeToDateOnly(new Date(req.body.day)),
        oldValues,
        { [key]: value }
      );
    }
  }

  clearOldVersionHistory();

  res.send({
    error: false,
    response: await db.trackingEntry.findUnique({
      where: { day: dateTimeToDateOnly(new Date(req.body.day)) },
    }),
  });
});

async function init() {
  await initDatabase();
}

app.listen(PORT, () => {
  logger.info(`Tracking has started on port ${PORT}`);
});

init();

interface ITrackingEntryObject {
  bedTime?: Date;
  sleepTime?: Date;
  firstAlarmTime?: Date;
  wakeUpTime?: Date;
  getUpTime?: Date;
  rate?: number;
}

export { ITrackingEntryObject };
