import app from './App';
import http from 'http';
import { Server as SocketIOServer, Socket } from 'socket.io';
import configureSocketServer from './socketServer';

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

