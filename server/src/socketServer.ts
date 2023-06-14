import { Server, Socket } from "socket.io";

export default function configureSocketServer(io: Server) {
  console.log("A user connected");

  io.on('connection', (socket: Socket) => {
    console.log("A user connected");

    // Handle 'message' event
    socket.on('message', (data) => {
      console.log('Received message:', data);
      io.emit('message', data); // Broadcast the message to all connected sockets
    });

    // Handle 'hello' event
    socket.on('hello', () => {
      console.log('Hello');
      socket.emit('message', 'Hello, client!'); // Send a message back to the client that triggered the 'hello' event
    });
  });
}
