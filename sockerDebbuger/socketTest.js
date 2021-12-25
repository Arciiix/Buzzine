const socket = require("socket.io-client");

const io = socket("http://localhost:5555");

io.on("connect", () => {
  console.log("Successfully connected");
});

io.onAny((e, data) => {
  console.log("\nNEW EVENT");
  console.log(e);
  console.log(data);
});
