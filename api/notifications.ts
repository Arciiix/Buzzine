import express from "express";
import logger from "./utils/logger";
import firebaseAdmin from "firebase-admin";
import fs from "fs";
import FirebaseNotificationTokenModel from "./models/FirebaseNotificationToken.model";
import { socket } from ".";
import { NotificationMessagePayload } from "firebase-admin/lib/messaging/messaging-api";

const notificationsRouter = express.Router();

let firebaseServiceAccount;
let notificationServiceInstance: NotificationService;

class NotificationService {
  alarmIdsWithNotificationSent: string[] = [];
  tokens: string[];

  constructor() {
    this.fetchTokens();
  }

  async sendNotification(
    alarmId: string,
    alarmName?: string,
    alarmDescription?: string
  ): Promise<void> {
    if (this.alarmIdsWithNotificationSent.includes(alarmId)) return;
    this.alarmIdsWithNotificationSent.push(alarmId);

    //The Firebase send notification logic
    const notification: NotificationMessagePayload = {
      body: alarmDescription ?? "Aktywny alarm",
      color: "#0078f2",
      sound: "default",
      title: "Buzzine - " + (alarmName ?? "Alarm"),
    };

    if (this.tokens.length < 1) return;
    try {
      let response = await firebaseAdmin.messaging().sendToDevice(
        this.tokens,
        {
          notification,
          data: {
            alarmId: alarmId,
            alarmName: alarmName ?? "",
            alarmDescription: alarmDescription ?? "",
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

      let response = await firebaseAdmin.messaging().sendToDevice(
        token,
        { notification },
        {
          priority: "high",
          timeToLive: 60 * 5, //5 minutes
        }
      );

      logger.info(
        `Sent test Firebase notification: ${JSON.stringify(response)}`
      );
    }, 5000);
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
        alarmObj?.name,
        alarmObj?.notes
      );
    });
    socket.on("ALARM_OFF", () => {
      notificationServiceInstance.clearNotificationHistory();
    });

    socket.on("ALARM_MUTE", () => {
      notificationServiceInstance.clearNotificationHistory();
    });

    logger.info(`Loaded Firebase account config`);
  }
}

export default notificationsRouter;
export { loadFirebaseConfig, NotificationService };
