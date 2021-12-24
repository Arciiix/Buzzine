import express from "express";
import { Server as SocketServer, Socket } from "socket.io";
import dotenv from "dotenv";

//Load environment variables from file
dotenv.config();

const PORT = process.env.PORT || 5555;

const app = express();
const server = app.listen(PORT, () => {
  //TODO: Migrate to a logging library
  console.log(`Core has started on port ${PORT}.`);
});

const io = new SocketServer(server, {
  cors: {
    origin: "localhost",
  },
});

io.on("connection", (socket: Socket) => {
  //TODO: Migrate to a logging library
  console.log(
    `New socket with id ${
      socket.id
    } has connected! Request object: ${JSON.stringify(socket.handshake)}`
  );
});
