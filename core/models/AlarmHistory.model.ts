import { Sequelize, DataTypes, Model } from "sequelize";
import shortUUID from "short-uuid";
import db from "../utils/db";

const AlarmHistoryModel = db.define("AlarmHistory", {
  alarmId: {
    allowNull: false,
    type: DataTypes.UUIDV4,
    unique: false,
  },
  invocationDate: {
    allowNull: false,
    type: DataTypes.DATE,
  },

  name: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  notes: {
    type: DataTypes.STRING,
    allowNull: true,
  },
});

export default AlarmHistoryModel;
