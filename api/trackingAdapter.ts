import axios from "axios";
import { TRACKING_URL } from ".";
import { sendCustomNotification } from "./notifications";
import { dateTimeToDateOnly } from "./utils/formatting";
import logger from "./utils/logger";

class TrackingAdapter {
  static async updateIfDoesNotExistCurrent(
    data: ITrackingEntryObject,
    notifyUser?: boolean
  ) {
    try {
      //Associate the alarm with given sound
      let response = await axios.put(
        `${TRACKING_URL}/v1/updateDataForLatestIfDoesntExist`,
        {
          updateObject: data,
        }
      );

      if (notifyUser) {
        //Check if at least one of the data is updated
        let isUpdated = false;
        Object.entries(data).forEach(([key, value]) => {
          if (
            new Date(response.data.response[key]).getTime() ===
            new Date(value).getTime()
          ) {
            isUpdated = true;
          }
        });
        if (isUpdated) {
          sendCustomNotification({
            title: "Śledzenie snu",
            body: "Automatycznie zaaktualizowano dane śledzenia snu.",
            color: "#32a852",
            sound: "default",
          });
        }
      }
      logger.info(
        `Updated tracking data (if they didn't exist) for the latest: ${JSON.stringify(
          data
        )}`
      );
    } catch (err) {
      logger.error(
        `Error when trying to update tracking data if they didn't exist (${JSON.stringify(
          data
        )}) for the latest: ${JSON.stringify(
          err?.response?.data ?? ""
        )} with status ${err?.response?.status}`
      );
      return;
    }
  }
}

interface ITrackingEntryObject {
  bedTime?: Date;
  sleepTime?: Date;
  firstAlarmTime?: Date;
  wakeUpTime?: Date;
  getUpTime?: Date;
  alarmTimeFrom?: Date;
  alarmTimeTo?: Date;
  rate?: number;
}

export default TrackingAdapter;
