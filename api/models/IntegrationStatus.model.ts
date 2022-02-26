import { DataTypes } from "sequelize";
import db from "../utils/db";

const IntegrationStatusModel = db.define("IntegrationStatus", {
  name: {
    allowNull: false,
    type: DataTypes.STRING,
  },
  isActive: {
    allowNull: false,
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  config: {
    allowNull: true,
    type: DataTypes.JSON,
  },
});

export default IntegrationStatusModel;
