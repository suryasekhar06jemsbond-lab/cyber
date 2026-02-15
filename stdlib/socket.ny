# ===========================================
# Nyx Standard Library - Socket Module
# ===========================================
# TCP/UDP socket utilities

# Create TCP socket
fn socket(domain, type) {
    if type(domain) == "null" {
        domain = "AF_INET";
    }
    if type(type) == "null" {
        type = "SOCK_STREAM";
    }
    return _socket_create(domain, type);
}

# Create TCP server socket
fn server(port, host) {
    if type(host) == "null" {
        host = "0.0.0.0";
    }
    return _server_create(host, port);
}

# Accept connection
fn accept(server_socket) {
    return _server_accept(server_socket);
}

# Connect to server
fn connect(host, port) {
    return _socket_connect(host, port);
}

# Send data
fn send(socket, data) {
    return _socket_send(socket, data);
}

# Receive data
fn recv(socket, buffer_size) {
    if type(buffer_size) == "null" {
        buffer_size = 1024;
    }
    return _socket_recv(socket, buffer_size);
}

# Close socket
fn close(socket) {
    return _socket_close(socket);
}

# Set socket option
fn setsockopt(socket, level, option, value) {
    return _socket_setsockopt(socket, level, option, value);
}

# Get socket option
fn getsockopt(socket, level, option) {
    return _socket_getsockopt(socket, level, option);
}

# Get socket error
fn get_error(socket) {
    return _socket_get_error(socket);
}

# Get socket name (local address)
fn getsockname(socket) {
    return _socket_getsockname(socket);
}

# Get peer name (remote address)
fn getpeername(socket) {
    return _socket_getpeername(socket);
}

# Set socket to non-blocking mode
fn set_nonblocking(socket) {
    return _socket_set_nonblocking(socket);
}

# Set socket to blocking mode
fn set_blocking(socket) {
    return _socket_set_blocking(socket);
}

# TCP Socket class
class TCPSocket {
    fn init(self) {
        self.socket = socket("AF_INET", "SOCK_STREAM");
        self._connected = false;
        self._bound = false;
    }
    
    fn connect(self, host, port) {
        self.socket = connect(host, port);
        if self.socket != null {
            self._connected = true;
        }
        return self._connected;
    }
    
    fn send(self, data) {
        if !self._connected {
            throw "Socket not connected";
        }
        return send(self.socket, data);
    }
    
    fn recv(self, buffer_size) {
        if !self._connected {
            throw "Socket not connected";
        }
        return recv(self.socket, buffer_size);
    }
    
    fn close(self) {
        if self.socket != null {
            close(self.socket);
            self._connected = false;
        }
    }
    
    fn is_connected(self) {
        return self._connected;
    }
}

# TCP Server class
class TCPServer {
    fn init(self, port, host) {
        if type(host) == "null" {
            host = "0.0.0.0";
        }
        self.host = host;
        self.port = port;
        self.socket = server(port, host);
        self._running = false;
    }
    
    fn accept(self) {
        return accept(self.socket);
    }
    
    fn close(self) {
        if self.socket != null {
            close(self.socket);
            self._running = false;
        }
    }
    
    fn is_running(self) {
        return self._running;
    }
    
    fn set_reuse_addr(self, reuse) {
        setsockopt(self.socket, "SOL_SOCKET", "SO_REUSEADDR", if reuse { 1 } else { 0 });
    }
}

# UDP Socket class
class UDPSocket {
    fn init(self) {
        self.socket = socket("AF_INET", "SOCK_DGRAM");
        self._bound = false;
    }
    
    fn bind(self, host, port) {
        let result = _socket_bind(self.socket, host, port);
        if result {
            self._bound = true;
        }
        return result;
    }
    
    fn send_to(self, host, port, data) {
        return _socket_sendto(self.socket, host, port, data);
    }
    
    fn recv_from(self, buffer_size) {
        if type(buffer_size) == "null" {
            buffer_size = 1024;
        }
        return _socket_recvfrom(self.socket, buffer_size);
    }
    
    fn close(self) {
        if self.socket != null {
            close(self.socket);
            self._bound = false;
        }
    }
    
    fn is_bound(self) {
        return self._bound;
    }
}

# Socket address class
class Address {
    fn init(self, host, port) {
        self.host = host;
        self.port = port;
    }
    
    fn to_string(self) {
        return self.host + ":" + str(self.port);
    }
}

# Parse IP address
fn parse_address(addr) {
    let parts = split(addr, ":");
    if len(parts) != 2 {
        throw "Invalid address format: " + addr;
    }
    return Address(parts[0], int(parts[1]));
}

# Resolve hostname to IP
fn resolve(hostname) {
    return _dns_resolve(hostname);
}

# Check if IP is IPv4
fn is_ipv4(addr) {
    let parts = split(addr, ".");
    if len(parts) != 4 {
        return false;
    }
    for part in parts {
        let num = int(part);
        if num < 0 || num > 255 {
            return false;
        }
    }
    return true;
}

# Check if IP is IPv6
fn is_ipv6(addr) {
    return contains(addr, ":");
}

# Get local hostname
fn get_hostname() {
    return _socket_get_hostname();
}

# Get local IP addresses
fn get_local_ips() {
    return _socket_get_local_ips();
}

# Port numbers for common services
let PORT_HTTP = 80;
let PORT_HTTPS = 443;
let PORT_FTP = 21;
let PORT_SSH = 22;
let PORT_TELNET = 23;
let PORT_SMTP = 25;
let PORT_DNS = 53;
let PORT_POP3 = 110;
let PORT_IMAP = 143;
let PORT_SMB = 445;
let PORT_MYSQL = 3306;
let PORT_POSTGRESQL = 5432;
let PORT_REDIS = 6379;
let PORT_MONGODB = 27017;
let PORT_ELASTICSEARCH = 9200;
let PORT_RABBITMQ = 5672;
let PORT_KAFKA = 9092;

# Socket timeout
class Timeout {
    fn init(self, seconds) {
        self.seconds = seconds;
    }
}

# Socket error classes
class SocketError {
    fn init(self, message) {
        self.message = message;
    }
    
    fn to_string(self) {
        return "SocketError: " + self.message;
    }
}

class ConnectionRefusedError {
    fn init(self) {
        self.message = "Connection refused";
    }
}

class ConnectionTimeoutError {
    fn init(self) {
        self.message = "Connection timed out";
    }
}

class HostUnreachableError {
    fn init(self) {
        self.message = "Host unreachable";
    }
}

# Simple TCP echo server example
fn echo_server(port) {
    let server = TCPServer(port);
    server.set_reuse_addr(true);
    
    print("Echo server listening on port " + str(port));
    
    while true {
        let client = server.accept();
        if client != null {
            # Handle client in a simple way
            try {
                let data = recv(client, 1024);
                while len(data) > 0 {
                    send(client, data);
                    data = recv(client, 1024);
                }
            } catch e {
                # Ignore errors
            }
            close(client);
        }
    }
}

# Simple TCP client
fn tcp_connect(host, port) {
    let sock = TCPSocket();
    if sock.connect(host, port) {
        return sock;
    }
    return null;
}

# Simple UDP sender
fn udp_send(host, port, message) {
    let sock = UDPSocket();
    if sock.bind("0.0.0.0", 0) {
        sock.send_to(host, port, message);
        sock.close();
        return true;
    }
    return false;
}

# Socket constants
let AF_INET = 2;
let AF_INET6 = 10;
let SOCK_STREAM = 1;
let SOCK_DGRAM = 2;
let IPPROTO_TCP = 6;
let IPPROTO_UDP = 17;
let SOL_SOCKET = 1;
let SO_REUSEADDR = 2;
let SO_KEEPALIVE = 9;
let SO_RCVBUF = 8;
let SO_SNDBUF = 7;
let SO_RCVTIMEO = 20;
let SO_SNDTIMEO = 21;
