import axios from "axios";
import { TRACKER_DAY_START, TRACKING_URL } from ".";
import { sendCustomNotification } from "./notifications";
import logger from "./utils/logger";

class TrackingAdapter {
  static async updateIfDoesNotExistCurrent(
    data: ITrackingEntryObject,
    notifyUser?: boolean
  ) {
    let day = new Date();

    //If the date if after the tracker day start, add a one whole day to it
    if (
      day.getHours() * 60 + day.getMinutes() >
      TRACKER_DAY_START.hour * 60 + TRACKER_DAY_START.minute
    ) {
      day.setDate(day.getDate() + 1);
    }

    try {
      //Associate the alarm with given sound
      let response = await axios.put(
        `${TRACKING_URL}/v1/updateDataForDayIfDoesntExist`,
        {
          day,
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
        `Updated tracking data (if they didn't exist) for day ${day}: ${JSON.stringify(
          data
        )}`
      );
    } catch (err) {
      logger.error(
        `Error when trying to update tracking data if they didn't exist (${JSON.stringify(
          data
        )}) for day ${day}. ${JSON.stringify(
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
  rate?: number;
}

export default TrackingAdapter;
