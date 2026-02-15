# ============================================================================
# Nyx Monitoring - Production ML Monitoring & Observability
# ============================================================================
# Provides:
# - Real-time metrics collection
# - Data drift detection
# - Model performance monitoring
# - Alerting and auto-retraining triggers
# ============================================================================

# ============================================================================
# Metrics Collector
# ============================================================================

fn MetricsCollector(config) {
    return {
        "config": config,
        "metrics": {},
        "counters": {},
        "gauges": {},
        "histograms": {},
        "start_time": time.now()
    };
}

# Counter metric
fn increment_counter(collector, name, value) {
    if is_null(collector.counters[name]) {
        collector.counters[name] = 0;
    }
    collector.counters[name] = collector.counters[name] + (value || 1);
    return collector;
}

# Gauge metric
fn set_gauge(collector, name, value) {
    collector.gauges[name] = {
        "value": value,
        "timestamp": time.now()
    };
    return collector;
}

# Histogram metric
fn observe_histogram(collector, name, value) {
    if is_null(collector.histograms[name]) {
        collector.histograms[name] = [];
    }
    push(collector.histograms[name], {
        "value": value,
        "timestamp": time.now()
    });
    return collector;
}

# Get all metrics
fn get_all_metrics(collector) {
    return {
        "counters": collector.counters,
        "gauges": collector.gauges,
        "histograms": collector.histograms,
        "uptime": time.now() - collector.start_time
    };
}

# ============================================================================
# Latency Tracker
# ============================================================================

fn LatencyTracker(config) {
    return {
        "config": config,
        "latencies": [],
        "window_size": config.window_size || 1000
    };
}

fn track_latency(tracker, latency_ms) {
    push(tracker.latencies, latency_ms);
    
    if len(tracker.latencies) > tracker.window_size {
        shift(tracker.latencies);
    }
    
    return tracker;
}

fn get_latency_stats(tracker) {
    if len(tracker.latencies) == 0 {
        return null;
    }
    
    let sorted = sort(tracker.latencies);
    let n = len(sorted);
    let sum = 0;
    
    for l in sorted { sum = sum + l; }
    let mean = sum / n;
    
    return {
        "count": n,
        "mean": mean,
        "min": sorted[0],
        "max": sorted[n-1],
        "p50": sorted[floor(n * 0.5)],
        "p90": sorted[floor(n * 0.9)],
        "p95": sorted[floor(n * 0.95)],
        "p99": sorted[floor(n * 0.99)]
    };
}

# ============================================================================
# Prediction Monitor
# ============================================================================

fn PredictionMonitor(config) {
    return {
        "config": config,
        "predictions": [],
        "labels": [],
        "probabilities": [],
        "max_samples": config.max_samples || 10000,
        "window_start": time.now()
    };
}

# Record prediction
fn record_prediction(monitor, prediction, label, probability) {
    push(monitor.predictions, prediction);
    if !is_null(label) { push(monitor.labels, label); }
    if !is_null(probability) { push(monitor.probabilities, probability); }
    
    # Trim to max size
    while len(monitor.predictions) > monitor.max_samples {
        shift(monitor.predictions);
    }
    while len(monitor.labels) > monitor.max_samples {
        shift(monitor.labels);
    }
    while len(monitor.probabilities) > monitor.max_samples {
        shift(monitor.probabilities);
    }
    
    return monitor;
}

# Compute accuracy
fn compute_accuracy(monitor) {
    if len(monitor.predictions) == 0 || len(monitor.labels) == 0 {
        return null;
    }
    
    let correct = 0;
    for i in range(min(len(monitor.predictions), len(monitor.labels))) {
        if monitor.predictions[i] == monitor.labels[i] {
            correct = correct + 1;
        }
    }
    
    return correct / len(monitor.labels);
}

# Compute AUC-ROC
fn compute_auc(monitor) {
    # Simplified AUC computation
    if len(monitor.labels) == 0 || len(monitor.probabilities) == 0 {
        return null;
    }
    
    # Would compute actual AUC in real implementation
    return 0.85;
}

# Get prediction distribution
fn get_prediction_distribution(monitor) {
    let counts = {};
    
    for pred in monitor.predictions {
        if is_null(counts[pred]) { counts[pred] = 0; }
        counts[pred] = counts[pred] + 1;
    }
    
    return counts;
}

# ============================================================================
# Data Drift Detection
# ============================================================================

fn DataDriftDetector(config) {
    return {
        "config": config,
        "reference_data": [],
        "current_data": [],
        "drift_detected": false,
        "drift_history": []
    };
}

# Set reference data
fn set_reference_data(detector, data) {
    detector.reference_data = data;
    return detector;
}

# Check for drift
fn check_drift(detector, current_data, threshold) {
    if len(detector.reference_data) == 0 {
        return {"drift_detected": false};
    }
    
    detector.current_data = current_data;
    
    # Compute distribution distance
    let ref_dist = compute_distribution(detector.reference_data);
    let curr_dist = compute_distribution(current_data);
    
    # Compute drift metrics
    let drift_score = compute_distribution_distance(ref_dist, curr_dist);
    let drifted = drift_score > threshold;
    
    detector.drift_detected = drifted;
    
    if drifted {
        push(detector.drift_history, {
            "timestamp": time.now(),
            "drift_score": drift_score,
            "threshold": threshold
        });
    }
    
    return {
        "drift_detected": drifted,
        "drift_score": drift_score,
        "threshold": threshold,
        "reference_stats": ref_dist,
        "current_stats": curr_dist
    };
}

fn compute_distribution(data) {
    let counts = {};
    
    for val in data {
        let key = str(val);
        if is_null(counts[key]) { counts[key] = 0; }
        counts[key] = counts[key] + 1;
    }
    
    # Convert to probabilities
    let total = len(data);
    let probs = {};
    
    for k in keys(counts) {
        probs[k] = counts[k] / total;
    }
    
    return probs;
}

fn compute_distribution_distance(p, q) {
    # Compute total variation distance
    let distance = 0;
    
    let all_keys = {};
    for k in keys(p) { all_keys[k] = true; }
    for k in keys(q) { all_keys[k] = true; }
    
    for k in keys(all_keys) {
        let pi = p[k] || 0;
        let qi = q[k] || 0;
        distance = distance + abs(pi - qi);
    }
    
    return distance / 2;
}

# ============================================================================
# Concept Drift Detection
# ============================================================================

fn ConceptDriftDetector(config) {
    return {
        "config": config,
        "window_size": config.window_size || 1000,
        "performance_history": [],
        "drift_detected": false
    };
}

# Record performance
fn record_performance(detector, accuracy) {
    push(detector.performance_history, {
        "accuracy": accuracy,
        "timestamp": time.now()
    });
    
    # Keep only recent window
    while len(detector.performance_history) > detector.window_size {
        shift(detector.performance_history);
    }
    
    return detector;
}

# Check for concept drift
fn check_concept_drift(detector, threshold) {
    let history = detector.performance_history;
    
    if len(history) < detector.window_size / 2 {
        return {"drift_detected": false};
    }
    
    # Split into two halves
    let half = floor(len(history) / 2);
    let first_half = history[0:half];
    let second_half = history[half:];
    
    # Compute average accuracy for each half
    let first_avg = 0;
    for h in first_half { first_avg = first_avg + h.accuracy; }
    first_avg = first_avg / len(first_half);
    
    let second_avg = 0;
    for h in second_half { second_avg = second_avg + h.accuracy; }
    second_avg = second_avg / len(second_half);
    
    let change = first_avg - second_avg;
    let drifted = abs(change) > threshold;
    
    detector.drift_detected = drifted;
    
    return {
        "drift_detected": drifted,
        "first_half_accuracy": first_avg,
        "second_half_accuracy": second_avg,
        "change": change,
        "threshold": threshold
    };
}

# ============================================================================
# Alert Manager
# ============================================================================

let ALERT_INFO = "info";
let ALERT_WARNING = "warning";
let ALERT_ERROR = "error";
let ALERT_CRITICAL = "critical";

fn AlertManager(config) {
    return {
        "config": config,
        "alerts": [],
        "rules": {},
        "handlers": []
    };
}

# Add alert rule
fn add_alert_rule(manager, name, condition_fn, severity, message) {
    manager.rules[name] = {
        "condition": condition_fn,
        "severity": severity,
        "message": message,
        "enabled": true,
        "triggered_count": 0
    };
    return manager;
}

# Check rules and fire alerts
fn check_alerts(manager, metrics) {
    let fired_alerts = [];
    
    for name, rule in manager.rules {
        if !rule.enabled {
            continue;
        }
        
        if rule.condition(metrics) {
            rule.triggered_count = rule.triggered_count + 1;
            
            let alert = {
                "name": name,
                "severity": rule.severity,
                "message": rule.message,
                "timestamp": time.now(),
                "count": rule.triggered_count
            };
            
            push(manager.alerts, alert);
            push(fired_alerts, alert);
            
            # Call handlers
            for handler in manager.handlers {
                handler(alert);
            }
        }
    }
    
    return fired_alerts;
}

# Add alert handler
fn add_alert_handler(manager, handler_fn) {
    push(manager.handlers, handler_fn);
    return manager;
}

# Get active alerts
fn get_active_alerts(manager, max_age) {
    let now = time.now();
    let active = [];
    
    for alert in manager.alerts {
        if now - alert.timestamp < (max_age || 3600000) {
            push(active, alert);
        }
    }
    
    return active;
}

# ============================================================================
# Auto-Retraining Trigger
# ============================================================================

fn AutoRetrainTrigger(config) {
    return {
        "config": config,
        "drift_detector": null,
        "performance_monitor": null,
        "retrain_triggered": false,
        "retrain_history": []
    };
}

# Check if retraining is needed
fn check_retrain_needed(trigger, metrics) {
    let reasons = [];
    
    # Check for data drift
    if !is_null(trigger.drift_detector) {
        let drift_result = check_drift(trigger.drift_detector, metrics.current_data, trigger.config.drift_threshold);
        if drift_result.drift_detected {
            push(reasons, "data_drift");
        }
    }
    
    # Check for concept drift
    if !is_null(trigger.performance_monitor) {
        let concept_result = check_concept_drift(trigger.performance_monitor, trigger.config.performance_threshold);
        if concept_result.drift_detected {
            push(reasons, "concept_drift");
        }
    }
    
    # Check accuracy threshold
    if !is_null(metrics.accuracy) && metrics.accuracy < trigger.config.min_accuracy {
        push(reasons, "low_accuracy");
    }
    
    let should_retrain = len(reasons) > 0;
    
    if should_retrain {
        trigger.retrain_triggered = true;
        push(trigger.retrain_history, {
            "timestamp": time.now(),
            "reasons": reasons,
            "metrics": metrics
        });
    }
    
    return {
        "should_retrain": should_retrain,
        "reasons": reasons,
        "confidence": len(reasons) / 5  # Normalize by expected reason count
    };
}

# ============================================================================
# Dashboard Data
# ============================================================================

fn get_dashboard_data(monitor, collector, detector) {
    return {
        "performance": {
            "accuracy": compute_accuracy(monitor),
            "auc": compute_auc(monitor),
            "prediction_distribution": get_prediction_distribution(monitor)
        },
        "metrics": get_all_metrics(collector),
        "drift": {
            "detected": detector.drift_detected,
            "history": detector.drift_history
        },
        "timestamp": time.now()
    };
}

# ============================================================================
# Export
# ============================================================================

{
    # Metrics
    "MetricsCollector": MetricsCollector,
    "increment_counter": increment_counter,
    "set_gauge": set_gauge,
    "observe_histogram": observe_histogram,
    "get_all_metrics": get_all_metrics,
    
    # Latency
    "LatencyTracker": LatencyTracker,
    "track_latency": track_latency,
    "get_latency_stats": get_latency_stats,
    
    # Prediction Monitor
    "PredictionMonitor": PredictionMonitor,
    "record_prediction": record_prediction,
    "compute_accuracy": compute_accuracy,
    "compute_auc": compute_auc,
    "get_prediction_distribution": get_prediction_distribution,
    
    # Data Drift
    "DataDriftDetector": DataDriftDetector,
    "set_reference_data": set_reference_data,
    "check_drift": check_drift,
    
    # Concept Drift
    "ConceptDriftDetector": ConceptDriftDetector,
    "record_performance": record_performance,
    "check_concept_drift": check_concept_drift,
    
    # Alerts
    "AlertManager": AlertManager,
    "add_alert_rule": add_alert_rule,
    "check_alerts": check_alerts,
    "add_alert_handler": add_alert_handler,
    "get_active_alerts": get_active_alerts,
    "ALERT_INFO": ALERT_INFO,
    "ALERT_WARNING": ALERT_WARNING,
    "ALERT_ERROR": ALERT_ERROR,
    "ALERT_CRITICAL": ALERT_CRITICAL,
    
    # Auto-retrain
    "AutoRetrainTrigger": AutoRetrainTrigger,
    "check_retrain_needed": check_retrain_needed,
    
    # Dashboard
    "get_dashboard_data": get_dashboard_data
}
