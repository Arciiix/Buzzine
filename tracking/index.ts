import express from "express";
import { Op } from "sequelize";
import TrackingEntryModel from "./models/TrackingEntry";
import TrackingVersionHistoryModel from "./models/TrackingVersionHistory";
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

  let data: any = await TrackingEntryModel.findAll({
    where: {
      date: {
        [Op.gte]: dateTimeToDateOnly(new Date(req.query.day as string)),
        [Op.lt]: dateTimeToDateOnly(
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

  let latest = await TrackingEntryModel.findOne({
    where: {
      date: {
        [Op.gte]: date,
        [Op.lt]: new Date(date.getTime() + 1000 * 60 * 60 * 24),
      },
    },
    order: [["date", "DESC"]],
  });

  if (!latest) {
    logger.info(
      "There's no object for the latest date, so create an empty one"
    );
    latest = await TrackingEntryModel.create({
      date: date,
    });
  }

  res.send({ error: false, response: latest });
});

api.get("/getVersionHistoryForDate", async (req, res) => {
  if (!req.query.date || isNaN(new Date(req.query.date as string)?.getTime())) {
    res.status(400).send({ error: true, errorCode: "WRONG_DATE" });
    return;
  }

  let versionHistory = await TrackingVersionHistoryModel.findAll({
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

  let dbObject: any = await TrackingEntryModel.findOne({
    where: { date: new Date(req.body.date) },
  });
  if (!dbObject) {
    dbObject = await TrackingEntryModel.create({
      date: new Date(req.body.date),
    });
  }
  let oldValues: ITrackingEntryObject = {
    bedTime: dbObject.bedTime,
    sleepTime: dbObject.sleepTime,
    firstAlarmTime: dbObject.firstAlarmTime,
    wakeUpTime: dbObject.wakeUpTime,
    getUpTime: dbObject.getUpTime,
    rate: dbObject.rate,
  };

  if (req.body.updateObject.bedTime) {
    dbObject.bedTime = new Date(req.body.updateObject.bedTime);
  }
  if (req.body.updateObject.sleepTime) {
    dbObject.sleepTime = new Date(req.body.updateObject.sleepTime);
  }
  if (req.body.updateObject.firstAlarmTime) {
    dbObject.firstAlarmTime = new Date(req.body.updateObject.firstAlarmTime);
  }
  if (req.body.updateObject.wakeUpTime) {
    dbObject.wakeUpTime = new Date(req.body.updateObject.wakeUpTime);
  }
  if (req.body.updateObject.getUpTime) {
    dbObject.getUpTime = new Date(req.body.updateObject.getUpTime);
  }
  if (req.body.updateObject.rate) {
    dbObject.rate = parseInt(req.body.updateObject.rate);
  }
  await dbObject.save();

  await saveVersionHistory(
    dbObject.entryId,
    new Date(dbObject.date),
    oldValues,
    dbObject.dataValues
  );
  clearOldVersionHistory();

  logger.info(
    `Updated data for date ${toDateTimeString(new Date(req.body.date))}`
  );

  res.send({
    error: false,
    response: dbObject,
  });
});

api.delete("/deleteEntry", async (req, res) => {
  if (!req.body.date || isNaN(new Date(req.body.date)?.getTime())) {
    res.status(400).send({ error: true, errorCode: "WRONG_DATE" });
    return;
  }

  //Check if record exists
  let record = await TrackingEntryModel.findOne({
    where: { date: new Date(req.body.date) },
  });
  if (!record) {
    res.status(404).send({ error: true, errorCode: "NOT_FOUND" });
    return;
  }

  //First of all, delete all relations, so all version history of the given entry
  await TrackingVersionHistoryModel.destroy({
    where: { date: new Date(req.body.date) },
  });

  await TrackingEntryModel.destroy({
    where: { date: new Date(req.body.date) },
  });

  res.send({ error: false });
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
  let latest: any = await TrackingEntryModel.findOne({
    where: {
      date: {
        [Op.gt]: date,
        [Op.lt]: new Date(date.getTime() + 1000 * 60 * 60 * 24),
      },
    },
    order: [["date", "DESC"]],
  });

  if (latest) {
    logger.info(
      `Found newer entry (probably a nap) with date ${toDateTimeString(
        latest.date
      )}`
    );
    date = latest.date;
  }

  let dbObject: any = await TrackingEntryModel.findOne({ where: { date } });
  if (!dbObject) {
    dbObject = await TrackingEntryModel.create({
      date: date,
    });
  }

  let oldValues: ITrackingEntryObject = {
    bedTime: dbObject.bedTime,
    sleepTime: dbObject.sleepTime,
    firstAlarmTime: dbObject.firstAlarmTime,
    wakeUpTime: dbObject.wakeUpTime,
    getUpTime: dbObject.getUpTime,
    rate: dbObject.rate,
  };

  for (const [key, value] of Object.entries(req.body.updateObject)) {
    if (!value) continue;
    if (dbObject[key]) continue; //If a field has its own value already
    dbObject[key] =
      key === "rate" ? parseInt(value as string) : new Date(value as string);
  }

  await dbObject.save();

  await saveVersionHistory(
    dbObject.entryId,
    new Date(dbObject.date),
    oldValues,
    dbObject.dataValues
  );
  clearOldVersionHistory();

  res.send({
    error: false,
    response: dbObject,
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
