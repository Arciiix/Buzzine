import express from "express";
import { Op } from "sequelize";
import TrackingEntryModel from "./models/TrackingEntry";
import TrackingVersionHistoryModel from "./models/TrackingVersionHistory";
import {
  API_URL,
  PORT,
  STATS_REFRESH_TIME,
  TRACKER_DAY_START,
} from "./utils/constants";
import { initDatabase } from "./utils/db";
import {
  dateTimeToDateOnly,
  toDateString,
  toDateTimeString,
} from "./utils/formatting";
import logger, { logHTTPEndpoints } from "./utils/logger";
import Stats, { statsRouter } from "./utils/stats";
import {
  clearOldVersionHistory,
  saveVersionHistory,
} from "./utils/versionHistory";
import schedule, { Job } from "node-schedule";
import axios from "axios";

const app = express();
const api = express.Router();

app.use(express.json());
app.use(logHTTPEndpoints);
app.use("/v1", api);
api.use("/stats", statsRouter);

api.get("/ping", (req, res) => {
  res.send({ error: false, timestamp: new Date() });
});

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

api.get("/getLastTrackingEntries/:count", async (req, res) => {
  let count = parseInt(req.params.count as string);
  if (isNaN(count)) {
    res.status(400).send({ error: true, errorCode: "WRONG_COUNT" });
    return;
  }

  let data = await TrackingEntryModel.findAll({
    limit: count,
    order: [["date", "DESC"]],
  });

  res.send({ error: false, count: count, response: data });
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
    alarmTimeFrom: dbObject.alarmTimeFrom,
    alarmTimeTo: dbObject.alarmTimeTo,
    rate: dbObject.rate,
    timeTakenToTurnOffTheAlarm: dbObject.timeTakenToTurnOffTheAlarm,
    notes: dbObject.notes,
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
  if (req.body.updateObject.alarmTimeFrom) {
    dbObject.alarmTimeFrom = new Date(req.body.updateObject.alarmTimeFrom);
  }
  if (req.body.updateObject.alarmTimeTo) {
    dbObject.alarmTimeTo = new Date(req.body.updateObject.alarmTimeTo);
  }
  if (req.body.updateObject.rate) {
    dbObject.rate = parseInt(req.body.updateObject.rate);
  }
  if (req.body.updateObject.notes) {
    dbObject.notes = req.body.updateObject.notes.toString();
  }
  if (req.body.updateObject.timeTakenToTurnOffTheAlarm) {
    dbObject.timeTakenToTurnOffTheAlarm = parseInt(
      req.body.updateObject.timeTakenToTurnOffTheAlarm
    );
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
    alarmTimeFrom: dbObject.alarmTimeFrom,
    alarmTimeTo: dbObject.alarmTimeTo,
    timeTakenToTurnOffTheAlarm: dbObject.timeTakenToTurnOffTheAlarm,
    rate: dbObject.rate,
    notes: dbObject.notes,
  };

  for (const [key, value] of Object.entries(req.body.updateObject)) {
    if (!value) continue;

    //If a field has its own value already, don't change it, but add a new version history
    if (dbObject[key]) {
      await saveVersionHistory(
        dbObject.entryId,
        new Date(dbObject.date),
        {
          [key]: dbObject[key],
        },
        {
          [key]: value,
        }
      );

      continue;
    }
    if (key === "rate") {
      dbObject[key] = parseInt(value as string);
    } else if (key === "notes") {
      dbObject[key] = value.toString();
    } else {
      dbObject[key] = new Date(value as string);
    }
  }

  await dbObject.save();

  await saveVersionHistory(
    dbObject.entryId,
    new Date(dbObject.date),
    oldValues,
    dbObject.dataValues
  );
  clearOldVersionHistory();

  //If user updates the sleepTime, check if there's any alarm set for tomorrow, and if there isn't, notify user about that
  if (req.body.updateObject.sleepTime) {
    //Get upcoming alarms
    try {
      let { data } = await axios.get(`${API_URL}/v1/getUpcomingAlarms`);

      let allAlarms: any[] = [...data.response.alarms, ...data.response.naps];
      //Check if there's any upcoming element with date which is earlier than (the date variable + 24 hours)
      if (
        !allAlarms.find(
          (e: any) =>
            new Date(e.invocationDate).getTime() <
            date.getTime() + 1000 * 60 * 60 * 24
        )
      ) {
        logger.info(
          "User set the sleepTime but there's no alarm set for tomorrow"
        );

        await axios.post(`${API_URL}/v1/notifications/sendNotification`, {
          notificationPayload: {
            body: "Nie znaleziono żadnego alarmu na jutro!",
            color: "#f1c40f",
            title: "brak alarmu",
          },
        });
        logger.info(
          "Notification about missing alarm for the next day has been sent"
        );
      } else {
        let theEarliestAlarm = allAlarms.sort(
          (a, b) =>
            new Date(a.invocationDate).getTime() -
            new Date(b.invocationDate).getTime()
        )[0];

        let isNap =
          theEarliestAlarm.napId || theEarliestAlarm.alarmId.includes("NAP/");

        await axios.post(`${API_URL}/v1/notifications/sendNotification`, {
          notificationPayload: {
            body: `Najbliższ${
              isNap ? "a drzemka" : "y alarm"
            }: ${toDateTimeString(new Date(theEarliestAlarm.invocationDate))}`,
            color: "#0078f2",
            title: `najbliższ${isNap ? "a drzemka" : "y alarm"}`,
          },
        });
        logger.info("Notification about the next alarm has been sent");
      }
    } catch (err) {
      logger.error(
        `Error while getting upcoming alarms, while trying to notify user if there's no alarm set for the next day: ${err.toString()}; ${JSON.stringify(
          err?.response?.data ?? ""
        )} with status ${err?.response?.status}`
      );
    }
  }

  res.send({
    error: false,
    response: dbObject,
  });
});

api.put("/updateTimeTurningOffAlarmForLatest", async (req, res) => {
  if (!req.body.time || isNaN(parseInt(req.body.time))) {
    res.status(400).send({ error: true, errorCode: "WRONG_TIME" });
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

  //Update the time taken to turn off the alarm only if user hasn't woken/gotten up yet
  if (dbObject?.getUpTime) {
    res.status(200).send({ error: false, response: { updated: false } });
    return;
  } else {
    await saveVersionHistory(
      dbObject.entryId,
      new Date(dbObject.date),
      {
        timeTakenToTurnOffTheAlarm: dbObject.timeTakenToTurnOffTheAlarm,
      },
      {
        timeTakenToTurnOffTheAlarm:
          dbObject.timeTakenToTurnOffTheAlarm + parseInt(req.body.time),
      }
    );
    dbObject.timeTakenToTurnOffTheAlarm += parseInt(req.body.time);
    await dbObject.save();
    logger.info(
      `Updated the time taken to turn off the alarm of date ${toDateString(
        new Date(dbObject.date)
      )} to ${dbObject.timeTakenToTurnOffTheAlarm}`
    );
  }
});

async function init() {
  await initDatabase();
  Stats.calculateStats();

  const statsScheduleRule = new schedule.RecurrenceRule();
  statsScheduleRule.hour = STATS_REFRESH_TIME.hour;
  statsScheduleRule.minute = STATS_REFRESH_TIME.minute;
  schedule.scheduleJob(statsScheduleRule, Stats.calculateStats);
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
  alarmTimeFrom?: Date;
  alarmTimeTo?: Date;
  timeTakenToTurnOffTheAlarm?: number;
  rate?: number;
  notes?: string;
}

export { ITrackingEntryObject };
