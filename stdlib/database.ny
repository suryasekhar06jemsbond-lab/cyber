# ===========================================
# Nyx Standard Library - Database Module
# ===========================================
# Database interfaces and in-memory persistence

# ===========================================
# KEY-VALUE STORE (Simple In-Memory)
# ===========================================

class KVStore {
    fn init(self) {
        self._data = {};
        self._indexes = {};
    }
    
    fn put(self, key, value) {
        self._data[key] = value;
        
        # Update indexes
        for idx_name in self._indexes {
            let idx = self._indexes[idx_name];
            if idx._keys[key] != null {
                # Re-index this key
                idx._keys[key] = value;
            }
        }
    }
    
    fn get(self, key) {
        return self._data[key];
    }
    
    fn delete(self, key) {
        self._data[key] = null;
        
        # Remove from indexes
        for idx_name in self._indexes {
            let idx = self._indexes[idx_name];
            idx._keys[key] = null;
        }
    }
    
    fn has(self, key) {
        return self._data[key] != null;
    }
    
    fn keys(self) {
        let result = [];
        for k in self._data {
            if self._data[k] != null {
                push(result, k);
            }
        }
        return result;
    }
    
    fn values(self) {
        let result = [];
        for k in self._data {
            if self._data[k] != null {
                push(result, self._data[k]);
            }
        }
        return result;
    }
    
    fn items(self) {
        let result = [];
        for k in self._data {
            if self._data[k] != null {
                push(result, [k, self._data[k]]);
            }
        }
        return result;
    }
    
    fn clear(self) {
        self._data = {};
    }
    
    fn size(self) {
        return len(self.keys());
    }
    
    # Create index on a field
    fn create_index(self, name, key_fn) {
        let idx = Index(name, key_fn);
        for k in self._data {
            if self._data[k] != null {
                idx.add(k, key_fn(self._data[k]));
            }
        }
        self._indexes[name] = idx;
    }
    
    # Query by index
    fn query(self, index_name, value) {
        if self._indexes[index_name] == null {
            throw "Index not found: " + index_name;
        }
        return self._indexes[index_name].get(value);
    }
}

class Index {
    fn init(self, name, key_fn) {
        self.name = name;
        self.key_fn = key_fn;
        self._index = {};
        self._keys = {};
    }
    
    fn add(self, key, value) {
        let idx_val = self.key_fn(value);
        
        if self._index[idx_val] == null {
            self._index[idx_val] = [];
        }
        
        push(self._index[idx_val], key);
        self._keys[key] = value;
    }
    
    fn get(self, value) {
        let key_list = self._index[value];
        if key_list == null {
            return [];
        }
        
        let result = [];
        for k in key_list {
            if self._keys[k] != null {
                push(result, self._keys[k]);
            }
        }
        return result;
    }
}

# Simple file-based KV store (JSON-backed)
class FileKVStore {
    fn init(self, filename) {
        self.filename = filename;
        self._store = KVStore();
        self.load();
    }
    
    fn load(self) {
        if file_exists(self.filename) {
            let content = read_file(self.filename);
            if len(content) > 0 {
                let data = json_decode(content);
                for k in data {
                    self._store.put(k, data[k]);
                }
            }
        }
    }
    
    fn save(self) {
        let data = {};
        for k in self._store.keys() {
            data[k] = self._store.get(k);
        }
        write_file(self.filename, json_encode(data));
    }
    
    fn put(self, key, value) {
        self._store.put(key, value);
        self.save();
    }
    
    fn get(self, key) {
        return self._store.get(key);
    }
    
    fn delete(self, key) {
        self._store.delete(key);
        self.save();
    }
}

# ===========================================
# IN-MEMORY SQL-LIKE DATABASE
# ===========================================

class Table {
    fn init(self, name, schema) {
        self.name = name;
        self.schema = schema;  # Array of {name, type}
        self.rows = [];
        self._indexes = {};
    }
    
    fn insert(self, row) {
        # Validate against schema
        let validated = {};
        for field in self.schema {
            let field_name = field.name;
            let value = row[field_name];
            if value == null && field.default != null {
                value = field.default;
            }
            validated[field_name] = value;
        }
        push(self.rows, validated);
        return len(self.rows) - 1;
    }
    
    fn select(self, condition) {
        let result = [];
        for row in self.rows {
            if type(condition) == "null" || condition(row) {
                push(result, row);
            }
        }
        return result;
    }
    
    fn update(self, updates, condition) {
        let count = 0;
        for i in range(len(self.rows)) {
            let row = self.rows[i];
            if type(condition) == "null" || condition(row) {
                for k in updates {
                    self.rows[i][k] = updates[k];
                }
                count = count + 1;
            }
        }
        return count;
    }
    
    fn delete(self, condition) {
        let to_delete = [];
        for i in range(len(self.rows)) {
            if type(condition) == "null" || condition(self.rows[i]) {
                push(to_delete, i);
            }
        }
        
        # Delete in reverse order
        for i in range(len(to_delete) - 1, -1, -1) {
            self.rows = self.rows[:to_delete[i]] + self.rows[to_delete[i] + 1:];
        }
        return len(to_delete);
    }
    
    fn create_index(self, field_name) {
        let idx = {};
        for i in range(len(self.rows)) {
            let val = self.rows[i][field_name];
            if idx[val] == null {
                idx[val] = [];
            }
            push(idx[val], i);
        }
        self._indexes[field_name] = idx;
    }
    
    fn join(self, other_table, left_field, right_field) {
        let result = [];
        for left_row in self.rows {
            let key = left_row[left_field];
            for right_row in other_table.rows {
                if right_row[right_field] == key {
                    let merged = left_row[..];
                    for k in right_row {
                        merged[k] = right_row[k];
                    }
                    push(result, merged);
                }
            }
        }
        return result;
    }
    
    fn group_by(self, field_name, agg_fn) {
        let groups = {};
        for row in self.rows {
            let key = row[field_name];
            if groups[key] == null {
                groups[key] = [];
            }
            push(groups[key], row);
        }
        
        let result = [];
        for g in groups {
            push(result, agg_fn(g, groups[g]));
        }
        return result;
    }
    
    fn order_by(self, field_name, descending) {
        if type(descending) == "null" {
            descending = false;
        }
        
        let sorted = self.rows[..];
        
        # Simple bubble sort
        for i in range(len(sorted)) {
            for j in range(i + 1, len(sorted)) {
                let a = sorted[i][field_name];
                let b = sorted[j][field_name];
                let swap = if descending { a < b } else { a > b };
                if swap {
                    let temp = sorted[i];
                    sorted[i] = sorted[j];
                    sorted[j] = temp;
                }
            }
        }
        
        return sorted;
    }
    
    fn limit(self, n) {
        return self.rows[:n];
    }
    
    fn count(self, condition) {
        return len(self.select(condition));
    }
    
    fn sum(self, field_name) {
        let total = 0;
        for row in self.rows {
            total = total + (row[field_name] ?? 0);
        }
        return total;
    }
    
    fn avg(self, field_name) {
        if len(self.rows) == 0 {
            return 0;
        }
        return self.sum(field_name) / len(self.rows);
    }
    
    fn min(self, field_name) {
        if len(self.rows) == 0 {
            return null;
        }
        let min_val = self.rows[0][field_name];
        for row in self.rows {
            if row[field_name] < min_val {
                min_val = row[field_name];
            }
        }
        return min_val;
    }
    
    fn max(self, field_name) {
        if len(self.rows) == 0 {
            return null;
        }
        let max_val = self.rows[0][field_name];
        for row in self.rows {
            if row[field_name] > max_val {
                max_val = row[field_name];
            }
        }
        return max_val;
    }
}

class Database {
    fn init(self) {
        self.tables = {};
    }
    
    fn create_table(self, name, schema) {
        self.tables[name] = Table(name, schema);
        return self.tables[name];
    }
    
    fn table(self, name) {
        return self.tables[name];
    }
    
    fn drop_table(self, name) {
        self.tables[name] = null;
    }
    
    fn tables(self) {
        let result = [];
        for t in self.tables {
            push(result, t);
        }
        return result;
    }
}

# ===========================================
# DOCUMENT STORE (JSON Documents)
# ===========================================

class DocumentStore {
    fn init(self) {
        self._docs = [];
        self._id_counter = 0;
        self._indexes = {};
    }
    
    fn insert(self, doc) {
        if doc.id == null {
            self._id_counter = self._id_counter + 1;
            doc.id = self._id_counter;
        }
        push(self._docs, doc);
        
        # Update indexes
        for idx_name in self._indexes {
            self._indexes[idx_name].add(doc);
        }
        
        return doc.id;
    }
    
    fn find(self, query) {
        let result = [];
        for doc in self._docs {
            if self._matches(doc, query) {
                push(result, doc);
            }
        }
        return result;
    }
    
    fn find_one(self, query) {
        let results = self.find(query);
        if len(results) > 0 {
            return results[0];
        }
        return null;
    }
    
    fn _matches(self, doc, query) {
        for k in query {
            if doc[k] != query[k] {
                return false;
            }
        }
        return true;
    }
    
    fn update(self, query, updates) {
        let count = 0;
        for i in range(len(self._docs)) {
            if self._matches(self._docs[i], query) {
                for k in updates {
                    self._docs[i][k] = updates[k];
                }
                count = count + 1;
            }
        }
        return count;
    }
    
    fn delete(self, query) {
        let to_delete = [];
        for i in range(len(self._docs)) {
            if self._matches(self._docs[i], query) {
                push(to_delete, i);
            }
        }
        
        for i in range(len(to_delete) - 1, -1, -1) {
            self._docs = self._docs[:to_delete[i]] + self._docs[to_delete[i] + 1:];
        }
        return len(to_delete);
    }
    
    fn create_index(self, field_name) {
        let idx = DocIndex(field_name);
        for doc in self._docs {
            idx.add(doc);
        }
        self._indexes[field_name] = idx;
    }
    
    fn find_by_index(self, field_name, value) {
        if self._indexes[field_name] != null {
            return self._indexes[field_name].get(value);
        }
        return self.find({field_name: value});
    }
    
    fn count(self) {
        return len(self._docs);
    }
}

class DocIndex {
    fn init(self, field_name) {
        self.field_name = field_name;
        self._index = {};
    }
    
    fn add(self, doc) {
        let val = doc[self.field_name];
        if val != null {
            if self._index[val] == null {
                self._index[val] = [];
            }
            push(self._index[val], doc);
        }
    }
    
    fn get(self, value) {
        return self._index[value] ?? [];
    }
}

# ===========================================
# CACHE (LRU Cache)
# ===========================================

class Cache {
    fn init(self, max_size) {
        self.max_size = max_size;
        self._cache = KVStore();
        self._order = [];
    }
    
    fn get(self, key) {
        let value = self._cache.get(key);
        if value != null {
            # Move to end (most recently used)
            let new_order = [];
            for k in self._order {
                if k != key {
                    push(new_order, k);
                }
            }
            push(new_order, key);
            self._order = new_order;
        }
        return value;
    }
    
    fn put(self, key, value) {
        # Check if key exists
        if self._cache.has(key) {
            # Update and move to end
            self._cache.put(key, value);
            let new_order = [];
            for k in self._order {
                if k != key {
                    push(new_order, k);
                }
            }
            push(new_order, key);
            self._order = new_order;
            return;
        }
        
        # Evict if full
        if len(self._order) >= self.max_size {
            let lru_key = self._order[0];
            self._cache.delete(lru_key);
            self._order = self._order[1:];
        }
        
        # Add new entry
        self._cache.put(key, value);
        push(self._order, key);
    }
    
    fn delete(self, key) {
        self._cache.delete(key);
        let new_order = [];
        for k in self._order {
            if k != key {
                push(new_order, k);
            }
        }
        self._order = new_order;
    }
    
    fn clear(self) {
        self._cache.clear();
        self._order = [];
    }
    
    fn size(self) {
        return len(self._order);
    }
}

# ===========================================
# PERSISTENCE HELPERS
# ===========================================

# Save database to file
fn save_database(db, filename) {
    let data = {};
    for table_name in db.tables() {
        let table = db.table(table_name);
        data[table_name] = table.rows;
    }
    write_file(filename, json_encode(data));
}

# Load database from file
fn load_database(filename, schema) {
    let content = read_file(filename);
    let data = json_decode(content);
    
    let db = Database();
    for table_name in data {
        let table = db.create_table(table_name, schema[table_name]);
        for row in data[table_name] {
            table.insert(row);
        }
    }
    return db;
}

# Export to CSV
fn export_csv(table, filename) {
    let lines = [];
    
    # Header
    if len(table.rows) > 0 {
        let headers = [];
        for k in table.rows[0] {
            push(headers, k);
        }
        push(lines, join(headers, ","));
    }
    
    # Rows
    for row in table.rows {
        let values = [];
        for k in row {
            let val = str(row[k]);
            # Escape quotes and wrap in quotes if contains comma
            if contains(val, ",") || contains(val, "\"") {
                val = "\"" + replace(val, "\"", "\"\"") + "\"";
            }
            push(values, val);
        }
        push(lines, join(values, ","));
    }
    
    write_file(filename, join(lines, "\n"));
}

# Import from CSV
fn import_csv(filename, has_header) {
    if type(has_header) == "null" {
        has_header = true;
    }
    
    let lines = split(read_file(filename), "\n");
    let headers = [];
    let rows = [];
    let start_idx = 0;
    
    if has_header && len(lines) > 0 {
        headers = split(lines[0], ",");
        start_idx = 1;
    }
    
    for i in range(start_idx, len(lines)) {
        if len(lines[i]) > 0 {
            let values = split(lines[i], ",");
            let row = {};
            
            for j in range(len(headers)) {
                let val = if j < len(values) { values[j] } else { "" };
                row[headers[j]] = val;
            }
            push(rows, row);
        }
    }
    
    return rows;
}
