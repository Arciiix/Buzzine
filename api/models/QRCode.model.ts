import { DataTypes } from "sequelize";
import shortUUID from "short-uuid";
import db from "../utils/db";

const QRCodeModel = db.define("QRCode", {
  name: {
    allowNull: false,
    primaryKey: true,
    unique: true,
    type: DataTypes.STRING,
    defaultValue: () => shortUUID.generate(),
  },
  hash: {
    allowNull: false,
    type: DataTypes.STRING,
  },
});

export default QRCodeModel;
