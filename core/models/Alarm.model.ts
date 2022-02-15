import { Sequelize, DataTypes, Model } from "sequelize";
import shortUUID from "short-uuid";
import db from "../utils/db";

const AlarmModel = db.define("Alarm", {
  id: {
    primaryKey: true,
    allowNull: false,
    type: DataTypes.UUIDV4,
    defaultValue: () => shortUUID.generate(),
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true,
  },
  isGuardEnabled: {
    type: DataTypes.BOOLEAN,
    allowNull: true,
    defaultValue: true,
  },
  isSnoozeEnabled: {
    type: DataTypes.BOOLEAN,
    allowNull: true,
    defaultValue: true,
  },
  name: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  notes: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  hour: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  minute: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  repeat: {
    type: DataTypes.JSON,
    allowNull: true,
  },
  maxTotalSnoozeDuration: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  deleteAfterRinging: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  emergencyAlarmTimeoutSeconds: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },
});

export default AlarmModel;
