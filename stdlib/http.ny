# ===========================================
# Nyx Standard Library - HTTP Module
# ===========================================
# HTTP client and server utilities

# Make HTTP request
fn request(url, options, callback) {
    if type(options) == "null" {
        options = {};
    }
    
    let method = options.method;
    if type(method) == "null" {
        method = "GET";
    }
    
    let headers = options.headers;
    if type(headers) == "null" {
        headers = {};
    }
    
    let body = options.body;
    if type(body) == "null" {
        body = "";
    }
    
    let timeout = options.timeout;
    if type(timeout) == "null" {
        timeout = 30000;
    }
    
    # Simple URL parsing
    let url_parts = parse_url(url);
    let host = url_parts.host;
    let port = url_parts.port;
    let path = url_parts.path;
    
    if port == null {
        if url_parts.scheme == "https" {
            port = 443;
        } else {
            port = 80;
        }
    }
    
    # Connect and make request
    let conn = connect(host, port);
    if conn == null {
        throw "Failed to connect to " + host + ":" + str(port);
    }
    
    # Build request
    let request_line = method + " " + path + " HTTP/1.1\r\n";
    let header_str = "Host: " + host + "\r\n";
    
    for key in headers {
        header_str = header_str + key + ": " + str(headers[key]) + "\r\n";
    }
    
    if len(body) > 0 && headers["Content-Length"] == null {
        header_str = header_str + "Content-Length: " + str(len(body)) + "\r\n";
    }
    
    if headers["User-Agent"] == null {
        header_str = header_str + "User-Agent: Nyx/1.0\r\n";
    }
    
    if headers["Accept"] == null {
        header_str = header_str + "Accept: */*\r\n";
    }
    
    # Send request
    send(conn, request_line + header_str + "\r\n" + body);
    
    # Receive response
    let response_data = "";
    while true {
        let chunk = recv(conn, 1024);
        if len(chunk) == 0 {
            break;
        }
        response_data = response_data + chunk;
    }
    
    close(conn);
    
    # Parse response
    let response = parse_http_response(response_data);
    
    if type(callback) != "null" {
        callback(response);
    }
    
    return response;
}

# Parse URL into components
fn parse_url(url) {
    let scheme = "";
    let host = "";
    let port = null;
    let path = "/";
    let query = "";
    let fragment = "";
    
    # Find scheme
    let scheme_end = find(url, "://");
    if scheme_end >= 0 {
        scheme = url[:scheme_end];
        url = url[scheme_end + 3:];
    }
    
    # Find fragment
    let fragment_idx = find(url, "#");
    if fragment_idx >= 0 {
        fragment = url[fragment_idx + 1:];
        url = url[:fragment_idx];
    }
    
    # Find query
    let query_idx = find(url, "?");
    if query_idx >= 0 {
        query = url[query_idx + 1:];
        url = url[:query_idx];
    }
    
    # Find path
    let path_idx = find(url, "/");
    if path_idx >= 0 {
        path = url[path_idx:];
        url = url[:path_idx];
    }
    
    # Find port
    let port_idx = find(url, ":");
    if port_idx >= 0 {
        host = url[:port_idx];
        port = int(url[port_idx + 1:]);
    } else {
        host = url;
    }
    
    return {
        scheme: scheme,
        host: host,
        port: port,
        path: path,
        query: query,
        fragment: fragment
    };
}

# Parse HTTP response
fn parse_http_response(data) {
    # Find end of headers
    let header_end = find(data, "\r\n\r\n");
    if header_end < 0 {
        # No body
        header_end = len(data);
    }
    
    let header_section = data[:header_end];
    let body = data[header_end + 4:];
    
    # Parse status line
    let lines = split(header_section, "\r\n");
    let status_line = lines[0];
    let status_parts = split(status_line, " ");
    let http_version = status_parts[0];
    let status_code = int(status_parts[1]);
    let status_text = "";
    if len(status_parts) > 2 {
        status_text = join(status_parts[2:], " ");
    }
    
    # Parse headers
    let headers = {};
    for i in range(1, len(lines)) {
        let colon_idx = find(lines[i], ":");
        if colon_idx >= 0 {
            let key = strip(lines[i][:colon_idx]);
            let value = strip(lines[i][colon_idx + 1:]);
            headers[key] = value;
        }
    }
    
    return {
        http_version: http_version,
        status_code: status_code,
        status_text: status_text,
        headers: headers,
        body: body
    };
}

# Simple HTTP GET
fn get(url, headers) {
    if type(headers) == "null" {
        headers = {};
    }
    return request(url, {method: "GET", headers: headers});
}

# Simple HTTP POST
fn post(url, body, headers) {
    if type(headers) == "null" {
        headers = {};
    }
    if type(body) == "object" {
        # Convert to JSON
        headers["Content-Type"] = "application/json";
        body = json_encode(body);
    }
    return request(url, {method: "POST", headers: headers, body: body});
}

# Simple HTTP PUT
fn put(url, body, headers) {
    if type(headers) == "null" {
        headers = {};
    }
    return request(url, {method: "PUT", headers: headers, body: body});
}

# Simple HTTP DELETE
fn delete(url, headers) {
    if type(headers) == "null" {
        headers = {};
    }
    return request(url, {method: "DELETE", headers: headers});
}

# Simple HTTP PATCH
fn patch(url, body, headers) {
    if type(headers) == "null" {
        headers = {};
    }
    return request(url, {method: "PATCH", headers: headers, body: body});
}

# HTTP Headers class
class Headers {
    fn init(self) {
        self._headers = {};
    }
    
    fn set(self, key, value) {
        self._headers[key] = value;
        return self;
    }
    
    fn get(self, key) {
        return self._headers[key];
    }
    
    fn has(self, key) {
        return self._headers[key] != null;
    }
    
    fn delete(self, key) {
        self._headers[key] = null;
        return self;
    }
    
    fn to_object(self) {
        return self._headers;
    }
}

# HTTP Request class
class Request {
    fn init(self, method, url) {
        self.method = method;
        self.url = url;
        self.headers = Headers();
        self.body = "";
        self.timeout = 30000;
        self.follow_redirects = true;
        self.max_redirects = 5;
    }
    
    fn header(self, key, value) {
        self.headers.set(key, value);
        return self;
    }
    
    fn headers(self, obj) {
        for key in obj {
            self.headers.set(key, obj[key]);
        }
        return self;
    }
    
    fn body(self, data) {
        self.body = data;
        return self;
    }
    
    fn json(self, data) {
        self.body = json_encode(data);
        self.headers.set("Content-Type", "application/json");
        return self;
    }
    
    fn timeout(self, ms) {
        self.timeout = ms;
        return self;
    }
    
    fn send(self) {
        return request(self.url, {
            method: self.method,
            headers: self.headers.to_object(),
            body: self.body,
            timeout: self.timeout
        });
    }
}

# Create request builder
fn Request_get(url) {
    return Request("GET", url);
}

fn Request_post(url) {
    return Request("POST", url);
}

fn Request_put(url) {
    return Request("PUT", url);
}

fn Request_delete(url) {
    return Request("DELETE", url);
}

fn Request_patch(url) {
    return Request("PATCH", url);
}

# HTTP Response class
class Response {
    fn init(self, status_code, headers, body) {
        self.status_code = status_code;
        self.headers = headers;
        self.body = body;
        self.http_version = "HTTP/1.1";
    }
    
    fn ok(self) {
        return self.status_code >= 200 && self.status_code < 300;
    }
    
    fn redirect(self) {
        return self.status_code >= 300 && self.status_code < 400;
    }
    
    fn client_error(self) {
        return self.status_code >= 400 && self.status_code < 500;
    }
    
    fn server_error(self) {
        return self.status_code >= 500;
    }
    
    fn text(self) {
        return self.body;
    }
    
    fn json(self) {
        return json_decode(self.body);
    }
    
    fn status_text(self) {
        let codes = {
            200: "OK",
            201: "Created",
            204: "No Content",
            301: "Moved Permanently",
            302: "Found",
            304: "Not Modified",
            400: "Bad Request",
            401: "Unauthorized",
            403: "Forbidden",
            404: "Not Found",
            405: "Method Not Allowed",
            500: "Internal Server Error",
            502: "Bad Gateway",
            503: "Service Unavailable"
        };
        return codes[self.status_code];
    }
}

# HTTP Client class with session
class Client {
    fn init(self, base_url) {
        self.base_url = base_url;
        self.default_headers = Headers();
        self.timeout = 30000;
        self.follow_redirects = true;
    }
    
    fn header(self, key, value) {
        self.default_headers.set(key, value);
        return self;
    }
    
    fn headers(self, obj) {
        for key in obj {
            self.default_headers.set(key, obj[key]);
        }
        return self;
    }
    
    fn timeout(self, ms) {
        self.timeout = ms;
        return self;
    }
    
    fn get(self, path) {
        let url = self.base_url + path;
        return request(url, {
            method: "GET",
            headers: self.default_headers.to_object(),
            timeout: self.timeout
        });
    }
    
    fn post(self, path, body) {
        let url = self.base_url + path;
        let headers = self.default_headers.to_object();
        if type(body) == "object" {
            headers["Content-Type"] = "application/json";
            body = json_encode(body);
        }
        return request(url, {
            method: "POST",
            headers: headers,
            body: body,
            timeout: self.timeout
        });
    }
    
    fn put(self, path, body) {
        let url = self.base_url + path;
        return request(url, {
            method: "PUT",
            headers: self.default_headers.to_object(),
            body: body,
            timeout: self.timeout
        });
    }
    
    fn delete(self, path) {
        let url = self.base_url + path;
        return request(url, {
            method: "DELETE",
            headers: self.default_headers.to_object(),
            timeout: self.timeout
        });
    }
    
    fn patch(self, path, body) {
        let url = self.base_url + path;
        return request(url, {
            method: "PATCH",
            headers: self.default_headers.to_object(),
            body: body,
            timeout: self.timeout
        });
    }
}

# URL builder
class URL {
    fn init(self, base) {
        self.base = base;
        self._params = {};
    }
    
    fn param(self, key, value) {
        self._params[key] = value;
        return self;
    }
    
    fn params(self, obj) {
        for key in obj {
            self._params[key] = obj[key];
        }
        return self;
    }
    
    fn build(self) {
        let url = self.base;
        if len(self._params) > 0 {
            let query = "";
            for key in self._params {
                if len(query) > 0 {
                    query = query + "&";
                }
                query = query + key + "=" + str(self._params[key]);
            }
            let sep = if contains(url, "?") { "&" } else { "?" };
            url = url + sep + query;
        }
        return url;
    }
    
    fn to_string(self) {
        return self.build();
    }
}

# Query string builder
fn build_query(params) {
    let parts = [];
    for key in params {
        push(parts, key + "=" + str(params[key]));
    }
    return join(parts, "&");
}

# Parse query string
fn parse_query(query) {
    let result = {};
    let pairs = split(query, "&");
    for pair in pairs {
        let kv = split(pair, "=");
        if len(kv) >= 2 {
            result[kv[0]] = kv[1];
        }
    }
    return result;
}

# HTTP status codes
let HTTP_OK = 200;
let HTTP_CREATED = 201;
let HTTP_NO_CONTENT = 204;
let HTTP_MOVED_PERMANENTLY = 301;
let HTTP_FOUND = 302;
let HTTP_NOT_MODIFIED = 304;
let HTTP_BAD_REQUEST = 400;
let HTTP_UNAUTHORIZED = 401;
let HTTP_FORBIDDEN = 403;
let HTTP_NOT_FOUND = 404;
let HTTP_METHOD_NOT_ALLOWED = 405;
let HTTP_INTERNAL_SERVER_ERROR = 500;
let HTTP_BAD_GATEWAY = 502;
let HTTP_SERVICE_UNAVAILABLE = 503;
