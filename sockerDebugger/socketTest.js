const socket = require("socket.io-client");

const io = socket("http://localhost:3333");

io.on("connect", () => {
  console.log("Successfully connected");
});

io.onAny((e, data) => {
  console.log("\n");
  console.log(e);
  console.log(data);
});
