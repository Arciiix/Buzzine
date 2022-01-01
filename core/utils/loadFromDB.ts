import { IAlarm } from "../alarm";
import AlarmModel from "../models/Alarm.model";

class GetDatabaseData {
  static async getAlarms() {
    const alarmsQuery = await AlarmModel.findAll();
    const alarms: IAlarm[] = alarmsQuery.map((alarm: any) => {
      return {
        id: alarm?.id,
        isActive: alarm?.isActive,
        hour: alarm?.hour,
        minute: alarm?.minute,
        deleteAfterRinging: alarm?.deleteAfterRinging,
        isGuardEnabled: alarm?.isGuardEnabled,
        isSnoozeEnabled: alarm?.isSnoozeEnabled,
        name: alarm?.name,
        notes: alarm?.notes,
        repeat: alarm?.repeat,
      };
    });
    return alarms;
  }

  static async getAll() {
    let alarms = await GetDatabaseData.getAlarms();
    return { alarms };
  }
}

export default GetDatabaseData;
