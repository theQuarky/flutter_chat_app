// import app from './App';
import express from 'express';
import http from 'http';
import socketIO, { Socket } from 'socket.io';
import configureSocketServer from './socketServer';
const app = express();
const port = 3000;
const server = http.createServer(app);
const io = new socketIO.Server(server);

// Configure and handle socket events

app.listen(port, () => {
  configureSocketServer(io);
  console.log(`Server is running on port ${port}`);
});
