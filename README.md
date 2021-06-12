# ex-tcp

Demonstrating messaging in elixir using OTP + erlang's :gen_tcp.

This project is not built for production and is more of a demonstration for OTP + lower-level messaging.

`:gen_tcp` is the Erlang provided module that allows us to communicate over tcp.

## Modules

### Connection Proxy

Opens a TCP connection on our port (8080). Whenever a new user joins, it passes the TCP connection to our manager.

The proxy also handles calling `:gen_tcp.controlling_process` which passes incoming tcp packets to the respective connection_server process.

### Connection Manager

Receives a new TCP connection process & spins up a `DynamicSupervisor` for each new connection.

Also handles keeping connected clients in state & broadcasts messages to child processes.

### Connection Server

Handles incoming / outgoing messages for connected users. A `connection_server` is spun up for every connected user.

## Usage

Running the server:

```
make run
```

Connecting:

```
make connect
```
