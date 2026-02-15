# ============================================================
# Nyx Standard Library - Cache Module
# ============================================================
# Comprehensive caching framework providing multiple caching
# strategies including LRU, LFU, TTL, distributed caching,
# and cache invalidation patterns.

# ============================================================
# Constants
# ============================================================

let VERSION = "1.0.0";
let DEFAULT_MAX_SIZE = 1000;
let DEFAULT_TTL = 3600;
let DEFAULT_CLEANUP_INTERVAL = 60;

# Cache policies
let LRU = "lru";
let LFU = "lfu";
let FIFO = "fifo";
let LIFO = "lifo";
let TTL = "ttl";
let RANDOM = "random";

# Cache events
let CACHE_HIT = "hit";
let CACHE_MISS = "miss";
let CACHE_SET = "set";
let CACHE_DELETE = "delete";
let CACHE_EXPIRE = "expire";
let CACHE_EVICT = "evict";
let CACHE_CLEAR = "clear";

# ============================================================
# Cache Entry Class
# ============================================================

class CacheEntry {
    init(key, value, ttl, createdAt, accessCount, lastAccessed) {
        self.key = key;
        self.value = value;
        self.ttl = ttl;
        self.createdAt = createdAt;
        self.accessCount = accessCount;
        self.lastAccessed = lastAccessed;
        self.expiresAt = createdAt + ttl;
    }

    isExpired(currentTime) {
        if self.ttl <= 0 {
            return false;
        }
        return currentTime >= self.expiresAt;
    }

    touch(currentTime) {
        self.lastAccessed = currentTime;
        self.accessCount = self.accessCount + 1;
    }

    getAge(currentTime) {
        return currentTime - self.createdAt;
    }

    getTimeToLive(currentTime) {
        if self.ttl <= 0 {
            return -1;
        }
        let remaining = self.expiresAt - currentTime;
        if remaining < 0 {
            return 0;
        }
        return remaining;
    }
}

# ============================================================
# LRU Cache Implementation
# ============================================================

class LRUCache {
    init(maxSize, onEvict) {
        self.maxSize = maxSize;
        self.onEvict = onEvict;
        self.cache = {};
        self.order = [];
        self.hits = 0;
        self.misses = 0;
        self.evictions = 0;
    }

    get(key) {
        if self.has(key) {
            let entry = self.cache[key];
            self._updateOrder(key);
            entry.touch(self._currentTime());
            self.hits = self.hits + 1;
            return entry.value;
        }
        self.misses = self.misses + 1;
        return null;
    }

    set(key, value, ttl) {
        let currentTime = self._currentTime();
        
        if self.has(key) {
            let entry = self.cache[key];
            entry.value = value;
            entry.touch(currentTime);
            if ttl > 0 {
                entry.ttl = ttl;
                entry.expiresAt = currentTime + ttl;
            }
            self._updateOrder(key);
        } else {
            if self.size() >= self.maxSize {
                self._evictOldest();
            }
            
            let ttlValue = ttl;
            if ttlValue <= 0 {
                ttlValue = DEFAULT_TTL;
            }
            
            let entry = CacheEntry(key, value, ttlValue, currentTime, 1, currentTime);
            self.cache[key] = entry;
            self.order = self.order + [key];
        }
    }

    has(key) {
        if self.cache[key] == null {
            return false;
        }
        let entry = self.cache[key];
        return not entry.isExpired(self._currentTime());
    }

    delete(key) {
        if self.cache[key] != null {
            self._removeFromOrder(key);
            let value = self.cache[key].value;
            self.cache[key] = null;
            return value;
        }
        return null;
    }

    clear() {
        let keys = self.keys();
        for key in keys {
            if self.onEvict != null {
                self.onEvict(key, self.cache[key].value, CACHE_EVICT);
            }
            self.cache[key] = null;
        }
        self.cache = {};
        self.order = [];
    }

    size() {
        return self._countValid();
    }

    keys() {
        let result = [];
        for key in keys(self.cache) {
            if self.cache[key] != null {
                if not self.cache[key].isExpired(self._currentTime()) {
                    result = result + [key];
                }
            }
        }
        return result;
    }

    values() {
        let result = [];
        for key in keys(self.cache) {
            if self.cache[key] != null {
                if not self.cache[key].isExpired(self._currentTime()) {
                    result = result + [self.cache[key].value];
                }
            }
        }
        return result;
    }

    items() {
        let result = [];
        for key in keys(self.cache) {
            if self.cache[key] != null {
                if not self.cache[key].isExpired(self._currentTime()) {
                    result = result + [[key, self.cache[key].value]];
                }
            }
        }
        return result;
    }

    _updateOrder(key) {
        self._removeFromOrder(key);
        self.order = self.order + [key];
    }

    _removeFromOrder(key) {
        let newOrder = [];
        for k in self.order {
            if k != key {
                newOrder = newOrder + [k];
            }
        }
        self.order = newOrder;
    }

    _evictOldest() {
        if len(self.order) > 0 {
            let oldestKey = self.order[0];
            let entry = self.cache[oldestKey];
            if self.onEvict != null {
                self.onEvict(oldestKey, entry.value, CACHE_EVICT);
            }
            self.cache[oldestKey] = null;
            self.order = self.order[1:];
            self.evictions = self.evictions + 1;
        }
    }

    _countValid() {
        let count = 0;
        for key in keys(self.cache) {
            if self.cache[key] != null {
                if not self.cache[key].isExpired(self._currentTime()) {
                    count = count + 1;
                }
            }
        }
        return count;
    }

    _currentTime() {
        return time.time();
    }

    stats() {
        let total = self.hits + self.misses;
        let hitRate = 0;
        if total > 0 {
            hitRate = self.hits / total;
        }
        return {
            "size": self.size(),
            "maxSize": self.maxSize,
            "hits": self.hits,
            "misses": self.misses,
            "hitRate": hitRate,
            "evictions": self.evictions
        };
    }

    cleanup() {
        let currentTime = self._currentTime();
        let keysToRemove = [];
        
        for key in keys(self.cache) {
            if self.cache[key] != null {
                if self.cache[key].isExpired(currentTime) {
                    keysToRemove = keysToRemove + [key];
                }
            }
        }
        
        for key in keysToRemove {
            let entry = self.cache[key];
            if self.onEvict != null {
                self.onEvict(key, entry.value, CACHE_EXPIRE);
            }
            self.cache[key] = null;
            self._removeFromOrder(key);
        }
        
        return len(keysToRemove);
    }
}

# ============================================================
# LFU Cache Implementation
# ============================================================

class LFUCache {
    init(maxSize, onEvict) {
        self.maxSize = maxSize;
        self.onEvict = onEvict;
        self.cache = {};
        self.frequencyBuckets = {};
        self.minFrequency = 1;
        self.hits = 0;
        self.misses = 0;
        self.evictions = 0;
    }

    get(key) {
        if self.has(key) {
            let entry = self.cache[key];
            self._incrementFrequency(key);
            entry.touch(self._currentTime());
            self.hits = self.hits + 1;
            return entry.value;
        }
        self.misses = self.misses + 1;
        return null;
    }

    set(key, value, ttl) {
        let currentTime = self._currentTime();
        
        if self.has(key) {
            let entry = self.cache[key];
            entry.value = value;
            if ttl > 0 {
                entry.ttl = ttl;
                entry.expiresAt = currentTime + ttl;
            }
            self._incrementFrequency(key);
        } else {
            if self.size() >= self.maxSize {
                self._evictLFU();
            }
            
            let ttlValue = ttl;
            if ttlValue <= 0 {
                ttlValue = DEFAULT_TTL;
            }
            
            let entry = CacheEntry(key, value, ttlValue, currentTime, 1, currentTime);
            self.cache[key] = entry;
            self._addToFrequencyBucket(key, 1);
            
            if self.minFrequency == 0 {
                self.minFrequency = 1;
            }
        }
    }

    has(key) {
        if self.cache[key] == null {
            return false;
        }
        let entry = self.cache[key];
        return not entry.isExpired(self._currentTime());
    }

    delete(key) {
        if self.cache[key] != null {
            let entry = self.cache[key];
            self._removeFromFrequencyBucket(key, entry.accessCount);
            let value = entry.value;
            self.cache[key] = null;
            return value;
        }
        return null;
    }

    clear() {
        let keys = self.keys();
        for key in keys {
            if self.onEvict != null {
                self.onEvict(key, self.cache[key].value, CACHE_EVICT);
            }
            self.cache[key] = null;
        }
        self.cache = {};
        self.frequencyBuckets = {};
        self.minFrequency = 1;
    }

    size() {
        return self._countValid();
    }

    keys() {
        let result = [];
        for key in keys(self.cache) {
            if self.cache[key] != null {
                if not self.cache[key].isExpired(self._currentTime()) {
                    result = result + [key];
                }
            }
        }
        return result;
    }

    values() {
        let result = [];
        for key in keys(self.cache) {
            if self.cache[key] != null {
                if not self.cache[key].isExpired(self._currentTime()) {
                    result = result + [self.cache[key].value];
                }
            }
        }
        return result;
    }

    items() {
        let result = [];
        for key in keys(self.cache) {
            if self.cache[key] != null {
                if not self.cache[key].isExpired(self._currentTime()) {
                    result = result + [[key, self.cache[key].value]];
                }
            }
        }
        return result;
    }

    _incrementFrequency(key) {
        let entry = self.cache[key];
        let oldFreq = entry.accessCount;
        let newFreq = oldFreq + 1;
        
        self._removeFromFrequencyBucket(key, oldFreq);
        self._addToFrequencyBucket(key, newFreq);
        
        entry.accessCount = newFreq;
        
        if self.frequencyBuckets[self.minFrequency] == null or len(self.frequencyBuckets[self.minFrequency]) == 0 {
            self.minFrequency = newFreq;
        }
    }

    _addToFrequencyBucket(key, frequency) {
        if self.frequencyBuckets[frequency] == null {
            self.frequencyBuckets[frequency] = [];
        }
        self.frequencyBuckets[frequency] = self.frequencyBuckets[frequency] + [key];
    }

    _removeFromFrequencyBucket(key, frequency) {
        if self.frequencyBuckets[frequency] != null {
            let newBucket = [];
            for k in self.frequencyBuckets[frequency] {
                if k != key {
                    newBucket = newBucket + [k];
                }
            }
            self.frequencyBuckets[frequency] = newBucket;
        }
    }

    _evictLFU() {
        if self.frequencyBuckets[self.minFrequency] != null {
            if len(self.frequencyBuckets[self.minFrequency]) > 0 {
                let keyToEvict = self.frequencyBuckets[self.minFrequency][0];
                let entry = self.cache[keyToEvict];
                
                if self.onEvict != null {
                    self.onEvict(keyToEvict, entry.value, CACHE_EVICT);
                }
                
                self.cache[keyToEvict] = null;
                self.frequencyBuckets[self.minFrequency] = self.frequencyBuckets[self.minFrequency][1:];
                self.evictions = self.evictions + 1;
                
                while self.frequencyBuckets[self.minFrequency] != null and len(self.frequencyBuckets[self.minFrequency]) == 0 {
                    self.minFrequency = self.minFrequency + 1;
                }
            }
        }
    }

    _countValid() {
        let count = 0;
        for key in keys(self.cache) {
            if self.cache[key] != null {
                if not self.cache[key].isExpired(self._currentTime()) {
                    count = count + 1;
                }
            }
        }
        return count;
    }

    _currentTime() {
        return time.time();
    }

    stats() {
        let total = self.hits + self.misses;
        let hitRate = 0;
        if total > 0 {
            hitRate = self.hits / total;
        }
        return {
            "size": self.size(),
            "maxSize": self.maxSize,
            "hits": self.hits,
            "misses": self.misses,
            "hitRate": hitRate,
            "evictions": self.evictions,
            "minFrequency": self.minFrequency
        };
    }

    cleanup() {
        let currentTime = self._currentTime();
        let keysToRemove = [];
        
        for key in keys(self.cache) {
            if self.cache[key] != null {
                if self.cache[key].isExpired(currentTime) {
                    keysToRemove = keysToRemove + [key];
                }
            }
        }
        
        for key in keysToRemove {
            let entry = self.cache[key];
            if self.onEvict != null {
                self.onEvict(key, entry.value, CACHE_EXPIRE);
            }
            self._removeFromFrequencyBucket(key, entry.accessCount);
            self.cache[key] = null;
        }
        
        return len(keysToRemove);
    }
}

# ============================================================
# TTL Cache Implementation
# ============================================================

class TTLCache {
    init(defaultTTL, cleanupInterval, onExpire) {
        self.defaultTTL = defaultTTL;
        self.cleanupInterval = cleanupInterval;
        self.onExpire = onExpire;
        self.cache = {};
        self.lastCleanup = time.time();
        self.hits = 0;
        self.misses = 0;
        self.expirations = 0;
    }

    get(key) {
        self._maybeCleanup();
        
        if self.has(key) {
            let entry = self.cache[key];
            entry.touch(self._currentTime());
            self.hits = self.hits + 1;
            return entry.value;
        }
        self.misses = self.misses + 1;
        return null;
    }

    set(key, value, ttl) {
        let currentTime = self._currentTime();
        
        let ttlValue = ttl;
        if ttlValue <= 0 {
            ttlValue = self.defaultTTL;
        }
        
        let entry = CacheEntry(key, value, ttlValue, currentTime, 1, currentTime);
        self.cache[key] = entry;
    }

    has(key) {
        if self.cache[key] == null {
            return false;
        }
        let entry = self.cache[key];
        return not entry.isExpired(self._currentTime());
    }

    delete(key) {
        if self.cache[key] != null {
            let value = self.cache[key].value;
            self.cache[key] = null;
            return value;
        }
        return null;
    }

    clear() {
        self.cache = {};
    }

    size() {
        return self._countValid();
    }

    keys() {
        let result = [];
        for key in keys(self.cache) {
            if self.cache[key] != null {
                if not self.cache[key].isExpired(self._currentTime()) {
                    result = result + [key];
                }
            }
        }
        return result;
    }

    values() {
        let result = [];
        for key in keys(self.cache) {
            if self.cache[key] != null {
                if not self.cache[key].isExpired(self._currentTime()) {
                    result = result + [self.cache[key].value];
                }
            }
        }
        return result;
    }

    items() {
        let result = [];
        for key in keys(self.cache) {
            if self.cache[key] != null {
                if not self.cache[key].isExpired(self._currentTime()) {
                    result = result + [[key, self.cache[key].value]];
                }
            }
        }
        return result;
    }

    getTTL(key) {
        if self.cache[key] != null {
            return self.cache[key].getTimeToLive(self._currentTime());
        }
        return -1;
    }

    refresh(key) {
        if self.has(key) {
            let entry = self.cache[key];
            let currentTime = self._currentTime();
            entry.lastAccessed = currentTime;
            entry.expiresAt = currentTime + entry.ttl;
            return true;
        }
        return false;
    }

    _maybeCleanup() {
        let currentTime = self._currentTime();
        if currentTime - self.lastCleanup >= self.cleanupInterval {
            self.cleanup();
            self.lastCleanup = currentTime;
        }
    }

    _countValid() {
        let count = 0;
        for key in keys(self.cache) {
            if self.cache[key] != null {
                if not self.cache[key].isExpired(self._currentTime()) {
                    count = count + 1;
                }
            }
        }
        return count;
    }

    _currentTime() {
        return time.time();
    }

    stats() {
        let total = self.hits + self.misses;
        let hitRate = 0;
        if total > 0 {
            hitRate = self.hits / total;
        }
        return {
            "size": self.size(),
            "hits": self.hits,
            "misses": self.misses,
            "hitRate": hitRate,
            "expirations": self.expirations,
            "defaultTTL": self.defaultTTL,
            "cleanupInterval": self.cleanupInterval
        };
    }

    cleanup() {
        let currentTime = self._currentTime();
        let keysToRemove = [];
        
        for key in keys(self.cache) {
            if self.cache[key] != null {
                if self.cache[key].isExpired(currentTime) {
                    keysToRemove = keysToRemove + [key];
                }
            }
        }
        
        for key in keysToRemove {
            let entry = self.cache[key];
            if self.onExpire != null {
                self.onExpire(key, entry.value);
            }
            self.cache[key] = null;
            self.expirations = self.expirations + 1;
        }
        
        return len(keysToRemove);
    }
}

# ============================================================
# Two-Level Cache (Memory + Disk)
# ============================================================

class TwoLevelCache {
    init(memoryCache, diskCache) {
        self.memoryCache = memoryCache;
        self.diskCache = diskCache;
        self.hits = 0;
        self.misses = 0;
    }

    get(key) {
        # Try memory first
        let value = self.memoryCache.get(key);
        if value != null {
            self.hits = self.hits + 1;
            return value;
        }
        
        # Try disk cache
        if self.diskCache != null {
            value = self.diskCache.get(key);
            if value != null {
                # Promote to memory cache
                self.memoryCache.set(key, value);
                self.hits = self.hits + 1;
                return value;
            }
        }
        
        self.misses = self.misses + 1;
        return null;
    }

    set(key, value, ttl) {
        self.memoryCache.set(key, value, ttl);
        if self.diskCache != null {
            self.diskCache.set(key, value, ttl);
        }
    }

    has(key) {
        return self.memoryCache.has(key) or (self.diskCache != null and self.diskCache.has(key));
    }

    delete(key) {
        self.memoryCache.delete(key);
        if self.diskCache != null {
            return self.diskCache.delete(key);
        }
        return null;
    }

    clear() {
        self.memoryCache.clear();
        if self.diskCache != null {
            self.diskCache.clear();
        }
    }

    size() {
        return self.memoryCache.size() + (self.diskCache != null ? self.diskCache.size() : 0);
    }

    stats() {
        let total = self.hits + self.misses;
        let hitRate = 0;
        if total > 0 {
            hitRate = self.hits / total;
        }
        return {
            "memorySize": self.memoryCache.size(),
            "diskSize": self.diskCache != null ? self.diskCache.size() : 0,
            "totalSize": self.size(),
            "hits": self.hits,
            "misses": self.misses,
            "hitRate": hitRate
        };
    }
}

# ============================================================
# Cache Decorator / Wrapper
# ============================================================

class CacheDecorator {
    init(cache, keyGenerator) {
        self.cache = cache;
        self.keyGenerator = keyGenerator;
    }

    get(key) {
        let cacheKey = self._generateKey(key);
        return self.cache.get(cacheKey);
    }

    set(key, value, ttl) {
        let cacheKey = self._generateKey(key);
        self.cache.set(cacheKey, value, ttl);
    }

    _generateKey(key) {
        if self.keyGenerator != null {
            return self.keyGenerator(key);
        }
        if type(key) == "string" {
            return key;
        }
        return json.stringify(key);
    }
}

# ============================================================
# Distributed Cache (Redis-style) Mock
# ============================================================

class DistributedCache {
    init(nodes, replicationFactor, onNodeFail) {
        self.nodes = nodes;
        self.replicationFactor = replicationFactor;
        self.onNodeFail = onNodeFail;
        self.localCache = LRUCache(1000);
        self.primaryNodes = {};
    }

    get(key) {
        # Try local cache first
        let value = self.localCache.get(key);
        if value != null {
            return value;
        }
        
        # Get primary node for key
        let node = self._getNodeForKey(key);
        
        # In a real implementation, this would query the remote node
        # For now, return null (cache miss)
        return null;
    }

    set(key, value, ttl) {
        # Store locally
        self.localCache.set(key, value, ttl);
        
        # Get primary and replica nodes
        let nodes = self._getNodesForKey(key);
        
        # In a real implementation, this would replicate to all nodes
    }

    delete(key) {
        self.localCache.delete(key);
        let nodes = self._getNodesForKey(key);
        # In a real implementation, this would delete from all nodes
    }

    _getNodeForKey(key) {
        let hash = self._hash(key);
        return self.nodes[hash % len(self.nodes)];
    }

    _getNodesForKey(key) {
        let hash = self._hash(key);
        let result = [];
        for i in range(self.replicationFactor) {
            result = result + [self.nodes[(hash + i) % len(self.nodes)]];
        }
        return result;
    }

    _hash(key) {
        let str = type(key) == "string" ? key : json.stringify(key);
        let hash = 0;
        for i in range(len(str)) {
            let char = str[i];
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash;
        }
        return hash;
    }
}

# ============================================================
# Cache Factory
# ============================================================

class CacheFactory {
    static createLRUCache(maxSize, onEvict) {
        return LRUCache(maxSize, onEvict);
    }

    static createLFUCache(maxSize, onEvict) {
        return LFUCache(maxSize, onEvict);
    }

    static createTTLCache(defaultTTL, cleanupInterval, onExpire) {
        return TTLCache(defaultTTL, cleanupInterval, onExpire);
    }

    static createTwoLevelCache(memorySize, diskCache, ttl) {
        let memory = LRUCache(memorySize);
        return TwoLevelCache(memory, diskCache);
    }

    static createDistributedCache(nodes, replicationFactor) {
        return DistributedCache(nodes, replicationFactor, null);
    }

    static createCache(policy, options) {
        let maxSize = options["maxSize"] ?? DEFAULT_MAX_SIZE;
        let ttl = options["ttl"] ?? DEFAULT_TTL;
        let cleanupInterval = options["cleanupInterval"] ?? DEFAULT_CLEANUP_INTERVAL;
        let onEvict = options["onEvict"] ?? null;
        let onExpire = options["onExpire"] ?? null;
        
        if policy == LRU {
            return LRUCache(maxSize, onEvict);
        } else if policy == LFU {
            return LFUCache(maxSize, onEvict);
        } else if policy == TTL {
            return TTLCache(ttl, cleanupInterval, onExpire);
        } else if policy == FIFO {
            return LRUCache(maxSize, onEvict);  # FIFO behavior via LRU
        } else if policy == RANDOM {
            return LRUCache(maxSize, onEvict);  # Random behavior via LRU
        }
        
        return LRUCache(maxSize, onEvict);
    }
}

# ============================================================
# Cache Statistics Collector
# ============================================================

class CacheStatsCollector {
    init() {
        self.caches = {};
        self.globalHits = 0;
        self.globalMisses = 0;
        self.globalSets = 0;
        self.globalDeletes = 0;
        self.globalEvictions = 0;
    }

    registerCache(name, cache) {
        self.caches[name] = cache;
    }

    recordHit(cacheName) {
        self.globalHits = self.globalHits + 1;
    }

    recordMiss(cacheName) {
        self.globalMisses = self.globalMisses + 1;
    }

    recordSet(cacheName) {
        self.globalSets = self.globalSets + 1;
    }

    recordDelete(cacheName) {
        self.globalDeletes = self.globalDeletes + 1;
    }

    recordEviction(cacheName) {
        self.globalEvictions = self.globalEvictions + 1;
    }

    getStats() {
        let cacheStats = {};
        for name in keys(self.caches) {
            cacheStats[name] = self.caches[name].stats();
        }
        
        let total = self.globalHits + self.globalMisses;
        let hitRate = 0;
        if total > 0 {
            hitRate = self.globalHits / total;
        }
        
        return {
            "caches": cacheStats,
            "global": {
                "hits": self.globalHits,
                "misses": self.globalMisses,
                "sets": self.globalSets,
                "deletes": self.globalDeletes,
                "evictions": self.globalEvictions,
                "hitRate": hitRate,
                "totalRequests": total
            }
        };
    }

    reset() {
        self.globalHits = 0;
        self.globalMisses = 0;
        self.globalSets = 0;
        self.globalDeletes = 0;
        self.globalEvictions = 0;
    }
}

# ============================================================
# Memoization Helper
# ============================================================

class Memoizer {
    init(cache, keyGenerator) {
        self.cache = cache;
        self.keyGenerator = keyGenerator;
    }

    memoize(fn) {
        let memoizer = self;
        
        return fn(key) {
            let cacheKey = memoizer._generateKey(key);
            let result = memoizer.cache.get(cacheKey);
            
            if result != null {
                return result;
            }
            
            result = fn(key);
            memoizer.cache.set(cacheKey, result);
            return result;
        };
    }

    _generateKey(key) {
        if self.keyGenerator != null {
            return self.keyGenerator(key);
        }
        if type(key) == "string" {
            return key;
        }
        return json.stringify(key);
    }
}

# ============================================================
# Global Cache Manager
# ============================================================

let _globalCacheManager = CacheStatsCollector();

# ============================================================
# Utility Functions
# ============================================================

fn createCache(policy, options) {
    return CacheFactory.createCache(policy, options);
}

fn createLRUCache(maxSize) {
    return LRUCache(maxSize, null);
}

fn createLFUCache(maxSize) {
    return LFUCache(maxSize, null);
}

fn createTTLCache(ttl, cleanupInterval) {
    return TTLCache(ttl, cleanupInterval, null);
}

fn memoize(fn, cache) {
    let memoizer = Memoizer(cache, null);
    return memoizer.memoize(fn);
}

fn registerCache(name, cache) {
    _globalCacheManager.registerCache(name, cache);
}

fn getCacheStats() {
    return _globalCacheManager.getStats();
}

fn resetCacheStats() {
    _globalCacheManager.reset();
}

# ============================================================
# Cache Region (Scoped Cache)
# ============================================================

class CacheRegion {
    init(name, policy, options) {
        self.name = name;
        self.cache = createCache(policy, options);
        registerCache(name, self.cache);
    }

    get(key) {
        return self.cache.get(key);
    }

    set(key, value, ttl) {
        self.cache.set(key, value, ttl);
    }

    has(key) {
        return self.cache.has(key);
    }

    delete(key) {
        return self.cache.delete(key);
    }

    clear() {
        self.cache.clear();
    }

    size() {
        return self.cache.size();
    }

    stats() {
        return self.cache.stats();
    }
}

# ============================================================
# Export
# ============================================================

{
    "CacheEntry": CacheEntry,
    "LRUCache": LRUCache,
    "LFUCache": LFUCache,
    "TTLCache": TTLCache,
    "TwoLevelCache": TwoLevelCache,
    "DistributedCache": DistributedCache,
    "CacheDecorator": CacheDecorator,
    "CacheFactory": CacheFactory,
    "CacheStatsCollector": CacheStatsCollector,
    "Memoizer": Memoizer,
    "CacheRegion": CacheRegion,
    "createCache": createCache,
    "createLRUCache": createLRUCache,
    "createLFUCache": createLFUCache,
    "createTTLCache": createTTLCache,
    "memoize": memoize,
    "registerCache": registerCache,
    "getCacheStats": getCacheStats,
    "resetCacheStats": resetCacheStats,
    "LRU": LRU,
    "LFU": LFU,
    "FIFO": FIFO,
    "LIFO": LIFO,
    "TTL": TTL,
    "RANDOM": RANDOM,
    "CACHE_HIT": CACHE_HIT,
    "CACHE_MISS": CACHE_MISS,
    "CACHE_SET": CACHE_SET,
    "CACHE_DELETE": CACHE_DELETE,
    "CACHE_EXPIRE": CACHE_EXPIRE,
    "CACHE_EVICT": CACHE_EVICT,
    "CACHE_CLEAR": CACHE_CLEAR,
    "VERSION": VERSION
}
