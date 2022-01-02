import { DataTypes } from "sequelize";
import db from "../utils/db";

const QRCodeModel = db.define("QRCode", {
  hash: {
    allowNull: false,
    type: DataTypes.STRING,
  },
});

export default QRCodeModel;
