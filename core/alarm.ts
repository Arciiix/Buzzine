import {
  Job,
  RecurrenceRule,
  RecurrenceSegment,
  scheduleJob,
} from "node-schedule";
import { io } from "./index";
import { formatDate, formatTime } from "./utils/format";
import logger from "./utils/logger";

const { info, error, warn, debug } = logger;

class Alarm {
  id: string;
  isActive: boolean;
  hour: number;
  minute: number;
  name?: string;
  repeat?: RecurrenceObject;

  private isNextInvocationCancelled: { isCancelled: boolean; clearJob: Job }; //clearJob is a Job which removes the isNextInvocationCancelled object
  private jobObject: Job;

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
        `Alarm ${this.name ?? "UNTITLED"} scheduled for ${formatTime(
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
        `Repeating alarm ${this.name} scheduled for ${formatTime(
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
  turnOff(): void {
    this.cancelJob();
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
    //DEV
    io.emit("ALARM_RINGING", this.toObject());
    info(`Alarm "${this.name}" is ringing!`);
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

export default Alarm;
