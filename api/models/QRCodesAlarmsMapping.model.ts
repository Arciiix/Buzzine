import { DataTypes } from "sequelize";
import db from "../utils/db";
import QRCodeModel from "./QRCode.model";

const QRCodeAlarmsMappingModel = db.define("QRCodeAlarmsMapping", {
  name: {
    allowNull: false,
    type: DataTypes.STRING,
    unique: true,
  },
  alarmId: {
    allowNull: false,
    unique: true,
    type: DataTypes.STRING,
  },
});

QRCodeAlarmsMappingModel.belongsTo(QRCodeModel, { foreignKey: "name" });

export default QRCodeAlarmsMappingModel;
