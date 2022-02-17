import { IAlarm } from "../alarm";
import AlarmModel from "../models/Alarm.model";
import NapModel from "../models/Nap.model";
import { INap } from "../nap";

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
        maxTotalSnoozeDuration: alarm?.maxTotalSnoozeDuration,
        name: alarm?.name,
        notes: alarm?.notes,
        repeat: alarm?.repeat,
        emergencyAlarmTimeoutSeconds: alarm?.emergencyAlarmTimeoutSeconds,
      };
    });
    return alarms;
  }

  static async getNaps() {
    const napQuery = await NapModel.findAll();
    const naps: INap[] = napQuery.map((nap: any) => {
      return {
        id: nap.id,
        isActive: nap?.invocationDate !== null,
        hour: nap.hour,
        minute: nap.minute,
        second: nap.second,
        deleteAfterRinging: nap?.deleteAfterRinging,
        isGuardEnabled: nap?.isGuardEnabled,
        isSnoozeEnabled: nap?.isSnoozeEnabled,
        maxTotalSnoozeDuration: nap?.maxTotalSnoozeDuration,
        name: nap?.name,
        notes: nap?.notes,
        emergencyAlarmTimeoutSeconds: nap?.emergencyAlarmTimeoutSeconds,
        invocationDate: nap?.invocationDate,
      };
    });
    return naps;
  }

  static async getAll() {
    let alarms = await GetDatabaseData.getAlarms();
    let naps = await GetDatabaseData.getNaps();

    return { alarms, naps };
  }
}

export default GetDatabaseData;
