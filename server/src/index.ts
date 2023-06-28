import app from './App.ts';
import * as http from 'node:http';
import {  Server as SocketIOServer, Socket } from "https://deno.land/x/socket_io@0.1.1/mod.ts";
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

