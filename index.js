const https = require('https');
const http = require('http');
const { URL } = require('url');

function request(method, urlStr, body = null, headers = {}) {
    return new Promise((resolve, reject) => {
        try {
            const url = new URL(urlStr);
            const lib = url.protocol === 'https:' ? https : http;
            
            const options = {
                method: method,
                headers: { ...headers }
            };
function create() {
    const routes = {
        GET: {},
        POST: {},
        PUT: {},
        DELETE: {}
    };
    let server = null;

            let bodyData = null;
            if (body) {
                bodyData = JSON.stringify(body);
                options.headers['Content-Type'] = 'application/json';
                options.headers['Content-Length'] = Buffer.byteLength(bodyData);
            }
    return {
        get: (path, handler) => routes.GET[path] = handler,
        post: (path, handler) => routes.POST[path] = handler,
        put: (path, handler) => routes.PUT[path] = handler,
        delete: (path, handler) => routes.DELETE[path] = handler,
        
        start: (port) => new Promise(resolve => {
            server = http.createServer((req, res) => {
                // Response Helpers
                res.json = (data) => {
                    res.setHeader('Content-Type', 'application/json');
                    res.end(JSON.stringify(data));
                };
                res.send = (data) => res.end(data);
                res.status = (code) => { res.statusCode = code; return res; };

            const req = lib.request(url, options, (res) => {
                let data = '';
                res.on('data', (chunk) => {
                    data += chunk;
                });
                res.on('end', () => {
                    let parsedData = data;
                    try {
                        const contentType = res.headers['content-type'];
                        if (contentType && contentType.includes('application/json')) {
                            parsedData = JSON.parse(data);
                        }
                    } catch (e) {
                        // Return raw data if parsing fails
                    }
                    resolve({
                        status: res.statusCode,
                        headers: res.headers,
                        data: parsedData
                const url = new URL(req.url, `http://${req.headers.host}`);
                const handler = routes[req.method]?.[url.pathname];

                if (!handler) return res.status(404).send('Not Found');

                if (['POST', 'PUT'].includes(req.method)) {
                    let body = '';
                    req.on('data', c => body += c);
                    req.on('end', () => {
                        try {
                            if (req.headers['content-type']?.includes('application/json')) {
                                req.body = JSON.parse(body);
                            } else {
                                req.body = body;
                            }
                        } catch (e) { req.body = body; }
                        handler(req, res);
                    });
                });
                } else {
                    handler(req, res);
                }
            });

            req.on('error', (e) => {
                reject(e);
            });

            if (bodyData) {
                req.write(bodyData);
            }
            req.end();
        } catch (error) {
            reject(error);
        }
    });
            server.listen(port, () => resolve(server));
        }),
        
        stop: () => server?.close()
    };
}

module.exports = {
    get: (url, headers) => request('GET', url, null, headers),
    post: (url, body, headers) => request('POST', url, body, headers),
    put: (url, body, headers) => request('PUT', url, body, headers),
    delete: (url, headers) => request('DELETE', url, null, headers)
};
module.exports = { create };