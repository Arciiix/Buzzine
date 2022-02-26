import { DataTypes } from "sequelize";
import db from "../db";

const TemperatureModel = db.define("Temperature", {
  timestamp: {
    allowNull: false,
    type: DataTypes.DATE,
  },
  value: {
    allowNull: false,
    type: DataTypes.FLOAT,
  },
});

export default TemperatureModel;
