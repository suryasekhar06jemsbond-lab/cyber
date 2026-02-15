# ===========================================
# Nyx Standard Library - Time Module
# ===========================================
# Comprehensive time and date utilities

# Current Unix timestamp in seconds
fn now() {
    return time();
}

# Current Unix timestamp in milliseconds
fn now_millis() {
    return int(time() * 1000);
}

# Current Unix timestamp in microseconds
fn now_micros() {
    return int(time() * 1000000);
}

# Current Unix timestamp in nanoseconds
fn now_nanos() {
    return int(time() * 1000000000);
}

# Sleep for seconds (supports fractional seconds)
fn sleep(seconds) {
    if type(seconds) != "int" && type(seconds) != "float" {
        throw "sleep: expected number";
    }
    if seconds < 0 {
        throw "sleep: negative duration";
    }
    
    # Use built-in sleep
    let start = time();
    while time() - start < seconds {
        # Busy wait - in a real implementation, this would be a native call
    }
    return;
}

# Sleep for milliseconds
fn sleep_ms(ms) {
    return sleep(ms / 1000.0);
}

# Sleep for microseconds
fn sleep_us(us) {
    return sleep(us / 1000000.0);
}

# Sleep for nanoseconds
fn sleep_ns(ns) {
    return sleep(ns / 1000000000.0);
}

# Parse ISO 8601 date string
fn parse_iso(s) {
    # Expected format: YYYY-MM-DDTHH:MM:SS.sssZ
    # Simplified parser - handles basic format
    let parts = split(s, "T");
    if len(parts) != 2 {
        throw "parse_iso: invalid format";
    }
    
    let date_parts = split(parts[0], "-");
    let time_parts = split(parts[1], ":");
    
    if len(date_parts) != 3 || len(time_parts) < 2 {
        throw "parse_iso: invalid format";
    }
    
    let year = int(date_parts[0]);
    let month = int(date_parts[1]);
    let day = int(date_parts[2]);
    
    let hour = int(time_parts[0]);
    let minute = int(time_parts[1]);
    let second = 0;
    let millis = 0;
    
    if len(time_parts) >= 3 {
        let sec_parts = split(time_parts[2], ".");
        second = int(sec_parts[0]);
        if len(sec_parts) >= 2 {
            let ms_str = sec_parts[1];
            while len(ms_str) < 6 {
                ms_str = ms_str + "0";
            }
            millis = int(ms_str[:3]);
        }
    }
    
    return to_timestamp(year, month, day, hour, minute, second) + millis / 1000.0;
}

# Convert timestamp to components
fn to_components(timestamp) {
    let secs = int(timestamp);
    let millis = int((timestamp - secs) * 1000);
    let days = secs / 86400;
    let year = 1970;
    let remaining_days = days;
    
    # Calculate year
    while true {
        let days_in_year = 366;
        if year % 4 != 0 || (year % 100 == 0 && year % 400 != 0) {
            days_in_year = 365;
        }
        if remaining_days < days_in_year {
            break;
        }
        remaining_days = remaining_days - days_in_year;
        year = year + 1;
    }
    
    # Calculate month and day
    let month = 1;
    let days_in_months = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if year % 4 == 0 && (year % 100 != 0 || year % 400 == 0) {
        days_in_months[1] = 29;
    }
    
    for m in range(12) {
        if remaining_days < days_in_months[m] {
            break;
        }
        remaining_days = remaining_days - days_in_months[m];
        month = month + 1;
    }
    let day = int(remaining_days) + 1;
    
    # Calculate time
    let day_secs = secs % 86400;
    let hour = day_secs / 3600;
    let minute = (day_secs % 3600) / 60;
    let second = day_secs % 60;
    
    return {
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        second: second,
        millisecond: millis,
        weekday: (int(days) + 4) % 7,
        yearday: int(remaining_days) + 1
    };
}

# Convert components to timestamp
fn to_timestamp(year, month, day, hour, minute, second) {
    let days = 0;
    
    for y in range(1970, year) {
        if y % 4 == 0 && (y % 100 != 0 || y % 400 == 0) {
            days = days + 366;
        } else {
            days = days + 365;
        }
    }
    
    let days_in_months = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if year % 4 == 0 && (year % 100 != 0 || year % 400 == 0) {
        days_in_months[1] = 29;
    }
    for m in range(1, month) {
        days = days + days_in_months[m - 1];
    }
    
    days = days + day - 1;
    let secs = days * 86400 + hour * 3600 + minute * 60 + second;
    return secs;
}

# Format time as string
fn format_time(timestamp, format) {
    if type(timestamp) == "null" {
        timestamp = time();
    }
    if type(format) == "null" {
        format = "%Y-%m-%d %H:%M:%S";
    }
    
    let comps = to_components(timestamp);
    let year = comps.year;
    let month = comps.month;
    let day = comps.day;
    let hour = comps.hour;
    let minute = comps.minute;
    let second = comps.second;
    let weekday = comps.weekday;
    let yearday = comps.yearday;
    
    let result = "";
    let i = 0;
    while i < len(format) {
        let c = format[i];
        if c == "%" {
            i = i + 1;
            if i >= len(format) {
                break;
            }
            c = format[i];
            
            if c == "Y" {
                result = result + str(year);
            } else if c == "y" {
                result = result + str(year)[2:];
            } else if c == "m" {
                result = result + (if month < 10 { "0" } else { "" }) + str(month);
            } else if c == "d" {
                result = result + (if day < 10 { "0" } else { "" }) + str(day);
            } else if c == "H" {
                result = result + (if hour < 10 { "0" } else { "" }) + str(hour);
            } else if c == "I" {
                let h = hour % 12;
                if h == 0 { h = 12; }
                result = result + (if h < 10 { "0" } else { "" }) + str(h);
            } else if c == "M" {
                result = result + (if minute < 10 { "0" } else { "" }) + str(minute);
            } else if c == "S" {
                result = result + (if second < 10 { "0" } else { "" }) + str(second);
            } else if c == "f" {
                result = result + (if comps.millisecond < 10 { "00" } else { "" }) + str(comps.millisecond);
            } else if c == "j" {
                result = result + str(yearday);
            } else if c == "w" {
                result = result + str(weekday);
            } else if c == "a" {
                let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
                result = result + days[weekday];
            } else if c == "A" {
                let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
                result = result + days[weekday];
            } else if c == "b" {
                let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                result = result + months[month - 1];
            } else if c == "B" {
                let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
                result = result + months[month - 1];
            } else if c == "p" {
                result = result + (if hour < 12 { "AM" } else { "PM" });
            } else if c == "c" {
                result = result + format_time(timestamp, "%a %b %d %H:%M:%S %Y");
            } else if c == "x" {
                result = result + format_time(timestamp, "%m/%d/%y");
            } else if c == "X" {
                result = result + format_time(timestamp, "%H:%M:%S");
            } else if c == "%" {
                result = result + "%";
            } else {
                result = result + c;
            }
        } else {
            result = result + c;
        }
        i = i + 1;
    }
    return result;
}

# Get current date components
fn localtime() {
    let t = time();
    return to_components(t);
}

# Get UTC date components
fn gmtime() {
    return to_components(time());
}

# Get current date as string (YYYY-MM-DD)
fn date() {
    return format_time(time(), "%Y-%m-%d");
}

# Get current time as string (HH:MM:SS)
fn time_str() {
    return format_time(time(), "%H:%M:%S");
}

# Get current datetime as string (ISO 8601)
fn datetime() {
    return format_time(time(), "%Y-%m-%dT%H:%M:%S");
}

# Get current datetime with milliseconds
fn datetime_ms() {
    return format_time(time(), "%Y-%m-%dT%H:%M:%S.%f");
}

# Add time duration
fn add_time(timestamp, value, unit) {
    if unit == "seconds" || unit == "s" {
        return timestamp + value;
    }
    if unit == "minutes" || unit == "m" {
        return timestamp + value * 60;
    }
    if unit == "hours" || unit == "h" {
        return timestamp + value * 3600;
    }
    if unit == "days" || unit == "d" {
        return timestamp + value * 86400;
    }
    if unit == "weeks" || unit == "w" {
        return timestamp + value * 604800;
    }
    if unit == "months" {
        let comps = to_components(timestamp);
        let new_month = comps.month + value;
        let year_offset = (new_month - 1) / 12;
        let new_month_adj = (new_month - 1) % 12 + 1;
        let new_year = comps.year + year_offset;
        let new_day = min(comps.day, days_in_month(new_year, new_month_adj));
        return to_timestamp(new_year, new_month_adj, new_day, comps.hour, comps.minute, comps.second);
    }
    if unit == "years" {
        let comps = to_components(timestamp);
        let new_year = comps.year + value;
        let new_day = min(comps.day, days_in_month(new_year, comps.month));
        return to_timestamp(new_year, comps.month, new_day, comps.hour, comps.minute, comps.second);
    }
    throw "add_time: unknown unit " + unit;
}

# Subtract time duration
fn sub_time(timestamp, value, unit) {
    return add_time(timestamp, -value, unit);
}

# Get difference between two timestamps in given unit
fn time_diff(t1, t2, unit) {
    let diff = t2 - t1;
    if unit == "seconds" || unit == "s" {
        return diff;
    }
    if unit == "minutes" || unit == "m" {
        return diff / 60;
    }
    if unit == "hours" || unit == "h" {
        return diff / 3600;
    }
    if unit == "days" || unit == "d" {
        return diff / 86400;
    }
    if unit == "weeks" || unit == "w" {
        return diff / 604800;
    }
    throw "time_diff: unknown unit " + unit;
}

# Check if year is leap year
fn is_leap_year(year) {
    return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
}

# Get days in month
fn days_in_month(year, month) {
    let days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if month == 2 && is_leap_year(year) {
        return 29;
    }
    return days[month - 1];
}

# Get days in year
fn days_in_year(year) {
    if is_leap_year(year) {
        return 366;
    }
    return 365;
}

# Get week number of year (ISO 8601)
fn week_number(timestamp) {
    let comps = to_components(timestamp);
    let year = comps.year;
    let day = comps.day;
    let dow = comps.weekday;
    let thursday = day + 3 - dow;
    
    let jan1 = to_timestamp(year, 1, 1, 0, 0, 0);
    let comps_jan1 = to_components(jan1);
    let jan1_dow = comps_jan1.weekday;
    
    let week = (thursday + 6 - jan1_dow) / 7;
    
    if comps.month == 1 && thursday <= 0 {
        let prev_year = year - 1;
        let prev_dec31 = to_timestamp(prev_year, 12, 31, 0, 0, 0);
        return week_number(prev_dec31);
    }
    
    if comps.month == 12 && thursday > days_in_year(year) {
        let next_jan1 = to_timestamp(year + 1, 1, 1, 0, 0, 0);
        return week_number(next_jan1);
    }
    
    return week;
}

# Timer class for benchmarking
class Timer {
    fn init(self) {
        self.start_time = null;
        self.end_time = null;
        self.elapsed = null;
    }
    
    fn start(self) {
        self.start_time = time();
        self.end_time = null;
        self.elapsed = null;
        return self;
    }
    
    fn stop(self) {
        if self.start_time == null {
            throw "Timer not started";
        }
        self.end_time = time();
        self.elapsed = self.end_time - self.start_time;
        return self.elapsed;
    }
    
    fn reset(self) {
        self.start_time = null;
        self.end_time = null;
        self.elapsed = null;
        return self;
    }
    
    fn elapsed_ms(self) {
        if self.elapsed == null {
            self.stop();
        }
        return self.elapsed * 1000;
    }
    
    fn elapsed_us(self) {
        if self.elapsed == null {
            self.stop();
        }
        return self.elapsed * 1000000;
    }
    
    fn elapsed_ns(self) {
        if self.elapsed == null {
            self.stop();
        }
        return self.elapsed * 1000000000;
    }
    
    fn is_running(self) {
        return self.start_time != null && self.end_time == null;
    }
}

# Stopwatch class with lap times
class Stopwatch {
    fn init(self) {
        self._start = null;
        self._laps = [];
        self._running = false;
    }
    
    fn start(self) {
        self._start = time();
        self._laps = [];
        self._running = true;
        return self;
    }
    
    fn lap(self) {
        if self._start == null {
            throw "Stopwatch not started";
        }
        let lap_time = time() - self._start;
        push(self._laps, lap_time);
        return lap_time;
    }
    
    fn stop(self) {
        if self._start == null {
            throw "Stopwatch not started";
        }
        let total = time() - self._start;
        self._start = null;
        self._running = false;
        return total;
    }
    
    fn reset(self) {
        self._start = null;
        self._laps = [];
        self._running = false;
        return self;
    }
    
    fn laps(self) {
        return self._laps;
    }
    
    fn lap_times(self) {
        let times = [];
        let prev = 0;
        for lap in self._laps {
            push(times, lap - prev);
            prev = lap;
        }
        return times;
    }
    
    fn is_running(self) {
        return self._running;
    }
}

# Rate limiter / throttle
class RateLimiter {
    fn init(self, max_calls, period) {
        self.max_calls = max_calls;
        self.period = period;
        self.calls = [];
    }
    
    fn try_acquire(self) {
        let now = time();
        # Remove old calls
        let new_calls = [];
        for ts in self.calls {
            if now - ts < self.period {
                push(new_calls, ts);
            }
        }
        self.calls = new_calls;
        
        if len(self.calls) < self.max_calls {
            push(self.calls, now);
            return true;
        }
        return false;
    }
    
    fn wait_and_acquire(self) {
        while !self.try_acquire() {
            sleep(0.01);
        }
    }
}

# Timeout wrapper
fn with_timeout(fn_to_wrap, timeout_seconds) {
    return fn(...args) {
        let start = time();
        let result = fn_to_wrap(...args);
        let elapsed = time() - start;
        if elapsed > timeout_seconds {
            throw "timeout: function took " + str(elapsed) + "s, limit was " + str(timeout_seconds) + "s";
        }
        return result;
    };
}

# Retry with exponential backoff
fn retry(fn_to_wrap, max_attempts, initial_delay, max_delay) {
    let attempt = 0;
    let delay = initial_delay;
    
    while attempt < max_attempts {
        try {
            return fn_to_wrap();
        } catch e {
            attempt = attempt + 1;
            if attempt >= max_attempts {
                throw e;
            }
            sleep(delay);
            delay = min(delay * 2, max_delay);
        }
    }
    throw "retry: max attempts exceeded";
}

# Format duration in human-readable form
fn format_duration(seconds) {
    if seconds < 0.000001 {
        return str(int(seconds * 1000000000)) + "ns";
    }
    if seconds < 0.001 {
        return str(int(seconds * 1000000)) + "μs";
    }
    if seconds < 1 {
        return str(int(seconds * 1000)) + "ms";
    }
    if seconds < 60 {
        return str(int(seconds * 100) / 100) + "s";
    }
    if seconds < 3600 {
        let mins = int(seconds / 60);
        let secs = int((seconds % 60) * 100) / 100;
        return str(mins) + "m " + str(secs) + "s";
    }
    let hours = int(seconds / 3600);
    let mins = int((seconds % 3600) / 60);
    return str(hours) + "h " + str(mins) + "m";
}

# Unix epoch constants
let EPOCH_YEAR = 1970;
let SECONDS_PER_MINUTE = 60;
let SECONDS_PER_HOUR = 3600;
let SECONDS_PER_DAY = 86400;
let SECONDS_PER_WEEK = 604800;
