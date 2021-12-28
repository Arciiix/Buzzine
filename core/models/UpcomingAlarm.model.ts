import { DataTypes } from "sequelize";
import db from "../utils/db";
import AlarmModel from "./Alarm.model";

const UpcomingAlarmModel = db.define("UpcomingAlarm", {
  invocationDate: {
    type: DataTypes.DATE,
    allowNull: false,
  },
  AlarmId: {
    type: DataTypes.UUIDV4,
    allowNull: false,
  },
});

UpcomingAlarmModel.belongsTo(AlarmModel, {
  foreignKey: "AlarmId",
});

export default UpcomingAlarmModel;
