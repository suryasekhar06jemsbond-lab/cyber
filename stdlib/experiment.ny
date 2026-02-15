# ============================================================================
# Nyx Experiment Tracking - ML Experiment Management
# ============================================================================
# Provides:
# - Experiment versioning and metadata
# - Metrics logging and visualization
# - Artifact storage
# - Comparison and analysis tools
# ============================================================================

# ============================================================================
# Experiment Management
# ============================================================================

fn Experiment(name, description) {
    return {
        "id": generate_experiment_id(),
        "name": name,
        "description": description,
        "status": "running",
        "start_time": time.now(),
        "end_time": null,
        "params": {},
        "metrics": {},
        "artifacts": {},
        "tags": [],
        "notes": "",
        "parent_id": null,
        "git_hash": null,
        "environment": {}
    };
}

fn generate_experiment_id() {
    # Simplified ID generation
    return "exp_" + str(time.now());
}

# Set experiment parameters
fn set_params(exp, params) {
    exp.params = params;
    return exp;
}

# Add tags
fn add_tag(exp, tag) {
    push(exp.tags, tag);
    return exp;
}

# Set status
fn set_status(exp, status) {
    exp.status = status;
    if status == "completed" || status == "failed" {
        exp.end_time = time.now();
    }
    return exp;
}

# Log metric
fn log_metric(exp, metric_name, value, step) {
    if is_null(exp.metrics[metric_name]) {
        exp.metrics[metric_name] = [];
    }
    
    push(exp.metrics[metric_name], {
        "value": value,
        "step": step || len(exp.metrics[metric_name]),
        "timestamp": time.now()
    });
    
    return exp;
}

# Log metrics
fn log_metrics(exp, metrics, step) {
    for name in keys(metrics) {
        log_metric(exp, name, metrics[name], step);
    }
    return exp;
}

# Add artifact
fn log_artifact(exp, name, path, artifact_type) {
    exp.artifacts[name] = {
        "path": path,
        "type": artifact_type || "file",
        "timestamp": time.now(),
        "size": 0
    };
    return exp;
}

# Add note
fn add_note(exp, note) {
    exp.notes = exp.notes + "\n" + "[" + str(time.now()) + "] " + note;
    return exp;
}

# ============================================================================
# Experiment Tracker
# ============================================================================

fn ExperimentTracker(storage_dir) {
    return {
        "storage_dir": storage_dir,
        "experiments": {},
        "current_experiment": null,
        "runs": []
    };
}

# Start new experiment
fn start_experiment(tracker, name, description, params) {
    let exp = Experiment(name, description);
    
    if !is_null(params) {
        set_params(exp, params);
    }
    
    tracker.current_experiment = exp;
    tracker.experiments[exp.id] = exp;
    
    return exp;
}

# Log to current experiment
fn log(tracker, metric_name, value, step) {
    if !is_null(tracker.current_experiment) {
        log_metric(tracker.current_experiment, metric_name, value, step);
    }
    return tracker;
}

# Log metrics
fn log_params(tracker, params) {
    if !is_null(tracker.current_experiment) {
        set_params(tracker.current_experiment, params);
    }
    return tracker;
}

# End experiment
fn end_experiment(tracker, status) {
    if !is_null(tracker.current_experiment) {
        set_status(tracker.current_experiment, status || "completed");
    }
    return tracker;
}

# Get experiment
fn get_experiment(tracker, exp_id) {
    return tracker.experiments[exp_id];
}

# List experiments
fn list_experiments(tracker, filters) {
    let results = [];
    
    for id, exp in tracker.experiments {
        let match = true;
        
        if !is_null(filters.name) {
            match = match && exp.name == filters.name;
        }
        if !is_null(filters.status) {
            match = match && exp.status == filters.status;
        }
        if !is_null(filters.tag) {
            match = match && contains(exp.tags, filters.tag);
        }
        
        if match {
            push(results, exp);
        }
    }
    
    return results;
}

# ============================================================================
# Metrics Analysis
# ============================================================================

# Get metric history
fn get_metric_history(exp, metric_name) {
    return exp.metrics[metric_name] || [];
}

# Get best metric value
fn get_best_metric(exp, metric_name, mode) {
    let history = get_metric_history(exp, metric_name);
    if len(history) == 0 {
        return null;
    }
    
    let best = history[0];
    
    for entry in history {
        if mode == "max" {
            if entry.value > best.value {
                best = entry;
            }
        }
        if mode == "min" {
            if entry.value < best.value {
                best = entry;
            }
        }
    }
    
    return best;
}

# Compute metric statistics
fn compute_metric_stats(exp, metric_name) {
    let history = get_metric_history(exp, metric_name);
    if len(history) == 0 {
        return null;
    }
    
    let values = [entry.value for entry in history];
    
    return compute_statistics(values);
}

fn compute_statistics(values) {
    let n = len(values);
    if n == 0 { return null; }
    
    let sum_val = 0;
    for v in values { sum_val = sum_val + v; }
    let mean = sum_val / n;
    
    let variance = 0;
    for v in values { variance = variance + (v - mean) ^ 2; }
    variance = variance / n;
    
    let sorted = sort(values);
    let median = sorted[floor(n/2)];
    
    return {
        "count": n,
        "mean": mean,
        "std": sqrt(variance),
        "min": sorted[0],
        "max": sorted[n-1],
        "median": median,
        "p25": sorted[floor(n * 0.25)],
        "p75": sorted[floor(n * 0.75)]
    };
}

# ============================================================================
# Experiment Comparison
# ============================================================================

# Compare multiple experiments
fn compare_experiments(experiments, metrics_to_compare) {
    let comparison = {
        "experiments": [exp.id for exp in experiments],
        "metrics": {}
    };
    
    for metric_name in metrics_to_compare {
        let metric_data = [];
        
        for exp in experiments {
            let stats = compute_metric_stats(exp, metric_name);
            push(metric_data, {
                "exp_id": exp.id,
                "exp_name": exp.name,
                "stats": stats,
                "best": get_best_metric(exp, metric_name, "max")
            });
        }
        
        comparison.metrics[metric_name] = metric_data;
    }
    
    return comparison;
}

# Compute experiment similarity
fn compute_similarity(exp1, exp2) {
    # Compare parameter overlap
    let common_params = 0;
    let total_params = len(exp1.params);
    
    for p in keys(exp1.params) {
        if exp1.params[p] == exp2.params[p] {
            common_params = common_params + 1;
        }
    }
    
    let param_similarity = common_params / total_params;
    
    # Compare metrics correlation (simplified)
    let metric_correlation = 0;
    let common_metrics = 0;
    
    for m in keys(exp1.metrics) {
        if !is_null(exp2.metrics[m]) {
            common_metrics = common_metrics + 1;
        }
    }
    
    return {
        "param_similarity": param_similarity,
        "metric_overlap": common_metrics / max(len(exp1.metrics), len(exp2.metrics)),
        "common_params": common_params,
        "common_metrics": common_metrics
    };
}

# ============================================================================
# Visualization Data
# ============================================================================

# Get metrics for plotting
fn get_plot_data(exp, metric_name) {
    let history = get_metric_history(exp, metric_name);
    
    return {
        "x": [entry.step for entry in history],
        "y": [entry.value for entry in history],
        "name": exp.name,
        "metric": metric_name
    };
}

# Get all metrics for parallel coordinates plot
fn get_parallel_coords_data(experiments) {
    let params = {};
    
    for exp in experiments {
        for p in keys(exp.params) {
            params[p] = true;
        }
    }
    
    let data = [];
    
    for exp in experiments {
        let row = {"experiment": exp.name};
        for p in keys(params) {
            row[p] = exp.params[p];
        }
        push(data, row);
    }
    
    return {
        "dimensions": keys(params),
        "data": data
    };
}

# ============================================================================
# Artifact Management
# ============================================================================

# List artifacts
fn list_artifacts(exp) {
    return keys(exp.artifacts);
}

# Get artifact info
fn get_artifact(exp, artifact_name) {
    return exp.artifacts[artifact_name];
}

# Download artifact (placeholder)
fn download_artifact(exp, artifact_name, destination) {
    let artifact = get_artifact(exp, artifact_name);
    if is_null(artifact) {
        return null;
    }
    
    # Would download in real implementation
    return destination + "/" + artifact.path;
}

# ============================================================================
# Run Comparison Dashboard
# ============================================================================

fn create_dashboard(tracker, experiments, config) {
    return {
        "title": config.title || "Experiment Dashboard",
        "experiments": [exp.id for exp in experiments],
        "metrics": config.metrics || [],
        "created_at": time.now(),
        "filters": config.filters || {},
        "comparisons": compare_experiments(experiments, config.metrics || [])
    };
}

# ============================================================================
# Auto-logging Hooks
# ============================================================================

fn create_auto_logger(tracker, config) {
    return {
        "tracker": tracker,
        "log_interval": config.log_interval || 100,
        "save_artifacts": config.save_artifacts || true,
        "capture_git": config.capture_git || false,
        "capture_env": config.capture_env || true
    };
}

fn auto_log_metrics(auto_logger, step, metrics) {
    log(auto_logger.tracker, "step", step, step);
    
    for name in keys(metrics) {
        log(auto_logger.tracker, name, metrics[name], step);
    }
}

fn auto_save_checkpoint(auto_logger, model, step) {
    if auto_logger.save_artifacts {
        # Would save model checkpoint
    }
}

# ============================================================================
# Export
# ============================================================================

{
    # Experiment
    "Experiment": Experiment,
    "set_params": set_params,
    "add_tag": add_tag,
    "set_status": set_status,
    "log_metric": log_metric,
    "log_metrics": log_metrics,
    "log_artifact": log_artifact,
    "add_note": add_note,
    
    # Tracker
    "ExperimentTracker": ExperimentTracker,
    "start_experiment": start_experiment,
    "log": log,
    "log_params": log_params,
    "end_experiment": end_experiment,
    "get_experiment": get_experiment,
    "list_experiments": list_experiments,
    
    # Analysis
    "get_metric_history": get_metric_history,
    "get_best_metric": get_best_metric,
    "compute_metric_stats": compute_metric_stats,
    "compare_experiments": compare_experiments,
    "compute_similarity": compute_similarity,
    
    # Visualization
    "get_plot_data": get_plot_data,
    "get_parallel_coords_data": get_parallel_coords_data,
    "create_dashboard": create_dashboard,
    
    # Artifacts
    "list_artifacts": list_artifacts,
    "get_artifact": get_artifact,
    "download_artifact": download_artifact,
    
    # Auto-logging
    "create_auto_logger": create_auto_logger,
    "auto_log_metrics": auto_log_metrics,
    "auto_save_checkpoint": auto_save_checkpoint
}
