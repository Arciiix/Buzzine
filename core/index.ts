import express from "express";
import { Server as SocketServer, Socket } from "socket.io";
import dotenv from "dotenv";
import logger from "./utils/logger";

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
  info(
    `New socket with id ${
      socket.id
    } has connected! Request object: ${JSON.stringify(socket.handshake)}`
  );
});
