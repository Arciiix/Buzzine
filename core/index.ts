import express from "express";
import { Server as SocketServer, Socket } from "socket.io";
import dotenv from "dotenv";
import logger from "./utils/logger";
import Alarm from "./alarm";
import { initDatabase } from "./utils/db";
import GetDatabaseData from "./utils/loadFromDb";
import {
  checkForAlarmProtection,
  getUpcomingAlarms,
  saveUpcomingAlarms,
} from "./utils/alarmProtection";
import AlarmModel from "./models/Alarm.model";

//Load environment variables from file
dotenv.config();
const PORT = process.env.PORT || 3333;

const app = express();
const server = app.listen(PORT, () => {
  logger.info(`Core has started on port ${PORT}.`);
});

const io = new SocketServer(server, {
  cors: {
    origin: "localhost",
  },
});

app.get("/", (req, res) => {
  res.send({ error: false });
});

io.on("connection", (socket: Socket) => {
  //Send initial message, to let the client know everything's working
  socket.emit("hello");

  logger.info(
    `New socket with id ${
      socket.id
    } has connected! Request object: ${JSON.stringify(socket.handshake)}`
  );

  socket.on("CMD/CREATE_ALARM", async (payload: any, cb?: any) => {
    if (payload?.repeat && !payload.repeat?.tz) {
      logger.warn(
        `Missing timezone in the repeat object when creating alarm! ${JSON.stringify(
          payload
        )}`
      );
      if (cb) {
        cb({ error: true, errorCode: "MISSING_TIMEZONE" });
      }
      return;
    }
    try {
      let newAlarm: any = await AlarmModel.create({
        isActive: payload.isActive,
        isGuardEnabled: payload?.isGuardEnabled,
        isSnoozeEnabled: payload?.isSnoozeEnabled,
        name: payload?.name,
        notes: payload?.notes,
        hour: payload.hour,
        minute: payload.minute,
        repeat: payload?.repeat,
        maxTotalSnoozeDuration: payload?.maxTotalSnoozeDuration,
        deleteAfterRinging: payload?.deleteAfterRinging ?? false,
      });
      if (cb) {
        cb(newAlarm);
      }
      logger.info(`Added new alarm ${newAlarm.id}`);
      const alarms = await GetDatabaseData.getAlarms();
      Buzzine.alarms.forEach((elem) => {
        elem.cancelJob();
      });
      Buzzine.alarms = alarms.map((e) => {
        return new Alarm(e);
      });
      logger.info(`Refetched alarms from the db`);
    } catch (err) {
      logger.warn(
        `Tried to create an alarm with a probably wrong payload! ${JSON.stringify(
          payload
        )}; err: ${err.toString()}`
      );
      if (cb) {
        cb({ error: true });
      }
    }
  });

  socket.on("CMD/TOOGLE_ALARM", async (payload: any, cb?: any) => {
    let alarm: Alarm = Buzzine.alarms.find((e) => e.id === payload.id);
    if (!alarm) {
      if (cb) {
        cb({ error: true, errorMessage: "WRONG_ID" });
      }
      logger.warn("Trying to toogle alarm with a wrong id!");
      return;
    }
    if (payload.status) {
      alarm.turnOn();
    } else {
      alarm.disableAlarm();
    }

    logger.info(
      `Successfully turned alarm ${payload.id} ${payload.status ? "on" : "off"}`
    );
    if (cb) {
      cb(alarm.toObject());
    }
  });

  socket.on("CMD/CANCEL_NEXT_INVOCATION", async (payload: any, cb?: any) => {
    let alarm: Alarm = Buzzine.alarms.find((e) => e.id === payload.id);
    if (!alarm) {
      if (cb) {
        cb({ error: true, errorMessage: "WRONG_ID" });
        logger.warn(
          "Tried to cancel next invocation of an alarm with a wrong id!"
        );
      }
      return;
    }
    if (!alarm.repeat) {
      cb({ error: true, errorMessage: "NON_REPEATING_ALARM" });
      logger.warn(
        `Tried to cancel next invocation of a non-repeating alarm ${alarm.id}`
      );
      return;
    }

    alarm.cancelNextInvocation();
    logger.info(
      `Successfully cancelled the next invocation of alarm ${payload.id}`
    );
    if (cb) {
      cb(alarm.toObject());
    }
  });

  socket.on("CMD/TURN_ALARM_OFF", async (payload: any, cb?: any) => {
    let alarm: Alarm = Buzzine.alarms.find((e) => e.id === payload.id);
    if (!alarm) {
      if (cb) {
        cb({ error: true, errorMessage: "WRONG_ID" });
      }
      logger.warn("Trying to turn off an alarm with a wrong id!");
      return;
    }
    alarm.turnOff();

    logger.info(`Successfully turned alarm ${payload.id} off`);
    if (cb) {
      cb(alarm.toObject());
    }
  });

  socket.on("CMD/SNOOZE_ALARM", async (payload: any, cb?: any) => {
    let alarm: Alarm = Buzzine.alarms.find((e) => e.id === payload.id);
    if (!alarm) {
      if (cb) {
        cb({ error: true, errorMessage: "WRONG_ID" });
      }
      logger.warn("Trying to snooze an alarm with a wrong id!");
      return;
    }

    let didSnooze = alarm.snoozeAlarm(payload?.snoozeDuration);

    logger.info(
      `${didSnooze ? "Snoozed" : "Couldn't snooze"} alarm ${alarm.id}`
    );

    if (cb) {
      cb({
        didSnooze: didSnooze,
        snoozeInvocationDate:
          alarm.snoozes?.[alarm.snoozes.length - 1]?.invocationDate,
        totalSnoozes: alarm.snoozes?.length,
        totalSnoozesTime:
          alarm.snoozes?.length > 0
            ? Math.floor(
                (new Date().getTime() - alarm.snoozes[0].startDate.getTime()) /
                  1000
              )
            : 0,
        alarm: alarm.toObject(),
      });
    }
  });

  socket.on("CMD/DELETE_ALARM", async (payload: any, cb?: any) => {
    let alarm: Alarm = Buzzine.alarms.find((e) => e.id === payload.id);
    if (!alarm) {
      if (cb) {
        cb({ error: true, errorMessage: "WRONG_ID" });
      }
      logger.warn("Trying to delete an alarm with a wrong id!");
      return;
    }
    await alarm.deleteSelf();

    logger.info(`Successfully deleted alarm ${payload.id}`);
    if (cb) {
      cb({});
    }
  });

  socket.on("CMD/UPDATE_ALARM", async (payload: any, cb?: any) => {
    if (payload?.repeat && !payload.repeat?.tz) {
      logger.warn(
        `Missing timezone in the repeat object when creating alarm! ${JSON.stringify(
          payload
        )}`
      );
      if (cb) {
        cb({ error: true, errorCode: "MISSING_TIMEZONE" });
      }
      return;
    }
    try {
      let alarm: any = await AlarmModel.findOne({ where: { id: payload.id } });
      await alarm.set({
        isActive: payload.isActive,
        isGuardEnabled: payload?.isGuardEnabled,
        isSnoozeEnabled: payload?.isSnoozeEnabled,
        name: payload?.name,
        notes: payload?.notes,
        hour: payload.hour,
        minute: payload.minute,
        repeat: payload?.repeat,
        maxTotalSnoozeDuration: payload?.maxTotalSnoozeDuration,
        deleteAfterRinging: payload?.deleteAfterRinging ?? false,
      });
      await alarm.save();

      if (cb) {
        cb(alarm);
      }
      logger.info(`Updated alarm ${alarm.id}`);
      logger.info(`Refetched alarms from the db`);
      const alarms = await GetDatabaseData.getAlarms();
      Buzzine.alarms.forEach((elem) => {
        elem.cancelJob();
      });
      Buzzine.alarms = alarms.map((e) => {
        return new Alarm(e);
      });
    } catch (err) {
      logger.warn(
        `Tried to update an alarm with a probably wrong payload! ${JSON.stringify(
          payload
        )}; err: ${err.toString()}`
      );
      if (cb) {
        cb({ error: true });
      }
    }
  });

  socket.on("CMD/GET_UPCOMING_ALARMS", async (cb) => {
    let upcomingAlarms = await getUpcomingAlarms();
    saveUpcomingAlarms();
    if (cb) {
      cb(upcomingAlarms);
    } else {
      logger.warn("Missing callback on GET request - GET_UPCOMING_ALARMS");
    }
  });

  socket.on("CMD/GET_ALL_ALARMS", async (cb) => {
    if (cb) {
      cb(Buzzine.alarms.map((e) => e.toObject()));
    } else {
      logger.warn("Missing callback on GET request - GET_ALL_ALARMS");
    }
  });
  socket.on("CMD/GET_RINGING_ALARMS", async (cb) => {
    if (cb) {
      cb(Buzzine.currentlyRingingAlarms.map((e) => e.toRingingObject()));
    } else {
      logger.warn("Missing callback on GET request - GET_RINGING_ALARMS");
    }
  });
  socket.on("CMD/GET_ACTIVE_SNOOZES", async (cb) => {
    if (cb) {
      let alarmsWithSnoozes = Buzzine.alarms.filter(
        (e) => e.snoozes.length > 0
      );
      cb(
        alarmsWithSnoozes.map((elem: Alarm) => {
          return {
            snooze: elem.snoozes[elem.snoozes.length - 1].toObject(),
            alarm: elem.toObject(),
          };
        })
      );
    } else {
      logger.warn("Missing callback on GET request - GET_ACTIVE_SNOOZES");
    }
  });
  socket.on("CMD/CANCEL_ALL_ALARMS", async (cb) => {
    for await (const element of Buzzine.currentlyRingingAlarms) {
      await element.turnOff();
    }
    if (cb) {
      cb({ error: false });
    }
  });
});
class Buzzine {
  static alarms: Alarm[] = [];
  static currentlyRingingAlarms: Alarm[] = [];
}

async function init() {
  await initDatabase();
  await checkForAlarmProtection();
  const { alarms } = await GetDatabaseData.getAll();

  Buzzine.alarms = alarms.map((e) => {
    return new Alarm(e);
  });

  //Delay it because it's ran every time the alarm turns on - the alarms are being created now
  setTimeout(() => {
    saveUpcomingAlarms();
  }, 5000);

  logger.info("Got database data");
}

init();

export { Buzzine, io };
