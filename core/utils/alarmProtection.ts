import { Buzzine, io } from "..";
import Alarm from "../alarm";
import AlarmModel from "../models/Alarm.model";
import UpcomingAlarmModel from "../models/UpcomingAlarm.model";
import logger from "./logger";

let emergency: IEmergency = {
  interval: null,
  startDate: null,
  timeElapsed: 0,
};

async function checkForAlarmProtection() {
  let fetchedUpcomingAlarms = await UpcomingAlarmModel.findAll({
    include: AlarmModel,
  });
  let missedAlarms = fetchedUpcomingAlarms.filter(
    (e: any) => e.invocationDate < new Date()
  );

  if (missedAlarms.length > 0) {
    io.emit("EMERGENCY_ALARM", {
      missedAlarms: missedAlarms,
    });
    sendEmergnecy(missedAlarms);
    logger.warn(
      `Missed alarms. Count: ${
        missedAlarms.length
      }, the first: ${JSON.stringify(missedAlarms[0])}`
    );
  } else {
    logger.info("No missed alarms found");
  }
}

function sendEmergnecy(missedAlarms: any) {
  if (emergency) {
    clearInterval(emergency.interval);
    emergency = null;
  }

  emergency = {
    startDate: new Date(),
    timeElapsed: 0,
    interval: setInterval(() => {
      emergency.timeElapsed = Math.floor(
        (new Date().getTime() - emergency.startDate.getTime()) / 1000
      );
      io.emit("EMERGENCY_ALARM", {
        missedAlarms: missedAlarms,
        timeElapsed: emergency.timeElapsed,
      });
      logger.info(
        `Resent emergency event. Time elapsed: ${emergency.timeElapsed}`
      );

      if (
        emergency.timeElapsed >=
        (parseInt(process.env.MUTE_AFTER) || 15) * 60
      ) {
        clearInterval(emergency.interval);
        emergency = null;
      }
    }, (parseInt(process.env.RESEND_INTERVAL) || 10) * 1000),
  };
}

function getUpcomingAlarms() {
  let upcomingAlarms: IUpcomingAlarm[];

  let alarms = Buzzine.alarms;
  //Only active alarms
  alarms = alarms.filter((e) => e.isActive);

  upcomingAlarms = alarms.map((alarm: Alarm): IUpcomingAlarm => {
    let nextInvocation: Date = alarm.getNextInvocation();
    return {
      alarmId: alarm.id,
      invocationDate: nextInvocation,
    };
  });

  let snoozes = alarms
    .filter((elem) => elem.snoozes.length !== 0)
    .map((element) => {
      return {
        alarmId: element.id,
        invocationDate:
          element.snoozes[element.snoozes.length - 1].invocationDate,
      };
    });

  upcomingAlarms = [...upcomingAlarms, ...snoozes];

  //Remove null dates from the array
  upcomingAlarms = upcomingAlarms.filter((el) => el.invocationDate);

  return upcomingAlarms;
}

async function saveUpcomingAlarms() {
  //TODO: Save the upcomingAlarms from getUpcomingAlarms() method
  let upcomingAlarms: IUpcomingAlarm[] = await getUpcomingAlarms();

  await UpcomingAlarmModel.destroy({ where: {} });

  for await (const upcomingAlarm of upcomingAlarms) {
    await UpcomingAlarmModel.create({
      invocationDate: upcomingAlarm.invocationDate,
      AlarmId: upcomingAlarm.alarmId,
    });
  }
}

//TODO: Send emergency alarm on exit

interface IUpcomingAlarm {
  alarmId: string;
  invocationDate: Date;
}
interface IEmergency {
  interval: ReturnType<typeof setInterval>;
  startDate: Date;
  timeElapsed: number;
}

export { checkForAlarmProtection, getUpcomingAlarms, saveUpcomingAlarms };
