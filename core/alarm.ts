import {
  Job,
  RecurrenceRule,
  RecurrenceSegment,
  scheduleJob,
} from "node-schedule";
import { Buzzine, io } from "./index";
import { formatDate, formatTime } from "./utils/format";
import logger from "./utils/logger";
import dotenv from "dotenv";
import Snooze from "./snooze";
import AlarmModel from "./models/Alarm.model";
import { saveUpcomingAlarms } from "./utils/alarmProtection";
import shortUUID from "short-uuid";
import UpcomingAlarmModel from "./models/UpcomingAlarm.model";

//Load environment variables from file
dotenv.config();

class Alarm {
  id: string;
  isActive: boolean;
  hour: number;
  minute: number;
  deleteAfterRinging: boolean;
  isGuardEnabled: boolean;
  isSnoozeEnabled: boolean;
  name?: string;
  notes?: string;
  repeat?: RecurrenceObject;

  ringingStats: IRingingStats;
  snoozes: Snooze[] = [];

  maxTotalSnoozeDuration: number; //In seconds

  private isNextInvocationCancelled: { isCancelled: boolean; clearJob: Job }; //clearJob is a Job which removes the isNextInvocationCancelled object
  private jobObject: Job;

  private dbObject;

  constructor({
    hour,
    minute,
    id,
    isActive,
    maxTotalSnoozeDuration,
    deleteAfterRinging = false,
    isGuardEnabled = false,
    isSnoozeEnabled = true,
    name,
    notes,
    repeat,
  }: {
    hour: number;
    minute: number;
    id: string;
    isActive: boolean;
    maxTotalSnoozeDuration?: number;
    deleteAfterRinging?: boolean;
    isGuardEnabled?: boolean;
    isSnoozeEnabled?: boolean;
    name?: string;
    notes?: string;
    repeat?: RecurrenceObject;
  }) {
    if (name) {
      this.name = name;
    }
    if (notes) {
      this.notes = notes;
    }
    this.deleteAfterRinging = deleteAfterRinging;
    this.isGuardEnabled = isGuardEnabled;
    this.isSnoozeEnabled = isSnoozeEnabled;
    this.id = id;
    this.hour = hour;
    this.minute = minute;
    this.maxTotalSnoozeDuration =
      maxTotalSnoozeDuration ||
      parseInt(process.env.MAX_TOTAL_SNOOZE_DURATION) ||
      900;
    if (repeat) {
      this.repeat = {
        ...repeat,
        ...{
          second: 0,
          minute: minute,
          hour: hour,
        },
      };
    }
    this.getDBObject();
    if (isActive) {
      this.turnOn();
    }
  }

  async getDBObject() {
    this.dbObject = await AlarmModel.findOne({ where: { id: this.id } });
  }

  toObject(): IAlarm {
    return {
      id: this.id,
      isActive: this.isActive,
      hour: this.hour,
      minute: this.minute,
      deleteAfterRinging: this.deleteAfterRinging,
      isGuardEnabled: this.isGuardEnabled,
      isSnoozeEnabled: this.isSnoozeEnabled,
      maxTotalSnoozeDuration:
        this.maxTotalSnoozeDuration ||
        parseInt(process.env.DEFAULT_SNOOZE_LENGTH) ||
        300,
      nextInvocationDate: this.getNextInvocation(),
      name: this.name,
      notes: this.notes,
      repeat: this.repeat,
    };
  }

  toRingingObject(): RingingAlarm {
    let baseObj: IAlarm = this.toObject();
    let returnObj: RingingAlarm = baseObj;

    //Add a "maxAlarmDate" property that will calculate the date when the max amount of snoozes will be reached, if they're enabled
    if (baseObj.isSnoozeEnabled) {
      returnObj.maxAlarmDate = new Date(
        (
          this.snoozes?.[0]?.startDate ??
          this.ringingStats?.dateStarted ??
          new Date()
        ).getTime() +
          this.maxTotalSnoozeDuration * 1000
      );
    }

    return returnObj;
  }

  getNextInvocation(): Date | null {
    if (this.isActive && this.jobObject) {
      let date = this.jobObject.nextInvocation();
      if (date) {
        return new Date(date);
      }
    }
    return null;
  }

  createJob(): void {
    if (!this.isActive) return;
    this.isNextInvocationCancelled?.clearJob.cancel();
    this.isNextInvocationCancelled = null;
    if (!this.repeat) {
      let alarmDate: Date = new Date();
      alarmDate.setHours(this.hour);
      alarmDate.setMinutes(this.minute);
      alarmDate.setSeconds(0);

      if (alarmDate < new Date()) {
        //If the alarm occurs earlier than now, add a whole day (24 hours) to it
        alarmDate.setTime(alarmDate.getTime() + 1000 * 60 * 60 * 24);
      }

      this.jobObject = scheduleJob(alarmDate, this.onAlarmRinging.bind(this));
      logger.info(
        `Alarm ${this.id} scheduled for ${formatTime(
          this.hour,
          this.minute
        )}. Next invocation: ${formatDate(alarmDate)}`
      );
    } else {
      //Assuming RecurrenceObject is assignable to the RecurrenceRule constructor
      const rule = new RecurrenceRule(
        this.repeat.year,
        this.repeat.month,
        this.repeat.date,
        this.repeat.dayOfWeek,
        this.repeat.hour,
        this.repeat.minute,
        this.repeat.second,
        this.repeat.tz
      );

      this.jobObject = scheduleJob(rule, this.onAlarmRinging.bind(this));
      logger.info(
        `Repeating alarm ${this.id} scheduled for ${formatTime(
          this.hour,
          this.minute
        )}. Next invocation: ${formatDate(this.jobObject.nextInvocation())}`
      );
    }
  }

  async turnOn(): Promise<void> {
    if (this.isActive) {
      logger.warn(
        `Tried to turn on an alarm ${this.id} which is already active.`
      );
      return;
    }
    this.isActive = true;
    this.createJob();

    if (!this.dbObject) await this.getDBObject();
    this.dbObject.isActive = true;
    this.dbObject.save();

    saveUpcomingAlarms();

    io.emit("ALARM_ON", this.toObject());
  }
  mute(): void {
    if (this.ringingStats) {
      clearInterval(this.ringingStats?.eventResendingInterval);
      clearTimeout(this.ringingStats?.alarmSilentTimeout);
    }
    Buzzine.currentlyRingingAlarms = Buzzine.currentlyRingingAlarms.filter(
      (e) => e.id !== this.id
    );
    io.emit("ALARM_MUTE", this.toObject());
  }
  //turnOff - used when alarm rings, not the list
  async turnOff(): Promise<void> {
    if (!this.isActive) {
      logger.warn(
        `Tried to turn off an alarm ${this.id} which is already inactive.`
      );
      return;
    }
    if (this.ringingStats) {
      clearInterval(this.ringingStats?.eventResendingInterval);
      clearTimeout(this.ringingStats?.alarmSilentTimeout);
    }
    this.ringingStats = null;
    if (!this.repeat) {
      this.cancelJob();
      this.isActive = false;
      if (!this.dbObject) await this.getDBObject();
      this.dbObject.isActive = false;
      this.dbObject.save();
    }

    this.snoozes.forEach((e) => {
      e.cancelJob();
    });
    this.snoozes = [];

    io.emit("ALARM_OFF", this.toObject());
    logger.info(
      `Turned the alarm ${this.id} ${
        this.repeat ? "(repeating)" : "(manual)"
      } off`
    );

    this.mute();

    if (this.deleteAfterRinging) {
      await this.deleteSelf();
      logger.info(`Deleted alarm ${this.id}`);
    }
    saveUpcomingAlarms();
  }

  //disableAlarm - used in the alarm list menu
  async disableAlarm(): Promise<void> {
    if (!this.isActive) {
      logger.warn(
        `Tried to disable an alarm ${this.id} which is already disabled.`
      );
      return;
    }
    if (this.ringingStats) {
      clearInterval(this.ringingStats?.eventResendingInterval);
      clearTimeout(this.ringingStats?.alarmSilentTimeout);
    }
    this.ringingStats = null;
    this.cancelJob();
    this.isActive = false;

    this.snoozes.forEach((e) => {
      e.cancelJob();
    });
    this.snoozes = [];

    if (!this.dbObject) await this.getDBObject();
    this.dbObject.isActive = false;
    this.dbObject.save();

    saveUpcomingAlarms();

    io.emit("ALARM_DISABLE", this.toObject());
    logger.info(
      `Disabled the alarm ${this.id} ${
        this.repeat ? "(repeating)" : "(manual)"
      } off`
    );
  }

  snoozeAlarm(
    snoozeLengthSeconds: number = parseInt(process.env.DEFAULT_SNOOZE_LENGTH) ||
      300
  ): boolean {
    if (!this.ringingStats) {
      logger.warn(
        `Tried to snooze alarm with id ${this.id} which isn't ringing!`
      );
      return false;
    }
    if (!this.isSnoozeEnabled) {
      logger.warn(
        `Tried to snooze an alarm ${this.id} which has snooze disabled`
      );
      return false;
    }

    //Check if the latest snooze has been triggered already (there cannot be two snoozes at once)
    if (
      this.snoozes.length === 0 ||
      this.snoozes[this.snoozes.length - 1].invocationDate < new Date()
    ) {
      if (
        this.snoozes.length !== 0 &&
        new Date().getTime() -
          this.snoozes[0].startDate.getTime() +
          snoozeLengthSeconds * 1000 >
          this.maxTotalSnoozeDuration * 1000
      ) {
        //If the total max snooze time is exceeded (current time - first snooze time + next snooze time > max total snooze duration)
        logger.info(
          `Disallowed snooze since the total snooze duration is exceeded! Alarm id: ${this.id}`
        );
        //TODO: Emit an appropriate event
        return false;
      }
      this.mute();
      this.snoozes.push(
        new Snooze({
          alarmInstance: this,
          id: shortUUID.generate(),
          length: snoozeLengthSeconds,
        })
      );
      saveUpcomingAlarms();
      logger.info(
        `Snooze (id: ${this.snoozes[this.snoozes.length - 1].id}) of alarm ${
          this.id
        } has started!`
      );
      return true;
    }
  }

  cancelJob(): void {
    if (!this.jobObject) return;

    this.isNextInvocationCancelled?.clearJob.cancel();
    this.isNextInvocationCancelled = null;

    this.jobObject.cancel();
    this.jobObject = null;
  }

  cancelNextInvocation(): void {
    this.isNextInvocationCancelled = {
      isCancelled: true,
      clearJob: scheduleJob(this.jobObject.nextInvocation(), () => {
        this.isNextInvocationCancelled = null;
      }),
    };
    this.jobObject.cancelNext();
    saveUpcomingAlarms();
  }

  recreateJob(): void {
    this.cancelJob();
    this.createJob();
  }

  onAlarmRinging(): void {
    if (this.ringingStats) {
      clearInterval(this.ringingStats?.eventResendingInterval);
      clearTimeout(this.ringingStats?.alarmSilentTimeout);
    }
    this.ringingStats = {
      timeElapsed: 0,
      dateStarted: new Date(),
      eventResendingInterval: setInterval(() => {
        //Resend the ALARM_RINGING event in case some socket would disconnect for a while or something else happened
        this.ringingStats.timeElapsed = Math.floor(
          (new Date().getTime() - this.ringingStats.dateStarted.getTime()) /
            1000
        );

        io.emit("ALARM_RINGING", {
          ...this.toObject(),
          ...{ timeElapsed: this.ringingStats.timeElapsed },
        });

        logger.info(
          `Resent ALARM_RINGING event of alarm ${this.id}. Time elapsed: ${this.ringingStats.timeElapsed}`
        );
      }, (parseInt(process.env.RESEND_INTERVAL) || 10) * 1000),
      alarmSilentTimeout: setTimeout(() => {
        logger.warn(`Alarm ${this.id} was muted due to user inactivity!`);
        this.mute();
      }, (parseInt(process.env.MUTE_AFTER) || 15) * 1000 * 60),
    };

    Buzzine.currentlyRingingAlarms.push(this);
    io.emit("ALARM_RINGING", { ...this.toObject(), ...{ timeElapsed: 0 } });
    logger.info(`Alarm "${this.id}" is ringing!`);
  }

  async deleteSelf() {
    this.cancelJob();
    if (this.ringingStats) {
      this.mute();
    }
    this.snoozes.forEach((e) => {
      e.cancelJob();
    });
    //Delete all the upcoming alarms due to relations (which wouldn't allow to delete the alarm itself)
    Buzzine.alarms = Buzzine.alarms.filter((e) => e !== this);
    await UpcomingAlarmModel.destroy({ where: {} });
    await this.dbObject.destroy();
    await saveUpcomingAlarms();

    Buzzine.currentlyRingingAlarms = Buzzine.currentlyRingingAlarms.filter(
      (e) => e.id !== this.id
    );

    logger.info(`Deleted alarm ${this.id}`);
  }

  onSnoozeRinging(snooze: Snooze): void {
    this.onAlarmRinging();
  }
}

interface RecurrenceObject {
  second?: RecurrenceSegment;
  minute?: RecurrenceSegment;
  hour?: RecurrenceSegment;
  date?: RecurrenceSegment;
  month?: RecurrenceSegment;
  year?: RecurrenceSegment;
  dayOfWeek?: RecurrenceSegment;
  tz: string;
}

interface IAlarm {
  id: string;
  isActive: boolean;
  hour: number;
  minute: number;
  deleteAfterRinging: boolean;
  isGuardEnabled: boolean;
  isSnoozeEnabled: boolean;
  maxTotalSnoozeDuration?: number;
  nextInvocationDate?: Date;
  name?: string;
  notes?: string;
  repeat?: RecurrenceObject;
}

interface IRingingStats {
  timeElapsed: number;
  dateStarted: Date;
  eventResendingInterval: ReturnType<typeof setInterval>;
  alarmSilentTimeout: ReturnType<typeof setTimeout>;
}

type RingingAlarm = IAlarm & { maxAlarmDate?: Date };

export default Alarm;
export { IAlarm };
