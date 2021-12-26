import {
  Job,
  RecurrenceRule,
  RecurrenceSegment,
  scheduleJob,
} from "node-schedule";
import { io } from "./index";
import { formatDate, formatTime } from "./utils/format";
import logger from "./utils/logger";
import dotenv from "dotenv";
import Snooze from "./snooze";

//Load environment variables from file
dotenv.config();

class Alarm {
  id: string;
  isActive: boolean;
  hour: number;
  minute: number;
  deleteAfterRinging: boolean;
  name?: string;
  notes?: string;
  repeat?: RecurrenceObject;

  ringingStats: IRingingStats;
  snoozes: Snooze[] = [];

  maxTotalSnoozeDuration: number; //In seconds

  private isNextInvocationCancelled: { isCancelled: boolean; clearJob: Job }; //clearJob is a Job which removes the isNextInvocationCancelled object
  private jobObject: Job;

  constructor({
    hour,
    minute,
    id,
    maxTotalSnoozeDuration,
    deleteAfterRinging = false,
    name,
    notes,
    repeat,
  }: {
    hour: number;
    minute: number;
    id: string;
    maxTotalSnoozeDuration?: number;
    deleteAfterRinging: boolean;
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
    this.turnOn();
  }

  toObject(): IAlarm {
    return {
      id: this.id,
      isActive: this.isActive,
      hour: this.hour,
      minute: this.minute,
      deleteAfterRinging: this.deleteAfterRinging,
      name: this.name,
      notes: this.notes,
      repeat: this.repeat,
    };
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

  turnOn(): void {
    this.isActive = true;
    this.createJob();
    io.emit("ALARM_ON", this.toObject());
  }
  mute(): void {
    if (this.ringingStats) {
      clearInterval(this.ringingStats?.eventResendingInterval);
      clearTimeout(this.ringingStats?.alarmSilentTimeout);
    }
    io.emit("ALARM_MUTE", this.toObject());
  }
  turnOff(): void {
    if (this.ringingStats) {
      clearInterval(this.ringingStats?.eventResendingInterval);
      clearTimeout(this.ringingStats?.alarmSilentTimeout);
    }
    this.ringingStats = null;
    if (!this.repeat) {
      this.cancelJob();
      this.isActive = false;
    }

    this.snoozes.forEach((e) => {
      e.cancelJob();
    });

    io.emit("ALARM_OFF", this.toObject());
    logger.info(
      `Turned the alarm ${this.id} ${
        this.repeat ? "(repeating)" : "(manual)"
      } off`
    );
  }

  disableAlarm(): void {
    if (this.ringingStats) {
      clearInterval(this.ringingStats?.eventResendingInterval);
      clearTimeout(this.ringingStats?.alarmSilentTimeout);
    }
    this.ringingStats = null;
    this.cancelJob();
    this.isActive = false;

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
  ): void {
    if (!this.ringingStats) {
      logger.warn(
        `Tried to snooze alarm with id ${this.id} which isn't ringing!`
      );
      return;
    }

    //Check if the latest snooze has already been triggered (there cannot be two snoozes at once)
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
        return;
      }
      this.mute();
      this.snoozes.push(
        //TODO: Generate the id
        new Snooze({
          alarmInstance: this,
          id: "DEV",
          length: snoozeLengthSeconds,
        })
      );
      logger.info(
        `Snooze (id: ${this.snoozes[this.snoozes.length - 1].id}) of alarm ${
          this.id
        } has started!`
      );
    }
  }

  cancelJob(): void {
    this.isActive = false;

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

    io.emit("ALARM_RINGING", { ...this.toObject(), ...{ timeElapsed: 0 } });
    logger.info(`Alarm "${this.id}" is ringing!`);
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
  tz?: string;
}

interface IAlarm {
  id: string;
  isActive: boolean;
  hour: number;
  minute: number;
  deleteAfterRinging: boolean;
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

export default Alarm;
export { IAlarm };
