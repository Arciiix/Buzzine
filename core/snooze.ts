import { Job, scheduleJob } from "node-schedule";

import { io } from "./index";
import Alarm from "./alarm";
import { formatDate, formatTime } from "./utils/format";

import logger from "./utils/logger";
import dotenv from "dotenv";

//Load environment variables from file
dotenv.config();

class Snooze {
  id: string;
  length: number; //in seconds

  startDate: Date;
  invocationDate: Date;

  private alarmInstance: Alarm;
  private jobObject: Job;

  constructor({
    alarmInstance,
    id,
    length,
  }: {
    alarmInstance: Alarm;
    id: string;
    length: number;
  }) {
    this.id = id;
    this.length = length;
    this.alarmInstance = alarmInstance;

    this.createJob();
  }

  createJob(): void {
    this.startDate = new Date();
    this.invocationDate = new Date(new Date().getTime() + this.length * 1000);

    this.jobObject = scheduleJob(
      this.invocationDate,
      this.onSnoozeRinging.bind(this)
    );

    logger.info(
      `Snooze ${this.id} scheduled for ${formatDate(this.invocationDate)}`
    );
  }
  cancelJob(): void {
    if (this.jobObject) {
      this.jobObject.cancel();
    }
  }

  onSnoozeRinging(): void {
    logger.info(`Snooze ${this.id} is ringing! Calling Alarm...`);
    this.alarmInstance.onSnoozeRinging(this);
  }
}

export default Snooze;
