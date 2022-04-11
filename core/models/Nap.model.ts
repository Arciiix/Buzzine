import { Sequelize, DataTypes, Model } from "sequelize";
import shortUUID from "short-uuid";
import db from "../utils/db";

const NapModel = db.define("Nap", {
  id: {
    primaryKey: true,
    allowNull: false,
    type: DataTypes.STRING,
    defaultValue: () => "NAP/" + shortUUID.generate(),
  },
  isActive: {
    //This field isn't used in general, it's just because of compatibility with the Alarm class
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
  second: {
    type: DataTypes.INTEGER,
    allowNull: false,
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
  invocationDate: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  isFavorite: {
    type: DataTypes.BOOLEAN,
    defaultValue: 0,
    allowNull: true,
  },
});

export default NapModel;
