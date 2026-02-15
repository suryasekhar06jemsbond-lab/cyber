# ============================================================
# Nyx Standard Library - Cron Module
# ============================================================
# Comprehensive cron scheduling framework providing cron expression
# parsing, time-based triggers, scheduling, and job management.

# ============================================================
# Constants
# ============================================================

let VERSION = "1.0.0";

# Cron field names
let FIELD_MINUTE = "minute";
let FIELD_HOUR = "hour";
let FIELD_DAY_OF_MONTH = "dayOfMonth";
let FIELD_MONTH = "month";
let FIELD_DAY_OF_WEEK = "dayOfWeek";

# Cron field constraints
let MINUTE_MIN = 0;
let MINUTE_MAX = 59;
let HOUR_MIN = 0;
let HOUR_MAX = 23;
let DAY_OF_MONTH_MIN = 1;
let DAY_OF_MONTH_MAX = 31;
let MONTH_MIN = 1;
let MONTH_MAX = 12;
let DAY_OF_WEEK_MIN = 0;
let DAY_OF_WEEK_MAX = 6;

# Month names
let MONTH_NAMES = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"];
let MONTH_NAMES_FULL = ["january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december"];

# Day names
let DAY_NAMES = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"];
let DAY_NAMES_FULL = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"];

# ============================================================
# Cron Expression Parser
# ============================================================

class CronExpression {
    init(expression) {
        self.raw = expression;
        self.parsed = null;
        
        self.minute = [];
        self.hour = [];
        self.dayOfMonth = [];
        self.month = [];
        self.dayOfWeek = [];
        
        self._parse(expression);
    }

    _parse(expression) {
        # Normalize expression
        let parts = split(trim(expression), " ");
        
        if len(parts) < 5 {
            return false;
        }
        
        if len(parts) == 5 {
            self.minute = self._parseField(parts[0], MINUTE_MIN, MINUTE_MAX);
            self.hour = self._parseField(parts[1], HOUR_MIN, HOUR_MAX);
            self.dayOfMonth = self._parseField(parts[2], DAY_OF_MONTH_MIN, DAY_OF_MONTH_MAX);
            self.month = self._parseField(parts[3], MONTH_MIN, MONTH_MAX);
            self.dayOfWeek = self._parseField(parts[4], DAY_OF_WEEK_MIN, DAY_OF_WEEK_MAX);
            
            self.parsed = true;
            return true;
        }
        
        # 6-field format with seconds
        if len(parts) == 6 {
            # Skip seconds for now
            self.minute = self._parseField(parts[1], MINUTE_MIN, MINUTE_MAX);
            self.hour = self._parseField(parts[2], HOUR_MIN, HOUR_MAX);
            self.dayOfMonth = self._parseField(parts[3], DAY_OF_MONTH_MIN, DAY_OF_MONTH_MAX);
            self.month = self._parseField(parts[4], MONTH_MIN, MONTH_MAX);
            self.dayOfWeek = self._parseField(parts[5], DAY_OF_WEEK_MIN, DAY_OF_WEEK_MAX);
            
            self.parsed = true;
            return true;
        }
        
        return false;
    }

    _parseField(field, minVal, maxVal) {
        # Handle special characters
        if field == "*" {
            return self._rangeToArray(minVal, maxVal);
        }
        
        if field == "?" {
            return [-1];  # Wildcard
        }
        
        # Handle step values (*/5, 0/5)
        let stepMatch = split(field, "/");
        if len(stepMatch) == 2 {
            let base = stepMatch[0];
            let step = parseInt(stepMatch[1]);
            
            if base == "*" {
                return self._generateStepArray(minVal, maxVal, step);
            }
            
            let start = parseInt(base);
            return self._generateStepArray(start, maxVal, step);
        }
        
        # Handle ranges (1-5)
        if contains(field, "-") {
            let rangeParts = split(field, "-");
            if len(rangeParts) == 2 {
                let start = self._parseValue(rangeParts[0], minVal, maxVal);
                let end = self._parseValue(rangeParts[1], minVal, maxVal);
                return self._rangeToArray(start, end);
            }
        }
        
        # Handle lists (1,2,3)
        if contains(field, ",") {
            let values = split(field, ",");
            let result = [];
            for value in values {
                let parsed = self._parseValue(trim(value), minVal, maxVal);
                if parsed >= 0 {
                    result = result + [parsed];
                }
            }
            return result;
        }
        
        # Single value
        let singleValue = self._parseValue(field, minVal, maxVal);
        if singleValue >= 0 {
            return [singleValue];
        }
        
        return [];
    }

    _parseValue(value, minVal, maxVal) {
        value = trim(value);
        
        # Try numeric
        if value >= "0" and value <= "9" {
            let num = parseInt(value);
            if num >= minVal and num <= maxVal {
                return num;
            }
            return -1;
        }
        
        # Try month name
        let lowerValue = lower(value);
        for i in range(len(MONTH_NAMES)) {
            if lowerValue == MONTH_NAMES[i] or lowerValue == MONTH_NAMES_FULL[i] {
                return i + 1;
            }
        }
        
        # Try day name
        for i in range(len(DAY_NAMES)) {
            if lowerValue == DAY_NAMES[i] or lowerValue == DAY_NAMES_FULL[i] {
                return i;
            }
        }
        
        return -1;
    }

    _rangeToArray(start, end) {
        let result = [];
        for i in range(start, end + 1) {
            result = result + [i];
        }
        return result;
    }

    _generateStepArray(start, end, step) {
        let result = [];
        for i in range(start, end + 1, step) {
            result = result + [i];
        }
        return result;
    }

    matches(datetime) {
        let minute = datetime["minute"] ?? 0;
        let hour = datetime["hour"] ?? 0;
        let dayOfMonth = datetime["day"] ?? 1;
        let month = datetime["month"] ?? 1;
        let dayOfWeek = datetime["weekday"] ?? 0;
        
        # Check each field
        if len(self.minute) > 0 and self.minute[0] >= 0 {
            if minute not in self.minute {
                return false;
            }
        }
        
        if len(self.hour) > 0 and self.hour[0] >= 0 {
            if hour not in self.hour {
                return false;
            }
        }
        
        if len(self.dayOfMonth) > 0 and self.dayOfMonth[0] >= 0 {
            if dayOfMonth not in self.dayOfMonth {
                return false;
            }
        }
        
        if len(self.month) > 0 and self.month[0] >= 0 {
            if month not in self.month {
                return false;
            }
        }
        
        if len(self.dayOfWeek) > 0 and self.dayOfWeek[0] >= 0 {
            if dayOfWeek not in self.dayOfWeek {
                return false;
            }
        }
        
        return true;
    }

    getNextRun(afterDatetime) {
        let current = afterDatetime ?? time.now();
        let maxIterations = 366 * 24 * 60;  # One year of minutes
        
        for i in range(maxIterations) {
            if self.matches(current) {
                return current;
            }
            current = self._addMinute(current);
        }
        
        return null;
    }

    _addMinute(datetime) {
        let minute = datetime["minute"] + 1;
        let hour = datetime["hour"];
        let day = datetime["day"];
        let month = datetime["month"];
        let year = datetime["year"];
        
        if minute >= 60 {
            minute = 0;
            hour = hour + 1;
        }
        
        if hour >= 24 {
            hour = 0;
            day = day + 1;
        }
        
        if day > 28 and month == 2 {
            month = 3;
            day = 1;
        } else if day > 30 and month in [4, 6, 9, 11] {
            day = 1;
            month = month + 1;
        } else if day > 31 and month in [1, 3, 5, 7, 8, 10, 12] {
            day = 1;
            month = month + 1;
        }
        
        if month > 12 {
            month = 1;
            year = year + 1;
        }
        
        return {
            "year": year,
            "month": month,
            "day": day,
            "hour": hour,
            "minute": minute
        };
    }

    toString() {
        return self.raw;
    }

    getFields() {
        return {
            "minute": self.minute,
            "hour": self.hour,
            "dayOfMonth": self.dayOfMonth,
            "month": self.month,
            "dayOfWeek": self.dayOfWeek
        };
    }
}

# ============================================================
# Cron Field Descriptor
# ============================================================

class CronField {
    init(name, min, max, names) {
        self.name = name;
        self.min = min;
        self.max = max;
        self.names = names ?? [];
    }

    parse(value) {
        if value == "*" {
            return self._rangeToArray(self.min, self.max);
        }
        
        if contains(value, "/") {
            return self._parseStep(value);
        }
        
        if contains(value, "-") {
            return self._parseRange(value);
        }
        
        if contains(value, ",") {
            return self._parseList(value);
        }
        
        return self._parseSingle(value);
    }

    _parseStep(value) {
        let parts = split(value, "/");
        let start = parts[0];
        let step = parseInt(parts[1]);
        
        let startVal = self.min;
        if start != "*" {
            startVal = self._parseSingle(start);
        }
        
        let result = [];
        for i in range(startVal, self.max + 1, step) {
            result = result + [i];
        }
        return result;
    }

    _parseRange(value) {
        let parts = split(value, "-");
        let start = self._parseSingle(parts[0]);
        let end = self._parseSingle(parts[1]);
        
        return self._rangeToArray(start, end);
    }

    _parseList(value) {
        let items = split(value, ",");
        let result = [];
        for item in items {
            result = result + [self._parseSingle(trim(item))];
        }
        return result;
    }

    _parseSingle(value) {
        value = trim(value);
        
        # Check names
        for i in range(len(self.names)) {
            if lower(value) == self.names[i] {
                return self.min + i;
            }
        }
        
        return parseInt(value);
    }

    _rangeToArray(start, end) {
        let result = [];
        for i in range(start, end + 1) {
            result = result + [i];
        }
        return result;
    }

    validate(values) {
        for val in values {
            if val < self.min or val > self.max {
                return false;
            }
        }
        return true;
    }

    describe(values) {
        if len(values) == self.max - self.min + 1 {
            return "every " + self.name;
        }
        
        return json.stringify(values);
    }
}

# ============================================================
# Cron Job
# ============================================================

class CronJob {
    init(id, expression, handler, options) {
        self.id = id;
        self.expression = expression;
        self.handler = handler;
        self.options = options ?? {};
        
        self.name = options["name"] ?? id;
        self.enabled = options["enabled"] ?? true;
        self.timezone = options["timezone"] ?? "UTC";
        self.description = options["description"] ?? "";
        self.tags = options["tags"] ?? {};
        
        self.lastRun = null;
        self.nextRun = null;
        self.runCount = 0;
        self.errorCount = 0;
        
        # Parse expression
        if type(expression) == "string" {
            self.cronExpression = CronExpression(expression);
        } else {
            self.cronExpression = expression;
        }
        
        self._calculateNextRun();
    }

    _calculateNextRun() {
        if self.enabled {
            self.nextRun = self.cronExpression.getNextRun(time.now());
        } else {
            self.nextRun = null;
        }
    }

    execute() {
        let startTime = time.time();
        
        self.lastRun = startTime;
        self.runCount = self.runCount + 1;
        
        try {
            if type(self.handler) == "function" {
                self.handler(self);
            }
            
            self._calculateNextRun();
            return true;
        } catch e {
            self.errorCount = self.errorCount + 1;
            self._calculateNextRun();
            return false;
        }
    }

    runNow() {
        return self.execute();
    }

    enable() {
        self.enabled = true;
        self._calculateNextRun();
    }

    disable() {
        self.enabled = false;
        self.nextRun = null;
    }

    isDue() {
        if not self.enabled {
            return false;
        }
        
        if self.nextRun == null {
            return false;
        }
        
        let now = time.now();
        return self._isTimePassed(now, self.nextRun);
    }

    _isTimePassed(now, target) {
        if now["year"] > target["year"] {
            return true;
        }
        if now["year"] < target["year"] {
            return false;
        }
        
        if now["month"] > target["month"] {
            return true;
        }
        if now["month"] < target["month"] {
            return false;
        }
        
        if now["day"] > target["day"] {
            return true;
        }
        if now["day"] < target["day"] {
            return false;
        }
        
        if now["hour"] > target["hour"] {
            return true;
        }
        if now["hour"] < target["hour"] {
            return false;
        }
        
        return now["minute"] >= target["minute"];
    }

    getNextRun() {
        return self.nextRun;
    }

    getLastRun() {
        return self.lastRun;
    }

    getRunCount() {
        return self.runCount;
    }

    getErrorCount() {
        return self.errorCount;
    }

    toString() {
        return "CronJob[" + self.id + "]: " + self.cronExpression.toString();
    }
}

# ============================================================
# Cron Scheduler
# ============================================================

class CronScheduler {
    init(options) {
        self.options = options ?? {};
        self.jobs = {};
        self.running = false;
        self.interval = options["interval"] ?? 60000;  # 1 minute
        self.maxMissedRuns = options["maxMissedRuns"] ?? 10;
        self.onJobRun = options["onJobRun"] ?? null;
        self.onJobError = options["onJobError"] ?? null;
        self.onJobSkip = options["onJobSkip"] ?? null;
        
        self.stats = {
            "totalRuns": 0,
            "totalErrors": 0,
            "jobsEnabled": 0,
            "jobsDisabled": 0
        };
    }

    addJob(id, expression, handler, options) {
        let job = CronJob(id, expression, handler, options);
        self.jobs[id] = job;
        
        if job.enabled {
            self.stats["jobsEnabled"] = self.stats["jobsEnabled"] + 1;
        } else {
            self.stats["jobsDisabled"] = self.stats["jobsDisabled"] + 1;
        }
        
        return job;
    }

    removeJob(id) {
        if self.jobs[id] != null {
            let job = self.jobs[id];
            self.jobs[id] = null;
            
            if job.enabled {
                self.stats["jobsEnabled"] = self.stats["jobsEnabled"] - 1;
            } else {
                self.stats["jobsDisabled"] = self.stats["jobsDisabled"] - 1;
            }
            
            return true;
        }
        return false;
    }

    getJob(id) {
        return self.jobs[id];
    }

    listJobs() {
        let jobList = [];
        for id in keys(self.jobs) {
            if self.jobs[id] != null {
                jobList = jobList + [self.jobs[id]];
            }
        }
        return jobList;
    }

    enableJob(id) {
        if self.jobs[id] != null {
            self.jobs[id].enable();
            return true;
        }
        return false;
    }

    disableJob(id) {
        if self.jobs[id] != null {
            self.jobs[id].disable();
            return true;
        }
        return false;
    }

    runJob(id) {
        if self.jobs[id] != null {
            return self.jobs[id].execute();
        }
        return false;
    }

    start() {
        self.running = true;
        self._runLoop();
    }

    stop() {
        self.running = false;
    }

    _runLoop() {
        if not self.running {
            return;
        }
        
        # Check all jobs
        for id in keys(self.jobs) {
            let job = self.jobs[id];
            
            if job == null {
                continue;
            }
            
            if job.isDue() {
                # Check for missed runs
                if self.maxMissedRuns > 0 and job.lastRun != null {
                    let missed = self._countMissedRuns(job);
                    
                    if missed > self.maxMissedRuns {
                        if self.onJobSkip != null {
                            self.onJobSkip(job, missed);
                        }
                        continue;
                    }
                }
                
                # Run the job
                let success = job.execute();
                
                self.stats["totalRuns"] = self.stats["totalRuns"] + 1;
                
                if not success {
                    self.stats["totalErrors"] = self.stats["totalErrors"] + 1;
                    
                    if self.onJobError != null {
                        self.onJobError(job);
                    }
                } else {
                    if self.onJobRun != null {
                        self.onJobRun(job);
                    }
                }
            }
        }
        
        # Schedule next check
        # In a real implementation, this would use setTimeout or similar
    }

    _countMissedRuns(job) {
        if job.lastRun == null or job.nextRun == null {
            return 0;
        }
        
        let missed = 0;
        let checkTime = job.lastRun;
        
        while true {
            checkTime = job.cronExpression.getNextRun(checkTime);
            
            if checkTime == null {
                break;
            }
            
            let now = time.now();
            
            if self._isTimePassed(now, checkTime) {
                missed = missed + 1;
                
                if missed >= self.maxMissedRuns {
                    break;
                }
            } else {
                break;
            }
        }
        
        return missed;
    }

    _isTimePassed(now, target) {
        if now["year"] > target["year"] {
            return true;
        }
        if now["year"] < target["year"] {
            return false;
        }
        
        if now["month"] > target["month"] {
            return true;
        }
        if now["month"] < target["month"] {
            return false;
        }
        
        if now["day"] > target["day"] {
            return true;
        }
        if now["day"] < target["day"] {
            return false;
        }
        
        if now["hour"] > target["hour"] {
            return true;
        }
        if now["hour"] < target["hour"] {
            return false;
        }
        
        return now["minute"] >= target["minute"];
    }

    getStats() {
        return {
            "totalRuns": self.stats["totalRuns"],
            "totalErrors": self.stats["totalErrors"],
            "jobsEnabled": self.stats["jobsEnabled"],
            "jobsDisabled": self.stats["jobsDisabled"],
            "running": self.running,
            "jobsCount": len(keys(self.jobs))
        };
    }

    clearJobs() {
        self.jobs = {};
        self.stats["jobsEnabled"] = 0;
        self.stats["jobsDisabled"] = 0;
    }

    findDueJobs() {
        let dueJobs = [];
        
        for id in keys(self.jobs) {
            let job = self.jobs[id];
            
            if job != null and job.isDue() {
                dueJobs = dueJobs + [job];
            }
        }
        
        return dueJobs;
    }

    findNextJobs(count) {
        let jobRunTimes = [];
        
        for id in keys(self.jobs) {
            let job = self.jobs[id];
            
            if job != null and job.enabled {
                jobRunTimes = jobRunTimes + [{
                    "job": job,
                    "nextRun": job.nextRun
                }];
            }
        }
        
        # Sort by next run time
        # Would sort here
        
        return jobRunTimes[0:count];
    }
}

# ============================================================
# Cron Builder
# ============================================================

class CronBuilder {
    init() {
        self.minute = "*";
        self.hour = "*";
        self.dayOfMonth = "*";
        self.month = "*";
        self.dayOfWeek = "*";
    }

    everyMinute() {
        self.minute = "*";
        return self;
    }

    everyHour() {
        self.minute = "0";
        self.hour = "*";
        return self;
    }

    everyDay() {
        self.hour = "0";
        self.minute = "0";
        return self;
    }

    everyWeek() {
        self.dayOfWeek = "*";
        self.hour = "0";
        self.minute = "0";
        return self;
    }

    everyMonth() {
        self.dayOfMonth = "1";
        self.hour = "0";
        self.minute = "0";
        return self;
    }

    at(hour, minute) {
        self.hour = str(hour);
        self.minute = str(minute);
        return self;
    }

    atMidnight() {
        return self.at(0, 0);
    }

    atNoon() {
        return self.at(12, 0);
    }

    minute(value) {
        self.minute = str(value);
        return self;
    }

    hour(value) {
        self.hour = str(value);
        return self;
    }

    dayOfMonth(value) {
        self.dayOfMonth = str(value);
        return self;
    }

    month(value) {
        self.month = str(value);
        return self;
    }

    dayOfWeek(value) {
        self.dayOfWeek = str(value);
        return self;
    }

    onSunday() {
        self.dayOfWeek = "0";
        return self;
    }

    onMonday() {
        self.dayOfWeek = "1";
        return self;
    }

    onTuesday() {
        self.dayOfWeek = "2";
        return self;
    }

    onWednesday() {
        self.dayOfWeek = "3";
        return self;
    }

    onThursday() {
        self.dayOfWeek = "4";
        return self;
    }

    onFriday() {
        self.dayOfWeek = "5";
        return self;
    }

    onSaturday() {
        self.dayOfWeek = "6";
        return self;
    }

    every(value) {
        return self;
    }

    build() {
        return self.minute + " " + self.hour + " " + self.dayOfMonth + " " + self.month + " " + self.dayOfWeek;
    }
}

# ============================================================
# Cron Presets
# ============================================================

let CronPresets = {
    "everyMinute": "0 * * * *",
    "every5Minutes": "*/5 * * * *",
    "every10Minutes": "*/10 * * * *",
    "every15Minutes": "*/15 * * * *",
    "every30Minutes": "*/30 * * * *",
    "everyHour": "0 * * * *",
    "everyDay": "0 0 * * *",
    "everyMidnight": "0 0 * * *",
    "everyNoon": "0 12 * * *",
    "everyDayAt6AM": "0 6 * * *",
    "everyDayAt6PM": "0 18 * * *",
    "everySunday": "0 0 * * 0",
    "everyMonday": "0 0 * * 1",
    "everyTuesday": "0 0 * * 2",
    "everyWednesday": "0 0 * * 3",
    "everyThursday": "0 0 * * 4",
    "everyFriday": "0 0 * * 5",
    "everySaturday": "0 0 * * 6",
    "everyWeekday": "0 0 * * 1-5",
    "everyWeekend": "0 0 * * 0,6",
    "firstDayOfMonth": "0 0 1 * *",
    "lastDayOfMonth": "0 0 28-31 * *",
    "everyQuarter": "0 0 1 */3 *",
    "every6Months": "0 0 1 */6 *",
    "everyYear": "0 0 1 1 *"
};

# ============================================================
# Utility Functions
# ============================================================

fn parseCron(expression) {
    return CronExpression(expression);
}

fn cron(expression, handler, options) {
    let id = options["id"] ?? "job_" + str(time.time());
    return CronJob(id, expression, handler, options);
}

fn schedule(expression, handler, options) {
    let scheduler = CronScheduler();
    return scheduler.addJob("job_" + str(time.time()), expression, handler, options);
}

fn scheduleEveryMinute(handler) {
    return schedule("* * * * *", handler, {"name": "everyMinute"});
}

fn scheduleEvery5Minutes(handler) {
    return schedule("*/5 * * * *", handler, {"name": "every5Minutes"});
}

fn scheduleEveryHour(handler) {
    return schedule("0 * * * *", handler, {"name": "everyHour"});
}

fn scheduleEveryDay(handler, hour, minute) {
    let hourStr = str(hour ?? 0);
    let minuteStr = str(minute ?? 0);
    return schedule(minuteStr + " " + hourStr + " * * *", handler, {"name": "everyDay"});
}

fn scheduleEveryWeek(handler, dayOfWeek, hour, minute) {
    let dayStr = str(dayOfWeek ?? 0);
    let hourStr = str(hour ?? 0);
    let minuteStr = str(minute ?? 0);
    return schedule(minuteStr + " " + hourStr + " * * " + dayStr, handler, {"name": "everyWeek"});
}

fn scheduleEveryMonth(handler, dayOfMonth, hour, minute) {
    let dayStr = str(dayOfMonth ?? 1);
    let hourStr = str(hour ?? 0);
    let minuteStr = str(minute ?? 0);
    return schedule(minuteStr + " " + hourStr + " " + dayStr + " * *", handler, {"name": "everyMonth"});
}

fn createScheduler(options) {
    return CronScheduler(options);
}

fn builder() {
    return CronBuilder();
}

fn getPreset(name) {
    return CronPresets[name];
}

fn listPresets() {
    return keys(CronPresets);
}

fn validateCron(expression) {
    let expr = CronExpression(expression);
    return expr.parsed == true;
}

fn getNextRun(expression, afterDatetime) {
    let expr = CronExpression(expression);
    return expr.getNextRun(afterDatetime);
}

# ============================================================
# Export
# ============================================================

{
    "CronExpression": CronExpression,
    "CronField": CronField,
    "CronJob": CronJob,
    "CronScheduler": CronScheduler,
    "CronBuilder": CronBuilder,
    "CronPresets": CronPresets,
    "parseCron": parseCron,
    "cron": cron,
    "schedule": schedule,
    "scheduleEveryMinute": scheduleEveryMinute,
    "scheduleEvery5Minutes": scheduleEvery5Minutes,
    "scheduleEveryHour": scheduleEveryHour,
    "scheduleEveryDay": scheduleEveryDay,
    "scheduleEveryWeek": scheduleEveryWeek,
    "scheduleEveryMonth": scheduleEveryMonth,
    "createScheduler": createScheduler,
    "builder": builder,
    "getPreset": getPreset,
    "listPresets": listPresets,
    "validateCron": validateCron,
    "getNextRun": getNextRun,
    "FIELD_MINUTE": FIELD_MINUTE,
    "FIELD_HOUR": FIELD_HOUR,
    "FIELD_DAY_OF_MONTH": FIELD_DAY_OF_MONTH,
    "FIELD_MONTH": FIELD_MONTH,
    "FIELD_DAY_OF_WEEK": FIELD_DAY_OF_WEEK,
    "VERSION": VERSION
}
