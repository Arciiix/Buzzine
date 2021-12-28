import { Buzzine } from "..";
import Alarm from "../alarm";
import UpcomingAlarmModel from "../models/UpcomingAlarm.model";

async function checkForAlarmProtection() {
  //TODO: Fetch UpcomingAlarms from the db and check if any of them has been omitted
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

interface IUpcomingAlarm {
  alarmId: string;
  invocationDate: Date;
}

export { getUpcomingAlarms, saveUpcomingAlarms };
