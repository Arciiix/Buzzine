import { DataTypes } from "sequelize";
import db from "../utils/db";

const FirebaseNotificationTokenModel = db.define("FirebaseNotificationToken", {
  token: {
    allowNull: false,
    type: DataTypes.STRING,
  },
});

export default FirebaseNotificationTokenModel;
