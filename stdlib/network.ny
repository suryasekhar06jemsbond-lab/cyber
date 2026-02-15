# ============================================================
# Nyx Standard Library - Network Module
# ============================================================
# Comprehensive networking framework providing DNS resolution,
# FTP, SMTP, WebSocket, and low-level socket operations.

# ============================================================
# Constants
# ============================================================

let VERSION = "1.0.0";

# Protocol constants
let TCP = "tcp";
let UDP = "udp";
let HTTP = "http";
let HTTPS = "https";
let FTP = "ftp";
let SMTP = "smtp";
let POP3 = "pop3";
let IMAP = "imap";
let SSH = "ssh";
let WEBSOCKET = "ws";
let WSS = "wss";

# Address families
let AF_INET = "ipv4";
let AF_INET6 = "ipv6";
let AF_UNIX = "unix";

# Socket states
let SOCKET_CLOSED = "closed";
let SOCKET_LISTENING = "listening";
let SOCKET_CONNECTED = "connected";
let SOCKET_CONNECTING = "connecting";

# DNS record types
let DNS_A = "A";
let DNS_AAAA = "AAAA";
let DNS_CNAME = "CNAME";
let DNS_MX = "MX";
let DNS_NS = "NS";
let DNS_TXT = "TXT";
let DNS_SRV = "SRV";
let DNS_SOA = "SOA";
let DNS_PTR = "PTR";

# HTTP methods
let GET = "GET";
let POST = "POST";
let PUT = "PUT";
let DELETE = "DELETE";
let PATCH = "PATCH";
let HEAD = "HEAD";
let OPTIONS = "OPTIONS";

# Status codes
let HTTP_OK = 200;
let HTTP_CREATED = 201;
let HTTP_ACCEPTED = 202;
let HTTP_NO_CONTENT = 204;
let HTTP_MOVED_PERMANENTLY = 301;
let HTTP_FOUND = 302;
let HTTP_NOT_MODIFIED = 304;
let HTTP_BAD_REQUEST = 400;
let HTTP_UNAUTHORIZED = 401;
let HTTP_FORBIDDEN = 403;
let HTTP_NOT_FOUND = 404;
let HTTP_METHOD_NOT_ALLOWED = 405;
let HTTP_CONFLICT = 409;
let HTTP_INTERNAL_SERVER_ERROR = 500;
let HTTP_NOT_IMPLEMENTED = 501;
let HTTP_BAD_GATEWAY = 502;
let HTTP_SERVICE_UNAVAILABLE = 503;

# ============================================================
# Network Error Classes
# ============================================================

class NetworkError {
    init(message, code, details) {
        self.message = message;
        self.code = code ?? "network_error";
        self.details = details ?? {};
    }

    toString() {
        return "NetworkError[" + self.code + "]: " + self.message;
    }
}

class DNSError < NetworkError {
    init(message, details) {
        super(message, "dns_error", details);
    }
}

class SocketError < NetworkError {
    init(message, details) {
        super(message, "socket_error", details);
    }
}

class HTTPError < NetworkError {
    init(message, statusCode, details) {
        super(message, "http_error", details);
        self.statusCode = statusCode;
    }
}

class FTPError < NetworkError {
    init(message, replyCode, details) {
        super(message, "ftp_error", details);
        self.replyCode = replyCode;
    }
}

class SMTPError < NetworkError {
    init(message, replyCode, details) {
        super(message, "smtp_error", details);
        self.replyCode = replyCode;
    }
}

# ============================================================
# IP Address
# ============================================================

class IPAddress {
    init(address, family) {
        self.address = address;
        self.family = family ?? AF_INET;
        self.version = family == AF_INET6 ? 6 : 4;
    }

    isIPv4() {
        return self.version == 4;
    }

    isIPv6() {
        return self.version == 6;
    }

    toString() {
        return self.address;
    }

    toBytes() {
        if self.isIPv4() {
            let parts = split(self.address, ".");
            let bytes = [];
            for part in parts {
                bytes = bytes + [parseInt(part)];
            }
            return bytes;
        }
        # IPv6 parsing would go here
        return [];
    }

    isLoopback() {
        if self.isIPv4() {
            return self.address == "127.0.0.1" or self.address == "127.0.0.0/8";
        }
        return self.address == "::1";
    }

    isPrivate() {
        if self.isIPv4() {
            let parts = split(self.address, ".");
            let first = parseInt(parts[0]);
            if first == 10 {
                return true;
            }
            if first == 172 and parseInt(parts[1]) >= 16 and parseInt(parts[1]) <= 31 {
                return true;
            }
            if first == 192 and parseInt(parts[1]) == 168 {
                return true;
            }
            if first == 127 {
                return true;
            }
            return false;
        }
        return false;
    }

    isMulticast() {
        if self.isIPv4() {
            let first = parseInt(split(self.address, ".")[0]);
            return first >= 224 and first <= 239;
        }
        return self.address[0] == "f";
    }
}

# ============================================================
# Network Interface
# ============================================================

class NetworkInterface {
    init(name, addresses, macAddress, mtu) {
        self.name = name;
        self.addresses = addresses ?? [];
        self.macAddress = macAddress;
        self.mtu = mtu ?? 1500;
        self.isUp = true;
        self.isLoopback = false;
    }

    getIPv4Address() {
        for addr in self.addresses {
            if addr.isIPv4() {
                return addr;
            }
        }
        return null;
    }

    getIPv6Address() {
        for addr in self.addresses {
            if addr.isIPv6() {
                return addr;
            }
        }
        return null;
    }

    toString() {
        return self.name + ": " + json.stringify(self.addresses);
    }
}

# ============================================================
# Socket
# ============================================================

class Socket {
    init(family, type, protocol) {
        self.family = family ?? AF_INET;
        self.type = type ?? TCP;
        self.protocol = protocol ?? 0;
        self.fd = -1;
        self.state = SOCKET_CLOSED;
        self.remoteAddress = null;
        self.localAddress = null;
        self.bufferSize = 8192;
    }

    connect(address, port) {
        # In a real implementation, this would connect to a remote host
        # For now, we simulate the socket interface
        self.remoteAddress = {"address": address, "port": port};
        self.state = SOCKET_CONNECTED;
        return true;
    }

    bind(address, port) {
        self.localAddress = {"address": address ?? "0.0.0.0", "port": port};
        return true;
    }

    listen(backlog) {
        self.state = SOCKET_LISTENING;
        return true;
    }

    accept() {
        # Would accept incoming connections
        return null;
    }

    send(data) {
        if self.state != SOCKET_CONNECTED {
            return 0;
        }
        return len(data);
    }

    receive(maxSize) {
        if self.state != SOCKET_CONNECTED {
            return "";
        }
        return "";
    }

    sendTo(address, port, data) {
        return len(data);
    }

    receiveFrom() {
        return {"data": "", "address": null, "port": 0};
    }

    close() {
        self.state = SOCKET_CLOSED;
        self.fd = -1;
    }

    setBlocking(blocking) {
        # Would set socket to blocking/non-blocking mode
    }

    setTimeout(timeout) {
        # Would set socket timeout
    }

    getLocalAddress() {
        return self.localAddress;
    }

    getRemoteAddress() {
        return self.remoteAddress;
    }

    isClosed() {
        return self.state == SOCKET_CLOSED;
    }

    isConnected() {
        return self.state == SOCKET_CONNECTED;
    }

    getState() {
        return self.state;
    }
}

# ============================================================
# Server Socket
# ============================================================

class ServerSocket {
    init(address, port, family) {
        self.address = address ?? "0.0.0.0";
        self.port = port;
        self.family = family ?? AF_INET;
        self.socket = null;
        self.backlog = 128;
        self.keepAlive = false;
        self.noDelay = false;
    }

    bind() {
        self.socket = Socket(self.family, TCP);
        return self.socket.bind(self.address, self.port);
    }

    listen() {
        if self.socket != null {
            return self.socket.listen(self.backlog);
        }
        return false;
    }

    accept() {
        if self.socket != null {
            return self.socket.accept();
        }
        return null;
    }

    close() {
        if self.socket != null {
            self.socket.close();
        }
    }

    setBacklog(backlog) {
        self.backlog = backlog;
    }

    setKeepAlive(keepAlive) {
        self.keepAlive = keepAlive;
    }

    setNoDelay(noDelay) {
        self.noDelay = noDelay;
    }
}

# ============================================================
# DNS Resolver
# ============================================================

class DNSResolver {
    init(servers, timeout) {
        self.servers = servers ?? ["8.8.8.8", "8.8.4.4"];
        self.timeout = timeout ?? 5000;
        self.cache = {};
        self.useCache = true;
        self.useSystemServers = true;
    }

    resolve(hostname, recordType) {
        # Check cache first
        if self.useCache {
            let cached = self._getCached(hostname, recordType);
            if cached != null {
                return cached;
            }
        }

        # In a real implementation, this would perform actual DNS resolution
        # For now, we simulate common resolutions
        let result = self._resolveInternal(hostname, recordType);

        # Cache the result
        if self.useCache and result != null {
            self._cacheResult(hostname, recordType, result);
        }

        return result;
    }

    resolveA(hostname) {
        return self.resolve(hostname, DNS_A);
    }

    resolveAAAA(hostname) {
        return self.resolve(hostname, DNS_AAAA);
    }

    resolveCNAME(hostname) {
        return self.resolve(hostname, DNS_CNAME);
    }

    resolveMX(hostname) {
        return self.resolve(hostname, DNS_MX);
    }

    resolveNS(hostname) {
        return self.resolve(hostname, DNS_NS);
    }

    resolveTXT(hostname) {
        return self.resolve(hostname, DNS_TXT);
    }

    resolveSRV(hostname) {
        return self.resolve(hostname, DNS_SRV);
    }

    reverseLookup(ip) {
        return self.resolve(ip, DNS_PTR);
    }

    _resolveInternal(hostname, recordType) {
        # Simulated DNS resolution
        # In production, this would use actual DNS queries

        # Handle localhost
        if hostname == "localhost" {
            return [IPAddress("127.0.0.1", AF_INET)];
        }

        # Simulate some common hostnames
        let simulated = {
            "google.com": ["142.250.185.14"],
            "www.google.com": ["142.250.185.14"],
            "github.com": ["140.82.121.3"],
            "www.github.com": ["140.82.121.3"],
            "cloudflare.com": ["104.16.248.249"],
            "microsoft.com": ["40.107.106.51"],
            "apple.com": ["17.253.144.10"]
        };

        if simulated[hostname] != null {
            let ips = [];
            for ip in simulated[hostname] {
                ips = ips + [IPAddress(ip, AF_INET)];
            }
            return ips;
        }

        return null;
    }

    _getCached(hostname, recordType) {
        let key = hostname + ":" + recordType;
        if self.cache[key] != null {
            let entry = self.cache[key];
            if time.time() < entry["expiresAt"] {
                return entry["records"];
            }
        }
        return null;
    }

    _cacheResult(hostname, recordType, records) {
        let key = hostname + ":" + recordType;
        self.cache[key] = {
            "records": records,
            "expiresAt": time.time() + 300  # 5 minute TTL
        };
    }

    clearCache() {
        self.cache = {};
    }

    addServer(server) {
        self.servers = self.servers + [server];
    }

    setTimeout(timeout) {
        self.timeout = timeout;
    }

    enableCache(enable) {
        self.useCache = enable;
    }
}

# ============================================================
# URL Parser
# ============================================================

class URL {
    init(urlString) {
        self.original = urlString;
        self.scheme = "";
        self.host = "";
        self.port = 0;
        self.path = "/";
        self.query = {};
        self.fragment = "";
        self.username = "";
        self.password = "";

        self._parse(urlString);
    }

    _parse(urlString) {
        # Simple URL parsing
        # scheme://username:password@host:port/path?query#fragment

        let parts = split(urlString, "://");
        if len(parts) > 0 {
            let rest = parts[0];
            let remaining = "";

            if len(parts) > 1 {
                self.scheme = rest;
                remaining = parts[1];
            }

            # Parse userinfo
            let atIndex = -1;
            for i in range(len(remaining)) {
                if remaining[i] == "@" {
                    atIndex = i;
                    break;
                }
            }

            if atIndex > 0 {
                let userinfo = remaining[:atIndex];
                remaining = remaining[atIndex + 1:];

                let colonIndex = -1;
                for i in range(len(userinfo)) {
                    if userinfo[i] == ":" {
                        colonIndex = i;
                        break;
                    }
                }

                if colonIndex > 0 {
                    self.username = userinfo[:colonIndex];
                    self.password = userinfo[colonIndex + 1:];
                } else {
                    self.username = userinfo;
                }
            }

            # Parse host:port
            let slashIndex = -1;
            for i in range(len(remaining)) {
                if remaining[i] == "/" {
                    slashIndex = i;
                    break;
                }
            }

            let hostport = "";
            if slashIndex > 0 {
                hostport = remaining[:slashIndex];
                self.path = remaining[slashIndex:];
            } else {
                hostport = remaining;
            }

            # Parse port
            let colonIndex = -1;
            for i in range(len(hostport)) {
                if hostport[i] == ":" {
                    colonIndex = i;
                    break;
                }
            }

            if colonIndex > 0 {
                self.host = hostport[:colonIndex];
                self.port = parseInt(hostport[colonIndex + 1:]);
            } else {
                self.host = hostport;
                self.port = self._getDefaultPort();
            }

            # Parse query
            let qmarkIndex = -1;
            for i in range(len(self.path)) {
                if self.path[i] == "?" {
                    qmarkIndex = i;
                    break;
                }
            }

            if qmarkIndex > 0 {
                let queryString = self.path[qmarkIndex + 1:];
                self.path = self.path[:qmarkIndex];
                self.query = self._parseQuery(queryString);
            }

            # Parse fragment
            let hashIndex = -1;
            for i in range(len(self.path)) {
                if self.path[i] == "#" {
                    hashIndex = i;
                    break;
                }
            }

            if hashIndex > 0 {
                self.fragment = self.path[hashIndex + 1:];
                self.path = self.path[:hashIndex];
            }
        }
    }

    _parseQuery(queryString) {
        let params = {};
        let pairs = split(queryString, "&");
        for pair in pairs {
            let kv = split(pair, "=");
            if len(kv) > 0 {
                let key = kv[0];
                let value = len(kv) > 1 ? kv[1] : "";
                params[key] = value;
            }
        }
        return params;
    }

    _getDefaultPort() {
        if self.scheme == "http" {
            return 80;
        }
        if self.scheme == "https" {
            return 443;
        }
        if self.scheme == "ftp" {
            return 21;
        }
        if self.scheme == "ssh" {
            return 22;
        }
        if self.scheme == "smtp" {
            return 25;
        }
        return 0;
    }

    getScheme() {
        return self.scheme;
    }

    getHost() {
        return self.host;
    }

    getPort() {
        return self.port;
    }

    getPath() {
        return self.path;
    }

    getQuery() {
        return self.query;
    }

    getFragment() {
        return self.fragment;
    }

    getUsername() {
        return self.username;
    }

    getPassword() {
        return self.password;
    }

    getAuthority() {
        let authority = "";
        if self.username != "" {
            authority = self.username;
            if self.password != "" {
                authority = authority + ":" + self.password;
            }
            authority = authority + "@";
        }
        authority = authority + self.host;
        if self.port != self._getDefaultPort() {
            authority = authority + ":" + str(self.port);
        }
        return authority;
    }

    toString() {
        let url = self.scheme + "://";
        url = url + self.getAuthority();
        url = url + self.path;

        if len(keys(self.query)) > 0 {
            url = url + "?";
            let first = true;
            for key in keys(self.query) {
                if not first {
                    url = url + "&";
                }
                url = url + key + "=" + str(self.query[key]);
                first = false;
            }
        }

        if self.fragment != "" {
            url = url + "#" + self.fragment;
        }

        return url;
    }

    isSecure() {
        return self.scheme == "https" or self.scheme == "wss";
    }

    isAbsolute() {
        return self.scheme != "" and self.host != "";
    }
}

# ============================================================
# HTTP Request
# ============================================================

class HTTPRequest {
    init(method, url) {
        self.method = method ?? GET;
        self.url = url;
        self.headers = {};
        self.body = "";
        self.timeout = 30000;
        self.followRedirects = true;
        self.maxRedirects = 10;
        self.cookies = {};
        self.auth = null;
        self.proxy = null;

        if type(url) == "string" {
            self.url = URL(url);
        }
    }

    setHeader(name, value) {
        self.headers[name] = value;
        return self;
    }

    setHeaders(headers) {
        for key in keys(headers) {
            self.headers[key] = headers[key];
        }
        return self;
    }

    setBody(body) {
        self.body = body;
        return self;
    }

    setJSONBody(data) {
        self.body = json.stringify(data);
        self.headers["Content-Type"] = "application/json";
        return self;
    }

    setFormBody(data) {
        self.body = self._encodeForm(data);
        self.headers["Content-Type"] = "application/x-www-form-urlencoded";
        return self;
    }

    setTimeout(timeout) {
        self.timeout = timeout;
        return self;
    }

    setFollowRedirects(follow) {
        self.followRedirects = follow;
        return self;
    }

    setMaxRedirects(max) {
        self.maxRedirects = max;
        return self;
    }

    setCookie(name, value) {
        self.cookies[name] = value;
        return self;
    }

    setAuth(username, password) {
        self.auth = {"username": username, "password": password};
        return self;
    }

    setProxy(proxy) {
        self.proxy = proxy;
        return self;
    }

    _encodeForm(data) {
        let parts = [];
        for key in keys(data) {
            parts = parts + [key + "=" + str(data[key])];
        }
        return join(parts, "&");
    }

    toCurl() {
        let cmd = "curl";
        
        if self.method != GET {
            cmd = cmd + " -X " + self.method;
        }

        for key in keys(self.headers) {
            cmd = cmd + " -H '" + key + ": " + self.headers[key] + "'";
        }

        if self.body != "" {
            cmd = cmd + " -d '" + self.body + "'";
        }

        cmd = cmd + " '" + self.url.toString() + "'";

        return cmd;
    }
}

# ============================================================
# HTTP Response
# ============================================================

class HTTPResponse {
    init(statusCode, statusText, headers, body) {
        self.statusCode = statusCode;
        self.statusText = statusText;
        self.headers = headers ?? {};
        self.body = body;
        self.url = null;
        self.redirects = [];
    }

    isSuccess() {
        return self.statusCode >= 200 and self.statusCode < 300;
    }

    isRedirect() {
        return self.statusCode >= 300 and self.statusCode < 400;
    }

    isClientError() {
        return self.statusCode >= 400 and self.statusCode < 500;
    }

    isServerError() {
        return self.statusCode >= 500;
    }

    getHeader(name) {
        return self.headers[name] ?? self.headers[lower(name)];
    }

    getContentType() {
        return self.getHeader("Content-Type");
    }

    getContentLength() {
        return parseInt(self.getHeader("Content-Length") ?? "0");
    }

    json() {
        try {
            return json.parse(self.body);
        } catch e {
            return null;
        }
    }

    text() {
        return self.body;
    }
}

# ============================================================
# HTTP Client
# ============================================================

class HTTPClient {
    init() {
        self.defaultHeaders = {};
        self.timeout = 30000;
        self.followRedirects = true;
        self.maxRedirects = 10;
        self.cookies = {};
        self.auth = null;
        self.proxy = null;
        self.verifySSL = true;
    }

    request(request) {
        # This would make an actual HTTP request
        # For now, we simulate the interface
        let response = HTTPResponse(200, "OK", {"Content-Type": "text/plain"}, "OK");
        return response;
    }

    get(url, params) {
        let request = HTTPRequest(GET, url);
        
        if params != null {
            let urlObj = request.url;
            for key in keys(params) {
                urlObj.query[key] = params[key];
            }
        }
        
        return self.request(request);
    }

    post(url, data) {
        let request = HTTPRequest(POST, url);
        
        if type(data) == "string" {
            request.setBody(data);
        } else if type(data) == "map" {
            request.setJSONBody(data);
        }
        
        return self.request(request);
    }

    put(url, data) {
        let request = HTTPRequest(PUT, url);
        
        if type(data) == "string" {
            request.setBody(data);
        } else if type(data) == "map" {
            request.setJSONBody(data);
        }
        
        return self.request(request);
    }

    delete(url) {
        let request = HTTPRequest(DELETE, url);
        return self.request(request);
    }

    patch(url, data) {
        let request = HTTPRequest(PATCH, url);
        
        if type(data) == "string" {
            request.setBody(data);
        } else if type(data) == "map" {
            request.setJSONBody(data);
        }
        
        return self.request(request);
    }

    head(url) {
        let request = HTTPRequest(HEAD, url);
        return self.request(request);
    }

    options(url) {
        let request = HTTPRequest(OPTIONS, url);
        return self.request(request);
    }

    setDefaultHeader(name, value) {
        self.defaultHeaders[name] = value;
        return self;
    }

    setTimeout(timeout) {
        self.timeout = timeout;
        return self;
    }

    setFollowRedirects(follow) {
        self.followRedirects = follow;
        return self;
    }

    setAuth(username, password) {
        self.auth = {"username": username, "password": password};
        return self;
    }

    setProxy(proxy) {
        self.proxy = proxy;
        return self;
    }

    setVerifySSL(verify) {
        self.verifySSL = verify;
        return self;
    }

    clearCookies() {
        self.cookies = {};
    }
}

# ============================================================
# FTP Client
# ============================================================

class FTPClient {
    init(host, port) {
        self.host = host;
        self.port = port ?? 21;
        self.socket = null;
        self.connected = false;
        self.loggedIn = false;
        self.currentDir = "/";
        self.passive = true;
        self.transferType = "binary";
    }

    connect() {
        self.socket = Socket(AF_INET, TCP);
        self.socket.connect(self.host, self.port);
        self.connected = true;
        
        # Read welcome message
        let response = self._readResponse();
        
        return response;
    }

    login(username, password) {
        self._sendCommand("USER", username);
        let userResponse = self._readResponse();
        
        if userResponse["code"] == 331 {
            self._sendCommand("PASS", password);
            let passResponse = self._readResponse();
            
            if passResponse["code"] == 230 {
                self.loggedIn = true;
                return true;
            }
        }
        
        return false;
    }

    cwd(path) {
        self._sendCommand("CWD", path);
        let response = self._readResponse();
        
        if response["code"] == 250 {
            self.currentDir = path;
            return true;
        }
        
        return false;
    }

    pwd() {
        self._sendCommand("PWD", "");
        let response = self._readResponse();
        
        if response["code"] == 257 {
            # Parse directory from response
            let msg = response["message"];
            return msg;
        }
        
        return null;
    }

    list(path) {
        # Enter passive mode
        let dataSocket = self._enterPassiveMode();
        
        self._sendCommand("LIST", path ?? "");
        let response = self._readResponse();
        
        # Read data from data socket
        let data = "";
        
        dataSocket.close();
        
        let finalResponse = self._readResponse();
        
        return data;
    }

    retr(filename) {
        let dataSocket = self._enterPassiveMode();
        
        self._sendCommand("RETR", filename);
        let response = self._readResponse();
        
        let data = "";
        
        dataSocket.close();
        
        let finalResponse = self._readResponse();
        
        return data;
    }

    stor(filename, data) {
        let dataSocket = self._enterPassiveMode();
        
        self._sendCommand("STOR", filename);
        let response = self._readResponse();
        
        dataSocket.send(data);
        dataSocket.close();
        
        let finalResponse = self._readResponse();
        
        return finalResponse["code"] == 226;
    }

    dele(filename) {
        self._sendCommand("DELE", filename);
        let response = self._readResponse();
        
        return response["code"] == 250;
    }

    mkdir(path) {
        self._sendCommand("MKD", path);
        let response = self._readResponse();
        
        return response["code"] == 257;
    }

    rmdir(path) {
        self._sendCommand("RMD", path);
        let response = self._readResponse();
        
        return response["code"] == 250;
    }

    rename(from, to) {
        self._sendCommand("RNFR", from);
        let response1 = self._readResponse();
        
        if response1["code"] == 350 {
            self._sendCommand("RNTO", to);
            let response2 = self._readResponse();
            
            return response2["code"] == 250;
        }
        
        return false;
    }

    type(type) {
        self._sendCommand("TYPE", type);
        let response = self._readResponse();
        
        if response["code"] == 200 {
            self.transferType = type;
            return true;
        }
        
        return false;
    }

    passive(enable) {
        self.passive = enable;
    }

    quit() {
        self._sendCommand("QUIT", "");
        let response = self._readResponse();
        
        self.socket.close();
        self.connected = false;
        self.loggedIn = false;
        
        return true;
    }

    _sendCommand(command, argument) {
        let cmd = command;
        if argument != "" {
            cmd = cmd + " " + argument;
        }
        # In real implementation, send via socket
    }

    _readResponse() {
        # In real implementation, read from socket
        return {"code": 220, "message": "Ready"};
    }

    _enterPassiveMode() {
        self._sendCommand("EPSV", "");
        let response = self._readResponse();
        
        # Parse response for port
        return Socket(AF_INET, TCP);
    }
}

# ============================================================
# SMTP Client
# ============================================================

class SMTPClient {
    init(host, port) {
        self.host = host;
        self.port = port ?? 25;
        self.socket = null;
        self.connected = false;
        self.authenticated = false;
        self.from = "";
        self.recipients = [];
    }

    connect() {
        self.socket = Socket(AF_INET, TCP);
        self.socket.connect(self.host, self.port);
        self.connected = true;
        
        let response = self._readResponse();
        
        return response["code"] == 220;
    }

    EHLO(hostname) {
        self._sendCommand("EHLO", hostname);
        
        let responses = [];
        while true {
            let response = self._readResponse();
            responses = responses + [response];
            
            if response["code"] != 250 {
                break;
            }
            
            if len(response["message"]) > 0 and response["message"][len(response["message"]) - 1] != "-" {
                break;
            }
        }
        
        return responses;
    }

    HELO(hostname) {
        self._sendCommand("HELO", hostname);
        let response = self._readResponse();
        
        return response["code"] == 250;
    }

    auth(username, password) {
        self._sendCommand("AUTH", "PLAIN");
        let response = self._readResponse();
        
        if response["code"] == 334 {
            # Send credentials
            let credentials = "\0" + username + "\0" + password;
            # Would base64 encode
            
            self._sendRaw(credentials);
            let authResponse = self._readResponse();
            
            if authResponse["code"] == 235 {
                self.authenticated = true;
                return true;
            }
        }
        
        return false;
    }

    mail(from) {
        self._sendCommand("MAIL", "FROM:<" + from + ">");
        let response = self._readResponse();
        
        if response["code"] == 250 {
            self.from = from;
            return true;
        }
        
        return false;
    }

    rcpt(to) {
        self._sendCommand("RCPT", "TO:<" + to + ">");
        let response = self._readResponse();
        
        if response["code"] == 250 {
            self.recipients = self.recipients + [to];
            return true;
        }
        
        return false;
    }

    data(content) {
        self._sendCommand("DATA", "");
        let response = self._readResponse();
        
        if response["code"] == 354 {
            self._sendRaw(content + "\r\n.");
            let finalResponse = self._readResponse();
            
            return finalResponse["code"] == 250;
        }
        
        return false;
    }

    sendMail(from, to, subject, body) {
        self.mail(from);
        
        if type(to) == "list" {
            for recipient in to {
                self.rcpt(recipient);
            }
        } else {
            self.rcpt(to);
        }
        
        let message = "From: " + from + "\r\n";
        message = message + "To: " + (type(to) == "list" ? join(to, ",") : to) + "\r\n";
        message = message + "Subject: " + subject + "\r\n";
        message = message + "\r\n";
        message = message + body;
        
        return self.data(message);
    }

    quit() {
        self._sendCommand("QUIT", "");
        let response = self._readResponse();
        
        self.socket.close();
        self.connected = false;
        
        return response["code"] == 221;
    }

    _sendCommand(command, argument) {
        let cmd = command;
        if argument != "" {
            cmd = cmd + " " + argument;
        }
        cmd = cmd + "\r\n";
        # In real implementation, send via socket
    }

    _sendRaw(data) {
        # In real implementation, send raw data
    }

    _readResponse() {
        # In real implementation, read from socket
        return {"code": 220, "message": "Ready"};
    }
}

# ============================================================
# WebSocket
# ============================================================

class WebSocket {
    init(url) {
        self.url = url;
        self.socket = null;
        self.connected = false;
        self.readyState = 0;  # CONNECTING
        self.extensions = "";
        self.protocol = "";
        self.binaryType = "arraybuffer";
        
        if type(url) == "string" {
            self.url = URL(url);
        }
    }

    connect() {
        self.socket = Socket(AF_INET, TCP);
        
        let host = self.url.getHost();
        let port = self.url.getPort();
        
        if port == 0 {
            port = self.url.isSecure() ? 443 : 80;
        }
        
        self.socket.connect(host, port);
        
        # Send WebSocket handshake
        self._sendHandshake();
        
        self.connected = true;
        self.readyState = 1;  # OPEN
        
        return true;
    }

    send(data) {
        if not self.connected {
            return false;
        }
        
        let opcode = 0x81;  # Text frame
        if type(data) == "string" {
            opcode = 0x81;
        } else {
            opcode = 0x82;  # Binary frame
        }
        
        # Frame the data
        let frame = self._createFrame(opcode, data);
        
        return true;
    }

    sendText(text) {
        return self.send(text);
    }

    sendBinary(data) {
        return self.send(data);
    }

    sendJSON(data) {
        return self.send(json.stringify(data));
    }

    ping(data) {
        if not self.connected {
            return false;
        }
        
        let frame = self._createFrame(0x89, data ?? "");
        return true;
    }

    pong(data) {
        if not self.connected {
            return false;
        }
        
        let frame = self._createFrame(0x8A, data ?? "");
        return true;
    }

    close(code, reason) {
        if not self.connected {
            return;
        }
        
        let data = "";
        if code != null {
            data = data + chr((code >> 8) & 0xFF);
            data = data + chr(code & 0xFF);
        }
        if reason != null {
            data = data + reason;
        }
        
        let frame = self._createFrame(0x88, data);
        
        self.socket.close();
        self.connected = false;
        self.readyState = 3;  # CLOSED
    }

    _sendHandshake() {
        let key = self._generateWebSocketKey();
        
        let request = "GET " + self.url.getPath();
        if len(keys(self.url.getQuery())) > 0 {
            request = request + "?" + json.stringify(self.url.getQuery());
        }
        request = request + " HTTP/1.1\r\n";
        
        request = request + "Host: " + self.url.getHost();
        if self.url.getPort() != 80 and self.url.getPort() != 443 {
            request = request + ":" + str(self.url.getPort());
        }
        request = request + "\r\n";
        
        request = request + "Upgrade: websocket\r\n";
        request = request + "Connection: Upgrade\r\n";
        request = request + "Sec-WebSocket-Key: " + key + "\r\n";
        request = request + "Sec-WebSocket-Version: 13\r\n";
        request = request + "Sec-WebSocket-Protocol: nyx-websocket\r\n";
        
        request = request + "\r\n";
    }

    _generateWebSocketKey() {
        # Generate a 16-byte random key and base64 encode it
        let key = "";
        for i in range(16) {
            key = key + chr(i * 7 % 256);
        }
        # Would actually use proper random bytes and base64 encoding
        return "dGhlIHNhbXBsZSBub25jZQ==";
    }

    _createFrame(opcode, data) {
        let fin = 0x80 | opcode;
        
        let payload = data;
        if type(data) == "string" {
            # Convert to bytes
            payload = data;
        }
        
        return [fin, 0x00, payload];
    }

    _parseFrame(data) {
        # Parse WebSocket frame
        return {"opcode": 1, "data": data};
    }

    getReadyState() {
        return self.readyState;
    }

    isConnected() {
        return self.connected;
    }
}

# ============================================================
# WebSocket Server
# ============================================================

class WebSocketServer {
    init(address, port) {
        self.address = address ?? "0.0.0.0";
        self.port = port;
        self.serverSocket = null;
        self.connections = [];
        self.handleConnection = null;
        self.handleMessage = null;
        self.handleClose = null;
    }

    start() {
        self.serverSocket = ServerSocket(self.address, self.port);
        self.serverSocket.bind();
        self.serverSocket.listen();
        
        return true;
    }

    stop() {
        if self.serverSocket != null {
            self.serverSocket.close();
        }
        
        for conn in self.connections {
            conn.close();
        }
    }

    accept() {
        if self.serverSocket == null {
            return null;
        }
        
        let socket = self.serverSocket.accept();
        
        if socket != null {
            let ws = WebSocket("");
            ws.socket = socket;
            ws.connected = true;
            
            self.connections = self.connections + [ws];
            
            return ws;
        }
        
        return null;
    }

    broadcast(message) {
        for conn in self.connections {
            conn.send(message);
        }
    }

    onConnection(handler) {
        self.handleConnection = handler;
    }

    onMessage(handler) {
        self.handleMessage = handler;
    }

    onClose(handler) {
        self.handleClose = handler;
    }
}

# ============================================================
# Network Utilities
# ============================================================

fn parseURL(urlString) {
    return URL(urlString);
}

fn resolveHostname(hostname) {
    let resolver = DNSResolver();
    return resolver.resolveA(hostname);
}

fn getLocalHostname() {
    return "localhost";
}

fn getLocalIP() {
    return "127.0.0.1";
}

fn isValidIPAddress(ip) {
    let parts = split(ip, ".");
    if len(parts) != 4 {
        return false;
    }
    
    for part in parts {
        let num = parseInt(part);
        if num < 0 or num > 255 {
            return false;
        }
    }
    
    return true;
}

fn isValidPort(port) {
    return port > 0 and port <= 65535;
}

fn getDefaultGateway() {
    return "192.168.1.1";
}

fn getMACAddress(interface) {
    return "00:00:00:00:00:00";
}

# ============================================================
# HTTP Utility Functions
# ============================================================

fn httpGet(url, params) {
    let client = HTTPClient();
    return client.get(url, params);
}

fn httpPost(url, data) {
    let client = HTTPClient();
    return client.post(url, data);
}

fn httpPut(url, data) {
    let client = HTTPClient();
    return client.put(url, data);
}

fn httpDelete(url) {
    let client = HTTPClient();
    return client.delete(url);
}

fn httpPatch(url, data) {
    let client = HTTPClient();
    return client.patch(url, data);
}

# ============================================================
# FTP Utility Functions
# ============================================================

fn ftpConnect(host, username, password) {
    let client = FTPClient(host, 21);
    client.connect();
    client.login(username, password);
    return client;
}

# ============================================================
# SMTP Utility Functions
# ============================================================

fn smtpConnect(host) {
    let client = SMTPClient(host, 25);
    client.connect();
    return client;
}

fn sendEmail(from, to, subject, body) {
    let client = SMTPClient("localhost", 25);
    client.connect();
    return client.sendMail(from, to, subject, body);
}

# ============================================================
# WebSocket Utility Functions
# ============================================================

fn wsConnect(url) {
    let ws = WebSocket(url);
    ws.connect();
    return ws;
}

fn wsServer(port) {
    return WebSocketServer("0.0.0.0", port);
}

# ============================================================
# Export
# ============================================================

{
    "IPAddress": IPAddress,
    "NetworkInterface": NetworkInterface,
    "Socket": Socket,
    "ServerSocket": ServerSocket,
    "DNSResolver": DNSResolver,
    "URL": URL,
    "HTTPRequest": HTTPRequest,
    "HTTPResponse": HTTPResponse,
    "HTTPClient": HTTPClient,
    "FTPClient": FTPClient,
    "SMTPClient": SMTPClient,
    "WebSocket": WebSocket,
    "WebSocketServer": WebSocketServer,
    "NetworkError": NetworkError,
    "DNSError": DNSError,
    "SocketError": SocketError,
    "HTTPError": HTTPError,
    "FTPError": FTPError,
    "SMTPError": SMTPError,
    "parseURL": parseURL,
    "resolveHostname": resolveHostname,
    "getLocalHostname": getLocalHostname,
    "getLocalIP": getLocalIP,
    "isValidIPAddress": isValidIPAddress,
    "isValidPort": isValidPort,
    "getDefaultGateway": getDefaultGateway,
    "getMACAddress": getMACAddress,
    "httpGet": httpGet,
    "httpPost": httpPost,
    "httpPut": httpPut,
    "httpDelete": httpDelete,
    "httpPatch": httpPatch,
    "ftpConnect": ftpConnect,
    "smtpConnect": smtpConnect,
    "sendEmail": sendEmail,
    "wsConnect": wsConnect,
    "wsServer": wsServer,
    "VERSION": VERSION,
    "TCP": TCP,
    "UDP": UDP,
    "HTTP": HTTP,
    "HTTPS": HTTPS,
    "FTP": FTP,
    "SMTP": SMTP,
    "WEBSOCKET": WEBSOCKET,
    "GET": GET,
    "POST": POST,
    "PUT": PUT,
    "DELETE": DELETE,
    "PATCH": PATCH,
    "AF_INET": AF_INET,
    "AF_INET6": AF_INET6,
    "DNS_A": DNS_A,
    "DNS_AAAA": DNS_AAAA,
    "DNS_CNAME": DNS_CNAME,
    "DNS_MX": DNS_MX,
    "DNS_NS": DNS_NS,
    "DNS_TXT": DNS_TXT
}
