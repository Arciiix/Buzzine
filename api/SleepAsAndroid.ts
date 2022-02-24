//The integration with Sleep as Android - a sleep tracking app for Android - using webhooks
import axios from "axios";
import express from "express";
import {
  AUDIO_URL,
  SLEEP_AS_ANDROID_MUTE_AFTER,
  toogleEmergencyDevice,
} from ".";
import TrackingAdapter from "./trackingAdapter";
import db from "./utils/db";
import logger from "./utils/logger";

const sleepAsAndroidRouter = express.Router();

sleepAsAndroidRouter.post("/webhook", async (req, res) => {
  handleSleepAsAndroidWebhook(
    req.body.event,
    req.body.value1,
    req.body.value2,
    req.body.value3
  );
  res.sendStatus(200);
});

sleepAsAndroidRouter.get("/getStatus", async (req, res) => {
  let status: boolean = await getStatus();
  let emergencyAlarmTimeoutSeconds =
    (await (
      await getSleepAsAndroidIntegrationDBObject()
    )?.config?.emergencyAlarmTimeoutSeconds) ??
    SLEEP_AS_ANDROID_MUTE_AFTER * 60;
  let delay =
    (await (await getSleepAsAndroidIntegrationDBObject())?.config?.delay) ?? 0;
  let associatedSound;

  try {
    //Get the audio associated to the Sleep as Android alarm
    let response = await axios.get(`${AUDIO_URL}/v1/getAlarmSound`, {
      params: {
        alarmId: "SLEEP_AS_ANDROID",
      },
    });
    associatedSound = response.data.response;
  } catch (err) {
    logger.error(
      `Error while getting Sleep as Android alarm's associated sound : ${err.toString()} - ${JSON.stringify(
        err?.response?.data
      )} with status ${err?.response?.status}`
    );
  }

  res.send({
    error: false,
    response: {
      isActive: status,
      emergencyAlarmTimeoutSeconds,
      delay,
      associatedSound,
    },
  });
  logger.info(
    `[SLEEP AS ANDROID] Sent Sleep as Android integration status (isActive: ${status})`
  );
});

sleepAsAndroidRouter.put("/toogleStatus", async (req, res) => {
  if (req.body.isActive === null || req.body.isActive === undefined) {
    res.status(400).send({ error: true, errorCode: "MISSING_IS_ACTIVE" });
    return;
  }

  let dbIntegrationInstance: any = await getSleepAsAndroidIntegrationDBObject();
  dbIntegrationInstance.isActive = req.body.isActive;
  await dbIntegrationInstance.save();

  logger.info(
    `[SLEEP AS ANDROID] Set Sleep as Android integration status to ${req.body.isActive}`
  );

  res.send({ error: false, response: { isActive: req.body.isActive } });
});

sleepAsAndroidRouter.put(
  "/changeEmergencyAlarmTimeoutSeconds",
  async (req, res) => {
    if (!req.body.emergencyAlarmTimeoutSeconds) {
      res.status(400).send({
        error: true,
        errorCode: "MISSING_EMERGENCY_ALARM_TIMEOUT_SECONDS",
      });
      return;
    }

    if (
      isNaN(parseInt(req.body.emergencyAlarmTimeoutSeconds)) ||
      parseInt(req.body.emergencyAlarmTimeoutSeconds) < 0
    ) {
      res.status(400).send({
        error: true,
        errorCode: "WRONG_EMERGENCY_ALARM_TIMEOUT_SECONDS",
      });
      return;
    }

    let dbIntegrationInstance: any =
      await getSleepAsAndroidIntegrationDBObject();

    //Do it this way to avoid unexisting config error
    let oldConfig = { ...dbIntegrationInstance.config };
    oldConfig.emergencyAlarmTimeoutSeconds =
      req.body.emergencyAlarmTimeoutSeconds;
    dbIntegrationInstance.config = oldConfig;
    await dbIntegrationInstance.save();

    logger.info(
      `[SLEEP AS ANDROID] Set Sleep as Android emergencyAlarmTimeoutSeconds to ${req.body.emergencyAlarmTimeoutSeconds}`
    );

    res.send({
      error: false,
      response: {
        emergencyAlarmTimeoutSeconds:
          dbIntegrationInstance.config.emergencyAlarmTimeoutSeconds,
      },
    });
  }
);

sleepAsAndroidRouter.put("/changeSound", async (req, res) => {
  if (!req.body.audioId) {
    res.status(400).send({ error: true, errorCode: "MISSING_AUDIOID" });
    return;
  }

  try {
    //Associate the audio to the Sleep as Android alarm
    await axios.put(`${AUDIO_URL}/v1/changeAlarmSound`, {
      audioId: req.body.audioId,
      alarmId: "SLEEP_AS_ANDROID",
    });
    res.send({ error: false });
  } catch (err) {
    logger.error(
      `Error while trying to associate an audio to the Sleep as Android integration : ${err.toString()} - ${JSON.stringify(
        err?.response?.data
      )} with status ${err?.response?.status}`
    );
    res.status(502).send({ error: true, errorCode: err?.response?.data });
  }
});

sleepAsAndroidRouter.put("/changeDelay", async (req, res) => {
  if (!req.body.delay) {
    res.status(400).send({
      error: true,
      errorCode: "MISSING_DELAY",
    });
    return;
  }

  if (isNaN(parseInt(req.body.delay)) || parseInt(req.body.delay) < 0) {
    res.status(400).send({
      error: true,
      errorCode: "WRONG_DELAY",
    });
    return;
  }

  let dbIntegrationInstance: any = await getSleepAsAndroidIntegrationDBObject();

  //Do it this way to avoid unexisting config error
  let oldConfig = { ...dbIntegrationInstance.config };
  oldConfig.delay = req.body.delay;
  dbIntegrationInstance.config = oldConfig;
  await dbIntegrationInstance.save();

  logger.info(
    `[SLEEP AS ANDROID] Set Sleep as Android delay to ${req.body.delay}`
  );

  res.send({
    error: false,
    response: {
      delay: dbIntegrationInstance.config.delay,
    },
  });
});

sleepAsAndroidRouter.put("/toogleCurrentAlarm", async (req, res) => {
  if (req.body.isActive === null || req.body.isActive === undefined) {
    res.status(400).send({ error: true, errorCode: "MISSING_IS_ACTIVE" });
    return;
  }

  if (req.body.isActive) {
    await SleepAsAndroidAlarm.onAlarm();
  } else {
    await SleepAsAndroidAlarm.stopTheAlarm();
  }

  res.send({ error: false });
});

async function handleSleepAsAndroidWebhook(event, value1?, value2?, value3?) {
  if (!(await getStatus())) return;

  logger.info(
    `[SLEEP AS ANDROID] New Sleep as Android event received: ${event} with values ${value1}, ${value2}, ${value3}`
  );
  switch (event) {
    case "alarm_alert_start":
      SleepAsAndroidAlarm.onAlarm();
      TrackingAdapter.updateIfDoesNotExistCurrent(
        {
          firstAlarmTime: new Date(),
        },
        true
      );
      break;
    case "alarm_snooze_clicked":
      SleepAsAndroidAlarm.stopTheAlarm();
      break;
    case "alarm_alert_dismiss":
      SleepAsAndroidAlarm.stopTheAlarm();
      TrackingAdapter.updateIfDoesNotExistCurrent(
        {
          wakeUpTime: new Date(),
        },
        true
      );
      break;
    case "sleep_tracking_started":
      TrackingAdapter.updateIfDoesNotExistCurrent(
        {
          sleepTime: new Date(),
        },
        true
      );
      break;
    default:
      break;
  }
}

async function getStatus(): Promise<boolean> {
  let dbIntegrationInstance: any = await getSleepAsAndroidIntegrationDBObject();
  return dbIntegrationInstance.isActive ?? false;
}

async function initSleepAsAndroidIntegration() {
  let dbIntegrationInstance: any = await getSleepAsAndroidIntegrationDBObject();
  if (!dbIntegrationInstance) {
    dbIntegrationInstance = await db.integrationStatuses.create({
      data: {
        name: "Sleep_as_Android",
        isActive: false,
        config: JSON.stringify({
          emergencyAlarmTimeoutSeconds: SLEEP_AS_ANDROID_MUTE_AFTER,
        }),
      },
    });
  }
  logger.info(`Initialized the Sleep as Android integration`);
}

async function getSleepAsAndroidIntegrationDBObject(): Promise<any> {
  return await db.integrationStatuses.findFirst({
    where: {
      name: "Sleep_as_Android",
    },
  });
}

interface IRingingStats {
  dateStarted: Date;
  alarmSilentTimeout: ReturnType<typeof setTimeout>;
  alarmEmergencyDeviceTimeout: ReturnType<typeof setTimeout>;
}

class SleepAsAndroidAlarm {
  static ringingStats?: IRingingStats;
  static delayTimeout: ReturnType<typeof setTimeout>;

  static async onAlarm(): Promise<void> {
    if (this.delayTimeout) {
      clearTimeout(this.delayTimeout);
      this.delayTimeout = null;
    }

    let delay =
      (await (await getSleepAsAndroidIntegrationDBObject())?.config?.delay) ??
      0; //In seconds

    this.delayTimeout = setTimeout(() => this.startTheAlarm(), delay * 1000);
  }

  static async startTheAlarm(): Promise<boolean> {
    if (this.delayTimeout) {
      clearTimeout(this.delayTimeout);
      this.delayTimeout = null;
    }
    if (this.ringingStats) {
      clearTimeout(this.ringingStats?.alarmSilentTimeout);
    }
    this.ringingStats = {
      dateStarted: new Date(),
      alarmSilentTimeout: setTimeout(
        () => this.stopTheAlarm,
        SLEEP_AS_ANDROID_MUTE_AFTER * 60 * 1000
      ),
      alarmEmergencyDeviceTimeout: setTimeout(
        () => toogleEmergencyDevice(true),
        ((await (
          await getSleepAsAndroidIntegrationDBObject()
        )?.config?.emergencyAlarmTimeoutSeconds) ??
          SLEEP_AS_ANDROID_MUTE_AFTER * 60) * 1000
      ),
    };
    try {
      await axios.put(`${AUDIO_URL}/v1/alarmRinging`, {
        alarmId: "SLEEP_AS_ANDROID",
      });
    } catch (err) {
      logger.error(
        `Error when sending the RINGING_ALARM event (Sleep as Android integration). ${JSON.stringify(
          err?.response?.data ?? ""
        )} with status ${err?.response?.status}`
      );
      return false;
    }
    logger.info(`[SLEEP AS ANDROID] Started the Sleep as Android alarm`);

    return true;
  }

  static async stopTheAlarm(): Promise<boolean> {
    if (this.delayTimeout) {
      clearTimeout(this.delayTimeout);
      this.delayTimeout = null;
      return;
    }
    if (this.ringingStats) {
      clearTimeout(this.ringingStats?.alarmSilentTimeout);
      clearTimeout(this.ringingStats?.alarmEmergencyDeviceTimeout);
    }
    this.ringingStats = null;

    try {
      await axios.put(`${AUDIO_URL}/v1/muteAudio`, {
        alarmId: "SLEEP_AS_ANDROID",
      });
    } catch (err) {
      logger.error(
        `Error when sending the MUTE_AUDIO event. ${JSON.stringify(
          err?.response?.data ?? ""
        )} with status ${err?.response?.status}`
      );
      return false;
    }

    await toogleEmergencyDevice(false);

    logger.info(`[SLEEP AS ANDROID] Stopped the Sleep as Android alarm`);
  }
}

export default sleepAsAndroidRouter;
export { initSleepAsAndroidIntegration };
