import { Sequelize, DataTypes, Model } from "sequelize";
import short from "short-uuid";
import db from "../utils/db";

const AlarmModel = db.define("Alarm", {
  id: {
    primaryKey: true,
    allowNull: false,
    type: DataTypes.UUIDV4,
    defaultValue: () => short.generate(),
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
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
});

export default AlarmModel;
