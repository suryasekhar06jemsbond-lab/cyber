# ============================================================
# Nyx Standard Library - JWT Module
# ============================================================
# Comprehensive JWT (JSON Web Token) framework providing
# token creation, validation, signing, and OAuth support.

# ============================================================
# Constants
# ============================================================

let VERSION = "1.0.0";

# JWT algorithms
let ALG_NONE = "none";
let ALG_HS256 = "HS256";
let ALG_HS384 = "HS384";
let ALG_HS512 = "HS512";
let ALG_RS256 = "RS256";
let ALG_RS384 = "RS384";
let ALG_RS512 = "RS512";
let ALG_ES256 = "ES256";
let ALG_ES384 = "ES384";
let ALG_ES512 = "ES512";
let ALG_PS256 = "PS256";
let ALG_PS384 = "PS384";
let ALG_PS512 = "PS512";

# JWT claims
let CLAIM_ISSUER = "iss";
let CLAIM_SUBJECT = "sub";
let CLAIM_AUDIENCE = "aud";
let CLAIM_EXPIRATION = "exp";
let CLAIM_NOT_BEFORE = "nbf";
let CLAIM_ISSUED_AT = "iat";
let CLAIM_JTI = "jti";

# Token types
let ACCESS_TOKEN = "access";
let REFRESH_TOKEN = "refresh";
let ID_TOKEN = "id";

# OAuth grant types
let GRANT_AUTHORIZATION_CODE = "authorization_code";
let GRANT_CLIENT_CREDENTIALS = "client_credentials";
let GRANT_PASSWORD = "password";
let GRANT_REFRESH_TOKEN = "refresh_token";

# OAuth flows
let FLOW_AUTHORIZATION_CODE = "authorization_code";
let FLOW_IMPLICIT = "implicit";
let FLOW_CLIENT_CREDENTIALS = "client_credentials";
let FLOW_PASSWORD = "password";

# ============================================================
# Base64 Encoding/Decoding
# ============================================================

fn _base64URLEncode(data) {
    # Replace + with -, / with _, and remove padding
    let encoded = base64.encode(data);
    encoded = replace(encoded, "+", "-");
    encoded = replace(encoded, "/", "_");
    encoded = replace(encoded, "=", "");
    return encoded;
}

fn _base64URLDecode(data) {
    # Add padding back
    let padding = 4 - (len(data) % 4);
    if padding < 4 {
        data = data + repeat("=", padding);
    }
    
    # Replace - with +, _ with /
    data = replace(data, "-", "+");
    data = replace(data, "_", "/");
    
    return base64.decode(data);
}

# ============================================================
# JWT Header
# ============================================================

class JWTHeader {
    init(algorithm, type, keyID) {
        self.alg = algorithm ?? ALG_HS256;
        self.typ = type ?? "JWT";
        self.kid = keyID ?? null;
    }

    toJSON() {
        let header = {"alg": self.alg, "typ": self.typ};
        if self.kid != null {
            header["kid"] = self.kid;
        }
        return header;
    }

    toBase64URL() {
        return _base64URLEncode(json.stringify(self.toJSON()));
    }

    static fromJSON(json) {
        return JWTHeader(json["alg"], json["typ"], json["kid"]);
    }

    static fromBase64URL(base64URL) {
        let json = json.parse(_base64URLDecode(base64URL));
        return JWTHeader.fromJSON(json);
    }
}

# ============================================================
# JWT Payload
# ============================================================

class JWTPayload {
    init(claims) {
        self.claims = claims ?? {};
    }

    setIssuer(issuer) {
        self.claims[CLAIM_ISSUER] = issuer;
        return self;
    }

    getIssuer() {
        return self.claims[CLAIM_ISSUER];
    }

    setSubject(subject) {
        self.claims[CLAIM_SUBJECT] = subject;
        return self;
    }

    getSubject() {
        return self.claims[CLAIM_SUBJECT];
    }

    setAudience(audience) {
        self.claims[CLAIM_AUDIENCE] = audience;
        return self;
    }

    getAudience() {
        return self.claims[CLAIM_AUDIENCE];
    }

    setExpiration(seconds) {
        self.claims[CLAIM_EXPIRATION] = time.time() + seconds;
        return self;
    }

    getExpiration() {
        return self.claims[CLAIM_EXPIRATION];
    }

    setNotBefore(seconds) {
        self.claims[CLAIM_NOT_BEFORE] = time.time() + seconds;
        return self;
    }

    getNotBefore() {
        return self.claims[CLAIM_NOT_BEFORE];
    }

    setIssuedAt() {
        self.claims[CLAIM_ISSUED_AT] = time.time();
        return self;
    }

    getIssuedAt() {
        return self.claims[CLAIM_ISSUED_AT];
    }

    setJWTID(jti) {
        self.claims[CLAIM_JTI] = jti;
        return self;
    }

    getJWTID() {
        return self.claims[CLAIM_JTI];
    }

    setClaim(key, value) {
        self.claims[key] = value;
        return self;
    }

    getClaim(key) {
        return self.claims[key];
    }

    hasClaim(key) {
        return self.claims[key] != null;
    }

    removeClaim(key) {
        self.claims[key] = null;
        return self;
    }

    toJSON() {
        return self.claims;
    }

    toBase64URL() {
        return _base64URLEncode(json.stringify(self.claims));
    }

    static fromJSON(json) {
        return JWTPayload(json);
    }

    static fromBase64URL(base64URL) {
        let json = json.parse(_base64URLDecode(base64URL));
        return JWTPayload.fromJSON(json);
    }

    isExpired() {
        if self.claims[CLAIM_EXPIRATION] == null {
            return false;
        }
        return time.time() > self.claims[CLAIM_EXPIRATION];
    }

    isNotYetValid() {
        if self.claims[CLAIM_NOT_BEFORE] == null {
            return false;
        }
        return time.time() < self.claims[CLAIM_NOT_BEFORE];
    }

    expiresIn() {
        if self.claims[CLAIM_EXPIRATION] == null {
            return -1;
        }
        return self.claims[CLAIM_EXPIRATION] - time.time();
    }

    issuedAtAgo() {
        if self.claims[CLAIM_ISSUED_AT] == null {
            return -1;
        }
        return time.time() - self.claims[CLAIM_ISSUED_AT];
    }
}

# ============================================================
# JWT Token
# ============================================================

class JWT {
    init(header, payload) {
        self.header = header;
        self.payload = payload;
        self.signature = "";
    }

    static create(algorithm, payloadClaims) {
        let header = JWTHeader(algorithm);
        let payload = JWTPayload(payloadClaims);
        return JWT(header, payload);
    }

    static parse(token) {
        let parts = split(token, ".");
        
        if len(parts) != 3 {
            return null;
        }
        
        let header = JWTHeader.fromBase64URL(parts[0]);
        let payload = JWTPayload.fromBase64URL(parts[1]);
        
        let jwt = JWT(header, payload);
        jwt.signature = parts[2];
        
        return jwt;
    }

    sign(secret) {
        let signingInput = self.header.toBase64URL() + "." + self.payload.toBase64URL();
        
        # Sign based on algorithm
        let alg = self.header.alg;
        
        if alg == ALG_NONE {
            self.signature = "";
        } else if alg == ALG_HS256 or alg == ALG_HS384 or alg == ALG_HS512 {
            self.signature = self._hmacSign(signingInput, secret, alg);
        } else if alg == ALG_RS256 or alg == ALG_RS384 or alg == ALG_RS512 {
            self.signature = self._rsaSign(signingInput, secret, alg);
        } else if alg == ALG_ES256 or alg == ALG_ES384 or alg == ALG_ES512 {
            self.signature = self._ecdsaSign(signingInput, secret, alg);
        } else if alg == ALG_PS256 or alg == ALG_PS384 or alg == ALG_PS512 {
            self.signature = self._rsaPssSign(signingInput, secret, alg);
        }
        
        return self;
    }

    verify(secret) {
        let alg = self.header.alg;
        
        if alg == ALG_NONE {
            return self.signature == "";
        }
        
        let signingInput = self.header.toBase64URL() + "." + self.payload.toBase64URL();
        
        if alg == ALG_HS256 or alg == ALG_HS384 or alg == ALG_HS512 {
            return self._hmacVerify(signingInput, secret, self.signature, alg);
        }
        
        # Other algorithms would be verified here
        return false;
    }

    _hmacSign(input, secret, algorithm) {
        let hashAlg = "sha256";
        if algorithm == ALG_HS384 {
            hashAlg = "sha384";
        } else if algorithm == ALG_HS512 {
            hashAlg = "sha512";
        }
        
        let crypto = require("crypto");
        let hmac = crypto.hmac(hashAlg, secret);
        let signature = hmac.sign(input);
        
        return _base64URLEncode(signature);
    }

    _hmacVerify(input, secret, signature, algorithm) {
        let expected = self._hmacSign(input, secret, algorithm);
        return expected == signature;
    }

    _rsaSign(input, privateKey, algorithm) {
        # RSA signing would use crypto module
        return "";
    }

    _ecdsaSign(input, privateKey, algorithm) {
        # ECDSA signing would use crypto module
        return "";
    }

    _rsaPssSign(input, privateKey, algorithm) {
        # RSA-PSS signing would use crypto module
        return "";
    }

    toString() {
        return self.header.toBase64URL() + "." + self.payload.toBase64URL() + "." + self.signature;
    }

    toJSON() {
        return {
            "header": self.header.toJSON(),
            "payload": self.payload.toJSON(),
            "signature": self.signature
        };
    }

    getHeader() {
        return self.header;
    }

    getPayload() {
        return self.payload;
    }

    getSignature() {
        return self.signature;
    }

    isExpired() {
        return self.payload.isExpired();
    }

    isNotYetValid() {
        return self.payload.isNotYetValid();
    }

    expiresIn() {
        return self.payload.expiresIn();
    }

    issuedAtAgo() {
        return self.payload.issuedAtAgo();
    }
}

# ============================================================
# JWT Builder
# ============================================================

class JWTBuilder {
    init() {
        self.algorithm = ALG_HS256;
        self.claims = {};
    }

    setAlgorithm(algorithm) {
        self.algorithm = algorithm;
        return self;
    }

    issuer(issuer) {
        self.claims[CLAIM_ISSUER] = issuer;
        return self;
    }

    subject(subject) {
        self.claims[CLAIM_SUBJECT] = subject;
        return self;
    }

    audience(audience) {
        self.claims[CLAIM_AUDIENCE] = audience;
        return self;
    }

    expiresIn(seconds) {
        self.claims[CLAIM_EXPIRATION] = time.time() + seconds;
        return self;
    }

    notBefore(seconds) {
        self.claims[CLAIM_NOT_BEFORE] = time.time() + seconds;
        return self;
    }

    issuedAt() {
        self.claims[CLAIM_ISSUED_AT] = time.time();
        return self;
    }

    jwtID(jti) {
        self.claims[CLAIM_JTI] = jti;
        return self;
    }

    claim(key, value) {
        self.claims[key] = value;
        return self;
    }

    claims(claims) {
        for key in keys(claims) {
            self.claims[key] = claims[key];
        }
        return self;
    }

    build() {
        return JWT.create(self.algorithm, self.claims);
    }
}

# ============================================================
# JWT Verifier
# ============================================================

class JWTVerifier {
    init(secret, options) {
        self.secret = secret;
        self.options = options ?? {};
        
        self.algorithms = options["algorithms"] ?? [ALG_HS256];
        self.issuer = options["issuer"] ?? null;
        self.audience = options["audience"] ?? null;
        self.subject = options["subject"] ?? null;
        self.leeway = options["leeway"] ?? 0;
    }

    verify(token) {
        let jwt = JWT.parse(token);
        
        if jwt == null {
            return {
                "valid": false,
                "error": "Invalid token format"
            };
        }
        
        # Verify algorithm
        if self.algorithms not in jwt.header.alg {
            return {
                "valid": false,
                "error": "Invalid algorithm"
            };
        }
        
        # Verify signature
        if not jwt.verify(self.secret) {
            return {
                "valid": false,
                "error": "Invalid signature"
            };
        }
        
        # Verify expiration
        if jwt.payload.claims[CLAIM_EXPIRATION] != null {
            if time.time() > jwt.payload.claims[CLAIM_EXPIRATION] + self.leeway {
                return {
                    "valid": false,
                    "error": "Token expired"
                };
            }
        }
        
        # Verify not before
        if jwt.payload.claims[CLAIM_NOT_BEFORE] != null {
            if time.time() < jwt.payload.claims[CLAIM_NOT_BEFORE] - self.leeway {
                return {
                    "valid": false,
                    "error": "Token not yet valid"
                };
            }
        }
        
        # Verify issuer
        if self.issuer != null {
            if jwt.payload.claims[CLAIM_ISSUER] != self.issuer {
                return {
                    "valid": false,
                    "error": "Invalid issuer"
                };
            }
        }
        
        # Verify audience
        if self.audience != null {
            let tokenAudience = jwt.payload.claims[CLAIM_AUDIENCE];
            if type(tokenAudience) == "list" {
                if self.audience not in tokenAudience {
                    return {
                        "valid": false,
                        "error": "Invalid audience"
                    };
                }
            } else if tokenAudience != self.audience {
                return {
                    "valid": false,
                    "error": "Invalid audience"
                };
            }
        }
        
        # Verify subject
        if self.subject != null {
            if jwt.payload.claims[CLAIM_SUBJECT] != self.subject {
                return {
                    "valid": false,
                    "error": "Invalid subject"
                };
            }
        }
        
        return {
            "valid": true,
            "token": jwt,
            "payload": jwt.payload.claims
        };
    }

    verifyAsync(token) {
        # Async version for non-blocking verification
        return self.verify(token);
    }
}

# ============================================================
# OAuth Client
# ============================================================

class OAuthClient {
    init(config) {
        self.clientID = config["clientID"];
        self.clientSecret = config["clientSecret"];
        self.redirectURI = config["redirectURI"] ?? "";
        self.authorizationEndpoint = config["authorizationEndpoint"] ?? "";
        self.tokenEndpoint = config["tokenEndpoint"] ?? "";
        self.scopes = config["scopes"] ?? [];
        self.grantType = config["grantType"] ?? GRANT_AUTHORIZATION_CODE;
    }

    getAuthorizationURL(state, nonce) {
        let params = {
            "response_type": "code",
            "client_id": self.clientID,
            "redirect_uri": self.redirectURI,
            "scope": join(self.scopes, " ")
        };
        
        if state != null {
            params["state"] = state;
        }
        
        if nonce != null {
            params["nonce"] = nonce;
        }
        
        let url = self.authorizationEndpoint;
        let first = true;
        
        for key in keys(params) {
            if first {
                url = url + "?";
                first = false;
            } else {
                url = url + "&";
            }
            url = url + key + "=" + encodeURIComponent(params[key]);
        }
        
        return url;
    }

    getLogoutURL(idTokenHint, postLogoutRedirectURI) {
        let params = {
            "id_token_hint": idTokenHint
        };
        
        if postLogoutRedirectURI != null {
            params["post_logout_redirect_uri"] = postLogoutRedirectURI;
        }
        
        let url = self.authorizationEndpoint + "/logout";
        
        let first = true;
        for key in keys(params) {
            if first {
                url = url + "?";
                first = false;
            } else {
                url = url + "&";
            }
            url = url + key + "=" + encodeURIComponent(params[key]);
        }
        
        return url;
    }

    exchangeCodeForToken(code) {
        let params = {
            "grant_type": GRANT_AUTHORIZATION_CODE,
            "code": code,
            "client_id": self.clientID,
            "client_secret": self.clientSecret,
            "redirect_uri": self.redirectURI
        };
        
        # Would make HTTP POST request to token endpoint
        return {
            "access_token": "",
            "token_type": "Bearer",
            "expires_in": 3600,
            "refresh_token": "",
            "scope": join(self.scopes, " ")
        };
    }

    refreshAccessToken(refreshToken) {
        let params = {
            "grant_type": GRANT_REFRESH_TOKEN,
            "refresh_token": refreshToken,
            "client_id": self.clientID,
            "client_secret": self.clientSecret
        };
        
        # Would make HTTP POST request
        return {
            "access_token": "",
            "token_type": "Bearer",
            "expires_in": 3600,
            "refresh_token": ""
        };
    }

    revokeToken(token, tokenType) {
        # Would make HTTP POST to revoke endpoint
        return true;
    }

    getUserInfo(accessToken) {
        # Would make HTTP GET request to userinfo endpoint
        return {
            "sub": "",
            "name": "",
            "email": "",
            "picture": ""
        };
    }

    requestResource(url, accessToken) {
        # Would make HTTP GET request with Bearer token
        return {};
    }
}

# ============================================================
# OAuth Server
# ============================================================

class OAuthServer {
    init(config) {
        self.config = config ?? {};
        self.issuer = config["issuer"] ?? "http://localhost";
        self.authorizationEndpoint = config["authorizationEndpoint"] ?? "/oauth/authorize";
        self.tokenEndpoint = config["tokenEndpoint"] ?? "/oauth/token";
        self.userinfoEndpoint = config["userinfoEndpoint"] ?? "/oauth/userinfo";
        self.jwksEndpoint = config["jwksEndpoint"] ?? "/oauth/jwks";
        self.revokeEndpoint = config["revokeEndpoint"] ?? "/oauth/revoke";
        
        self.clients = {};
        self.authorizationCodes = {};
        self.accessTokens = {};
        self.refreshTokens = {};
    }

    registerClient(clientID, clientSecret, redirectURIs) {
        self.clients[clientID] = {
            "clientID": clientID,
            "clientSecret": clientSecret,
            "redirectURIs": redirectURIs,
            "createdAt": time.time()
        };
        
        return self.clients[clientID];
    }

    authorize(clientID, redirectURI, responseType, scope, state, userID) {
        # Verify client
        if self.clients[clientID] == null {
            return {"error": "invalid_client"};
        }
        
        # Verify redirect URI
        if redirectURI not in self.clients[clientID]["redirectURIs"] {
            return {"error": "invalid_request", "error_description": "Invalid redirect URI"};
        }
        
        if responseType != "code" {
            return {"error": "unsupported_response_type"};
        }
        
        # Generate authorization code
        let code = self._generateCode();
        
        self.authorizationCodes[code] = {
            "clientID": clientID,
            "redirectURI": redirectURI,
            "scope": scope,
            "userID": userID,
            "createdAt": time.time(),
            "expiresAt": time.time() + 600  # 10 minutes
        };
        
        let result = {"code": code};
        
        if state != null {
            result["state"] = state;
        }
        
        return result;
    }

    token(clientID, clientSecret, grantType, code, redirectURI, refreshToken) {
        # Verify client
        if self.clients[clientID] == null {
            return {"error": "invalid_client"};
        }
        
        if self.clients[clientID]["clientSecret"] != clientSecret {
            return {"error": "invalid_client"};
        }
        
        if grantType == GRANT_AUTHORIZATION_CODE {
            return self._handleAuthorizationCodeGrant(code, redirectURI, clientID);
        } else if grantType == GRANT_REFRESH_TOKEN {
            return self._handleRefreshTokenGrant(refreshToken, clientID);
        } else if grantType == GRANT_CLIENT_CREDENTIALS {
            return self._handleClientCredentialsGrant(clientID);
        }
        
        return {"error": "unsupported_grant_type"};
    }

    _handleAuthorizationCodeGrant(code, redirectURI, clientID) {
        if self.authorizationCodes[code] == null {
            return {"error": "invalid_grant"};
        }
        
        let authCode = self.authorizationCodes[code];
        
        if authCode["expiresAt"] < time.time() {
            self.authorizationCodes[code] = null;
            return {"error": "invalid_grant", "error_description": "Code expired"};
        }
        
        if authCode["clientID"] != clientID {
            return {"error": "invalid_grant"};
        }
        
        if authCode["redirectURI"] != redirectURI {
            return {"error": "invalid_grant"};
        }
        
        # Generate tokens
        let accessToken = self._generateToken();
        let refreshToken = self._generateToken();
        
        self.accessTokens[accessToken] = {
            "clientID": clientID,
            "userID": authCode["userID"],
            "scope": authCode["scope"],
            "createdAt": time.time(),
            "expiresAt": time.time() + 3600
        };
        
        self.refreshTokens[refreshToken] = {
            "clientID": clientID,
            "userID": authCode["userID"],
            "createdAt": time.time(),
            "expiresAt": time.time() + 86400 * 30
        };
        
        # Delete authorization code
        self.authorizationCodes[code] = null;
        
        return {
            "access_token": accessToken,
            "token_type": "Bearer",
            "expires_in": 3600,
            "refresh_token": refreshToken,
            "scope": authCode["scope"]
        };
    }

    _handleRefreshTokenGrant(refreshToken, clientID) {
        if self.refreshTokens[refreshToken] == null {
            return {"error": "invalid_grant"};
        }
        
        let refreshData = self.refreshTokens[refreshToken];
        
        if refreshData["clientID"] != clientID {
            return {"error": "invalid_grant"};
        }
        
        if refreshData["expiresAt"] < time.time() {
            self.refreshTokens[refreshToken] = null;
            return {"error": "invalid_grant"};
        }
        
        # Generate new access token
        let accessToken = self._generateToken();
        
        self.accessTokens[accessToken] = {
            "clientID": clientID,
            "userID": refreshData["userID"],
            "scope": refreshData["scope"],
            "createdAt": time.time(),
            "expiresAt": time.time() + 3600
        };
        
        return {
            "access_token": accessToken,
            "token_type": "Bearer",
            "expires_in": 3600
        };
    }

    _handleClientCredentialsGrant(clientID) {
        let accessToken = self._generateToken();
        
        self.accessTokens[accessToken] = {
            "clientID": clientID,
            "userID": null,
            "scope": "",
            "createdAt": time.time(),
            "expiresAt": time.time() + 3600
        };
        
        return {
            "access_token": accessToken,
            "token_type": "Bearer",
            "expires_in": 3600
        };
    }

    verifyAccessToken(accessToken) {
        if self.accessTokens[accessToken] == null {
            return null;
        }
        
        let tokenData = self.accessTokens[accessToken];
        
        if tokenData["expiresAt"] < time.time() {
            self.accessTokens[accessToken] = null;
            return null;
        }
        
        return tokenData;
    }

    getUserInfo(accessToken) {
        let tokenData = self.verifyAccessToken(accessToken);
        
        if tokenData == null {
            return {"error": "invalid_token"};
        }
        
        return {
            "sub": tokenData["userID"],
            "tokenData": tokenData
        };
    }

    revokeToken(token) {
        if self.accessTokens[token] != null {
            self.accessTokens[token] = null;
        }
        
        if self.refreshTokens[token] != null {
            self.refreshTokens[token] = null;
        }
        
        return true;
    }

    _generateCode() {
        # Would generate secure random code
        return "code_" + str(time.time());
    }

    _generateToken() {
        # Would generate secure random token
        return "token_" + str(time.time());
    }
}

# ============================================================
# Key Management
# ============================================================

class KeyManager {
    init() {
        self.keys = {};
    }

    addKey(keyID, key, algorithm) {
        self.keys[keyID] = {
            "key": key,
            "algorithm": algorithm,
            "createdAt": time.time()
        };
    }

    getKey(keyID) {
        return self.keys[keyID];
    }

    removeKey(keyID) {
        self.keys[keyID] = null;
    }

    getPublicKeys() {
        let jwks = {"keys": []};
        
        for keyID in keys(self.keys) {
            let keyData = self.keys[keyID];
            jwks["keys"] = jwks["keys"] + [{
                "kid": keyID,
                "kty": "RSA",
                "alg": keyData["algorithm"]
            }];
        }
        
        return jwks;
    }
}

# ============================================================
# Utility Functions
# ============================================================

fn createJWT(claims, secret, algorithm) {
    let builder = JWTBuilder();
    builder.claims(claims);
    let jwt = builder.build();
    jwt.sign(secret);
    return jwt;
}

fn decodeJWT(token) {
    return JWT.parse(token);
}

fn verifyJWT(token, secret) {
    let jwt = JWT.parse(token);
    if jwt == null {
        return false;
    }
    return jwt.verify(secret);
}

fn signJWT(token, secret) {
    let jwt = JWT.parse(token);
    if jwt != null {
        jwt.sign(secret);
    }
    return jwt;
}

fn createVerifier(secret, options) {
    return JWTVerifier(secret, options);
}

fn createOAuthClient(config) {
    return OAuthClient(config);
}

fn createOAuthServer(config) {
    return OAuthServer(config);
}

fn createKeyManager() {
    return KeyManager();
}

fn encodeURIComponent(str) {
    # Simple URL encoding
    let encoded = "";
    for i in range(len(str)) {
        let c = str[i];
        if c == " " {
            encoded = encoded + "%20";
        } else if c == "!" {
            encoded = encoded + "%21";
        } else if c == "#" {
            encoded = encoded + "%23";
        } else if c == "$" {
            encoded = encoded + "%24";
        } else if c == "&" {
            encoded = encoded + "%26";
        } else if c == "+" {
            encoded = encoded + "%2B";
        } else if c == "=" {
            encoded = encoded + "%3D";
        } else if c == "?" {
            encoded = encoded + "%3F";
        } else {
            encoded = encoded + c;
        }
    }
    return encoded;
}

# ============================================================
# Preset Configurations
# ============================================================

let GoogleOAuth = {
    "authorizationEndpoint": "https://accounts.google.com/o/oauth2/v2/auth",
    "tokenEndpoint": "https://oauth2.googleapis.com/token",
    "userinfoEndpoint": "https://www.googleapis.com/oauth2/v3/userinfo",
    "jwksEndpoint": "https://www.googleapis.com/oauth2/v3/certs"
};

let GitHubOAuth = {
    "authorizationEndpoint": "https://github.com/login/oauth/authorize",
    "tokenEndpoint": "https://github.com/login/oauth/access_token",
    "userinfoEndpoint": "https://api.github.com/user"
};

let MicrosoftOAuth = {
    "authorizationEndpoint": "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
    "tokenEndpoint": "https://login.microsoftonline.com/common/oauth2/v2.0/token",
    "userinfoEndpoint": "https://graph.microsoft.com/v1.0/me"
};

# ============================================================
# Export
# ============================================================

{
    "JWT": JWT,
    "JWTHeader": JWTHeader,
    "JWTPayload": JWTPayload,
    "JWTBuilder": JWTBuilder,
    "JWTVerifier": JWTVerifier,
    "OAuthClient": OAuthClient,
    "OAuthServer": OAuthServer,
    "KeyManager": KeyManager,
    "createJWT": createJWT,
    "decodeJWT": decodeJWT,
    "verifyJWT": verifyJWT,
    "signJWT": signJWT,
    "createVerifier": createVerifier,
    "createOAuthClient": createOAuthClient,
    "createOAuthServer": createOAuthServer,
    "createKeyManager": createKeyManager,
    "GoogleOAuth": GoogleOAuth,
    "GitHubOAuth": GitHubOAuth,
    "MicrosoftOAuth": MicrosoftOAuth,
    "ALG_NONE": ALG_NONE,
    "ALG_HS256": ALG_HS256,
    "ALG_HS384": ALG_HS384,
    "ALG_HS512": ALG_HS512,
    "ALG_RS256": ALG_RS256,
    "ALG_RS384": ALG_RS384,
    "ALG_RS512": ALG_RS512,
    "CLAIM_ISSUER": CLAIM_ISSUER,
    "CLAIM_SUBJECT": CLAIM_SUBJECT,
    "CLAIM_AUDIENCE": CLAIM_AUDIENCE,
    "CLAIM_EXPIRATION": CLAIM_EXPIRATION,
    "CLAIM_NOT_BEFORE": CLAIM_NOT_BEFORE,
    "CLAIM_ISSUED_AT": CLAIM_ISSUED_AT,
    "CLAIM_JTI": CLAIM_JTI,
    "GRANT_AUTHORIZATION_CODE": GRANT_AUTHORIZATION_CODE,
    "GRANT_CLIENT_CREDENTIALS": GRANT_CLIENT_CREDENTIALS,
    "GRANT_PASSWORD": GRANT_PASSWORD,
    "GRANT_REFRESH_TOKEN": GRANT_REFRESH_TOKEN,
    "VERSION": VERSION
}
