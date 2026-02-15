# ===========================================
# Nyx Standard Library - Web Framework
# ===========================================
# HTTP routing, middleware, and templates

# ===========================================
# HTTP ROUTER
# ===========================================

class Router {
    fn init(self) {
        self.routes = [];
        self.middleware = [];
        self.named_routes = {};
    }
    
    # Add route
    fn get(self, path, handler) {
        return self.add_route("GET", path, handler);
    }
    
    fn post(self, path, handler) {
        return self.add_route("POST", path, handler);
    }
    
    fn put(self, path, handler) {
        return self.add_route("PUT", path, handler);
    }
    
    fn delete(self, path, handler) {
        return self.add_route("DELETE", path, handler);
    }
    
    fn patch(self, path, handler) {
        return self.add_route("PATCH", path, handler);
    }
    
    fn add_route(self, method, path, handler) {
        let route = {
            method: method,
            path: path,
            handler: handler,
            params: self._parse_path(path)
        };
        push(self.routes, route);
        return self;
    }
    
    fn _parse_path(self, path) {
        let parts = split(path, "/");
        let params = [];
        
        for part in parts {
            if len(part) > 0 && part[0] == ":" {
                push(params, part[1:]);
            }
        }
        
        return params;
    }
    
    fn match(self, method, path) {
        for route in self.routes {
            if route.method != method && route.method != "*" {
                continue;
            }
            
            let match_result = self._match_path(route.path, path);
            if match_result != null {
                return {
                    handler: route.handler,
                    params: match_result
                };
            }
        }
        return null;
    }
    
    fn _match_path(self, pattern, path) {
        let pattern_parts = split(pattern, "/");
        let path_parts = split(path, "/");
        
        if len(pattern_parts) != len(path_parts) {
            return null;
        }
        
        let params = {};
        
        for i in range(len(pattern_parts)) {
            let p = pattern_parts[i];
            let a = path_parts[i];
            
            if len(p) > 0 && p[0] == ":" {
                # Parameter
                params[p[1:]] = a;
            } else if p != a {
                return null;
            }
        }
        
        return params;
    }
    
    fn use(self, middleware_fn) {
        push(self.middleware, middleware_fn);
        return self;
    }
    
    fn group(self, prefix, routes_fn) {
        # Create a sub-router
        let group_router = Router();
        routes_fn(group_router);
        
        # Add prefix to all routes
        for route in group_router.routes {
            route.path = prefix + route.path;
            push(self.routes, route);
        }
        
        return self;
    }
}

# ===========================================
# REQUEST / RESPONSE
# ===========================================

class Request {
    fn init(self) {
        self.method = "GET";
        self.path = "/";
        self.query = {};
        self.headers = {};
        self.body = "";
        self.params = {};
        self.cookies = {};
        self.json = null;
    }
    
    fn header(self, name) {
        return self.headers[name];
    }
    
    fn param(self, name) {
        return self.params[name];
    }
    
    fn query_param(self, name) {
        return self.query[name];
    }
    
    fn cookie(self, name) {
        return self.cookies[name];
    }
    
    fn is_json(self) {
        return self.headers["Content-Type"] == "application/json";
    }
    
    fn is_html(self) {
        return self.headers["Content-Type"] == "text/html";
    }
}

class Response {
    fn init(self) {
        self.status_code = 200;
        self.headers = {};
        self.body = "";
        self.cookies = {};
    }
    
    fn status(self, code) {
        self.status_code = code;
        return self;
    }
    
    fn header(self, name, value) {
        self.headers[name] = value;
        return self;
    }
    
    fn json(self, data) {
        self.headers["Content-Type"] = "application/json";
        self.body = json_encode(data);
        return self;
    }
    
    fn html(self, content) {
        self.headers["Content-Type"] = "text/html";
        self.body = content;
        return self;
    }
    
    fn text(self, content) {
        self.headers["Content-Type"] = "text/plain";
        self.body = content;
        return self;
    }
    
    fn redirect(self, url) {
        self.status_code = 302;
        self.headers["Location"] = url;
        return self;
    }
    
    fn cookie(self, name, value, options) {
        self.cookies[name] = {value: value, options: options ?? {}};
        return self;
    }
    
    fn send_file(self, filename) {
        # Would send file
        self.headers["Content-Type"] = "application/octet-stream";
        self.body = "[FILE: " + filename + "]";
        return self;
    }
    
    fn to_object(self) {
        return {
            status_code: self.status_code,
            headers: self.headers,
            body: self.body,
            cookies: self.cookies
        };
    }
}

# ===========================================
# MIDDLEWARE
# ===========================================

# CORS middleware
fn cors_middleware(options) {
    if type(options) == "null" {
        options = {};
    }
    
    let origin = options.origin ?? "*";
    let methods = options.methods ?? ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"];
    let headers = options.headers ?? ["Content-Type", "Authorization"];
    
    return fn(req, res, next) {
        res.header("Access-Control-Allow-Origin", origin);
        res.header("Access-Control-Allow-Methods", join(methods, ", "));
        res.header("Access-Control-Allow-Headers", join(headers, ", "));
        
        if req.method == "OPTIONS" {
            return res.status(204).send("");
        }
        
        next();
    };
}

# Logging middleware
fn log_middleware(req, res, next) {
    let start = time();
    
    # Would log request
    
    # After response
    fn log_response() {
        let elapsed = time() - start;
        print(req.method + " " + req.path + " - " + str(res.status_code) + " (" + str(elapsed) + "s)");
    }
    
    next();
}

# Body parser middleware
fn body_parser_middleware(req, res, next) {
    if req.is_json() {
        try {
            req.json = json_decode(req.body);
        } catch e {
            return res.status(400).json({error: "Invalid JSON"});
        }
    }
    next();
}

# Query parser middleware
fn query_parser_middleware(req, res, next) {
    # Parse query string
    # Simplified - would use proper parser
    next();
}

# Static file middleware
fn static_middleware(root_dir) {
    return fn(req, res, next) {
        # Would serve static files
        next();
    };
}

# Error handler middleware
fn error_handler_middleware(err, req, res, next) {
    print("Error: " + str(err));
    res.status(500).json({error: "Internal Server Error"});
}

# Rate limiter middleware
fn rate_limiter_middleware(max_requests, window_seconds) {
    let requests = {};
    
    return fn(req, res, next) {
        let ip = req.headers["X-Forwarded-For"] ?? "unknown";
        let now = time();
        
        if requests[ip] == null {
            requests[ip] = [];
        }
        
        # Remove old requests
        let recent = [];
        for ts in requests[ip] {
            if now - ts < window_seconds {
                push(recent, ts);
            }
        }
        requests[ip] = recent;
        
        if len(recent) >= max_requests {
            return res.status(429).json({error: "Too many requests"});
        }
        
        push(requests[ip], now);
        next();
    };
}

# ===========================================
# TEMPLATE ENGINE
# ===========================================

class TemplateEngine {
    fn init(self) {
        self.cache = {};
        self.filters = {};
        self.globals = {};
        
        # Built-in filters
        self.filters["upper"] = fn(v) { return upper(v); };
        self.filters["lower"] = fn(v) { return lower(v); };
        self.filters["length"] = fn(v) { return len(v); };
        self.filters["first"] = fn(v) { return v[0]; };
        self.filters["last"] = fn(v) { return v[len(v) - 1]; };
        self.filters["join"] = fn(v, sep) { return join(v, sep); };
        self.filters["json"] = fn(v) { return json_encode(v); };
        self.filters["safe"] = fn(v) { return str(v); };
    }
    
    fn render(self, template_str, context) {
        let result = template_str;
        
        # Add globals to context
        for k in self.globals {
            context[k] = self.globals[k];
        }
        
        # Process includes
        result = self._process_includes(result, context);
        
        # Process conditionals
        result = self._process_conditionals(result, context);
        
        # Process loops
        result = self._process_loops(result, context);
        
        # Process expressions
        result = self._process_expressions(result, context);
        
        # Process filters
        result = self._process_filters(result, context);
        
        return result;
    }
    
    fn render_file(self, filename, context) {
        if self.cache[filename] == null {
            self.cache[filename] = read_file(filename);
        }
        return self.render(self.cache[filename], context);
    }
    
    fn _process_includes(self, template, context) {
        # Would process {% include "file.html" %}
        return template;
    }
    
    fn _process_conditionals(self, template, context) {
        # Simple conditional processing
        # {% if condition %} ... {% endif %}
        return template;
    }
    
    fn _process_loops(self, template, context) {
        # {% for item in items %} ... {% endfor %}
        return template;
    }
    
    fn _process_expressions(self, template, context) {
        # {{ variable }} or {{ expression }}
        let result = "";
        let i = 0;
        
        while i < len(template) {
            if template[i] == "{" && i + 1 < len(template) && template[i + 1] == "{" {
                # Find closing }}
                let end = find(template[i + 2:], "}}");
                if end >= 0 {
                    let expr = strip(template[i + 2:i + 2 + end]);
                    result = result + self._eval_expression(expr, context);
                    i = i + 2 + end + 2;
                } else {
                    result = result + template[i];
                    i = i + 1;
                }
            } else {
                result = result + template[i];
                i = i + 1;
            }
        }
        
        return result;
    }
    
    fn _eval_expression(self, expr, context) {
        # Simple variable lookup
        # Would support more complex expressions
        
        # Check for filter
        let pipe_idx = find(expr, "|");
        if pipe_idx >= 0 {
            let var = strip(expr[:pipe_idx]);
            let filter_chain = split(strip(expr[pipe_idx + 1:]), "|");
            
            let value = self._get_value(var, context);
            
            for f in filter_chain {
                f = strip(f);
                let filter_name = strip(split(f, ":")[0]);
                let filter_args = [];
                if contains(f, ":") {
                    filter_args = split(f[find(f, ":") + 1:], ",");
                }
                
                if self.filters[filter_name] != null {
                    if len(filter_args) > 0 {
                        value = self.filters[filter_name](value, ...filter_args);
                    } else {
                        value = self.filters[filter_name](value);
                    }
                }
            }
            
            return str(value);
        }
        
        return str(self._get_value(expr, context));
    }
    
    fn _get_value(self, path, context) {
        let parts = split(path, ".");
        let current = context;
        
        for part in parts {
            if current == null {
                return "";
            }
            current = current[part];
        }
        
        return current ?? "";
    }
    
    fn _process_filters(self, template, context) {
        return template;
    }
    
    fn add_filter(self, name, fn_to_add) {
        self.filters[name] = fn_to_add;
    }
    
    fn add_global(self, name, value) {
        self.globals[name] = value;
    }
}

# Simple template function
fn render_template(template_str, context) {
    let engine = TemplateEngine();
    return engine.render(template_str, context);
}

# ===========================================
# WEB APPLICATION
# ===========================================

class App {
    fn init(self) {
        self.router = Router();
        self.middleware = [];
        self.engine = TemplateEngine();
        self.context = {};
    }
    
    fn use(self, middleware_fn) {
        push(self.middleware, middleware_fn);
        return self;
    }
    
    fn get(self, path, handler) {
        self.router.get(path, handler);
        return self;
    }
    
    fn post(self, path, handler) {
        self.router.post(path, handler);
        return self;
    }
    
    fn put(self, path, handler) {
        self.router.put(path, handler);
        return self;
    }
    
    fn delete(self, path, handler) {
        self.router.delete(path, handler);
        return self;
    }
    
    fn patch(self, path, handler) {
        self.router.patch(path, handler);
        return self;
    }
    
    fn set(self, key, value) {
        self.context[key] = value;
        return self;
    }
    
    fn engine(self, ext, engine) {
        self.engine = engine;
        return self;
    }
    
    fn handle_request(self, req) {
        let res = Response();
        
        # Apply middleware
        let idx = 0;
        let middleware_len = len(self.middleware);
        
        fn next_fn() {
            idx = idx + 1;
            if idx < middleware_len {
                self.middleware[idx](req, res, next_fn);
            } else {
                # Find route
                let match = self.router.match(req.method, req.path);
                
                if match != null {
                    req.params = match.params;
                    
                    # Apply route middleware
                    for mw in self.router.middleware {
                        mw(req, res, fn() {});
                    }
                    
                    # Call handler
                    try {
                        match.handler(req, res);
                    } catch e {
                        res.status(500).json({error: str(e)});
                    }
                } else {
                    res.status(404).json({error: "Not Found"});
                }
            }
        }
        
        # Start middleware chain
        if middleware_len > 0 {
            self.middleware[0](req, res, next_fn);
        } else {
            next_fn();
        }
        
        return res.to_object();
    }
    
    # Convenience methods
    fn listen(self, port, host) {
        if type(host) == "null" {
            host = "0.0.0.0";
        }
        print("Server listening on " + host + ":" + str(port));
        # Would start server loop
    }
}

# Create app
fn create_app() {
    return App();
}

# ===========================================
# REST HELPERS
# ===========================================

# JSON response helper
fn json(data, status_code) {
    let res = Response();
    if type(status_code) != "null" {
        res.status(status    return res.json_code);
    }
(data);
}

# Success response
fn success(data, message) {
    return json({
        success: true,
        data: data,
        message: message ?? "OK"
    });
}

# Error response
fn error(message, code) {
    return json({
        success: false,
        error: message,
        code: code ?? "ERROR"
    }, 400);
}

# Not found
fn not_found(message) {
    return json({
        success: false,
        error: message ?? "Not Found"
    }, 404);
}

# Created
fn created(data, location) {
    let res = json({success: true, data: data}, 201);
    if type(location) != "null" {
        res.header("Location", location);
    }
    return res;
}

# No content
fn no_content() {
    return Response().status(204);
}

# Paginated response
fn paginated(data, page, per_page, total) {
    return json({
        success: true,
        data: data,
        pagination: {
            page: page,
            per_page: per_page,
            total: total,
            pages: (total + per_page - 1) / per_page
        }
    });
}
