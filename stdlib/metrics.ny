# ============================================================
# Nyx Standard Library - Metrics Module
# ============================================================
# Comprehensive metrics collection and monitoring framework
# providing Prometheus-compatible metrics, counters, gauges,
# histograms, and summary metrics.

# ============================================================
# Constants
# ============================================================

let VERSION = "1.0.0";

# Metric types
let COUNTER = "counter";
let GAUGE = "gauge";
let HISTOGRAM = "histogram";
let SUMMARY = "summary";
let UNKNOWN = "unknown";

# Metric aggregation types
let SUM = "sum";
let COUNT = "count";
let MIN = "min";
let MAX = "max";
let AVG = "avg";

# Time units
let UNIT_SECONDS = "seconds";
let UNIT_MILLISECONDS = "milliseconds";
let UNIT_MICROSECONDS = "microseconds";
let UNIT_BYTES = "bytes";
let UNIT_BYTES_PER_SECOND = "bytes_per_second";
let UNIT Requests_PER_SECOND = "requests_per_second";

# ============================================================
# Labels
# ============================================================

class Labels {
    init(labels) {
        self.labels = labels ?? {};
    }

    get(key) {
        return self.labels[key];
    }

    set(key, value) {
        self.labels[key] = value;
    }

    merge(other) {
        let merged = {};
        for key in keys(self.labels) {
            merged[key] = self.labels[key];
        }
        for key in keys(other.labels) {
            merged[key] = other.labels[key];
        }
        return Labels(merged);
    }

    toString() {
        let parts = [];
        for key in keys(self.labels) {
            parts = parts + [key + "=\"" + str(self.labels[key]) + "\""];
        }
        return join(parts, ",");
    }

    toDict() {
        return self.labels;
    }

    isEmpty() {
        return len(keys(self.labels)) == 0;
    }

    hash() {
        let keys = sort(keys(self.labels));
        let str = "";
        for key in keys {
            str = str + key + "=" + str(self.labels[key]) + ";";
        }
        return str;
    }
}

# ============================================================
# Metric Base
# ============================================================

class Metric {
    init(name, help, type, labelNames) {
        self.name = name;
        self.help = help ?? "";
        self.type = type;
        self.labelNames = labelNames ?? [];
        self.labelValues = {};
        self.createdAt = time.time();
    }

    labels(labelValues) {
        let labels = Labels(labelValues);
        let key = labels.hash();
        
        if self.labelValues[key] == null {
            self.labelValues[key] = {
                "labels": labels,
                "value": self._getInitialValue()
            };
        }
        
        return self.labelValues[key]["value"];
    }

    _getInitialValue() {
        return 0;
    }

    getValue(labelValues) {
        let labels = Labels(labelValues);
        let key = labels.hash();
        
        if self.labelValues[key] != null {
            return self.labelValues[key]["value"];
        }
        return self._getInitialValue();
    }

    reset() {
        self.labelValues = {};
    }

    getAllValues() {
        let values = [];
        for key in keys(self.labelValues) {
            values = values + [self.labelValues[key]];
        }
        return values;
    }

    getMetricFamily() {
        return {
            "name": self.name,
            "help": self.help,
            "type": self.type,
            "metrics": self._getMetrics()
        };
    }

    _getMetrics() {
        let metrics = [];
        for key in keys(self.labelValues) {
            let entry = self.labelValues[key];
            metrics = metrics + [{
                "labels": entry["labels"].toDict(),
                "value": entry["value"]
            }];
        }
        return metrics;
    }

    toPrometheus() {
        let output = "";
        
        if self.help != "" {
            output = output + "# HELP " + self.name + " " + self.help + "\n";
        }
        
        output = output + "# TYPE " + self.name + " " + self.type + "\n";
        
        for key in keys(self.labelValues) {
            let entry = self.labelValues[key];
            let metricLine = self.name;
            
            if not entry["labels"].isEmpty() {
                metricLine = metricLine + "{" + entry["labels"].toString() + "}";
            }
            
            metricLine = metricLine + " " + str(entry["value"]) + "\n";
            output = output + metricLine;
        }
        
        return output;
    }
}

# ============================================================
# Counter Metric
# ============================================================

class Counter < Metric {
    init(name, help, labelNames) {
        super(name, help, COUNTER, labelNames);
        self.value = 0;
    }

    inc(value, labelValues) {
        if value == null {
            value = 1;
        }
        
        if len(self.labelNames) > 0 {
            let labels = Labels(labelValues);
            let key = labels.hash();
            
            if self.labelValues[key] == null {
                self.labelValues[key] = {
                    "labels": labels,
                    "value": 0
                };
            }
            
            self.labelValues[key]["value"] = self.labelValues[key]["value"] + value;
            return self.labelValues[key]["value"];
        }
        
        self.value = self.value + value;
        return self.value;
    }

    get() {
        if len(self.labelNames) > 0 {
            return self.getAllValues();
        }
        return self.value;
    }

    _getInitialValue() {
        return 0;
    }
}

# ============================================================
# Gauge Metric
# ============================================================

class Gauge < Metric {
    init(name, help, labelNames) {
        super(name, help, GAUGE, labelNames);
        self.value = 0;
    }

    set(value, labelValues) {
        if len(self.labelNames) > 0 {
            let labels = Labels(labelValues);
            let key = labels.hash();
            
            if self.labelValues[key] == null {
                self.labelValues[key] = {
                    "labels": labels,
                    "value": value
                };
            } else {
                self.labelValues[key]["value"] = value;
            }
            return self.labelValues[key]["value"];
        }
        
        self.value = value;
        return self.value;
    }

    inc(value, labelValues) {
        if value == null {
            value = 1;
        }
        
        if len(self.labelNames) > 0 {
            let labels = Labels(labelValues);
            let key = labels.hash();
            
            if self.labelValues[key] == null {
                self.labelValues[key] = {
                    "labels": labels,
                    "value": value
                };
            } else {
                self.labelValues[key]["value"] = self.labelValues[key]["value"] + value;
            }
            return self.labelValues[key]["value"];
        }
        
        self.value = self.value + value;
        return self.value;
    }

    dec(value, labelValues) {
        if value == null {
            value = 1;
        }
        
        return self.inc(-value, labelValues);
    }

    setToCurrentTime(labelValues) {
        return self.set(time.time(), labelValues);
    }

    startTimer(labelValues) {
        return Timer(self, labelValues);
    }

    get() {
        if len(self.labelNames) > 0 {
            return self.getAllValues();
        }
        return self.value;
    }

    _getInitialValue() {
        return 0;
    }
}

# ============================================================
# Timer Helper
# ============================================================

class Timer {
    init(gauge, labelValues) {
        self.gauge = gauge;
        self.labelValues = labelValues;
        self.startTime = time.time();
    }

    observeDuration() {
        let duration = time.time() - self.startTime;
        self.gauge.set(duration, self.labelValues);
        return duration;
    }

    stop() {
        return self.observeDuration();
    }
}

# ============================================================
# Histogram Metric
# ============================================================

class Histogram < Metric {
    init(name, help, labelNames, buckets) {
        super(name, help, HISTOGRAM, labelNames);
        
        # Default buckets
        self.buckets = buckets ?? [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0];
        self.bucketValues = {};
        self.sum = 0;
        self.count = 0;
    }

    observe(value, labelValues) {
        if len(self.labelNames) > 0 {
            let labels = Labels(labelValues);
            let key = labels.hash();
            
            if self.labelValues[key] == null {
                self.labelValues[key] = {
                    "labels": labels,
                    "buckets": self._createBuckets(),
                    "sum": 0,
                    "count": 0
                };
            }
            
            let entry = self.labelValues[key];
            
            # Update buckets
            for bucket in self.buckets {
                if value <= bucket {
                    entry["buckets"][bucket] = entry["buckets"][bucket] + 1;
                }
            }
            
            entry["sum"] = entry["sum"] + value;
            entry["count"] = entry["count"] + 1;
            
            return;
        }
        
        # Update global buckets
        for bucket in self.buckets {
            if value <= bucket {
                self.buckets[bucket] = self.buckets[bucket] + 1;
            }
        }
        
        self.sum = self.sum + value;
        self.count = self.count + 1;
    }

    startTimer(labelValues) {
        return HistogramTimer(self, labelValues);
    }

    _createBuckets() {
        let buckets = {};
        for bucket in self.buckets {
            buckets[bucket] = 0;
        }
        buckets["+Inf"] = 0;
        return buckets;
    }

    _getInitialValue() {
        return {
            "buckets": self._createBuckets(),
            "sum": 0,
            "count": 0
        };
    }

    toPrometheus() {
        let output = "";
        
        output = output + "# HELP " + self.name + " " + self.help + "\n";
        output = output + "# TYPE " + self.name + " histogram\n";
        
        for key in keys(self.labelValues) {
            let entry = self.labelValues[key];
            
            # Output buckets
            for bucket in sort(keys(entry["buckets"])) {
                let bucketLabel = "_bucket";
                let le = str(bucket);
                if bucket == "+Inf" {
                    le = "+Inf";
                }
                
                let metricLine = self.name + bucketLabel + "{le=\"" + le + "\"";
                if not entry["labels"].isEmpty() {
                    metricLine = metricLine + "," + entry["labels"].toString();
                }
                metricLine = metricLine + "} " + str(entry["buckets"][bucket]) + "\n";
                output = output + metricLine;
            }
            
            # Output sum
            let sumLine = self.name + "_sum";
            if not entry["labels"].isEmpty() {
                sumLine = sumLine + "{" + entry["labels"].toString() + "}";
            }
            output = output + sumLine + " " + str(entry["sum"]) + "\n";
            
            # Output count
            let countLine = self.name + "_count";
            if not entry["labels"].isEmpty() {
                countLine = countLine + "{" + entry["labels"].toString() + "}";
            }
            output = output + countLine + " " + str(entry["count"]) + "\n";
        }
        
        return output;
    }
}

# ============================================================
# Histogram Timer Helper
# ============================================================

class HistogramTimer {
    init(histogram, labelValues) {
        self.histogram = histogram;
        self.labelValues = labelValues;
        self.startTime = time.time();
    }

    observeDuration() {
        let duration = time.time() - self.startTime;
        self.histogram.observe(duration, self.labelValues);
        return duration;
    }

    stop() {
        return self.observeDuration();
    }
}

# ============================================================
# Summary Metric
# ============================================================

class Summary < Metric {
    init(name, help, labelNames, percentiles) {
        super(name, help, SUMMARY, labelNames);
        
        self.percentiles = percentiles ?? [0.5, 0.9, 0.95, 0.99];
        self.quantileValues = {};
    }

    observe(value, labelValues) {
        if len(self.labelNames) > 0 {
            let labels = Labels(labelValues);
            let key = labels.hash();
            
            if self.labelValues[key] == null {
                self.labelValues[key] = {
                    "labels": labels,
                    "values": [],
                    "sum": 0,
                    "count": 0
                };
            }
            
            let entry = self.labelValues[key];
            entry["values"] = entry["values"] + [value];
            entry["sum"] = entry["sum"] + value;
            entry["count"] = entry["count"] + 1;
            
            return;
        }
        
        self.quantileValues = self.quantileValues + [value];
        self.sum = self.sum + value;
        self.count = self.count + 1;
    }

    _getInitialValue() {
        return {
            "values": [],
            "sum": 0,
            "count": 0
        };
    }

    _calculatePercentile(values, percentile) {
        if len(values) == 0 {
            return 0;
        }
        
        let sorted = sort(values);
        let index = floor(percentile * (len(sorted) - 1));
        
        return sorted[index];
    }

    toPrometheus() {
        let output = "";
        
        output = output + "# HELP " + self.name + " " + self.help + "\n";
        output = output + "# TYPE " + self.name + " summary\n";
        
        for key in keys(self.labelValues) {
            let entry = self.labelValues[key];
            
            # Output quantiles
            for percentile in self.percentiles {
                let q = self._calculatePercentile(entry["values"], percentile);
                let quantileLabel = "{quantile=\"" + str(percentile) + "\"}";
                
                let metricLine = self.name + quantileLabel;
                if not entry["labels"].isEmpty() {
                    metricLine = metricLine + "{" + entry["labels"].toString() + "}";
                }
                metricLine = metricLine + " " + str(q) + "\n";
                output = output + metricLine;
            }
            
            # Output sum
            let sumLine = self.name + "_sum";
            if not entry["labels"].isEmpty() {
                sumLine = sumLine + "{" + entry["labels"].toString() + "}";
            }
            output = output + sumLine + " " + str(entry["sum"]) + "\n";
            
            # Output count
            let countLine = self.name + "_count";
            if not entry["labels"].isEmpty() {
                countLine = countLine + "{" + entry["labels"].toString() + "}";
            }
            output = output + countLine + " " + str(entry["count"]) + "\n";
        }
        
        return output;
    }
}

# ============================================================
# Registry
# ============================================================

class Registry {
    init() {
        self.metrics = {};
        self.collectors = [];
    }

    register(metric) {
        if self.metrics[metric.name] != null {
            # Metric already exists
            return false;
        }
        
        self.metrics[metric.name] = metric;
        return true;
    }

    unregister(name) {
        if self.metrics[name] != null {
            self.metrics[name] = null;
            return true;
        }
        return false;
    }

    get(name) {
        return self.metrics[name];
    }

    counter(name, help, labelNames) {
        let metric = Counter(name, help, labelNames);
        self.register(metric);
        return metric;
    }

    gauge(name, help, labelNames) {
        let metric = Gauge(name, help, labelNames);
        self.register(metric);
        return metric;
    }

    histogram(name, help, labelNames, buckets) {
        let metric = Histogram(name, help, labelNames, buckets);
        self.register(metric);
        return metric;
    }

    summary(name, help, labelNames, percentiles) {
        let metric = Summary(name, help, labelNames, percentiles);
        self.register(metric);
        return metric;
    }

    registerCollector(collector) {
        self.collectors = self.collectors + [collector];
    }

    collect() {
        for collector in self.collectors {
            collector.collect(self);
        }
    }

    metrics() {
        return self.metrics;
    }

    toPrometheus() {
        let output = "";
        
        # Collect from collectors first
        self.collect();
        
        for name in keys(self.metrics) {
            let metric = self.metrics[name];
            if metric != null {
                output = output + metric.toPrometheus();
            }
        }
        
        return output;
    }

    writeToFile(filename) {
        # Would write to file
    }

    reset() {
        for name in keys(self.metrics) {
            if self.metrics[name] != null {
                self.metrics[name].reset();
            }
        }
    }

    getMetricFamilies() {
        let families = [];
        
        for name in keys(self.metrics) {
            if self.metrics[name] != null {
                families = families + [self.metrics[name].getMetricFamily()];
            }
        }
        
        return families;
    }
}

# ============================================================
# Default Registry
# ============================================================

let defaultRegistry = Registry();

# ============================================================
# Collector Interface
# ============================================================

class Collector {
    init() {
        self.metrics = [];
    }

    collect(registry) {
        # Override in subclasses
    }

    addMetric(metric) {
        self.metrics = self.metrics + [metric];
    }
}

# ============================================================
# Process Collector
# ============================================================

class ProcessCollector < Collector {
    init() {
        super();
        self.name = "process";
    }

    collect(registry) {
        # Would collect process-level metrics like:
        # - process_cpu_seconds_total
        # - process_open_fds
        # - process_max_fds
        # - process_virtual_memory_bytes
        # - process_resident_memory_bytes
        # - process_start_time_seconds
        # - process_num_threads
    }
}

# ============================================================
# Go Collector (for Go runtime)
# ============================================================

class GoCollector < Collector {
    init() {
        super();
        self.name = "go";
    }

    collect(registry) {
        # Would collect Go runtime metrics like:
        # - go_goroutines
        # - go_memstats_alloc_bytes
        # - go_memstats_heap_alloc_bytes
        # - go_memstats_heap_sys_bytes
        # - go_memstats_stack_inuse_bytes
        # - go_gc_duration_seconds
    }
}

# ============================================================
# Node Collector (for system metrics)
# ============================================================

class NodeCollector < Collector {
    init() {
        super();
        self.name = "node";
    }

    collect(registry) {
        # Would collect node-level metrics like:
        # - node_cpu_seconds_total
        # - node_memory_MemAvailable_bytes
        # - node_network_receive_bytes_total
        # - node_network_transmit_bytes_total
    }
}

# ============================================================
# Push Gateway Client
# ============================================================

class PushGateway {
    init(address, job, groupingKey) {
        self.address = address;
        self.job = job;
        self.groupingKey = groupingKey ?? {};
        self.client = null;
    }

    push(registry) {
        let metrics = registry.toPrometheus();
        
        let url = self.address + "/metrics/job/" + self.job;
        
        for key in keys(self.groupingKey) {
            url = url + "/" + key + "/" + self.groupingKey[key];
        }
        
        # Would POST to push gateway
        return true;
    }

    pushAdd(registry) {
        # Push with "add" semantics (don't replace existing metrics)
        return self.push(registry);
    }

    delete() {
        # Delete all metrics for this job/grouping key
        let url = self.address + "/metrics/job/" + self.job;
        
        for key in keys(self.groupingKey) {
            url = url + "/" + key + "/" + self.groupingKey[key];
        }
        
        # Would DELETE to push gateway
        return true;
    }
}

# ============================================================
# Exporters
# ============================================================

class PrometheusExporter {
    init(registry) {
        self.registry = registry ?? defaultRegistry;
        self.port = 9090;
        self.path = "/metrics";
    }

    start() {
        # Would start HTTP server
    }

    stop() {
        # Would stop HTTP server
    }

    serve() {
        return self.registry.toPrometheus();
    }
}

# ============================================================
# Metrics Decorators
# ============================================================

class MetricsDecorator {
    init(registry) {
        self.registry = registry ?? defaultRegistry;
    }

    count(name, labels) {
        let counter = self.registry.get(name);
        if counter == null {
            counter = self.registry.counter(name, "", keys(labels ?? {}));
        }
        
        return fn(value) {
            return counter.inc(value, labels);
        };
    }

    gauge(name, labels) {
        let gauge = self.registry.get(name);
        if gauge == null {
            gauge = self.registry.gauge(name, "", keys(labels ?? {}));
        }
        
        return fn(value) {
            return gauge.set(value, labels);
        };
    }

    histogram(name, labels, buckets) {
        let histogram = self.registry.get(name);
        if histogram == null {
            histogram = self.registry.histogram(name, "", keys(labels ?? {}), buckets);
        }
        
        return fn(value) {
            return histogram.observe(value, labels);
        };
    }

    timed(name, labels) {
        let histogram = self.registry.get(name + "_seconds");
        if histogram == null {
            histogram = self.registry.histogram(name + "_seconds", "", keys(labels ?? {}), 
                [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0]);
        }
        
        return fn() {
            let start = time.time();
            return fn(result) {
                let duration = time.time() - start;
                histogram.observe(duration, labels);
                return result;
            };
        };
    }
}

# ============================================================
# Utility Functions
# ============================================================

fn createCounter(name, help, labelNames) {
    return defaultRegistry.counter(name, help, labelNames);
}

fn createGauge(name, help, labelNames) {
    return defaultRegistry.gauge(name, help, labelNames);
}

fn createHistogram(name, help, labelNames, buckets) {
    return defaultRegistry.histogram(name, help, labelNames, buckets);
}

fn createSummary(name, help, labelNames, percentiles) {
    return defaultRegistry.summary(name, help, labelNames, percentiles);
}

fn getDefaultRegistry() {
    return defaultRegistry;
}

fn registerCollector(collector) {
    return defaultRegistry.registerCollector(collector);
}

fn toPrometheus() {
    return defaultRegistry.toPrometheus();
}

fn pushToGateway(address, job, groupingKey) {
    let gateway = PushGateway(address, job, groupingKey);
    return gateway.push(defaultRegistry);
}

fn pushAddToGateway(address, job, groupingKey) {
    let gateway = PushGateway(address, job, groupingKey);
    return gateway.pushAdd(defaultRegistry);
}

fn deleteFromGateway(address, job, groupingKey) {
    let gateway = PushGateway(address, job, groupingKey);
    return gateway.delete();
}

# ============================================================
# Predefined Metrics
# ============================================================

let processCPU = defaultRegistry.counter("process_cpu_seconds_total", "Total user and system CPU time spent in seconds", []);
let processStartTime = defaultRegistry.gauge("process_start_time_seconds", "Start time of the process since unix epoch", []);
let processOpenFDs = defaultRegistry.gauge("process_open_fds", "Number of open file descriptors", []);
let processMaxFDs = defaultRegistry.gauge("process_max_fds", "Maximum number of open file descriptors", []);
let processVirtualMemory = defaultRegistry.gauge("process_virtual_memory_bytes", "Virtual memory size in bytes", []);
let processResidentMemory = defaultRegistry.gauge("process_resident_memory_bytes", "Resident memory size in bytes", []);
let processThreads = defaultRegistry.gauge("process_threads", "Number of threads", []);

let httpRequestsTotal = defaultRegistry.counter("http_requests_total", "Total number of HTTP requests", ["method", "status", "path"]);
let httpRequestDuration = defaultRegistry.histogram("http_request_duration_seconds", "HTTP request latency in seconds", ["method", "path"], [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0]);

let httpInFlight = defaultRegistry.gauge("http_requests_in_flight", "Number of HTTP requests currently being processed", ["method", "path"]);

# ============================================================
# Export
# ============================================================

{
    "Labels": Labels,
    "Metric": Metric,
    "Counter": Counter,
    "Gauge": Gauge,
    "Histogram": Histogram,
    "Summary": Summary,
    "Timer": Timer,
    "HistogramTimer": HistogramTimer,
    "Registry": Registry,
    "Collector": Collector,
    "ProcessCollector": ProcessCollector,
    "GoCollector": GoCollector,
    "NodeCollector": NodeCollector,
    "PushGateway": PushGateway,
    "PrometheusExporter": PrometheusExporter,
    "MetricsDecorator": MetricsDecorator,
    "createCounter": createCounter,
    "createGauge": createGauge,
    "createHistogram": createHistogram,
    "createSummary": createSummary,
    "getDefaultRegistry": getDefaultRegistry,
    "registerCollector": registerCollector,
    "toPrometheus": toPrometheus,
    "pushToGateway": pushToGateway,
    "pushAddToGateway": pushAddToGateway,
    "deleteFromGateway": deleteFromGateway,
    "defaultRegistry": defaultRegistry,
    "COUNTER": COUNTER,
    "GAUGE": GAUGE,
    "HISTOGRAM": HISTOGRAM,
    "SUMMARY": SUMMARY,
    "processCPU": processCPU,
    "processStartTime": processStartTime,
    "processOpenFDs": processOpenFDs,
    "processMaxFDs": processMaxFDs,
    "processVirtualMemory": processVirtualMemory,
    "processResidentMemory": processResidentMemory,
    "processThreads": processThreads,
    "httpRequestsTotal": httpRequestsTotal,
    "httpRequestDuration": httpRequestDuration,
    "httpInFlight": httpInFlight,
    "VERSION": VERSION
}
