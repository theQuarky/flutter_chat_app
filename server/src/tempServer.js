const express = require('express');
const http = require('http');
const socketIO = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = socketIO(server);

// Handle socket connection
io.on('connection', (socket) => {
  console.log('A user connected');

  // Handle socket events
  socket.on('message', (data) => {
    console.log('Received message:', data);

    // Broadcast the message to all connected sockets
    io.emit('message', data);
  });

  socket.on('disconnect', () => {
    console.log('A user disconnected');
  });
});

// Start the server
const port = 4000;
server.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
