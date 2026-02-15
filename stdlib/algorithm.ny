# ===========================================
# Nyx Standard Library - Algorithm Module
# ===========================================
# Common algorithms and utilities

# Sort array (in-place, uses quicksort)
fn sort(arr) {
    if type(arr) != "array" {
        throw "sort: expected array";
    }
    if len(arr) <= 1 {
        return arr;
    }
    _quick_sort(arr, 0, len(arr) - 1);
    return arr;
}

fn _quick_sort(arr, low, high) {
    if low >= high {
        return;
    }
    let pivot = _partition(arr, low, high);
    _quick_sort(arr, low, pivot - 1);
    _quick_sort(arr, pivot + 1, high);
}

fn _partition(arr, low, high) {
    let pivot_value = arr[high];
    let i = low;
    for j in range(low, high) {
        if arr[j] < pivot_value {
            let temp = arr[i];
            arr[i] = arr[j];
            arr[j] = temp;
            i = i + 1;
        }
    }
    let temp = arr[i];
    arr[i] = arr[high];
    arr[high] = temp;
    return i;
}

# Sort with comparator
fn sort_with(arr, comparator) {
    if type(arr) != "array" {
        throw "sort_with: expected array";
    }
    if len(arr) <= 1 {
        return arr;
    }
    _quick_sort_with(arr, 0, len(arr) - 1, comparator);
    return arr;
}

fn _quick_sort_with(arr, low, high, comparator) {
    if low >= high {
        return;
    }
    let pivot = _partition_with(arr, low, high, comparator);
    _quick_sort_with(arr, low, pivot - 1, comparator);
    _quick_sort_with(arr, pivot + 1, high, comparator);
}

fn _partition_with(arr, low, high, comparator) {
    let pivot_value = arr[high];
    let i = low;
    for j in range(low, high) {
        if comparator(arr[j], pivot_value) < 0 {
            let temp = arr[i];
            arr[i] = arr[j];
            arr[j] = temp;
            i = i + 1;
        }
    }
    let temp = arr[i];
    arr[i] = arr[high];
    arr[high] = temp;
    return i;
}

# Reverse array (in-place)
fn reverse(arr) {
    if type(arr) != "array" {
        throw "reverse: expected array";
    }
    let i = 0;
    let j = len(arr) - 1;
    while i < j {
        let temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
        i = i + 1;
        j = j - 1;
    }
    return arr;
}

# Find element in array (returns index or -1)
fn find(arr, value) {
    if type(arr) != "array" {
        throw "find: expected array";
    }
    for i in range(len(arr)) {
        if arr[i] == value {
            return i;
        }
    }
    return -1;
}

# Find with predicate
fn find_if(arr, predicate) {
    if type(arr) != "array" {
        throw "find_if: expected array";
    }
    for i in range(len(arr)) {
        if predicate(arr[i]) {
            return i;
        }
    }
    return -1;
}

# Filter array - keep elements that match predicate
fn filter(arr, predicate) {
    if type(arr) != "array" {
        throw "filter: expected array";
    }
    let result = [];
    for item in arr {
        if predicate(item) {
            push(result, item);
        }
    }
    return result;
}

# Map array - transform each element
fn map(arr, transform) {
    if type(arr) != "array" {
        throw "map: expected array";
    }
    let result = [];
    for item in arr {
        push(result, transform(item));
    }
    return result;
}

# Reduce array - accumulate to single value
fn reduce(arr, reducer, initial) {
    if type(arr) != "array" {
        throw "reduce: expected array";
    }
    let acc = initial;
    for item in arr {
        acc = reducer(acc, item);
    }
    return acc;
}

# Binary search (array must be sorted)
fn binary_search(arr, value) {
    if type(arr) != "array" {
        throw "binary_search: expected array";
    }
    let low = 0;
    let high = len(arr) - 1;
    
    while low <= high {
        let mid = (low + high) / 2;
        mid = int(mid);
        if arr[mid] == value {
            return mid;
        }
        if arr[mid] < value {
            low = mid + 1;
        } else {
            high = mid - 1;
        }
    }
    return -1;
}

# Unique - remove duplicates
fn unique(arr) {
    if type(arr) != "array" {
        throw "unique: expected array";
    }
    let result = [];
    for item in arr {
        if find(result, item) == -1 {
            push(result, item);
        }
    }
    return result;
}

# Unique with comparator
fn unique_with(arr, comparator) {
    if type(arr) != "array" {
        throw "unique_with: expected array";
    }
    let result = [];
    for item in arr {
        let found = false;
        for r in result {
            if comparator(item, r) == 0 {
                found = true;
                break;
            }
        }
        if !found {
            push(result, item);
        }
    }
    return result;
}

# Union of two arrays
fn union(arr1, arr2) {
    let result = [];
    for item in arr1 {
        if find(result, item) == -1 {
            push(result, item);
        }
    }
    for item in arr2 {
        if find(result, item) == -1 {
            push(result, item);
        }
    }
    return result;
}

# Intersection of two arrays
fn intersection(arr1, arr2) {
    let result = [];
    for item in arr1 {
        if find(arr2, item) != -1 && find(result, item) == -1 {
            push(result, item);
        }
    }
    return result;
}

# Difference of two arrays
fn difference(arr1, arr2) {
    let result = [];
    for item in arr1 {
        if find(arr2, item) == -1 {
            push(result, item);
        }
    }
    return result;
}

# Flatten nested array
fn flatten(arr) {
    if type(arr) != "array" {
        throw "flatten: expected array";
    }
    let result = [];
    for item in arr {
        if type(item) == "array" {
            let flattened = flatten(item);
            for f in flattened {
                push(result, f);
            }
        } else {
            push(result, item);
        }
    }
    return result;
}

# Chunk array into smaller arrays
fn chunk(arr, size) {
    if type(arr) != "array" {
        throw "chunk: expected array";
    }
    if size <= 0 {
        throw "chunk: size must be positive";
    }
    let result = [];
    for i in range(0, len(arr), size) {
        let chunk = [];
        for j in range(size) {
            if i + j < len(arr) {
                push(chunk, arr[i + j]);
            }
        }
        push(result, chunk);
    }
    return result;
}

# Zip two arrays together
fn zip(arr1, arr2) {
    if type(arr1) != "array" || type(arr2) != "array" {
        throw "zip: expected arrays";
    }
    let result = [];
    let len1 = len(arr1);
    let len2 = len(arr2);
    let min_len = (if len1 < len2 { len1 } else { len2 });
    for i in range(min_len) {
        push(result, [arr1[i], arr2[i]]);
    }
    return result;
}

# Any - check if any element matches
fn any(arr, predicate) {
    if type(arr) != "array" {
        throw "any: expected array";
    }
    for item in arr {
        if predicate(item) {
            return true;
        }
    }
    return false;
}

# All - check if all elements match
fn all(arr, predicate) {
    if type(arr) != "array" {
        throw "all: expected array";
    }
    for item in arr {
        if !predicate(item) {
            return false;
        }
    }
    return true;
}

# None - check if no elements match
fn none(arr, predicate) {
    return !any(arr, predicate);
}

# Count - count elements matching predicate
fn count(arr, predicate) {
    if type(arr) != "array" {
        throw "count: expected array";
    }
    let c = 0;
    for item in arr {
        if predicate(item) {
            c = c + 1;
        }
    }
    return c;
}

# Shuffle array (Fisher-Yates)
fn shuffle(arr) {
    if type(arr) != "array" {
        throw "shuffle: expected array";
    }
    for i in range(len(arr) - 1, 0, -1) {
        let j = int((i + 1) * random());
        let temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }
    return arr;
}

# Sample - get random elements
fn sample(arr, n) {
    if type(arr) != "array" {
        throw "sample: expected array";
    }
    if n > len(arr) {
        n = len(arr);
    }
    let indices = [];
    for i in range(len(arr)) {
        push(indices, i);
    }
    shuffle(indices);
    let result = [];
    for i in range(n) {
        push(result, arr[indices[i]]);
    }
    return result;
}
