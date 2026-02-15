# ============================================================================
# Nyx Feature Store - Production ML Feature Infrastructure
# ============================================================================
# Feature stores ensure:
# - Reusable features defined once
# - Consistent transformations in training & inference
# - Low-latency serving for real-time prediction
# - Point-in-time correctness
# - Feature versioning and lineage
# ============================================================================

# ============================================================================
# Feature Schema DSL
# ============================================================================

# Feature types
let FEATURE_TYPE_FLOAT = "float";
let FEATURE_TYPE_INT = "int";
let FEATURE_TYPE_STRING = "string";
let FEATURE_TYPE_BOOL = "bool";
let FEATURE_TYPE_TIMESTAMP = "timestamp";
let FEATURE_TYPE_FLOAT_LIST = "float_list";
let FEATURE_TYPE_INT_LIST = "int_list";

# Feature modes
let FEATURE_MODE_ONLINE = "online";
let FEATURE_MODE_OFFLINE = "offline";
let FEATURE_MODE_BOTH = "both";

# Create a feature schema
fn FeatureSchema(name, ftype, mode, description, default) {
    return {
        "name": name,
        "type": ftype,
        "mode": mode,
        "description": description,
        "default": default,
        "version": 1,
        "created_at": time.now(),
        "transforms": []
    };
}

# Define a feature with transformations
fn Feature(name, ftype, description, transforms, default) {
    let schema = FeatureSchema(name, ftype, FEATURE_MODE_BOTH, description, default);
    schema.transforms = transforms;
    return schema;
}

# Create feature group
fn FeatureGroup(name, features, description, ttl) {
    return {
        "name": name,
        "features": features,
        "description": description,
        "ttl": ttl,  # Time-to-live in seconds
        "version": 1,
        "created_at": time.now(),
        "online_enabled": true,
        "offline_enabled": true,
        "statistics": {}
    };
}

# ============================================================================
# Feature Transformation Functions
# ============================================================================

# Standard transformations
let TRANSFORM_STANDARDIZE = "standardize";
let TRANSFORM_NORMALIZE = "normalize";
let TRANSFORM_ONE_HOT = "one_hot";
let TRANSFORM_LABEL_ENCODE = "label_encode";
let TRANSFORM_BUCKETIZE = "bucketize";
let TRANSFORM_LOG = "log";
let TRANSFORM_SQRT = "sqrt";
let TRANSFORM_CLIP = "clip";
let TRANSFORM_IMPUTE_MEAN = "impute_mean";
let TRANSFORM_IMPUTE_MEDIAN = "impute_median";
let TRANSFORM_IMPUTE_MODE = "impute_mode";
let TRANSFORM_IMPUTE_CONSTANT = "impute_constant";

fn standardize(value, mean, std) {
    return (value - mean) / std;
}

fn normalize(value, min_val, max_val) {
    return (value - min_val) / (max_val - min_val);
}

fn bucketize(value, boundaries) {
    for i in range(len(boundaries) - 1) {
        if value >= boundaries[i] && value < boundaries[i + 1] {
            return i;
        }
    }
    return len(boundaries) - 1;
}

fn clip(value, min_val, max_val) {
    if value < min_val { return min_val; }
    if value > max_val { return max_val; }
    return value;
}

# ============================================================================
# Point-in-Time Correctness
# ============================================================================

# Get feature value at specific timestamp
fn get_feature_at_time(features, entity_id, feature_name, timestamp) {
    # Filter features for entity at or before timestamp
    let entity_features = features[entity_id];
    if is_null(entity_features) {
        return null;
    }
    
    # Find most recent value at or before timestamp
    let result = null;
    let result_time = 0;
    
    for feature in entity_features {
        if feature.name == feature_name && feature.timestamp <= timestamp {
            if feature.timestamp > result_time {
                result = feature.value;
                result_time = feature.timestamp;
            }
        }
    }
    
    return result;
}

# Validate point-in-time correctness
fn validate_pit_correctness(features, entity_id, timestamp, features_needed) {
    let missing = [];
    for fname in features_needed {
        let value = get_feature_at_time(features, entity_id, fname, timestamp);
        if is_null(value) {
            push(missing, fname);
        }
    }
    return {
        "valid": len(missing) == 0,
        "missing_features": missing
    };
}

# ============================================================================
# Feature Store Implementation
# ============================================================================

fn FeatureStore(name, description) {
    return {
        "name": name,
        "description": description,
        "feature_groups": {},
        "entities": {},
        "versions": {},
        "online_stores": {},
        "offline_stores": {},
        "created_at": time.now()
    };
}

# Register feature group
fn register_feature_group(store, group) {
    store.feature_groups[group.name] = group;
    return store;
}

# Get feature group
fn get_feature_group(store, name) {
    return store.feature_groups[name];
}

# Compute features for entity
fn compute_features(store, entity_id, group_name, params) {
    let group = store.feature_groups[group_name];
    if is_null(group) {
        return null;
    }
    
    let computed = {};
    for feature in group.features {
        let value = compute_feature_value(feature, params);
        computed[feature.name] = value;
    }
    
    return computed;
}

fn compute_feature_value(feature, params) {
    let value = params[feature.name];
    
    # Apply default if null
    if is_null(value) {
        value = feature.default;
    }
    
    # Apply transformations
    for transform in feature.transforms {
        value = apply_transform(value, transform);
    }
    
    return value;
}

fn apply_transform(value, transform) {
    if is_null(value) {
        return value;
    }
    
    let ttype = transform.type;
    
    if ttype == TRANSFORM_STANDARDIZE {
        return (value - transform.mean) / transform.std;
    }
    if ttype == TRANSFORM_NORMALIZE {
        return (value - transform.min) / (transform.max - transform.min);
    }
    if ttype == TRANSFORM_CLIP {
        return clip(value, transform.min, transform.max);
    }
    if ttype == TRANSFORM_LOG {
        return log(value + 1);
    }
    if ttype == TRANSFORM_SQRT {
        return sqrt(abs(value));
    }
    
    return value;
}

# ============================================================================
# Online Feature Serving
# ============================================================================

fn OnlineFeatureServer(store) {
    return {
        "store": store,
        "cache": {},
        "cache_ttl": 300,  # 5 minutes
        "requests": 0,
        "hits": 0,
        "misses": 0
    };
}

# Get online feature
fn get_online_feature(server, entity_id, feature_name) {
    server.requests = server.requests + 1;
    
    let cache_key = entity_id + ":" + feature_name;
    
    # Check cache
    if !is_null(server.cache[cache_key]) {
        server.hits = server.hits + 1;
        return server.cache[cache_key];
    }
    
    server.misses = server.misses + 1;
    
    # Fetch from store (simulated)
    let value = null;
    
    # Cache result
    server.cache[cache_key] = value;
    
    return value;
}

# Get multiple features at once
fn get_online_features(server, entity_id, feature_names) {
    let result = {};
    for fname in feature_names {
        result[fname] = get_online_feature(server, entity_id, fname);
    }
    return result;
}

# Get cache statistics
fn get_cache_stats(server) {
    let hit_rate = 0;
    if server.requests > 0 {
        hit_rate = server.hits / server.requests;
    }
    
    return {
        "requests": server.requests,
        "hits": server.hits,
        "misses": server.misses,
        "hit_rate": hit_rate,
        "cache_size": len(server.cache)
    };
}

# Clear cache
fn clear_cache(server) {
    server.cache = {};
    return server;
}

# ============================================================================
# Offline Feature Retrieval (for training)
# ============================================================================

fn get_offline_features(store, entity_ids, feature_names, start_time, end_time) {
    let results = [];
    
    for entity_id in entity_ids {
        let entity_data = {
            "entity_id": entity_id,
            "features": {}
        };
        
        for fname in feature_names {
            # Get time-series feature values
            let values = get_historical_values(store, entity_id, fname, start_time, end_time);
            entity_data.features[fname] = values;
        }
        
        push(results, entity_data);
    }
    
    return results;
}

fn get_historical_values(store, entity_id, feature_name, start_time, end_time) {
    # Simulated historical retrieval
    # In production, this would query offline store (e.g., Spark, BigQuery)
    return [];
}

# ============================================================================
# Feature Drift Detection
# ============================================================================

fn compute_feature_statistics(values) {
    if len(values) == 0 {
        return null;
    }
    
    let sum_val = 0;
    let min_val = values[0];
    let max_val = values[0];
    
    for v in values {
        sum_val = sum_val + v;
        if v < min_val { min_val = v; }
        if v > max_val { max_val = v; }
    }
    
    let mean = sum_val / len(values);
    
    # Compute variance
    let variance = 0;
    for v in values {
        variance = variance + (v - mean) ^ 2;
    }
    variance = variance / len(values);
    
    return {
        "mean": mean,
        "std": sqrt(variance),
        "min": min_val,
        "max": max_val,
        "count": len(values),
        "median": compute_median(values),
        "p25": compute_percentile(values, 25),
        "p75": compute_percentile(values, 75)
    };
}

fn compute_median(values) {
    # Simple median computation
    let sorted = sort(values);
    let n = len(sorted);
    if n % 2 == 0 {
        return (sorted[n/2 - 1] + sorted[n/2]) / 2;
    }
    return sorted[n/2];
}

fn compute_percentile(values, p) {
    let sorted = sort(values);
    let idx = (p / 100) * (len(sorted) - 1);
    let lower = floor(idx);
    let upper = ceil(idx);
    let frac = idx - lower;
    
    return sorted[lower] * (1 - frac) + sorted[upper] * frac;
}

# Detect feature drift
fn detect_drift(current_stats, reference_stats, threshold) {
    # Compute drift metrics
    let mean_drift = abs(current_stats.mean - reference_stats.mean) / (reference_stats.std + 0.0001);
    let std_drift = abs(current_stats.std - reference_stats.std) / (reference_stats.std + 0.0001);
    let dist_drift = sqrt(mean_drift ^ 2 + std_drift ^ 2);
    
    let drifted = dist_drift > threshold;
    
    return {
        "drifted": drifted,
        "mean_drift": mean_drift,
        "std_drift": std_drift,
        "total_drift": dist_drift,
        "threshold": threshold,
        "current_stats": current_stats,
        "reference_stats": reference_stats
    };
}

# ============================================================================
# Vector Store for Embeddings
# ============================================================================

fn VectorStore(name, dimension, metric) {
    return {
        "name": name,
        "dimension": dimension,
        "metric": metric,  # "cosine", "euclidean", "dot"
        "vectors": {},
        "metadata": {},
        "index": null
    };
}

# Add vector
fn add_vector(store, id, vector, metadata) {
    if len(vector) != store.dimension {
        return null;
    }
    
    store.vectors[id] = vector;
    store.metadata[id] = metadata;
    
    return true;
}

# Search vectors
fn search_vectors(store, query_vector, top_k) {
    let scores = [];
    
    for id, vector in store.vectors {
        let score = compute_similarity(query_vector, vector, store.metric);
        push(scores, {"id": id, "score": score, "metadata": store.metadata[id]});
    }
    
    # Sort by score descending
    scores = sort_by(scores, fn(x) { -x.score; });
    
    # Return top k
    return scores[0:min(top_k, len(scores))];
}

fn compute_similarity(a, b, metric) {
    if metric == "cosine" {
        return cosine_similarity(a, b);
    }
    if metric == "euclidean" {
        return -euclidean_distance(a, b);  # Negative for sorting
    }
    if metric == "dot" {
        return dot_product(a, b);
    }
    return 0;
}

fn cosine_similarity(a, b) {
    let dot = dot_product(a, b);
    let norm_a = sqrt(dot_product(a, a));
    let norm_b = sqrt(dot_product(b, b));
    
    if norm_a == 0 || norm_b == 0 {
        return 0;
    }
    
    return dot / (norm_a * norm_b);
}

fn euclidean_distance(a, b) {
    let sum = 0;
    for i in range(len(a)) {
        sum = sum + (a[i] - b[i]) ^ 2;
    }
    return sqrt(sum);
}

fn dot_product(a, b) {
    let sum = 0;
    for i in range(len(a)) {
        sum = sum + a[i] * b[i];
    }
    return sum;
}

# ============================================================================
# Feature Lineage Tracking
# ============================================================================

fn FeatureLineage() {
    return {
        "features": {},
        "dependencies": {},
        "transformations": {}
    };
}

fn track_feature(lineage, feature_name, source_features, transformation) {
    lineage.features[feature_name] = {
        "created_at": time.now(),
        "sources": source_features,
        "transformation": transformation
    };
    
    # Track dependencies
    for src in source_features {
        if is_null(lineage.dependencies[src]) {
            lineage.dependencies[src] = [];
        }
        push(lineage.dependencies[src], feature_name);
    }
    
    return lineage;
}

fn get_feature_dependencies(lineage, feature_name) {
    return lineage.dependencies[feature_name] || [];
}

fn get_upstream_features(lineage, feature_name) {
    let visited = {};
    let queue = [feature_name];
    
    while len(queue) > 0 {
        let current = pop(queue);
        if !is_null(visited[current]) {
            continue;
        }
        visited[current] = true;
        
        let feature = lineage.features[current];
        if !is_null(feature) {
            for src in feature.sources {
                push(queue, src);
            }
        }
    }
    
    # Remove self
    delete(visited, feature_name);
    
    return keys(visited);
}

# ============================================================================
# Feature Versioning
# ============================================================================

fn create_feature_version(store, feature_name, new_schema) {
    let version_key = feature_name + ":" + str(new_schema.version);
    
    store.versions[version_key] = {
        "schema": new_schema,
        "created_at": time.now(),
        "active": false
    };
    
    return store.versions[version_key];
}

fn activate_feature_version(store, feature_name, version) {
    let version_key = feature_name + ":" + str(version);
    
    if !is_null(store.versions[version_key]) {
        store.versions[version_key].active = true;
    }
    
    return store;
}

# ============================================================================
# Example Usage
# ============================================================================

# Create a feature store for user features
let user_store = FeatureStore("user_features", "User behavior features");

# Define user features
let user_age = Feature("user_age", FEATURE_TYPE_INT, "User age", 
    [{"type": TRANSFORM_CLIP, "min": 18, "max": 100}], 18);
let user_income = Feature("user_income", FEATURE_TYPE_FLOAT, "Annual income",
    [{"type": TRANSFORM_LOG}, {"type": TRANSFORM_STANDARDIZE, "mean": 50000, "std": 25000}], 0);
let user_credit_score = Feature("credit_score", FEATURE_TYPE_INT, "Credit score",
    [{"type": TRANSFORM_NORMALIZE, "min": 300, "max": 850}], 650);

# Create feature group
let user_group = FeatureGroup("user_demographics", 
    [user_age, user_income, user_credit_score],
    "User demographic features",
    86400);  # 24 hour TTL

# Register group
register_feature_group(user_store, user_group);

# Create online server
let online_server = OnlineFeatureServer(user_store);

# Example: Get online features
# let features = get_online_features(online_server, "user_123", ["user_age", "user_income"]);

# ============================================================================
# Export public API
# ============================================================================

{
    # Types
    "FEATURE_TYPE_FLOAT": FEATURE_TYPE_FLOAT,
    "FEATURE_TYPE_INT": FEATURE_TYPE_INT,
    "FEATURE_TYPE_STRING": FEATURE_TYPE_STRING,
    "FEATURE_TYPE_BOOL": FEATURE_TYPE_BOOL,
    "FEATURE_TYPE_TIMESTAMP": FEATURE_TYPE_TIMESTAMP,
    
    # Transforms
    "TRANSFORM_STANDARDIZE": TRANSFORM_STANDARDIZE,
    "TRANSFORM_NORMALIZE": TRANSFORM_NORMALIZE,
    "TRANSFORM_CLIP": TRANSFORM_CLIP,
    "TRANSFORM_LOG": TRANSFORM_LOG,
    "TRANSFORM_SQRT": TRANSFORM_SQRT,
    
    # Core functions
    "Feature": Feature,
    "FeatureGroup": FeatureGroup,
    "FeatureStore": FeatureStore,
    "register_feature_group": register_feature_group,
    "get_feature_group": get_feature_group,
    "compute_features": compute_features,
    
    # Online serving
    "OnlineFeatureServer": OnlineFeatureServer,
    "get_online_feature": get_online_feature,
    "get_online_features": get_online_features,
    "get_cache_stats": get_cache_stats,
    "clear_cache": clear_cache,
    
    # Offline retrieval
    "get_offline_features": get_offline_features,
    
    # Point-in-time
    "get_feature_at_time": get_feature_at_time,
    "validate_pit_correctness": validate_pit_correctness,
    
    # Drift detection
    "compute_feature_statistics": compute_feature_statistics,
    "detect_drift": detect_drift,
    
    # Vector store
    "VectorStore": VectorStore,
    "add_vector": add_vector,
    "search_vectors": search_vectors,
    
    # Lineage
    "FeatureLineage": FeatureLineage,
    "track_feature": track_feature,
    "get_feature_dependencies": get_feature_dependencies,
    "get_upstream_features": get_upstream_features,
    
    # Versioning
    "create_feature_version": create_feature_version,
    "activate_feature_version": activate_feature_version
}
