import { Buzzine } from ".";
import Alarm, { IAlarm, RingingAlarm } from "./alarm";
import NapModel from "./models/Nap.model";
import UpcomingAlarmModel from "./models/UpcomingAlarm.model";
import UpcomingNapModel from "./models/UpcomingNapModel";
import { saveUpcomingAlarms } from "./utils/alarmProtection";
import logger from "./utils/logger";

class Nap extends Alarm {
  constructor({
    hour,
    minute,
    second,
    id,
    maxTotalSnoozeDuration,
    deleteAfterRinging = false,
    isGuardEnabled = false,
    isSnoozeEnabled = true,
    name,
    notes,
    emergencyAlarmTimeoutSeconds,
    invocationDate,
  }: {
    hour: number;
    minute: number;
    second: number;
    id: string;
    maxTotalSnoozeDuration?: number;
    deleteAfterRinging?: boolean;
    isGuardEnabled?: boolean;
    isSnoozeEnabled?: boolean;
    name?: string;
    notes?: string;
    emergencyAlarmTimeoutSeconds?: number;
    invocationDate?: Date;
  }) {
    super({
      hour,
      minute,
      second,
      id,
      isActive: invocationDate?.getTime() > new Date().getTime(),
      maxTotalSnoozeDuration,
      deleteAfterRinging,
      isGuardEnabled,
      isSnoozeEnabled,
      name,
      notes,
      emergencyAlarmTimeoutSeconds,
    });

    if (invocationDate?.getTime() <= new Date().getTime()) {
      this.saveNextInvocationDate(true);
    }
  }

  override async getDBObject(): Promise<void> {
    this.dbObject = await NapModel.findOne({ where: { id: this.id } });
  }

  async saveNextInvocationDate(overrideNull?: boolean): Promise<void> {
    if (!this.dbObject) await this.getDBObject();
    this.dbObject.invocationDate = overrideNull
      ? null
      : this.getNextInvocation();

    await this.dbObject.save();
  }
  override getInvocationDateFromTime(hour: number, minute: number): Date {
    return new Date(
      new Date().getTime() +
        hour * 3600 * 1000 +
        minute * 60 * 1000 +
        this.second * 1000
    );
  }

  override async turnOn(): Promise<void> {
    await super.turnOn();
    await this.saveNextInvocationDate();
  }

  override mute(): void {
    super.mute();
    //Remove the nap from currentlyRingingNaps
    Buzzine.currentlyRingingNaps = Buzzine.currentlyRingingNaps.filter(
      (e) => e.id !== this.id
    );
  }

  override async turnOff(): Promise<void> {
    await super.turnOff();
    await this.saveNextInvocationDate(true);
  }

  override async disableAlarm(): Promise<void> {
    await this.turnOff();
    await super.disableAlarm();
    await this.saveNextInvocationDate(true);
  }

  override pushToCurrentlyRinging(): void {
    Buzzine.currentlyRingingNaps.push(this);
  }
  override async deleteSelf(): Promise<void> {
    this.cancelJob();
    if (this.ringingStats) {
      this.mute();
    }
    this.toogleEmergencyDevice(false);
    this.snoozes.forEach((e) => {
      e.cancelJob();
    });
    await this.dbObject.destroy();
    await UpcomingNapModel.destroy({ where: {} });
    Buzzine.naps = Buzzine.naps.filter((e) => e !== this);
    Buzzine.currentlyRingingNaps = Buzzine.currentlyRingingNaps.filter(
      (e) => e.id !== this.id
    );
    saveUpcomingAlarms();
    logger.info(`Deleted nap ${this.id}`);
  }

  override toObject(): INap {
    return {
      id: this.id,
      isActive: this.getNextInvocation() !== null,
      hour: this.hour,
      minute: this.minute,
      second: this.second,
      deleteAfterRinging: this.deleteAfterRinging,
      isGuardEnabled: this.isGuardEnabled,
      isSnoozeEnabled: this.isSnoozeEnabled,
      maxTotalSnoozeDuration:
        this.maxTotalSnoozeDuration ||
        parseInt(process.env.DEFAULT_SNOOZE_LENGTH) ||
        300,
      invocationDate: this.getNextInvocation(),
      name: this.name,
      notes: this.notes,
      emergencyAlarmTimeoutSeconds: this.emergencyAlarmTimeoutSeconds,
    };
  }

  override toRingingObject(): RingingNap {
    let baseObj: INap = this.toObject();
    let returnObj: RingingNap = baseObj;

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
}

interface INap {
  id: string;
  hour: number;
  minute: number;
  second: number;
  isActive: boolean;
  maxTotalSnoozeDuration?: number;
  deleteAfterRinging: boolean;
  isGuardEnabled: boolean;
  isSnoozeEnabled: boolean;
  name?: string;
  notes?: string;
  emergencyAlarmTimeoutSeconds?: number;
  invocationDate?: Date;
}

type RingingNap = INap & { maxAlarmDate?: Date };

export default Nap;
export { INap, RingingNap };
