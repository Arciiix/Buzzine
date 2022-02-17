import { DataTypes } from "sequelize";
import db from "../utils/db";
import NapModel from "./Nap.model";

const UpcomingNapModel = db.define("UpcomingNap", {
  invocationDate: {
    type: DataTypes.DATE,
    allowNull: false,
  },
  NapId: {
    type: DataTypes.UUIDV4,
    allowNull: false,
  },
});

UpcomingNapModel.belongsTo(NapModel, {
  foreignKey: "NapId",
});

export default UpcomingNapModel;
