import express from "express";
import { Op } from "sequelize";
import TrackingEntryModel from "../models/TrackingEntry";
import { dateTimeToDateOnly } from "./formatting";
import logger from "./logger";

const statsRouter = express.Router();

statsRouter.get("/getStats", (req, res) => {
  if (!Stats.calculationTimestamp) {
    Stats.calculateStats();
  }

  res.send({ error: false, response: Stats.toObject() });
});

statsRouter.put("/calculateStats", (req, res) => {
  Stats.calculateStats();
  res.send({ error: false, response: Stats.toObject() });
});

class Stats {
  static lifetimeStats: IStatsDetails;
  static monthlyStats: IStatsDetails;
  static calculationTimestamp?: Date;

  static async calculateStats() {
    logger.info("Starting calculating stats...");
    //A lot of calculation, you'd better not await or promise this. Just call it in the background

    //Calculated from all entries
    let allEntries: any[] = await TrackingEntryModel.findAll({});
    this.lifetimeStats = this.calculateForElements(allEntries);

    logger.info("Calculated lifetime stats. Waiting for monthly...");

    //Calculated from entries this month
    let month = new Date();
    //The offset is calculated from the average monthly temperature
    month.setDate(1);
    month.setHours(0);
    month.setMinutes(0);

    let endDate = new Date(
      month.getFullYear(),
      month.getMonth() + 1,
      0,
      23,
      59,
      59
    );
    let entriesThisMonth: any[] = await TrackingEntryModel.findAll({
      where: {
        date: {
          [Op.between]: [month, endDate],
        },
      },
    });

    this.monthlyStats = this.calculateForElements(entriesThisMonth);

    logger.info("Stats have been calculated");
    this.calculationTimestamp = new Date();

    return this;
  }

  static calculateForElements(elements: any[]): IStatsDetails {
    let sleepDuration: IAverageCalculation = {
      alarm: { sum: 0, count: 0 },
      nap: { sum: 0, count: 0 },
    };

    let timeAtBed: IAverageCalculation = {
      alarm: { sum: 0, count: 0 },
      nap: { sum: 0, count: 0 },
    };

    let alarmWakeUpProcrastinationTime: IAverageCalculation = {
      alarm: { sum: 0, count: 0 },
      nap: { sum: 0, count: 0 },
    };

    let timeBeforeGettingUp: IAverageCalculation = {
      alarm: { sum: 0, count: 0 },
      nap: { sum: 0, count: 0 },
    };

    for (const element of elements) {
      let isWholeDay =
        dateTimeToDateOnly(new Date(element.date)).getTime() ===
        new Date(element.date).getTime();

      //Sleep duration
      if (element.sleepTime && element.wakeUpTime) {
        sleepDuration[isWholeDay ? "alarm" : "nap"].sum += Math.floor(
          (element.wakeUpTime.getTime() - element.sleepTime.getTime()) / 1000
        );
        sleepDuration[isWholeDay ? "alarm" : "nap"].count++;
      }

      //Time at bed
      if (element.bedTime && element.sleepTime) {
        timeAtBed[isWholeDay ? "alarm" : "nap"].sum += Math.floor(
          (element.sleepTime.getTime() - element.bedTime.getTime()) / 1000
        );
        timeAtBed[isWholeDay ? "alarm" : "nap"].count++;
      }

      //Procrastination time after alarm
      if (element.firstAlarmTime && element.wakeUpTime) {
        alarmWakeUpProcrastinationTime[isWholeDay ? "alarm" : "nap"].sum +=
          Math.floor(
            (element.wakeUpTime.getTime() - element.firstAlarmTime.getTime()) /
              1000
          );
        alarmWakeUpProcrastinationTime[isWholeDay ? "alarm" : "nap"].count++;
      }

      //Time after the alarm before getting up
      if (element.wakeUpTime && element.getUpTime) {
        timeBeforeGettingUp[isWholeDay ? "alarm" : "nap"].sum += Math.floor(
          (element.getUpTime.getTime() - element.wakeUpTime.getTime()) / 1000
        );
        timeBeforeGettingUp[isWholeDay ? "alarm" : "nap"].count++;
      }
    }

    let averageSleepDuration =
      sleepDuration.alarm.sum / sleepDuration.alarm.count;
    let averageSleepDurationNap =
      sleepDuration.nap.sum / sleepDuration.nap.count;

    let averageTimeAtBed = timeAtBed.alarm.sum / timeAtBed.alarm.count;
    let averageTimeAtBedNap = timeAtBed.nap.sum / timeAtBed.nap.count;

    let averageAlarmWakeUpProcrastinationTime =
      alarmWakeUpProcrastinationTime.alarm.sum /
      alarmWakeUpProcrastinationTime.alarm.count;
    let averageAlarmWakeUpProcrastinationTimeNap =
      alarmWakeUpProcrastinationTime.nap.sum /
      alarmWakeUpProcrastinationTime.nap.count;

    let averageTimeBeforeGettingUp =
      timeBeforeGettingUp.alarm.sum / timeBeforeGettingUp.alarm.count;
    let averageTimeBeforeGettingUpNap =
      timeBeforeGettingUp.nap.sum / timeBeforeGettingUp.nap.count;

    if (isNaN(averageSleepDuration)) averageSleepDuration = 0;
    if (isNaN(averageTimeAtBed)) averageTimeAtBed = 0;
    if (isNaN(averageAlarmWakeUpProcrastinationTime))
      averageAlarmWakeUpProcrastinationTime = 0;
    if (isNaN(averageTimeBeforeGettingUp)) averageTimeBeforeGettingUp = 0;

    if (isNaN(averageSleepDurationNap)) averageSleepDurationNap = 0;
    if (isNaN(averageTimeAtBedNap)) averageTimeAtBedNap = 0;
    if (isNaN(averageAlarmWakeUpProcrastinationTimeNap))
      averageAlarmWakeUpProcrastinationTimeNap = 0;
    if (isNaN(averageTimeBeforeGettingUpNap)) averageTimeBeforeGettingUpNap = 0;

    return {
      alarm: {
        averageSleepDuration: Math.floor(averageSleepDuration),
        averageTimeAtBed: Math.floor(averageTimeAtBed),
        averageAlarmWakeUpProcrastinationTime: Math.floor(
          averageAlarmWakeUpProcrastinationTime
        ),
        averageTimeBeforeGettingUp: Math.floor(averageTimeBeforeGettingUp),
      },
      nap: {
        averageSleepDuration: Math.floor(averageSleepDurationNap),
        averageTimeAtBed: Math.floor(averageTimeAtBedNap),
        averageAlarmWakeUpProcrastinationTime: Math.floor(
          averageAlarmWakeUpProcrastinationTimeNap
        ),
        averageTimeBeforeGettingUp: Math.floor(averageTimeBeforeGettingUpNap),
      },
    };
  }

  static toObject(): IStats {
    return {
      lifetime: this.lifetimeStats,
      monthly: this.monthlyStats,
      timestamp: this.calculationTimestamp,
    };
  }
}

interface IAverageCalculation {
  alarm: { sum: number; count: number };
  nap: { sum: number; count: number };
}
interface IStatsObject {
  averageSleepDuration?: number;
  averageTimeAtBed?: number;
  averageAlarmWakeUpProcrastinationTime?: number;
  averageTimeBeforeGettingUp?: number;
}
interface IStatsDetails {
  alarm: IStatsObject;
  nap: IStatsObject;
}
interface IStats {
  lifetime: IStatsDetails;
  monthly: IStatsDetails;
  timestamp: Date;
}

export default Stats;
export { statsRouter };
