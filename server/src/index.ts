import app from './App';
import http from 'http';
import { Server as SocketIOServer, Socket } from 'socket.io';
import configureSocketServer from './socketServer';

const port = 3000;
const server = http.createServer(app);
const io = new SocketIOServer(server);

// Configure and handle socket events

app.listen(port, () => {
  configureSocketServer(io);
  console.log(`Server is running on port ${port}`);
});
