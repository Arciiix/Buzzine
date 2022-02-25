import express from "express";
import { PORT, TRACKER_DAY_START } from "./utils/constants";
import db, { initDatabase } from "./utils/db";
import {
  dateTimeToDateOnly,
  toDateString,
  toDateTimeString,
} from "./utils/formatting";
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

  let data = await db.trackingEntry.findMany({
    where: {
      date: {
        gte: dateTimeToDateOnly(new Date(req.query.day as string)),
        lt: dateTimeToDateOnly(
          new Date(
            dateTimeToDateOnly(new Date(req.query.day as string)).getTime() +
              24 * 60 * 60 * 1000
          )
        ),
      },
    },
  });

  res.send({ error: false, response: data });
  logger.info(
    `Sent data for date ${toDateString(new Date(req.query.day as string))}`
  );
});

api.get("/getLatest", async (req, res) => {
  let date = new Date();
  if (
    date.getHours() * 60 + date.getMinutes() >
    TRACKER_DAY_START.hour * 60 + TRACKER_DAY_START.minute
  ) {
    date.setDate(date.getDate() + 1);
  }

  date = dateTimeToDateOnly(date);

  let latest = await db.trackingEntry.findFirst({
    where: {
      date: {
        gte: date,
        lt: new Date(date.getTime() + 1000 * 60 * 60 * 24),
      },
    },
    orderBy: [
      {
        date: "desc",
      },
    ],
  });

  if (!latest) {
    logger.info(
      "There's no object for the latest date, so creating an empty one"
    );
    latest = await db.trackingEntry.create({
      data: {
        date: date,
      },
    });
  }

  res.send({ error: false, response: latest });
});

api.get("/getVersionHistoryForDate", async (req, res) => {
  if (!req.query.date || isNaN(new Date(req.query.date as string)?.getTime())) {
    res.status(400).send({ error: true, errorCode: "WRONG_DATE" });
    return;
  }

  let versionHistory = await db.trackingVersionHistory.findMany({
    where: {
      date: new Date(req.query.date as string),
    },
  });

  res.send({ error: false, response: versionHistory });
});

api.put("/updateDataForDate", async (req, res) => {
  if (!req.body.date || isNaN(new Date(req.body.date)?.getTime())) {
    res.status(400).send({ error: true, errorCode: "WRONG_DATE" });
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
      date: new Date(req.body.date),
    },
    update: {},
    create: {
      date: new Date(req.body.date),
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

  await saveVersionHistory(new Date(req.body.date), oldValues, updateObject);

  await db.trackingEntry.update({
    where: {
      date: new Date(req.body.date),
    },
    data: updateObject,
  });

  clearOldVersionHistory();

  logger.info(
    `Updated data for date ${toDateTimeString(new Date(req.body.date))}`
  );

  res.send({
    error: false,
    response: await db.trackingEntry.findUnique({
      where: { date: new Date(req.body.date) },
    }),
  });
});

api.put("/updateDataForLatestIfDoesntExist", async (req, res) => {
  if (!req.body.updateObject || typeof req.body.updateObject !== "object") {
    res.status(400).send({ error: true, errorCode: "WRONG_UPDATE_OBJECT" });
    return;
  }

  let date = new Date();
  if (
    date.getHours() * 60 + date.getMinutes() >
    TRACKER_DAY_START.hour * 60 + TRACKER_DAY_START.minute
  ) {
    date.setDate(date.getDate() + 1);
  }

  date = dateTimeToDateOnly(date);

  //Find a daytime nap, and if it exists - change the targeted date to it
  let latest = await db.trackingEntry.findFirst({
    where: {
      date: {
        gt: date,
        lt: new Date(date.getTime() + 1000 * 60 * 60 * 24),
      },
    },
    orderBy: [
      {
        date: "desc",
      },
    ],
  });

  if (latest) {
    logger.info(
      `Found newer entry (probably a nap) with date ${toDateTimeString(
        latest.date
      )}`
    );
    date = latest.date;
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
      date: date,
    },
    update: {},
    create: {
      date: date,
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
          date: date,
        },
        data: {
          [key]: value,
        },
      });
      await saveVersionHistory(date, oldValues, {
        [key]: value,
      });
    }
  }

  clearOldVersionHistory();

  res.send({
    error: false,
    response: await db.trackingEntry.findUnique({
      where: { date: date },
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
