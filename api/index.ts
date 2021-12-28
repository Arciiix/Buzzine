import express from "express";
import { io } from "socket.io-client";
import dotenv from "dotenv";
import logger from "./utils/logger";
import bodyParser from "body-parser";

//Load environment variables from file
dotenv.config();
const PORT = process.env.PORT || 1111;

const app = express();
app.use(bodyParser.json());

//REST API
const api = express.Router();
app.use("/v1", api);

api.post("/addAlarm", async (req, res) => {
  logger.http(`POST /addAlarm with data: ${JSON.stringify(req.body)}`);

  if (!req.body)
    return res.status(400).send({ error: true, errorCode: "EMPTY_PAYLOAD" });

  //Validate the payload
  if (
    req.body.hour === null ||
    req.body.minute === null ||
    isNaN(req.body.hour) ||
    isNaN(req.body.minute)
  ) {
    return res.status(400).send({ error: true, errorCode: "WRONG_TIME" });
  }

  socket.emit("CMD/CREATE_ALARM", req.body, (response) => {
    if (response.error) {
      res.status(400).send(response);
      logger.warn(
        `Response error when creating the alarm: ${JSON.stringify(response)}`
      );
    } else {
      res.status(201).send({ error: false, response });
      logger.info(
        `Created alarm successfully. Response: ${JSON.stringify(response)}`
      );
    }
  });
});

api.put("/cancelAlarm", async (req, res) => {
  logger.http(`PUT /cancelAlarm with data: ${JSON.stringify(req.body)}`);

  if (!req.body)
    return res.status(400).send({ error: true, errorCode: "EMPTY_PAYLOAD" });

  //Validate the payload
  if (!req.body.id) {
    return res.status(400).send({ error: true, errorCode: "MISSING_ID" });
  }

  socket.emit("CMD/TURN_ALARM_OFF", req.body, (response) => {
    if (response.error) {
      res.status(400).send(response);
      logger.warn(
        `Response error when cancelling the alarm: ${JSON.stringify(response)}`
      );
    } else {
      res.status(200).send({ error: false, response });
      logger.info(
        `Cancelled alarm ${
          req.body.id
        } successfully. Response: ${JSON.stringify(response)}`
      );
    }
  });
});

api.put("/toogleAlarm", async (req, res) => {
  logger.http(`PUT /toogleAlarm with data: ${JSON.stringify(req.body)}`);

  if (!req.body)
    return res.status(400).send({ error: true, errorCode: "EMPTY_PAYLOAD" });

  //Validate the payload
  if (!req.body.id) {
    return res.status(400).send({ error: true, errorCode: "MISSING_ID" });
  }
  if (!req.body.hasOwnProperty("status")) {
    return res
      .status(400)
      .send({ error: true, errorCode: "MISSING_ALARM_STATUS" });
  }

  socket.emit("CMD/TOOGLE_ALARM", req.body, (response) => {
    if (response.error) {
      res.status(400).send(response);
      logger.warn(
        `Response error when toogling the alarm: ${JSON.stringify(response)}`
      );
    } else {
      res.status(200).send({ error: false, response });
      logger.info(
        `Toogled alarm ${
          req.body.status ? "on" : "off"
        } successfully. Response: ${JSON.stringify(response)}`
      );
    }
  });
});
api.put("/cancelNextInvocation", (req, res) => {
  logger.http(
    `PUT /cancelNextInvocation with data: ${JSON.stringify(req.body)}`
  );

  if (!req.body)
    return res.status(400).send({ error: true, errorCode: "EMPTY_PAYLOAD" });

  //Validate the payload
  if (!req.body.id) {
    return res.status(400).send({ error: true, errorCode: "MISSING_ID" });
  }

  socket.emit("CMD/CANCEL_NEXT_INVOCATION", req.body, (response) => {
    if (response.error) {
      res.status(400).send(response);
      logger.warn(
        `Response error when canceling the invocation: ${JSON.stringify(
          response
        )}`
      );
    } else {
      res.status(200).send({ error: false, response });
      logger.info(
        `Cancelled next invocation of alarm ${
          req.body.id
        } successfully. Response: ${JSON.stringify(response)}`
      );
    }
  });
});

const socket = io(process.env.CORE_URL || "http://localhost:5555"); //DEV - to be changed with Docker

socket.on("connect", () => {
  logger.info(
    `Made a connection with the core, waiting for the initial message...`
  );
});

socket.on("hello", () => {
  logger.info(`Successfully connected to the core`);
});
const server = app.listen(PORT, () => {
  logger.info(`API has started on port ${PORT}`);
});
export { io };
