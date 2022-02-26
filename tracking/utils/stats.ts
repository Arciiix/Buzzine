import express from "express";
import { Op } from "sequelize";
import TrackingEntryModel from "../models/TrackingEntry";
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
  static lifetimeStats: IStatsObject;
  static monthlyStats: IStatsObject;
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

  static calculateForElements(elements: any[]): IStatsObject {
    let sleepDuration: IAverageCalculation = { sum: 0, count: 0 };
    let timeAtBed: IAverageCalculation = { sum: 0, count: 0 };
    let alarmWakeUpProcrastinationTime: IAverageCalculation = {
      sum: 0,
      count: 0,
    };
    let timeBeforeGettingUp: IAverageCalculation = { sum: 0, count: 0 };

    for (const element of elements) {
      //Sleep duration
      if (element.sleepTime && element.wakeUpTime) {
        sleepDuration.sum += Math.floor(
          (element.wakeUpTime.getTime() - element.sleepTime.getTime()) / 1000
        );
        sleepDuration.count++;
      }

      //Time at bed
      if (element.bedTime && element.sleepTime) {
        timeAtBed.sum += Math.floor(
          (element.sleepTime.getTime() - element.bedTime.getTime()) / 1000
        );
        timeAtBed.count++;
      }

      //Procrastination time after alarm
      if (element.firstAlarmTime && element.wakeUpTime) {
        alarmWakeUpProcrastinationTime.sum += Math.floor(
          (element.wakeUpTime.getTime() - element.firstAlarmTime.getTime()) /
            1000
        );
        alarmWakeUpProcrastinationTime.count++;
      }

      //Time after the alarm before getting up
      if (element.wakeUpTime && element.getUpTime) {
        timeBeforeGettingUp.sum += Math.floor(
          (element.getUpTime.getTime() - element.wakeUpTime.getTime()) / 1000
        );
        timeBeforeGettingUp.count++;
      }
    }

    let averageSleepDuration = sleepDuration.sum / sleepDuration.count;
    let averageTimeAtBed = timeAtBed.sum / timeAtBed.count;
    let averageAlarmWakeUpProcrastinationTime =
      alarmWakeUpProcrastinationTime.sum / alarmWakeUpProcrastinationTime.count;
    let averageTimeBeforeGettingUp =
      timeBeforeGettingUp.sum / timeBeforeGettingUp.count;

    if (isNaN(averageSleepDuration)) averageSleepDuration = 0;
    if (isNaN(averageTimeAtBed)) averageTimeAtBed = 0;
    if (isNaN(averageAlarmWakeUpProcrastinationTime))
      averageAlarmWakeUpProcrastinationTime = 0;
    if (isNaN(averageTimeBeforeGettingUp)) averageTimeBeforeGettingUp = 0;

    return {
      averageSleepDuration,
      averageTimeAtBed,
      averageAlarmWakeUpProcrastinationTime,
      averageTimeBeforeGettingUp,
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
  sum: number;
  count: number;
}
interface IStatsObject {
  averageSleepDuration?: number;
  averageTimeAtBed?: number;
  averageAlarmWakeUpProcrastinationTime?: number;
  averageTimeBeforeGettingUp?: number;
}
interface IStats {
  lifetime: IStatsObject;
  monthly: IStatsObject;
  timestamp: Date;
}

export default Stats;
export { statsRouter };
