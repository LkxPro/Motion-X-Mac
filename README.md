# Motion X View

Motion X View is a macOS application designed to receive, record, and visualize device motion data sent from the [Motion X iOS app](https://github.com/LkxPro/Motion-X-iOS). 

Motion X View offers a comprehensive interface to display real-time `roll`, `pitch`, `yaw`, and user `acceleration` data.

The app uses `WebSocket` for fast and low-latency data communication and offers real-time 3D visualization and charting capabilities for an enhanced user experience.

https://github.com/LkxPro/Motion-X-iOS/assets/20046257/59233619-5f04-444b-8ef8-7bd83a953daa

## Features

- **3D Visualization:** Visualizes device motion in 3D using SceneKit.

- **Real-Time Data Display:** Shows `roll`, `pitch`, `yaw`, and `acceleration` data.

- **WebSocket Communication:** Receives motion data from the [Motion X iOS app](https://github.com/LkxPro/Motion-X-iOS) with low-latency `Websocket` commuication.

- **Charting:** Displays motion data in adaptive line chart for each axis.

- **Data Recording:** Records motion data for analysis and review.

## Build from source
Clone the repository

    git clone https://github.com/LkxPro/Motion-X-Mac.git

Open the `Motion X View.xcodeproj` file in Xcode.

Choose a macOS device or simulator as the target.

Press Run to build and launch the application.

## Usage

This application **does not** include a built-in WebSocket server. You will need to set up a separate WebSocket server.

## Setting Up the Server
Install Node.js

    brew install node

Install WebSocket library

    npm install ws

Create a server.js file


```js
const WebSocket = require('ws');

const port = 8080;
const server = new WebSocket.Server({ port });

console.log(`WebSocket server is running on ws://localhost:${port}`);

server.on('connection', (ws) => {
  console.log('Client connected');

  ws.on('message', (message) => {
    console.log(`Received: ${message}`);
    // Broadcast the message to all other connected clients
    server.clients.forEach((client) => {
      if (client !== ws && client.readyState === WebSocket.OPEN) {
        client.send(message);
      }
    });
  });

  ws.on('close', () => {
    console.log('Client disconnected');
  });
});
```

Start server.js

    npm server.js

Enter the server address and port on the Motion X iOS App, then click 'Connect'. The server will now start receiving motion data.

## Receiving data

Once the server is running, click `Connect` on the Motion X View 

Make sure the [Motion X iOS app](https://github.com/LkxPro/Motion-X-iOS) is also connected to the same WebSocket server.

You'll then start receiving live motion data from your mobile devices.

## License
Motion X iOS is licensed under the [Apache License 2.0](LICENSE).
