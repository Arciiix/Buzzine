import express from "express";
import { Server as SocketServer, Socket } from "socket.io";
import dotenv from "dotenv";
import logger from "./utils/logger";
import Alarm from "./alarm";
import { initDatabase } from "./utils/db";
import GetDatabaseData from "./utils/loadFromDb";
import {
  cancelEmergencyAlarm,
  checkForAlarmProtection,
  getEmergencyStatus,
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

  socket.on("CMD/PING", (_: any, cb?: any) => {
    // await saveUpcomingAlarms();
    if (cb) {
      logger.info(`Core has been pinged`);
      cb({ error: false, timestamp: new Date() });
    } else {
      logger.warn("Missing callback on ping request");
    }
  });

  socket.on("CMD/GET_CONSTANTS", async (cb) => {
    //Get the useful safe constants - in this case MUTE_AFTER, used to determine the max emergencyAlarmTimeoutSeconds value
    let constants = {
      MUTE_AFTER: parseInt(process.env.MUTE_AFTER) || 10,
    };
    if (cb) {
      cb({ error: false, response: constants });
    } else {
      logger.warn("Missing callback on GET request - GET_CONSTANTS");
    }
    logger.info("Sent constants");
  });

  socket.on("CMD/GET_EMERGENCY_STATUS", async (cb) => {
    let emergencyStatus = getEmergencyStatus();

    if (cb) {
      cb({ error: false, response: emergencyStatus });
    } else {
      logger.warn("Missing callback on GET request - GET_EMERGENCY_STATUS");
    }
    logger.info("Sent emergency status");
  });

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
        emergencyAlarmTimeoutSeconds: payload?.emergencyAlarmTimeoutSeconds,
      });
      if (cb) {
        cb(newAlarm);
      }
      logger.info(`Added new alarm ${newAlarm.id}`);
      //I can't just refetch the alarms - e.g. it would cancel all snoozes
      Buzzine.alarms.push(
        new Alarm({
          id: newAlarm?.id,
          isActive: newAlarm?.isActive,
          hour: newAlarm?.hour,
          minute: newAlarm?.minute,
          deleteAfterRinging: newAlarm?.deleteAfterRinging,
          isGuardEnabled: newAlarm?.isGuardEnabled,
          isSnoozeEnabled: newAlarm?.isSnoozeEnabled,
          maxTotalSnoozeDuration: newAlarm?.maxTotalSnoozeDuration,
          name: newAlarm?.name,
          notes: newAlarm?.notes,
          repeat: newAlarm?.repeat,
          emergencyAlarmTimeoutSeconds: newAlarm?.emergencyAlarmTimeoutSeconds,
        })
      );
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
        emergencyAlarmTimeoutSeconds: payload?.emergencyAlarmTimeoutSeconds,
      });
      await alarm.save();
      //I can't just refetch the alarms - e.g. it would cancel all snoozes
      let oldAlarmIndex = Buzzine.alarms.findIndex((e) => e.id === payload.id);
      Buzzine.alarms[oldAlarmIndex].cancelJob();
      Buzzine.alarms[oldAlarmIndex] = new Alarm({
        id: payload.id,
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
      });

      if (cb) {
        cb(alarm);
      }
      logger.info(`Updated alarm ${alarm.id}`);
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
            alarm: elem.toRingingObject(),
          };
        })
      );
    } else {
      logger.warn("Missing callback on GET request - GET_ACTIVE_SNOOZES");
    }
  });
  socket.on("CMD/CANCEL_EMERGENCY_ALARM", (cb) => {
    cancelEmergencyAlarm();
    if (cb) {
      cb({ error: false });
    }
  });

  socket.on("CMD/CANCEL_ALL_ALARMS", async (cb) => {
    for await (const element of Buzzine.currentlyRingingAlarms) {
      await element.turnOff();
    }

    //Cancel all alarms with snoozes as well
    let alarmsWithSnooze = Buzzine.alarms.filter((e) => e.snoozes.length !== 0);
    for await (const elem of alarmsWithSnooze) {
      await elem.turnOff();
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
  if (!process.env.DISABLE_EMERGENCY) {
    await checkForAlarmProtection();
  } else {
    logger.warn("Emergency alerts are disabled!");
  }
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
