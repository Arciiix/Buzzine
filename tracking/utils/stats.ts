import express from "express";
import { Op } from "sequelize";
import TrackingEntryModel from "../models/TrackingEntry";
import { TRACKER_DAY_START } from "./constants";
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

    let timeTakenToTurnOffTheAlarm: IAverageCalculation = {
      alarm: { sum: 0, count: 0 },
      nap: { sum: 0, count: 0 },
    };

    let sleepTimes: Date[] = [];
    let wakeUpTimes: Date[] = [];

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

      //Used to calculate the average sleep and wake up time
      if (element.sleepTime) {
        sleepTimes.push(new Date(element.sleepTime));
      }
      if (element.wakeUpTime) {
        wakeUpTimes.push(new Date(element.wakeUpTime));
      }

      if (element.timeTakenToTurnOffTheAlarm) {
        timeTakenToTurnOffTheAlarm[isWholeDay ? "alarm" : "nap"].sum +=
          element.timeTakenToTurnOffTheAlarm;
        timeTakenToTurnOffTheAlarm[isWholeDay ? "alarm" : "nap"].count++;
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

    let averageTimeTakenToTurnOffTheAlarm =
      timeTakenToTurnOffTheAlarm.alarm.sum /
      timeTakenToTurnOffTheAlarm.alarm.count;
    let averageTimeTakenToTurnOffTheAlarmNap =
      timeTakenToTurnOffTheAlarm.nap.sum / timeTakenToTurnOffTheAlarm.nap.count;

    let averageSleepTime = this.calculateAverageTime(
      true,
      sleepTimes.map((e: Date) => {
        return {
          hour: e.getHours(),
          minute: e.getMinutes(),
        };
      }),
      TRACKER_DAY_START.hour
    );

    let averageWakeUpTime = this.calculateAverageTime(
      false,
      wakeUpTimes.map((e: Date) => {
        return {
          hour: e.getHours(),
          minute: e.getMinutes(),
        };
      })
    );

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

    if (isNaN(averageSleepTime.hour) || isNaN(averageSleepTime.minute)) {
      averageSleepTime = { hour: 0, minute: 0 };
    }

    if (isNaN(averageWakeUpTime.hour) || isNaN(averageWakeUpTime.minute)) {
      averageWakeUpTime = { hour: 0, minute: 0 };
    }

    if (isNaN(averageTimeTakenToTurnOffTheAlarm)) {
      averageTimeTakenToTurnOffTheAlarm = 0;
    }
    if (isNaN(averageTimeTakenToTurnOffTheAlarmNap)) {
      averageTimeTakenToTurnOffTheAlarmNap = 0;
    }

    return {
      alarm: {
        averageSleepDuration: Math.floor(averageSleepDuration),
        averageTimeAtBed: Math.floor(averageTimeAtBed),
        averageAlarmWakeUpProcrastinationTime: Math.floor(
          averageAlarmWakeUpProcrastinationTime
        ),
        averageTimeBeforeGettingUp: Math.floor(averageTimeBeforeGettingUp),
        averageTimeTakenToTurnOffTheAlarm: Math.floor(
          averageTimeTakenToTurnOffTheAlarm
        ),

        averageSleepTime: averageSleepTime,
        averageWakeUpTime: averageWakeUpTime,
      },
      nap: {
        averageSleepDuration: Math.floor(averageSleepDurationNap),
        averageTimeAtBed: Math.floor(averageTimeAtBedNap),
        averageAlarmWakeUpProcrastinationTime: Math.floor(
          averageAlarmWakeUpProcrastinationTimeNap
        ),
        averageTimeBeforeGettingUp: Math.floor(averageTimeBeforeGettingUpNap),
        averageTimeTakenToTurnOffTheAlarm: Math.floor(
          averageTimeTakenToTurnOffTheAlarmNap
        ),
      },
    };
  }

  static toObject(): IStats {
    return {
      lifetime: this.lifetimeStats,
      monthly: this.monthlyStats,
      timestamp: this.calculationTimestamp,
      trackerDayStartHour: TRACKER_DAY_START.hour,
    };
  }

  static calculateAverageTime(
    includeDayStartTime: boolean,
    times: ITime[],
    hourUpperRange?: number
  ): ITime {
    //To calculate the average time, we need to have something like an upper range, a border - used to determinate the start/end of the day.
    //Because, for example, the average time (when it comes to calculating it for average sleep time) of 23:00 and 01:00 is 0:00, not 12:00, so we can't just calculate the normal mathematical average.
    //On the other hand, 23:00 and 8:00 can be considered as a normal mathematical average ( (23+8)/2 )

    let minutesSum = 0;

    //Calculate the average time by adding up all the minutes of the times (1 hour = 60 minutes).
    times.forEach((elem) => {
      if (includeDayStartTime) {
        minutesSum +=
          elem.hour < hourUpperRange
            ? elem.minute + 24 * 60 + elem.hour * 60
            : elem.minute + elem.hour * 60;
      } else {
        minutesSum += elem.minute + elem.hour * 60;
      }
    });

    let averageMinutes = minutesSum / times.length;
    let hours = Math.floor(averageMinutes / 60);
    let minutes = Math.floor(averageMinutes - hours * 60);

    if (hours >= 24) {
      hours -= 24;
    }

    return { hour: hours, minute: minutes };
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
  averageTimeTakenToTurnOffTheAlarm?: number;
  averageSleepTime?: ITime; // Used only in alarm, not nap
  averageWakeUpTime?: ITime; // Used only in alarm, not nap
}
interface IStatsDetails {
  alarm: IStatsObject;
  nap: IStatsObject;
}
interface IStats {
  lifetime: IStatsDetails;
  monthly: IStatsDetails;
  timestamp: Date;
  trackerDayStartHour: number;
}
interface ITime {
  hour: number;
  minute: number;
}

export default Stats;
export { statsRouter };
