import { DataTypes } from "sequelize";
import shortUUID from "short-uuid";
import db from "../utils/db";
import TrackingEntryModel from "./TrackingEntry";

const TrackingVersionHistoryModel = db.define("TrackingVersionHistory", {
  id: {
    allowNull: false,
    type: DataTypes.STRING,
    unique: true,
    primaryKey: true,
    defaultValue: () => shortUUID.generate(),
  },
  timestamp: {
    allowNull: false,
    type: DataTypes.DATE,
    defaultValue: () => new Date(),
  },
  entryId: {
    allowNull: false,
    type: DataTypes.STRING,
  },
  date: {
    allowNull: false,
    type: DataTypes.DATE,
  },
  fieldName: {
    allowNull: false,
    type: DataTypes.STRING,
  },
  value: {
    allowNull: true,
    type: DataTypes.DATE,
  },
});

TrackingVersionHistoryModel.belongsTo(TrackingEntryModel, {
  foreignKey: "entryId",
});

export default TrackingVersionHistoryModel;
