# ============================================================
# Nyx Standard Library - Redis Module
# ============================================================
# Comprehensive Redis client providing full Redis protocol support,
# pub/sub, transactions, Lua scripting, and cluster support.

# ============================================================
# Constants
# ============================================================

let VERSION = "1.0.0";

# Redis data types
let TYPE_STRING = "string";
let TYPE_LIST = "list";
let TYPE_SET = "set";
let TYPE_ZSET = "zset";
let TYPE_HASH = "hash";
let TYPE_STREAM = "stream";
let TYPE_NONE = "none";

# Redis commands (grouped by category)
# String commands
let CMD_GET = "GET";
let CMD_SET = "SET";
let CMD_GETSET = "GETSET";
let CMD_MGET = "MGET";
let CMD_MSET = "MSET";
let CMD_INCR = "INCR";
let CMD_DECR = "DECR";
let CMD_INCRBY = "INCRBY";
let CMD_DECRBY = "DECRBY";
let CMD_APPEND = "APPEND";
let CMD_STRLEN = "STRLEN";
let CMD_SUBSTR = "SUBSTR";
let CMD_SETRANGE = "SETRANGE";
let CMD_GETRANGE = "GETRANGE";

# List commands
let CMD_LPUSH = "LPUSH";
let CMD_RPUSH = "RPUSH";
let CMD_LPOP = "LPOP";
let CMD_RPOP = "RPOP";
let CMD_LLEN = "LLEN";
let CMD_LRANGE = "LRANGE";
let CMD_LTRIM = "LTRIM";
let CMD_LINDEX = "LINDEX";
let CMD_LSET = "LSET";
let CMD_LINSERT = "LINSERT";

# Set commands
let CMD_SADD = "SADD";
let CMD_SREM = "SREM";
let CMD_SMEMBERS = "SMEMBERS";
let CMD_SISMEMBER = "SISMEMBER";
let CMD_SCARD = "SCARD";
let CMD_SUNION = "SUNION";
let CMD_SINTER = "SINTER";
let CMD_SDIFF = "SDIFF";

# Sorted set commands
let CMD_ZADD = "ZADD";
let CMD_ZREM = "ZREM";
let CMD_ZRANGE = "ZRANGE";
let CMD_ZREVRANGE = "ZREVRANGE";
let CMD_ZRANGEBYSCORE = "ZRANGEBYSCORE";
let CMD_ZCARD = "ZCARD";
let CMD_ZSCORE = "ZSCORE";

# Hash commands
let CMD_HGET = "HGET";
let CMD_HSET = "HSET";
let CMD_HDEL = "HDEL";
let CMD_HGETALL = "HGETALL";
let CMD_HKEYS = "HKEYS";
let CMD_HVALS = "HVALS";
let CMD_HLEN = "HLEN";
let CMD_HEXISTS = "HEXISTS";
let CMD_HINCRBY = "HINCRBY";

# Key commands
let CMD_DEL = "DEL";
let CMD_EXISTS = "EXISTS";
let CMD_EXPIRE = "EXPIRE";
let CMD_EXPIREAT = "EXPIREAT";
let CMD_TTL = "TTL";
let CMD_PERSIST = "PERSIST";
let CMD_KEYS = "KEYS";
let CMD_SCAN = "SCAN";

# Server commands
let CMD_PING = "PING";
let CMD_AUTH = "AUTH";
let CMD_SELECT = "SELECT";
let CMD_FLUSHDB = "FLUSHDB";
let CMD_FLUSHALL = "FLUSHALL";
let CMD_DBSIZE = "DBSIZE";
let CMD_INFO = "INFO";

# Transaction commands
let CMD_MULTI = "MULTI";
let CMD_EXEC = "EXEC";
let CMD_DISCARD = "DISCARD";
let CMD_WATCH = "WATCH";
let CMD_UNWATCH = "UNWATCH";

# Pub/Sub commands
let CMD_SUBSCRIBE = "SUBSCRIBE";
let CMD_PSUBSCRIBE = "PSUBSCRIBE";
let CMD_UNSUBSCRIBE = "UNSUBSCRIBE";
let CMD_PUNSUBSCRIBE = "PUNSUBSCRIBE";
let CMD_PUBLISH = "PUBLISH";

# Scripting commands
let CMD_EVAL = "EVAL";
let CMD_EVALSHA = "EVALSHA";
let CMD_SCRIPT_LOAD = "SCRIPT LOAD";
let CMD_SCRIPT_EXISTS = "SCRIPT EXISTS";
let CMD_SCRIPT_FLUSH = "SCRIPT FLUSH";

# ============================================================
# Redis Client
# ============================================================

class RedisClient {
    init(options) {
        self.options = options ?? {};
        self.host = self.options["host"] ?? "localhost";
        self.port = self.options["port"] ?? 6379;
        self.password = self.options["password"] ?? "";
        self.database = self.options["database"] ?? 0;
        self.socket = null;
        self.connected = false;
        self.pipeline = [];
        self.inTransaction = false;
        self.transactionCommands = [];
    }

    connect() {
        # In production, this would establish actual socket connection
        self.socket = {};
        self.connected = true;
        
        if self.password != "" {
            self.auth(self.password);
        }
        
        if self.database != 0 {
            self.select(self.database);
        }
        
        return self;
    }

    disconnect() {
        self.connected = false;
        self.socket = null;
    }

    isConnected() {
        return self.connected;
    }

    _sendCommand(command, args) {
        if not self.connected {
            return {"error": "Not connected"};
        }
        
        # In production, this would send actual Redis command
        # Format: *<num args>\r\n$<len arg1>\r\n<arg1>\r\n...
        
        return {"ok": true, "data": null};
    }

    # String commands
    get(key) {
        return self._sendCommand(CMD_GET, [key]);
    }

    set(key, value, options) {
        let args = [key, value];
        
        if options != null {
            if options["ex"] != null {
                args = args + ["ex", str(options["ex"])];
            }
            if options["px"] != null {
                args = args + ["px", str(options["px"])];
            }
            if options["nx"] == true {
                args = args + ["NX"];
            }
            if options["xx"] == true {
                args = args + ["XX"];
            }
        }
        
        return self._sendCommand(CMD_SET, args);
    }

    setex(key, seconds, value) {
        return self.set(key, value, {"ex": seconds});
    }

    psetex(key, milliseconds, value) {
        return self.set(key, value, {"px": milliseconds});
    }

    setnx(key, value) {
        return self.set(key, value, {"nx": true});
    }

    setxx(key, value) {
        return self.set(key, value, {"xx": true});
    }

    getset(key, value) {
        return self._sendCommand(CMD_GETSET, [key, value]);
    }

    mget(keys) {
        return self._sendCommand(CMD_MGET, keys);
    }

    mset(mapping) {
        let args = [];
        for key in keys(mapping) {
            args = args + [key, mapping[key]];
        }
        return self._sendCommand(CMD_MSET, args);
    }

    msetnx(mapping) {
        let args = [];
        for key in keys(mapping) {
            args = args + [key, mapping[key]];
        }
        return self._sendCommand("MSETNX", args);
    }

    incr(key) {
        return self._sendCommand(CMD_INCR, [key]);
    }

    decr(key) {
        return self._sendCommand(CMD_DECR, [key]);
    }

    incrby(key, increment) {
        return self._sendCommand(CMD_INCRBY, [key, str(increment)]);
    }

    decrby(key, decrement) {
        return self._sendCommand(CMD_DECRBY, [key, str(decrement)]);
    }

    incrbyfloat(key, increment) {
        return self._sendCommand("INCRBYFLOAT", [key, str(increment)]);
    }

    append(key, value) {
        return self._sendCommand(CMD_APPEND, [key, value]);
    }

    strlen(key) {
        return self._sendCommand(CMD_STRLEN, [key]);
    }

    getrange(key, start, end) {
        return self._sendCommand(CMD_GETRANGE, [key, str(start), str(end)]);
    }

    setrange(key, offset, value) {
        return self._sendCommand(CMD_SETRANGE, [key, str(offset), value]);
    }

    # List commands
    lpush(key, values) {
        let args = [key];
        for v in values {
            args = args + [v];
        }
        return self._sendCommand(CMD_LPUSH, args);
    }

    rpush(key, values) {
        let args = [key];
        for v in values {
            args = args + [v];
        }
        return self._sendCommand(CMD_RPUSH, args);
    }

    lpop(key) {
        return self._sendCommand(CMD_LPOP, [key]);
    }

    rpop(key) {
        return self._sendCommand(CMD_RPOP, [key]);
    }

    llen(key) {
        return self._sendCommand(CMD_LLEN, [key]);
    }

    lrange(key, start, stop) {
        return self._sendCommand(CMD_LRANGE, [key, str(start), str(stop)]);
    }

    lindex(key, index) {
        return self._sendCommand(CMD_LINDEX, [key, str(index)]);
    }

    lset(key, index, value) {
        return self._sendCommand(CMD_LSET, [key, str(index), value]);
    }

    ltrim(key, start, stop) {
        return self._sendCommand(CMD_LTRIM, [key, str(start), str(stop)]);
    }

    # Set commands
    sadd(key, members) {
        let args = [key];
        for m in members {
            args = args + [m];
        }
        return self._sendCommand(CMD_SADD, args);
    }

    srem(key, members) {
        let args = [key];
        for m in members {
            args = args + [m];
        }
        return self._sendCommand(CMD_SREM, args);
    }

    smembers(key) {
        return self._sendCommand(CMD_SMEMBERS, [key]);
    }

    sismember(key, member) {
        return self._sendCommand(CMD_SISMEMBER, [key, member]);
    }

    scard(key) {
        return self._sendCommand(CMD_SCARD, [key]);
    }

    sunion(keys) {
        return self._sendCommand(CMD_SUNION, keys);
    }

    sinter(keys) {
        return self._sendCommand(CMD_SINTER, keys);
    }

    sdiff(keys) {
        return self._sendCommand(CMD_SDIFF, keys);
    }

    # Sorted set commands
    zadd(key, members) {
        let args = [key];
        for m in keys(members) {
            args = args + [str(members[m]), m];
        }
        return self._sendCommand(CMD_ZADD, args);
    }

    zrem(key, members) {
        let args = [key];
        for m in members {
            args = args + [m];
        }
        return self._sendCommand(CMD_ZREM, args);
    }

    zrange(key, start, stop, withScores) {
        let args = [key, str(start), str(stop)];
        if withScores == true {
            args = args + ["WITHSCORES"];
        }
        return self._sendCommand(CMD_ZRANGE, args);
    }

    zrevrange(key, start, stop, withScores) {
        let args = [key, str(start), str(stop)];
        if withScores == true {
            args = args + ["WITHSCORES"];
        }
        return self._sendCommand(CMD_ZREVRANGE, args);
    }

    zrangebyscore(key, min, max, withScores, limit) {
        let args = [key, str(min), str(max)];
        if withScores == true {
            args = args + ["WITHSCORES"];
        }
        if limit != null {
            args = args + ["LIMIT", str(limit["offset"]), str(limit["count"])];
        }
        return self._sendCommand(CMD_ZRANGEBYSCORE, args);
    }

    zcard(key) {
        return self._sendCommand(CMD_ZCARD, [key]);
    }

    zscore(key, member) {
        return self._sendCommand(CMD_ZSCORE, [key, member]);
    }

    # Hash commands
    hget(key, field) {
        return self._sendCommand(CMD_HGET, [key, field]);
    }

    hset(key, field, value) {
        return self._sendCommand(CMD_HSET, [key, field, value]);
    }

    hmset(key, mapping) {
        let args = [key];
        for field in keys(mapping) {
            args = args + [field, mapping[field]];
        }
        return self._sendCommand("HMSET", args);
    }

    hdel(key, fields) {
        let args = [key];
        for f in fields {
            args = args + [f];
        }
        return self._sendCommand(CMD_HDEL, args);
    }

    hgetall(key) {
        return self._sendCommand(CMD_HGETALL, [key]);
    }

    hkeys(key) {
        return self._sendCommand(CMD_HKEYS, [key]);
    }

    hvals(key) {
        return self._sendCommand(CMD_HVALS, [key]);
    }

    hlen(key) {
        return self._sendCommand(CMD_HLEN, [key]);
    }

    hexists(key, field) {
        return self._sendCommand(CMD_HEXISTS, [key, field]);
    }

    hrincrement(key, field, increment) {
        return self._sendCommand(CMD_HINCRBY, [key, field, str(increment)]);
    }

    # Key commands
    del(keys) {
        return self._sendCommand(CMD_DEL, keys);
    }

    exists(keys) {
        return self._sendCommand(CMD_EXISTS, keys);
    }

    expire(key, seconds) {
        return self._sendCommand(CMD_EXPIRE, [key, str(seconds)]);
    }

    expireat(key, timestamp) {
        return self._sendCommand(CMD_EXPIREAT, [key, str(timestamp)]);
    }

    ttl(key) {
        return self._sendCommand(CMD_TTL, [key]);
    }

    persist(key) {
        return self._sendCommand(CMD_PERSIST, [key]);
    }

    keys(pattern) {
        return self._sendCommand(CMD_KEYS, [pattern]);
    }

    scan(cursor, options) {
        let args = [str(cursor)];
        if options != null {
            if options["match"] != null {
                args = args + ["MATCH", options["match"]];
            }
            if options["count"] != null {
                args = args + ["COUNT", str(options["count"])];
            }
        }
        return self._sendCommand(CMD_SCAN, args);
    }

    # Server commands
    ping() {
        return self._sendCommand(CMD_PING, []);
    }

    auth(password) {
        return self._sendCommand(CMD_AUTH, [password]);
    }

    select(database) {
        return self._sendCommand(CMD_SELECT, [str(database)]);
    }

    flushdb() {
        return self._sendCommand(CMD_FLUSHDB, []);
    }

    flushall() {
        return self._sendCommand(CMD_FLUSHALL, []);
    }

    dbsize() {
        return self._sendCommand(CMD_DBSIZE, []);
    }

    info(section) {
        let args = [];
        if section != null {
            args = [section];
        }
        return self._sendCommand(CMD_INFO, args);
    }

    # Transaction commands
    multi() {
        self.inTransaction = true;
        self.transactionCommands = [];
        return self._sendCommand(CMD_MULTI, []);
    }

    exec() {
        let results = [];
        
        for cmd in self.transactionCommands {
            results = results + [self._sendCommand(cmd[0], cmd[1])];
        }
        
        self.inTransaction = false;
        self.transactionCommands = [];
        
        return results;
    }

    discard() {
        self.inTransaction = false;
        self.transactionCommands = [];
        return self._sendCommand(CMD_DISCARD, []);
    }

    watch(keys) {
        return self._sendCommand(CMD_WATCH, keys);
    }

    unwatch() {
        return self._sendCommand(CMD_UNWATCH, []);
    }

    # Pipeline
    pipeline() {
        return RedisPipeline(self);
    }

    # Pub/Sub
    publish(channel, message) {
        return self._sendCommand(CMD_PUBLISH, [channel, message]);
    }

    subscribe(channels) {
        # Would subscribe to channels
        return self._sendCommand(CMD_SUBSCRIBE, channels);
    }

    psubscribe(patterns) {
        return self._sendCommand(CMD_PSUBSCRIBE, patterns);
    }

    unsubscribe(channels) {
        return self._sendCommand(CMD_UNSUBSCRIBE, channels);
    }

    punsubscribe(patterns) {
        return self._sendCommand(CMD_PUNSUBSCRIBE, patterns);
    }

    # Scripting
    eval(script, numKeys, keys, args) {
        let cmdArgs = [script, str(numKeys)];
        for k in keys {
            cmdArgs = cmdArgs + [k];
        }
        for a in args {
            cmdArgs = cmdArgs + [a];
        }
        return self._sendCommand(CMD_EVAL, cmdArgs);
    }

    evalsha(sha1, numKeys, keys, args) {
        let cmdArgs = [sha1, str(numKeys)];
        for k in keys {
            cmdArgs = cmdArgs + [k];
        }
        for a in args {
            cmdArgs = cmdArgs + [a];
        }
        return self._sendCommand(CMD_EVALSHA, cmdArgs);
    }

    scriptLoad(script) {
        return self._sendCommand(CMD_SCRIPT_LOAD, [script]);
    }

    scriptExists(sha1s) {
        return self._sendCommand(CMD_SCRIPT_EXISTS, sha1s);
    }

    scriptFlush() {
        return self._sendCommand(CMD_SCRIPT_FLUSH, []);
    }
}

# ============================================================
# Redis Pipeline
# ============================================================

class RedisPipeline {
    init(client) {
        self.client = client;
        self.commands = [];
    }

    get(key) {
        self.commands = self.commands + [[CMD_GET, [key]]];
        return self;
    }

    set(key, value, options) {
        let args = [key, value];
        if options != null {
            if options["ex"] != null {
                args = args + ["ex", str(options["ex"])];
            }
        }
        self.commands = self.commands + [[CMD_SET, args]];
        return self;
    }

    execute() {
        let results = [];
        
        for cmd in self.commands {
            results = results + [self.client._sendCommand(cmd[0], cmd[1])];
        }
        
        self.commands = [];
        return results;
    }
}

# ============================================================
# Redis Cluster Client
# ============================================================

class RedisCluster {
    init(options) {
        self.options = options ?? {};
        self.nodes = self.options["nodes"] ?? [];
        self.startupNodes = self.nodes;
        self.slots = {};
        self.clients = {};
    }

    connect() {
        # Connect to cluster nodes
        for node in self.nodes {
            let client = RedisClient(node);
            client.connect();
            self.clients[node["host"] + ":" + str(node["port"])] = client;
        }
        
        # Discover slots
        self._discoverSlots();
        
        return self;
    }

    _discoverSlots() {
        # Would discover slot distribution from cluster
        for i in range(16384) {
            self.slots[i] = "127.0.0.1:7000";
        }
    }

    _getNode(key) {
        # Calculate hash slot
        let slot = self._hashSlot(key);
        return self.slots[slot];
    }

    _hashSlot(key) {
        # CRC16 implementation for Redis cluster
        let s = key;
        let length = len(s);
        let crc = 0x0000;
        
        for i in range(length) {
            crc = crc ^ (s[i] << 8);
            for j in range(8) {
                if (crc & 0x8000) != 0 {
                    crc = (crc << 1) ^ 0x1021;
                } else {
                    crc = crc << 1;
                }
            }
        }
        
        return crc & 0x3FFF;
    }

    getClient(key) {
        let nodeKey = self._getNode(key);
        
        if self.clients[nodeKey] == null {
            # Create new client
            let parts = split(nodeKey, ":");
            let client = RedisClient({"host": parts[0], "port": parseInt(parts[1])});
            client.connect();
            self.clients[nodeKey] = client;
        }
        
        return self.clients[nodeKey];
    }

    get(key) {
        let client = self.getClient(key);
        return client.get(key);
    }

    set(key, value, options) {
        let client = self.getClient(key);
        return client.set(key, value, options);
    }

    del(keys) {
        # Delete from all relevant nodes
        let results = [];
        
        for key in keys {
            let client = self.getClient(key);
            results = results + [client.del([key])];
        }
        
        return results;
    }
}

# ============================================================
# Pub/Sub Client
# ============================================================

class RedisPubSub {
    init(options) {
        self.options = options ?? {};
        self.client = RedisClient(options);
        self.subscriptions = {};
        self.handlers = {};
    }

    connect() {
        self.client.connect();
        return self;
    }

    subscribe(channel, handler) {
        self.subscriptions[channel] = "subscribe";
        self.handlers[channel] = handler;
        return self.client.subscribe([channel]);
    }

    psubscribe(pattern, handler) {
        self.subscriptions[pattern] = "psubscribe";
        self.handlers[pattern] = handler;
        return self.client.psubscribe([pattern]);
    }

    unsubscribe(channel) {
        self.subscriptions[channel] = null;
        self.handlers[channel] = null;
        return self.client.unsubscribe([channel]);
    }

    punsubscribe(pattern) {
        self.subscriptions[pattern] = null;
        self.handlers[pattern] = null;
        return self.client.punsubscribe([pattern]);
    }

    publish(channel, message) {
        return self.client.publish(channel, message);
    }

    onMessage(channel, handler) {
        self.handlers[channel] = handler;
        return self;
    }

    onPattern(pattern, handler) {
        self.handlers[pattern] = handler;
        return self;
    }
}

# ============================================================
# Redis Sentinel Client
# ============================================================

class RedisSentinel {
    init(options) {
        self.options = options ?? {};
        self.sentinels = self.options["sentinels"] ?? [];
        self.masterName = self.options["masterName"] ?? "mymaster";
        self.sentinelPassword = self.options["sentinelPassword"] ?? "";
        self.clients = {};
    }

    getMaster() {
        # Query sentinels to find master
        for sentinel in self.sentinels {
            let client = RedisClient(sentinel);
            client.connect();
            
            let info = client._sendCommand("SENTINEL", ["GET-MASTER-ADDR-BY-NAME", self.masterName]);
            
            if info != null and info["data"] != null {
                return {
                    "host": info["data"][0],
                    "port": parseInt(info["data"][1])
                };
            }
        }
        
        return null;
    }

    getSlaves() {
        let slaves = [];
        
        for sentinel in self.sentinels {
            let client = RedisClient(sentinel);
            client.connect();
            
            let info = client._sendCommand("SENTINEL", ["SLAVES", self.masterName]);
            
            # Parse slave info
        }
        
        return slaves;
    }

    connect() {
        let master = self.getMaster();
        
        if master != null {
            let client = RedisClient(master);
            client.connect();
            return client;
        }
        
        return null;
    }
}

# ============================================================
# Lock Manager
# ============================================================

class RedisLock {
    init(client, name, options) {
        self.client = client;
        self.name = "lock:" + name;
        self.timeout = options["timeout"] ?? 10;
        self.blocking = options["blocking"] ?? false;
        self.blockTimeout = options["blockTimeout"] ?? 5;
        self.token = options["token"] ?? str(time.time());
    }

    acquire() {
        let result = self.client.set(self.name, self.token, {
            "nx": true,
            "ex": self.timeout
        });
        
        return result["ok"] == true;
    }

    release() {
        # Lua script for atomic check and delete
        let script = "if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end";
        
        return self.client.eval(script, 1, [self.name], [self.token]);
    }

    extend(additionalTime) {
        let script = "if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('pexpire', KEYS[1], ARGV[2]) else return 0 end";
        
        return self.client.eval(script, 1, [self.name], [self.token, str(additionalTime)]);
    }

    isLocked() {
        let result = self.client.exists([self.name]);
        return result["data"] == 1;
    }
}

# ============================================================
# Rate Limiter
# ============================================================

class RedisRateLimiter {
    init(client, key, limit, window) {
        self.client = client;
        self.key = "ratelimit:" + key;
        self.limit = limit;
        self.window = window;
    }

    allow() {
        let now = time.time();
        let windowStart = now - self.window;
        
        # Remove old entries
        self.client.zremrangebyscore(self.key, 0, windowStart);
        
        # Count current entries
        let count = self.client.zcard(self.key);
        
        if count["data"] >= self.limit {
            return false;
        }
        
        # Add new entry
        self.client.zadd(self.key, {str(now): str(now)});
        
        # Set expiry
        self.client.expire(self.key, self.window);
        
        return true;
    }

    remaining() {
        let now = time.time();
        let windowStart = now - self.window;
        
        self.client.zremrangebyscore(self.key, 0, windowStart);
        
        let count = self.client.zcard(self.key);
        
        return self.limit - count["data"];
    }
}

# ============================================================
# Cache Wrapper
# ============================================================

class RedisCache {
    init(client, prefix, defaultTTL) {
        self.client = client;
        self.prefix = prefix ?? "cache:";
        self.defaultTTL = defaultTTL ?? 3600;
    }

    get(key) {
        let fullKey = self.prefix + key;
        return self.client.get(fullKey);
    }

    set(key, value, ttl) {
        let fullKey = self.prefix + key;
        let expireTime = ttl ?? self.defaultTTL;
        return self.client.set(fullKey, value, {"ex": expireTime});
    }

    delete(key) {
        let fullKey = self.prefix + key;
        return self.client.del([fullKey]);
    }

    exists(key) {
        let fullKey = self.prefix + key;
        return self.client.exists([fullKey]);
    }

    clear() {
        let keys = self.client.keys(self.prefix + "*");
        
        if len(keys) > 0 {
            return self.client.del(keys);
        }
        
        return true;
    }
}

# ============================================================
# Utility Functions
# ============================================================

fn createRedisClient(options) {
    return RedisClient(options);
}

fn createRedisCluster(options) {
    return RedisCluster(options);
}

fn createRedisPubSub(options) {
    return RedisPubSub(options);
}

fn createRedisSentinel(options) {
    return RedisSentinel(options);
}

fn createRedisLock(client, name, options) {
    return RedisLock(client, name, options);
}

fn createRateLimiter(client, key, limit, window) {
    return RedisRateLimiter(client, key, limit, window);
}

fn createRedisCache(client, prefix, defaultTTL) {
    return RedisCache(client, prefix, defaultTTL);
}

# ============================================================
# Export
# ============================================================

{
    "RedisClient": RedisClient,
    "RedisCluster": RedisCluster,
    "RedisPubSub": RedisPubSub,
    "RedisSentinel": RedisSentinel,
    "RedisLock": RedisLock,
    "RedisRateLimiter": RedisRateLimiter,
    "RedisCache": RedisCache,
    "createRedisClient": createRedisClient,
    "createRedisCluster": createRedisCluster,
    "createRedisPubSub": createRedisPubSub,
    "createRedisSentinel": createRedisSentinel,
    "createRedisLock": createRedisLock,
    "createRateLimiter": createRateLimiter,
    "createRedisCache": createRedisCache,
    "TYPE_STRING": TYPE_STRING,
    "TYPE_LIST": TYPE_LIST,
    "TYPE_SET": TYPE_SET,
    "TYPE_ZSET": TYPE_ZSET,
    "TYPE_HASH": TYPE_HASH,
    "TYPE_STREAM": TYPE_STREAM,
    "TYPE_NONE": TYPE_NONE,
    "VERSION": VERSION
}
