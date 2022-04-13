import { DataTypes } from "sequelize";
import shortUUID from "short-uuid";
import db from "../utils/db";

const TrackingEntryModel = db.define("TrackingEntry", {
  entryId: {
    allowNull: false,
    type: DataTypes.STRING,
    unique: true,
    primaryKey: true,
    defaultValue: () => shortUUID.generate(),
  },
  date: {
    allowNull: false,
    type: DataTypes.DATE,
  },
  bedTime: {
    allowNull: true,
    type: DataTypes.DATE,
  },
  sleepTime: {
    allowNull: true,
    type: DataTypes.DATE,
  },
  firstAlarmTime: {
    allowNull: true,
    type: DataTypes.DATE,
  },
  wakeUpTime: {
    allowNull: true,
    type: DataTypes.DATE,
  },
  getUpTime: {
    allowNull: true,
    type: DataTypes.DATE,
  },
  rate: {
    allowNull: true,
    type: DataTypes.INTEGER,
  },
  alarmTimeFrom: {
    allowNull: true,
    type: DataTypes.DATE,
  },
  alarmTimeTo: {
    allowNull: true,
    type: DataTypes.DATE,
  },
  timeTakenToTurnOffTheAlarm: {
    allowNull: true,
    type: DataTypes.INTEGER,
  },
  notes: {
    allowNull: true,
    type: DataTypes.STRING,
  },
});

export default TrackingEntryModel;
