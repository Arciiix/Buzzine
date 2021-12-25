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

const { info, error, warn, debug } = logger;

//Load environment variables from file
dotenv.config();

class Alarm {
  id: string;
  isActive: boolean;
  hour: number;
  minute: number;
  name?: string;
  repeat?: RecurrenceObject;
  ringingStats: IRingingStats;

  private isNextInvocationCancelled: { isCancelled: boolean; clearJob: Job }; //clearJob is a Job which removes the isNextInvocationCancelled object
  private jobObject: Job;
  private;

  constructor({
    hour,
    minute,
    id,
    name,
    repeat,
  }: {
    hour: number;
    minute: number;
    id?: string;
    name?: string;
    repeat?: RecurrenceObject;
  }) {
    if (name) {
      this.name = name;
    }
    if (id) {
      this.id = id;
    }
    this.hour = hour;
    this.minute = minute;
    if (repeat) {
      this.repeat = {
        ...repeat,
        ...{
          second: 5,
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
      name: this.name,
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
      info(
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
      info(
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
    if (!this.repeat) {
      this.turnOff();
    }
    io.emit("ALARM_MUTE", this.toObject());
  }
  turnOff(): void {
    this.cancelJob();
    if (this.ringingStats) {
      clearInterval(this.ringingStats?.eventResendingInterval);
      clearTimeout(this.ringingStats?.alarmSilentTimeout);
    }
    io.emit("ALARM_OFF", this.toObject());
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
      }, (parseInt(process.env.RESEND_INTERVAL) || 30) * 1000),
      alarmSilentTimeout: setTimeout(() => {
        //TODO: Mute the alarm and send an appropriate event (or send events repeatedly)
        logger.warn("DEV: MUTE ALARM");
        logger.warn(`Alarm ${this.id} was muted due to user inactivity!`);
        this.mute();
      }, (parseInt(process.env.MUTE_AFTER) || 15) * 1000 * 60),
    };

    //DEV
    io.emit("ALARM_RINGING", { ...this.toObject(), ...{ timeElapsed: 0 } });
    info(`Alarm "${this.id}" is ringing!`);
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
  name?: string;
  repeat?: RecurrenceObject;
}

interface IRingingStats {
  timeElapsed: number;
  dateStarted: Date;
  eventResendingInterval: ReturnType<typeof setInterval>;
  alarmSilentTimeout: ReturnType<typeof setTimeout>;
}

export default Alarm;
