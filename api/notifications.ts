import express from "express";
import logger from "./utils/logger";
import firebaseAdmin from "firebase-admin";
import fs from "fs";
import { socket } from ".";
import {
  MessagingDevicesResponse,
  MessagingOptions,
  NotificationMessagePayload,
} from "firebase-admin/lib/messaging/messaging-api";
import TrackingAdapter from "./trackingAdapter";
import { addZero } from "./utils/formatting";
import FirebaseNotificationTokenModel from "./models/FirebaseNotificationToken.model";

const notificationsRouter = express.Router();

let firebaseServiceAccount;
let notificationServiceInstance: NotificationService;

class NotificationService {
  alarmIdsWithNotificationSent: string[] = [];
  emergencyNotificationSent: boolean;
  tokens: string[];

  constructor() {
    this.fetchTokens();
  }

  async sendNotification(
    alarmId: string,
    time: { hour: number; minute: number; second?: number },
    alarmName?: string,
    alarmDescription?: string
  ): Promise<void> {
    if (this.alarmIdsWithNotificationSent.includes(alarmId)) return;
    this.alarmIdsWithNotificationSent.push(alarmId);

    //The Firebase send notification logic
    const notification: NotificationMessagePayload = {
      body:
        alarmDescription ??
        `Aktywn${alarmId.includes("NAP/") ? "a drzemka" : "y alarm"}`,
      color: "#0078f2",
      sound: "default",
      title:
        "Buzzine - " +
        (alarmName ?? alarmId.includes("NAP/") ? "drzemka" : "alarm") +
        ` - ${addZero(time.hour)}:${addZero(time.minute)}${
          time.second ? ":" + addZero(time.second) : ""
        }`,
    };

    if (this.tokens.length < 1) return;
    try {
      let response = await firebaseAdmin.messaging().sendToDevice(
        this.tokens,
        {
          notification,
          data: {
            alarmId: alarmId,
          },
        },
        {
          priority: "high",
          timeToLive: 60 * 15, //15 minutes
        }
      );

      logger.info(`Sent Firebase notification: ${JSON.stringify(response)}`);
    } catch (err) {
      logger.error(
        `Error while sending a Firebase notification: ${err.toString()}`
      );
    }
  }

  async sendEmergencyNotification(): Promise<void> {
    if (this.emergencyNotificationSent) return;
    this.emergencyNotificationSent = true;

    //The Firebase send notification logic
    const notification: NotificationMessagePayload = {
      body: "System przeciwawaryjny aktywny",
      color: "#eb344c",
      sound: "default",
      title: "Buzzine - emergency",
    };

    if (this.tokens.length < 1) return;
    try {
      let response = await firebaseAdmin.messaging().sendToDevice(
        this.tokens,
        {
          notification,
        },
        {
          priority: "high",
          timeToLive: 3600, //1 hour
        }
      );

      logger.info(
        `Sent Firebase emergency notification: ${JSON.stringify(response)}`
      );
    } catch (err) {
      logger.error(
        `Error while sending the Firebase emergency notification: ${err.toString()}`
      );
    }
  }

  clearNotificationHistory() {
    this.alarmIdsWithNotificationSent = [];
  }

  sendTestNotification(token: string) {
    logger.info("Waiting to send the test Firebase notification...");
    //Wait for 5 seconds
    setTimeout(async () => {
      //The Firebase send notification logic
      const notification: NotificationMessagePayload = {
        body: "Jeśli to widzisz, prawdopodobnie możesz otrzymywać powiadomienia",
        color: "#0078f2",
        sound: "default",
        title: "Buzzine - test",
      };

      let response = await this.sendCustomNotification(notification, {
        token,
        options: {
          priority: "high",
          timeToLive: 60 * 5, //5 minutes
        },
      });

      logger.info(
        `Sent test Firebase notification: ${JSON.stringify(response)}`
      );
    }, 5000);
  }

  async sendCustomNotification(
    notification: NotificationMessagePayload,
    options?: {
      token?: string;
      options?: MessagingOptions;
    }
  ): Promise<MessagingDevicesResponse> {
    try {
      let response = await firebaseAdmin.messaging().sendToDevice(
        options?.token ?? this.tokens,
        {
          notification,
        },
        options?.options ?? {
          priority: "high",
          timeToLive: 3600, //1 hour
        }
      );

      logger.info(
        `Sent Firebase custom notification (${JSON.stringify(
          notification
        )} with options ${JSON.stringify(options)} to ${
          options?.token ? "token " + options.token : "all"
        }): ${JSON.stringify(response)}`
      );

      return response;
    } catch (err) {
      logger.error(
        `Error while sending a Firebase custom notification to ${
          options?.token ? "token " + options.token : "all"
        }: ${err.toString()}`
      );
    }
  }

  async fetchTokens() {
    let dbQueryResult: any = await FirebaseNotificationTokenModel.findAll();
    this.tokens = dbQueryResult.map((e) => e.token);
    return this.tokens;
  }
}

notificationsRouter.get("/sendTestNotification", async (req, res) => {
  if (!req.query.token) {
    res.status(400).send({ error: true, errorCode: "MISSING_TOKEN" });
    return;
  }
  await notificationServiceInstance.sendTestNotification(
    req.query.token as string
  );
  res.send({ error: false });
});

notificationsRouter.put("/toogleNotifications", async (req, res) => {
  if (!req.body.token) {
    logger.warn(
      `Tried to toogle notifications but didn't send the token in the request body`
    );
    res.status(400).send({ error: true, errorCode: "MISSING_TOKEN" });
    return;
  }
  if (req.body.isTurnedOn === null || req.body.isTurnedOn === undefined) {
    logger.warn(
      `Tried to toogle notifications but didn't specify the isTurnedOn param`
    );
    res.status(400).send({ error: true, errorCode: "MISSING_IS_TURNED_ON" });
    return;
  }

  if (req.body.isTurnedOn) {
    await FirebaseNotificationTokenModel.findOrCreate({
      where: {
        token: req.body.token,
      },
    });
  } else {
    await FirebaseNotificationTokenModel.destroy({
      where: { token: req.body.token },
    });
  }

  await notificationServiceInstance.fetchTokens();

  res.send({ error: false });
});

notificationsRouter.get("/checkIfTokenExists", async (req, res) => {
  if (!req.query.token) {
    logger.warn(
      `Tried to check if a token exists but didn't specify the token`
    );
    res.status(400).send({ error: true, errorCode: "MISSING_TOKEN" });
    return;
  }

  let token = await FirebaseNotificationTokenModel.findOne({
    where: { token: req.query.token },
  });

  if (!token) {
    res.status(404).send({ error: false, response: { found: false } });
  } else {
    res.send({ error: false, response: { found: true } });
  }
});

notificationsRouter.post("/sendNotification", async (req, res) => {
  if (
    !req.body.notificationPayload ||
    !req.body.notificationPayload.body ||
    !req.body.notificationPayload.title
  ) {
    res
      .status(400)
      .send({ error: true, errorCode: "MISSING_NOTIFICATION_PAYLOAD" });
    return;
  }

  const notification: NotificationMessagePayload = {
    body: req.body.notificationPayload.body,
    color: req.body.notificationPayload.color ?? "#0078f2",
    sound: req.body.notificationPayload.sound ?? "default",
    title: `Buzzine - ${req.body.notificationPayload.title}`,
  };

  let response = await notificationServiceInstance.sendCustomNotification(
    notification,
    {
      token: req.body.token,
      options: {
        priority: "high",
        timeToLive: req.body.timeToLive || 60 * 5, //5 minutes
      },
    }
  );

  logger.info(
    `Sent notification ${JSON.stringify(req.body.notificationPayload)} to ${
      req.body.token ? "token " + req.body.token : "all tokens"
    }`
  );
  res.send({ error: false });
});

function loadFirebaseConfig() {
  if (!fs.existsSync("firebaseServiceAccountKey.json")) {
    logger.error("Missing Firebase configuration file!");
    throw new Error("Missing Firebase configuration file!");
  } else {
    let config = fs.readFileSync("firebaseServiceAccountKey.json");
    firebaseServiceAccount = JSON.parse(config.toString());
    firebaseAdmin.initializeApp({
      credential: firebaseAdmin.credential.cert(firebaseServiceAccount),
    });
    notificationServiceInstance = new NotificationService();

    //Listen to socket events
    socket.on("ALARM_RINGING", async (alarmObj) => {
      notificationServiceInstance.sendNotification(
        alarmObj.id,
        {
          hour: alarmObj.hour,
          minute: alarmObj.minute,
          second: alarmObj?.second,
        },
        alarmObj?.name,
        alarmObj?.notes
      );
      TrackingAdapter.updateIfDoesNotExistCurrent({
        firstAlarmTime: new Date(new Date().setSeconds(0)),
      });
    });
    socket.on("ALARM_OFF", () => {
      notificationServiceInstance.clearNotificationHistory();
    });

    socket.on("ALARM_MUTE", () => {
      notificationServiceInstance.clearNotificationHistory();
    });
    socket.on("EMERGENCY_ALARM", async () => {
      notificationServiceInstance.sendEmergencyNotification();
    });
    socket.on("EMERGENCY_ALARM_CANCELLED", async () => {
      notificationServiceInstance.emergencyNotificationSent = false;
    });

    logger.info(`Loaded Firebase account config`);
  }
}

async function sendCustomNotification(
  notification: NotificationMessagePayload,
  options?: {
    token?: string;
    options?: MessagingOptions;
  }
): Promise<MessagingDevicesResponse> {
  return await notificationServiceInstance.sendCustomNotification(
    notification,
    options
  );
}

export default notificationsRouter;
export {
  loadFirebaseConfig,
  NotificationService,
  notificationServiceInstance,
  sendCustomNotification,
};
