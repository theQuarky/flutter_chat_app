import app from './App.ts';
import * as http from 'node:http';
import { Server as SocketIOServer, Socket } from 'socket.io';
import configureSocketServer from './socketServer.ts';

const server = http.createServer(app);
const io = new SocketIOServer(server,{
  path:'/socket.io'
});

// Configure and handle socket events
configureSocketServer(io);

const port = 3000;
server.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});

