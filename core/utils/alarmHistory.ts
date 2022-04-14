import dotenv from "dotenv";
import { Op } from "sequelize";
import Alarm from "../alarm";
import AlarmHistoryModel from "../models/AlarmHistory.model";
import logger from "./logger";
dotenv.config();

async function getAlarmHistory(): Promise<IHistoricalAlarm[]> {
  let alarms = await AlarmHistoryModel.findAll({});
  clearOldAlarmHistory();
  return alarms.map((elem: any): IHistoricalAlarm => {
    return {
      alarmId: elem.alarmId,
      invocationDate: elem.invocationDate,
      name: elem.name,
      notes: elem.notes,
    };
  });
}

async function addAlarmToHistory(alarm: Alarm): Promise<void> {
  await AlarmHistoryModel.create({
    alarmId: alarm.id,
    invocationDate: new Date(),
    name: alarm.name,
    notes: alarm.notes,
  });
  logger.info(`Added new entry to the alarm history (id: ${alarm.id})`);
  clearOldAlarmHistory();
}

async function clearOldAlarmHistory(): Promise<void> {
  logger.info(`Starting to remove the old alarm history...`);
  await AlarmHistoryModel.destroy({
    where: {
      invocationDate: {
        [Op.lt]: new Date(
          new Date().getTime() -
            parseInt(process.env.MAX_ALARM_HISTORY_AGE ?? "30") *
              24 *
              60 *
              60 *
              1000
        ),
      },
    },
  });

  logger.info(`Successfully removed the old alarm history`);
}

interface IHistoricalAlarm {
  alarmId: string;
  invocationDate: Date;
  name?: string;
  notes?: string;
}

export { getAlarmHistory, addAlarmToHistory, clearOldAlarmHistory };
