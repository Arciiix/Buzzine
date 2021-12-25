import express from "express";
import { Server as SocketServer, Socket } from "socket.io";
import dotenv from "dotenv";
import logger from "./utils/logger";
import Alarm from "./alarm";

const { info, error, warn, debug } = logger;

//Load environment variables from file
dotenv.config();
const PORT = process.env.PORT || 5555;

const app = express();
const server = app.listen(PORT, () => {
  info(`Core has started on port ${PORT}.`);
});

const io = new SocketServer(server, {
  cors: {
    origin: "localhost",
  },
});

io.on("connection", (socket: Socket) => {
  //Send initial message, to let the client know everything's working
  socket.emit("hello");

  info(
    `New socket with id ${
      socket.id
    } has connected! Request object: ${JSON.stringify(socket.handshake)}`
  );
});
class Buzzine {
  static alarms: Alarm[] = [];
}

export { io };
