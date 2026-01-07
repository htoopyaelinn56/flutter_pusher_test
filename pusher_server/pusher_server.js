const Pusher = require("pusher");
require('dotenv').config();

// get from .env
const appId = process.env.PUSHER_APP_ID.toString();
const key = process.env.PUSHER_APP_KEY.toString();
const secret = process.env.PUSHER_APP_SECRET.toString();
const cluster = process.env.PUSHER_APP_CLUSTER.toString();

const pusher = new Pusher({
    appId: appId, key: key, secret: secret, cluster: cluster,
});

// http serve
const express = require("express");
const app = express();
const port = 3000;

app.use(express.json());

app.get("/", (req, res) => {
    res.send("Pusher server is running");
});

app.listen(port, () => {
    console.log(`Pusher server listening at http://localhost:${port}`);
});

// send message by payload message
app.post("/send", (req, res) => {
    // Accessing message from the request body
    const pusherData = req.body || { message: "Hello from Pusher server!" };
    pusher.trigger("room-general", "message-event", pusherData)
        .then(r => {
            console.log("Event triggered: ", r);
            // show JSON encode pusher data
            res.send(`Message sent: ${JSON.stringify(pusherData)}`);
        })
        .catch(err => {
            console.error("Error triggering event:", err);
            res.status(500).send("Error sending message");
        });
});
