# ===========================================
# Nyx Standard Library - Collections Module (EXTENDED)
# ===========================================
# Comprehensive data structures and algorithms
# Including: advanced containers, trees, graphs, algorithms,
# sorting, searching, utilities, and more

# ===========================================
# LINKED LIST
# ===========================================

# Node for linked list
class ListNode {
    fn init(self, value) {
        self.value = value;
        self.next = null;
        self.prev = null;
    }
}

# Doubly Linked List
class LinkedList {
    fn init(self) {
        self.head = null;
        self.tail = null;
        self.size = 0;
    }
    
    fn append(self, value) {
        let node = ListNode(value);
        if self.tail == null {
            self.head = node;
            self.tail = node;
        } else {
            node.prev = self.tail;
            self.tail.next = node;
            self.tail = node;
        }
        self.size = self.size + 1;
        return self;
    }
    
    fn prepend(self, value) {
        let node = ListNode(value);
        if self.head == null {
            self.head = node;
            self.tail = node;
        } else {
            node.next = self.head;
            self.head.prev = node;
            self.head = node;
        }
        self.size = self.size + 1;
        return self;
    }
    
    fn insert(self, index, value) {
        if index < 0 || index > self.size {
            throw "Index out of bounds";
        }
        if index == 0 {
            return self.prepend(value);
        }
        if index == self.size {
            return self.append(value);
        }
        
        let node = ListNode(value);
        let current = self._get_node(index);
        
        node.prev = current.prev;
        node.next = current;
        current.prev.next = node;
        current.prev = node;
        
        self.size = self.size + 1;
        return self;
    }
    
    fn remove(self, index) {
        if index < 0 || index >= self.size {
            throw "Index out of bounds";
        }
        
        let current = self._get_node(index);
        
        if current.prev != null {
            current.prev.next = current.next;
        } else {
            self.head = current.next;
        }
        
        if current.next != null {
            current.next.prev = current.prev;
        } else {
            self.tail = current.prev;
        }
        
        self.size = self.size - 1;
        return current.value;
    }
    
    fn get(self, index) {
        if index < 0 || index >= self.size {
            throw "Index out of bounds";
        }
        return self._get_node(index).value;
    }
    
    fn set(self, index, value) {
        if index < 0 || index >= self.size {
            throw "Index out of bounds";
        }
        self._get_node(index).value = value;
        return self;
    }
    
    fn _get_node(self, index) {
        let current = null;
        if index < self.size / 2 {
            current = self.head;
            for i in range(index) {
                current = current.next;
            }
        } else {
            current = self.tail;
            for i in range(self.size - 1 - index) {
                current = current.prev;
            }
        }
        return current;
    }
    
    fn contains(self, value) {
        let current = self.head;
        while current != null {
            if current.value == value {
                return true;
            }
            current = current.next;
        }
        return false;
    }
    
    fn index_of(self, value) {
        let current = self.head;
        let index = 0;
        while current != null {
            if current.value == value {
                return index;
            }
            current = current.next;
            index = index + 1;
        }
        return -1;
    }
    
    fn clear(self) {
        self.head = null;
        self.tail = null;
        self.size = 0;
        return self;
    }
    
    fn is_empty(self) {
        return self.size == 0;
    }
    
    fn to_list(self) {
        let result = [];
        let current = self.head;
        while current != null {
            push(result, current.value);
            current = current.next;
        }
        return result;
    }
    
    fn reverse(self) {
        let current = self.head;
        let temp = null;
        
        while current != null {
            temp = current.prev;
            current.prev = current.next;
            current.next = temp;
            current = current.prev;
        }
        
        if temp != null {
            self.head = temp.prev;
        }
        
        return self;
    }
    
    fn for_each(self, fn) {
        let current = self.head;
        while current != null {
            fn(current.value);
            current = current.next;
        }
    }
    
    fn map(self, fn) {
        let result = LinkedList();
        let current = self.head;
        while current != null {
            result.append(fn(current.value));
            current = current.next;
        }
        return result;
    }
    
    fn filter(self, fn) {
        let result = LinkedList();
        let current = self.head;
        while current != null {
            if fn(current.value) {
                result.append(current.value);
            }
            current = current.next;
        }
        return result;
    }
    
    fn reduce(self, fn, initial) {
        let result = initial;
        let current = self.head;
        while current != null {
            result = fn(result, current.value);
            current = current.next;
        }
        return result;
    }
}

# ===========================================
# CIRCULAR LINKED LIST
# ===========================================

class CircularLinkedList {
    fn init(self) {
        self.tail = null;
        self.size = 0;
    }
    
    fn append(self, value) {
        let node = ListNode(value);
        if self.tail == null {
            node.next = node;
            node.prev = node;
            self.tail = node;
        } else {
            node.next = self.tail.next;
            node.prev = self.tail;
            self.tail.next.prev = node;
            self.tail.next = node;
            self.tail = node;
        }
        self.size = self.size + 1;
        return self;
    }
    
    fn prepend(self, value) {
        let node = ListNode(value);
        if self.tail == null {
            node.next = node;
            node.prev = node;
            self.tail = node;
        } else {
            node.next = self.tail.next;
            node.prev = self.tail;
            self.tail.next.prev = node;
            self.tail.next = node;
        }
        self.size = self.size + 1;
        return self;
    }
    
    fn remove(self, value) {
        if self.tail == null {
            return false;
        }
        
        let current = self.tail.next;
        while current != self.tail {
            if current.value == value {
                current.prev.next = current.next;
                current.next.prev = current.prev;
                if current == self.tail {
                    self.tail = current.prev;
                }
                self.size = self.size - 1;
                return true;
            }
            current = current.next;
        }
        
        if current.value == value {
            if self.size == 1 {
                self.tail = null;
            } else {
                current.prev.next = current.next;
                current.next.prev = current.prev;
                self.tail = current.prev;
            }
            self.size = self.size - 1;
            return true;
        }
        
        return false;
    }
    
    fn contains(self, value) {
        if self.tail == null {
            return false;
        }
        
        let current = self.tail.next;
        while current != self.tail {
            if current.value == value {
                return true;
            }
            current = current.next;
        }
        
        return current.value == value;
    }
    
    fn is_empty(self) {
        return self.size == 0;
    }
    
    fn clear(self) {
        self.tail = null;
        self.size = 0;
        return self;
    }
}

# ===========================================
# BINARY SEARCH TREE
# ===========================================

class TreeNode {
    fn init(self, key, value = null) {
        self.key = key;
        self.value = value;
        self.left = null;
        self.right = null;
        self.height = 1;
    }
}

class BinarySearchTree {
    fn init(self) {
        self.root = null;
        self.size = 0;
    }
    
    fn _height(self, node) {
        if node == null {
            return 0;
        }
        return node.height;
    }
    
    fn _balance(self, node) {
        if node == null {
            return 0;
        }
        return self._height(node.left) - self._height(node.right);
    }
    
    fn _rotate_right(self, y) {
        let x = y.left;
        let T2 = x.right;
        
        x.right = y;
        y.left = T2;
        
        y.height = max(self._height(y.left), self._height(y.right)) + 1;
        x.height = max(self._height(x.left), self._height(x.right)) + 1;
        
        return x;
    }
    
    fn _rotate_left(self, x) {
        let y = x.right;
        let T2 = y.left;
        
        y.left = x;
        x.right = T2;
        
        x.height = max(self._height(x.left), self._height(x.right)) + 1;
        y.height = max(self._height(y.left), self._height(y.right)) + 1;
        
        return y;
    }
    
    fn insert(self, key, value = null) {
        self.root = self._insert(self.root, key, value);
        self.size = self.size + 1;
        return self;
    }
    
    fn _insert(self, node, key, value) {
        if node == null {
            return TreeNode(key, value);
        }
        
        if key < node.key {
            node.left = self._insert(node.left, key, value);
        } else if key > node.key {
            node.right = self._insert(node.right, key, value);
        } else {
            node.value = value;
            self.size = self.size - 1;
            return node;
        }
        
        node.height = 1 + max(self._height(node.left), self._height(node.right));
        
        let balance = self._balance(node);
        
        # Left Left
        if balance > 1 && key < node.left.key {
            return self._rotate_right(node);
        }
        
        # Right Right
        if balance < -1 && key > node.right.key {
            return self._rotate_left(node);
        }
        
        # Left Right
        if balance > 1 && key > node.left.key {
            node.left = self._rotate_left(node.left);
            return self._rotate_right(node);
        }
        
        # Right Left
        if balance < -1 && key < node.right.key {
            node.right = self._rotate_right(node.right);
            return self._rotate_left(node);
        }
        
        return node;
    }
    
    fn remove(self, key) {
        self.root = self._remove(self.root, key);
        self.size = self.size - 1;
        return self;
    }
    
    fn _remove(self, node, key) {
        if node == null {
            return null;
        }
        
        if key < node.key {
            node.left = self._remove(node.left, key);
        } else if key > node.key {
            node.right = self._remove(node.right, key);
        } else {
            if node.left == null {
                return node.right;
            } else if node.right == null {
                return node.left;
            } else {
                let min_larger_node = node.right;
                while min_larger_node.left != null {
                    min_larger_node = min_larger_node.left;
                }
                node.key = min_larger_node.key;
                node.value = min_larger_node.value;
                node.right = self._remove(node.right, min_larger_node.key);
            }
        }
        
        if node == null {
            return null;
        }
        
        node.height = 1 + max(self._height(node.left), self._height(node.right));
        
        let balance = self._balance(node);
        
        if balance > 1 && self._balance(node.left) >= 0 {
            return self._rotate_right(node);
        }
        
        if balance > 1 && self._balance(node.left) < 0 {
            node.left = self._rotate_left(node.left);
            return self._rotate_right(node);
        }
        
        if balance < -1 && self._balance(node.right) <= 0 {
            return self._rotate_left(node);
        }
        
        if balance < -1 && self._balance(node.right) > 0 {
            node.right = self._rotate_right(node.right);
            return self._rotate_left(node);
        }
        
        return node;
    }
    
    fn search(self, key) {
        return self._search(self.root, key);
    }
    
    fn _search(self, node, key) {
        if node == null {
            return null;
        }
        
        if key == node.key {
            return node.value;
        } else if key < node.key {
            return self._search(node.left, key);
        } else {
            return self._search(node.right, key);
        }
    }
    
    fn contains(self, key) {
        return self.search(key) != null;
    }
    
    fn min(self) {
        if self.root == null {
            return null;
        }
        let current = self.root;
        while current.left != null {
            current = current.left;
        }
        return current.key;
    }
    
    fn max(self) {
        if self.root == null {
            return null;
        }
        let current = self.root;
        while current.right != null {
            current = current.right;
        }
        return current.key;
    }
    
    fn inorder(self) {
        let result = [];
        self._inorder(self.root, result);
        return result;
    }
    
    fn _inorder(self, node, result) {
        if node != null {
            self._inorder(node.left, result);
            push(result, [node.key, node.value]);
            self._inorder(node.right, result);
        }
    }
    
    fn preorder(self) {
        let result = [];
        self._preorder(self.root, result);
        return result;
    }
    
    fn _preorder(self, node, result) {
        if node != null {
            push(result, [node.key, node.value]);
            self._preorder(node.left, result);
            self._preorder(node.right, result);
        }
    }
    
    fn postorder(self) {
        let result = [];
        self._postorder(self.root, result);
        return result;
    }
    
    fn _postorder(self, node, result) {
        if node != null {
            self._postorder(node.left, result);
            self._postorder(node.right, result);
            push(result, [node.key, node.value]);
        }
    }
    
    fn is_empty(self) {
        return self.size == 0;
    }
    
    fn clear(self) {
        self.root = null;
        self.size = 0;
        return self;
    }
}

# ===========================================
# AVL TREE
# ===========================================

class AVLTree {
    fn init(self) {
        self.root = null;
        self.size = 0;
    }
    
    fn _height(self, node) {
        if node == null {
            return 0;
        }
        return node.height;
    }
    
    fn _balance(self, node) {
        if node == null {
            return 0;
        }
        return self._height(node.left) - self._height(node.right);
    }
    
    fn _rotate_right(self, y) {
        let x = y.left;
        let T2 = x.right;
        
        x.right = y;
        y.left = T2;
        
        y.height = max(self._height(y.left), self._height(y.right)) + 1;
        x.height = max(self._height(x.left), self._height(x.right)) + 1;
        
        return x;
    }
    
    fn _rotate_left(self, x) {
        let y = x.right;
        let T2 = y.left;
        
        y.left = x;
        x.right = T2;
        
        x.height = max(self._height(x.left), self._height(x.right)) + 1;
        y.height = max(self._height(y.left), self._height(y.right)) + 1;
        
        return y;
    }
    
    fn insert(self, key, value = null) {
        self.root = self._insert(self.root, key, value);
        self.size = self.size + 1;
        return self;
    }
    
    fn _insert(self, node, key, value) {
        if node == null {
            return TreeNode(key, value);
        }
        
        if key < node.key {
            node.left = self._insert(node.left, key, value);
        } else if key > node.key {
            node.right = self._insert(node.right, key, value);
        } else {
            node.value = value;
            self.size = self.size - 1;
            return node;
        }
        
        node.height = 1 + max(self._height(node.left), self._height(node.right));
        
        let balance = self._balance(node);
        
        if balance > 1 && key < node.left.key {
            return self._rotate_right(node);
        }
        
        if balance < -1 && key > node.right.key {
            return self._rotate_left(node);
        }
        
        if balance > 1 && key > node.left.key {
            node.left = self._rotate_left(node.left);
            return self._rotate_right(node);
        }
        
        if balance < -1 && key < node.right.key {
            node.right = self._rotate_right(node.right);
            return self._rotate_left(node);
        }
        
        return node;
    }
    
    fn remove(self, key) {
        self.root = self._remove(self.root, key);
        self.size = self.size - 1;
        return self;
    }
    
    fn _remove(self, node, key) {
        if node == null {
            return null;
        }
        
        if key < node.key {
            node.left = self._remove(node.left, key);
        } else if key > node.key {
            node.right = self._remove(node.right, key);
        } else {
            if node.left == null {
                return node.right;
            } else if node.right == null {
                return node.left;
            } else {
                let min_larger_node = node.right;
                while min_larger_node.left != null {
                    min_larger_node = min_larger_node.left;
                }
                node.key = min_larger_node.key;
                node.value = min_larger_node.value;
                node.right = self._remove(node.right, min_larger_node.key);
            }
        }
        
        if node == null {
            return null;
        }
        
        node.height = 1 + max(self._height(node.left), self._height(node.right));
        
        let balance = self._balance(node);
        
        if balance > 1 && self._balance(node.left) >= 0 {
            return self._rotate_right(node);
        }
        
        if balance > 1 && self._balance(node.left) < 0 {
            node.left = self._rotate_left(node.left);
            return self._rotate_right(node);
        }
        
        if balance < -1 && self._balance(node.right) <= 0 {
            return self._rotate_left(node);
        }
        
        if balance < -1 && self._balance(node.right) > 0 {
            node.right = self._rotate_right(node.right);
            return self._rotate_left(node);
        }
        
        return node;
    }
    
    fn search(self, key) {
        let current = self.root;
        while current != null {
            if key == current.key {
                return current.value;
            } else if key < current.key {
                current = current.left;
            } else {
                current = current.right;
            }
        }
        return null;
    }
    
    fn contains(self, key) {
        return self.search(key) != null;
    }
    
    fn is_empty(self) {
        return self.size == 0;
    }
}

# ===========================================
# RED-BLACK TREE
# ===========================================

class RBNode {
    fn init(self, key, value = null, color = "red") {
        self.key = key;
        self.value = value;
        self.color = color;
        self.left = null;
        self.right = null;
        self.parent = null;
    }
}

class RedBlackTree {
    fn init(self) {
        self.NIL = RBNode(null, null, "black");
        self.root = self.NIL;
        self.size = 0;
    }
    
    fn _left_rotate(self, x) {
        let y = x.right;
        x.right = y.left;
        
        if y.left != self.NIL {
            y.left.parent = x;
        }
        
        y.parent = x.parent;
        
        if x.parent == self.NIL {
            self.root = y;
        } else if x == x.parent.left {
            x.parent.left = y;
        } else {
            x.parent.right = y;
        }
        
        y.left = x;
        x.parent = y;
    }
    
    fn _right_rotate(self, y) {
        let x = y.left;
        y.left = x.right;
        
        if x.right != self.NIL {
            x.right.parent = y;
        }
        
        x.parent = y.parent;
        
        if y.parent == self.NIL {
            self.root = x;
        } else if y == y.parent.right {
            y.parent.right = x;
        } else {
            y.parent.left = x;
        }
        
        x.right = y;
        y.parent = x;
    }
    
    fn _insert_fixup(self, node) {
        while node.parent != self.NIL && node.parent.color == "red" {
            if node.parent == node.parent.parent.left {
                let uncle = node.parent.parent.right;
                
                if uncle.color == "red" {
                    node.parent.color = "black";
                    uncle.color = "black";
                    node.parent.parent.color = "red";
                    node = node.parent.parent;
                } else {
                    if node == node.parent.right {
                        node = node.parent;
                        self._left_rotate(node);
                    }
                    
                    node.parent.color = "black";
                    node.parent.parent.color = "red";
                    self._right_rotate(node.parent.parent);
                }
            } else {
                let uncle = node.parent.parent.left;
                
                if uncle.color == "red" {
                    node.parent.color = "black";
                    uncle.color = "black";
                    node.parent.parent.color = "red";
                    node = node.parent.parent;
                } else {
                    if node == node.parent.left {
                        node = node.parent;
                        self._right_rotate(node);
                    }
                    
                    node.parent.color = "black";
                    node.parent.parent.color = "red";
                    self._left_rotate(node.parent.parent);
                }
            }
        }
        
        self.root.color = "black";
    }
    
    fn insert(self, key, value = null) {
        let node = RBNode(key, value, "red");
        node.left = self.NIL;
        node.right = self.NIL;
        
        let parent = self.NIL;
        let current = self.root;
        
        while current != self.NIL {
            parent = current;
            if node.key < current.key {
                current = current.left;
            } else {
                current = current.right;
            }
        }
        
        node.parent = parent;
        
        if parent == self.NIL {
            self.root = node;
        } else if node.key < parent.key {
            parent.left = node;
        } else {
            parent.right = node;
        }
        
        self.size = self.size + 1;
        self._insert_fixup(node);
        
        return self;
    }
    
    fn _transplant(self, u, v) {
        if u.parent == self.NIL {
            self.root = v;
        } else if u == u.parent.left {
            u.parent.left = v;
        } else {
            u.parent.right = v;
        }
        v.parent = u.parent;
    }
    
    fn _minimum(self, node) {
        while node.left != self.NIL {
            node = node.left;
        }
        return node;
    }
    
    fn _delete_fixup(self, node) {
        while node != self.root && node.color == "black" {
            if node == node.parent.left {
                let sibling = node.parent.right;
                
                if sibling.color == "red" {
                    sibling.color = "black";
                    node.parent.color = "red";
                    self._left_rotate(node.parent);
                    sibling = node.parent.right;
                }
                
                if sibling.left.color == "black" && sibling.right.color == "black" {
                    sibling.color = "red";
                    node = node.parent;
                } else {
                    if sibling.right.color == "black" {
                        sibling.left.color = "black";
                        sibling.color = "red";
                        self._right_rotate(sibling);
                        sibling = node.parent.right;
                    }
                    
                    sibling.color = node.parent.color;
                    node.parent.color = "black";
                    sibling.right.color = "black";
                    self._left_rotate(node.parent);
                    node = self.root;
                }
            } else {
                let sibling = node.parent.left;
                
                if sibling.color == "red" {
                    sibling.color = "black";
                    node.parent.color = "red";
                    self._right_rotate(node.parent);
                    sibling = node.parent.left;
                }
                
                if sibling.right.color == "black" && sibling.left.color == "black" {
                    sibling.color = "red";
                    node = node.parent;
                } else {
                    if sibling.left.color == "black" {
                        sibling.right.color = "black";
                        sibling.color = "red";
                        self._left_rotate(sibling);
                        sibling = node.parent.left;
                    }
                    
                    sibling.color = node.parent.color;
                    node.parent.color = "black";
                    sibling.left.color = "black";
                    self._right_rotate(node.parent);
                    node = self.root;
                }
            }
        }
        
        node.color = "black";
    }
    
    fn _delete(self, node) {
        let y = node;
        let y_original_color = y.color;
        let x = null;
        
        if node.left == self.NIL {
            x = node.right;
            self._transplant(node, node.right);
        } else if node.right == self.NIL {
            x = node.left;
            self._transplant(node, node.left);
        } else {
            y = self._minimum(node.right);
            y_original_color = y.color;
            x = y.right;
            
            if y.parent == node {
                x.parent = y;
            } else {
                self._transplant(y, y.right);
                y.right = node.right;
                y.right.parent = y;
            }
            
            self._transplant(node, y);
            y.left = node.left;
            y.left.parent = y;
            y.color = node.color;
        }
        
        if y_original_color == "black" {
            self._delete_fixup(x);
        }
    }
    
    fn remove(self, key) {
        let node = self._search(key);
        if node != self.NIL {
            self._delete(node);
            self.size = self.size - 1;
        }
        return self;
    }
    
    fn _search(self, key) {
        let current = self.root;
        while current != self.NIL {
            if key == current.key {
                return current;
            } else if key < current.key {
                current = current.left;
            } else {
                current = current.right;
            }
        }
        return self.NIL;
    }
    
    fn search(self, key) {
        let node = self._search(key);
        if node != self.NIL {
            return node.value;
        }
        return null;
    }
    
    fn contains(self, key) {
        return self._search(key) != self.NIL;
    }
    
    fn is_empty(self) {
        return self.size == 0;
    }
}

# ===========================================
# HEAP / PRIORITY QUEUE
# ===========================================

class Heap {
    fn init(self, comparator = null) {
        self.data = [];
        self.comparator = comparator;
        if comparator == null {
            self.comparator = fn(a, b) { return a < b; };
        }
    }
    
    fn _parent(self, i) {
        return (i - 1) / 2;
    }
    
    fn _left(self, i) {
        return 2 * i + 1;
    }
    
    fn _right(self, i) {
        return 2 * i + 2;
    }
    
    fn _swap(self, i, j) {
        let temp = self.data[i];
        self.data[i] = self.data[j];
        self.data[j] = temp;
    }
    
    fn _compare(self, i, j) {
        return self.comparator(self.data[i], self.data[j]);
    }
    
    fn push(self, value) {
        push(self.data, value);
        self._sift_up(len(self.data) - 1);
        return self;
    }
    
    fn pop(self) {
        if self.is_empty() {
            throw "Heap is empty";
        }
        
        let result = self.data[0];
        let last = pop(self.data);
        
        if !self.is_empty() {
            self.data[0] = last;
            self._sift_down(0);
        }
        
        return result;
    }
    
    fn peek(self) {
        if self.is_empty() {
            return null;
        }
        return self.data[0];
    }
    
    fn _sift_up(self, i) {
        while i > 0 {
            let parent = self._parent(i);
            if self._compare(i, parent) {
                self._swap(i, parent);
                i = parent;
            } else {
                break;
            }
        }
    }
    
    fn _sift_down(self, i) {
        let size = len(self.data);
        
        while true {
            let smallest = i;
            let left = self._left(i);
            let right = self._right(i);
            
            if left < size && self._compare(left, smallest) {
                smallest = left;
            }
            
            if right < size && self._compare(right, smallest) {
                smallest = right;
            }
            
            if smallest != i {
                self._swap(i, smallest);
                i = smallest;
            } else {
                break;
            }
        }
    }
    
    fn is_empty(self) {
        return len(self.data) == 0;
    }
    
    fn size(self) {
        return len(self.data);
    }
    
    fn clear(self) {
        self.data = [];
        return self;
    }
    
    fn to_list(self) {
        return self.data;
    }
}

# Min Heap (alias)
class MinHeap < Heap {
    fn init(self) {
        super().init(fn(a, b) { return a < b; });
    }
}

# Max Heap
class MaxHeap < Heap {
    fn init(self) {
        super().init(fn(a, b) { return a > b; });
    }
}

# Priority Queue using Heap
class PriorityQueue {
    fn init(self, min_heap = true) {
        if min_heap {
            self.heap = MinHeap();
        } else {
            self.heap = MaxHeap();
        }
    }
    
    fn enqueue(self, item, priority = 0) {
        self.heap.push([priority, item]);
        return self;
    }
    
    fn dequeue(self) {
        return self.heap.pop()[1];
    }
    
    fn peek(self) {
        let result = self.heap.peek();
        if result == null {
            return null;
        }
        return result[1];
    }
    
    fn is_empty(self) {
        return self.heap.is_empty();
    }
    
    fn size(self) {
        return self.heap.size();
    }
    
    fn clear(self) {
        self.heap.clear();
        return self;
    }
}

# ===========================================
# GRAPH
# ===========================================

class Graph {
    fn init(self, directed = false) {
        self.directed = directed;
        self.adjacency_list = {};
    }
    
    fn add_vertex(self, vertex) {
        if !has(self.adjacency_list, vertex) {
            set(self.adjacency_list, vertex, []);
        }
        return self;
    }
    
    fn add_edge(self, source, destination, weight = 1.0) {
        if !has(self.adjacency_list, source) {
            self.add_vertex(source);
        }
        if !has(self.adjacency_list, destination) {
            self.add_vertex(destination);
        }
        
        let neighbors = self.adjacency_list[source];
        push(neighbors, [destination, weight]);
        set(self.adjacency_list, source, neighbors);
        
        if !self.directed {
            let reverse_neighbors = self.adjacency_list[destination];
            push(reverse_neighbors, [source, weight]);
            set(self.adjacency_list, destination, reverse_neighbors);
        }
        
        return self;
    }
    
    fn remove_edge(self, source, destination) {
        if !has(self.adjacency_list, source) {
            return self;
        }
        
        let neighbors = self.adjacency_list[source];
        let new_neighbors = [];
        for i in range(len(neighbors)) {
            if neighbors[i][0] != destination {
                push(new_neighbors, neighbors[i]);
            }
        }
        set(self.adjacency_list, source, new_neighbors);
        
        if !self.directed {
            let rev_neighbors = self.adjacency_list[destination];
            let new_rev_neighbors = [];
            for i in range(len(rev_neighbors)) {
                if rev_neighbors[i][0] != source {
                    push(new_rev_neighbors, rev_neighbors[i]);
                }
            }
            set(self.adjacency_list, destination, new_rev_neighbors);
        }
        
        return self;
    }
    
    fn remove_vertex(self, vertex) {
        if !has(self.adjacency_list, vertex) {
            return self;
        }
        
        # Remove all edges to this vertex
        for key in keys(self.adjacency_list) {
            if key != vertex {
                self.remove_edge(key, vertex);
            }
        }
        
        # Remove the vertex
        delete(self.adjacency_list, vertex);
        
        return self;
    }
    
    fn get_neighbors(self, vertex) {
        if has(self.adjacency_list, vertex) {
            return self.adjacency_list[vertex];
        }
        return [];
    }
    
    fn has_vertex(self, vertex) {
        return has(self.adjacency_list, vertex);
    }
    
    fn has_edge(self, source, destination) {
        if !has(self.adjacency_list, source) {
            return false;
        }
        let neighbors = self.adjacency_list[source];
        for i in range(len(neighbors)) {
            if neighbors[i][0] == destination {
                return true;
            }
        }
        return false;
    }
    
    fn get_edge_weight(self, source, destination) {
        if !has(self.adjacency_list, source) {
            return null;
        }
        let neighbors = self.adjacency_list[source];
        for i in range(len(neighbors)) {
            if neighbors[i][0] == destination {
                return neighbors[i][1];
            }
        }
        return null;
    }
    
    fn vertices(self) {
        return keys(self.adjacency_list);
    }
    
    fn num_vertices(self) {
        return len(keys(self.adjacency_list));
    }
    
    fn num_edges(self) {
        let count = 0;
        for key in keys(self.adjacency_list) {
            count = count + len(self.adjacency_list[key]);
        }
        if !self.directed {
            count = count / 2;
        }
        return count;
    }
    
    fn BFS(self, start) {
        if !has(self.adjacency_list, start) {
            return [];
        }
        
        let visited = {};
        let queue = [start];
        let result = [];
        
        set(visited, start, true);
        
        while len(queue) > 0 {
            let vertex = shift(queue);
            push(result, vertex);
            
            let neighbors = self.adjacency_list[vertex];
            for i in range(len(neighbors)) {
                let neighbor = neighbors[i][0];
                if !has(visited, neighbor) {
                    set(visited, neighbor, true);
                    push(queue, neighbor);
                }
            }
        }
        
        return result;
    }
    
    fn DFS(self, start) {
        if !has(self.adjacency_list, start) {
            return [];
        }
        
        let visited = {};
        let stack = [start];
        let result = [];
        
        while len(stack) > 0 {
            let vertex = pop(stack);
            
            if has(visited, vertex) {
                continue;
            }
            
            set(visited, vertex, true);
            push(result, vertex);
            
            let neighbors = self.adjacency_list[vertex];
            for i in range(len(neighbors) - 1, -1, -1) {
                let neighbor = neighbors[i][0];
                if !has(visited, neighbor) {
                    push(stack, neighbor);
                }
            }
        }
        
        return result;
    }
    
    fn dijkstra(self, start, end = null) {
        if !has(self.adjacency_list, start) {
            return {};
        }
        
        let distances = {};
        let previous = {};
        let unvisited = keys(self.adjacency_list);
        
        for i in range(len(unvisited)) {
            set(distances, unvisited[i], 1e10);
        }
        set(distances, start, 0);
        
        while len(unvisited) > 0 {
            # Find minimum distance vertex
            let min_dist = 1e10;
            let current = null;
            
            for i in range(len(unvisited)) {
                let v = unvisited[i];
                if distances[v] < min_dist {
                    min_dist = distances[v];
                    current = v;
                }
            }
            
            if current == null || min_dist == 1e10 {
                break;
            }
            
            if end != null && current == end {
                break;
            }
            
            # Remove current from unvisited
            let new_unvisited = [];
            for i in range(len(unvisited)) {
                if unvisited[i] != current {
                    push(new_unvisited, unvisited[i]);
                }
            }
            unvisited = new_unvisited;
            
            # Update distances
            let neighbors = self.adjacency_list[current];
            for i in range(len(neighbors)) {
                let neighbor = neighbors[i][0];
                let weight = neighbors[i][1];
                let alt = distances[current] + weight;
                
                if alt < distances[neighbor] {
                    set(distances, neighbor, alt);
                    set(previous, neighbor, current);
                }
            }
        }
        
        return [distances, previous];
    }
    
    fn prim(self) {
        if self.num_vertices() == 0 {
            return Graph(self.directed);
        }
        
        let in_mst = {};
        let result = Graph(self.directed);
        let keys_list = self.vertices();
        
        for i in range(len(keys_list)) {
            set(in_mst, keys_list[i], false);
        }
        
        let start = keys_list[0];
        set(in_mst, start, true);
        
        while true {
            let min_edge = null;
            let min_weight = 1e10;
            
            for i in range(len(keys_list)) {
                let v = keys_list[i];
                if in_mst[v] {
                    let neighbors = self.get_neighbors(v);
                    for j in range(len(neighbors)) {
                        let neighbor = neighbors[j][0];
                        let weight = neighbors[j][1];
                        if !in_mst[neighbor] && weight < min_weight {
                            min_weight = weight;
                            min_edge = [v, neighbor, weight];
                        }
                    }
                }
            }
            
            if min_edge == null {
                break;
            }
            
            result.add_edge(min_edge[0], min_edge[1], min_edge[2]);
            set(in_mst, min_edge[1], true);
        }
        
        return result;
    }
    
    fn clear(self) {
        self.adjacency_list = {};
        return self;
    }
}

# ===========================================
# TRIE (PREFIX TREE)
# ===========================================

class TrieNode {
    fn init(self) {
        self.children = {};
        self.is_end = false;
        self.value = null;
    }
}

class Trie {
    fn init(self) {
        self.root = TrieNode();
        self.size = 0;
    }
    
    fn insert(self, word, value = null) {
        let current = self.root;
        
        for i in range(len(word)) {
            let char = word[i];
            if !has(current.children, char) {
                set(current.children, char, TrieNode());
            }
            current = current.children[char];
        }
        
        if !current.is_end {
            self.size = self.size + 1;
        }
        current.is_end = true;
        current.value = value;
        
        return self;
    }
    
    fn search(self, word) {
        let node = self._find_node(word);
        if node != null && node.is_end {
            return node.value;
        }
        return null;
    }
    
    fn starts_with(self, prefix) {
        return self._find_node(prefix) != null;
    }
    
    fn _find_node(self, prefix) {
        let current = self.root;
        
        for i in range(len(prefix)) {
            let char = prefix[i];
            if !has(current.children, char) {
                return null;
            }
            current = current.children[char];
        }
        
        return current;
    }
    
    fn remove(self, word) {
        self._remove(self.root, word, 0);
        return self;
    }
    
    fn _remove(self, node, word, depth) {
        if node == null {
            return false;
        }
        
        if depth == len(word) {
            if node.is_end {
                node.is_end = false;
                self.size = self.size - 1;
            }
            return len(keys(node.children)) == 0;
        }
        
        let char = word[depth];
        
        if has(node.children, char) {
            let child = node.children[char];
            let should_delete = self._remove(child, word, depth + 1);
            
            if should_delete {
                delete(node.children, char);
                return !node.is_end && len(keys(node.children)) == 0;
            }
        }
        
        return false;
    }
    
    fn get_all_words(self) {
        let result = [];
        self._collect_words(self.root, "", result);
        return result;
    }
    
    fn _collect_words(self, node, prefix, result) {
        if node.is_end {
            push(result, prefix);
        }
        
        for key in keys(node.children) {
            self._collect_words(node.children[key], prefix + key, result);
        }
    }
    
    fn autocomplete(self, prefix) {
        let node = self._find_node(prefix);
        if node == null {
            return [];
        }
        
        let result = [];
        self._collect_words(node, prefix, result);
        return result;
    }
    
    fn is_empty(self) {
        return self.size == 0;
    }
}

# ===========================================
# HASH MAP / DICTIONARY
# ===========================================

class HashMap {
    fn init(self, capacity = 16, load_factor = 0.75) {
        self.capacity = capacity;
        self.load_factor = load_factor;
        self.size = 0;
        self.buckets = [];
        
        for i in range(capacity) {
            push(self.buckets, []);
        }
    }
    
    fn _hash(self, key) {
        let str_key = str(key);
        let hash = 0;
        for i in range(len(str_key)) {
            hash = (hash * 31 + int(str_key[i])) % self.capacity;
        }
        return hash;
    }
    
    fn _find_index(self, bucket, key) {
        for i in range(len(bucket)) {
            if bucket[i][0] == key {
                return i;
            }
        }
        return -1;
    }
    
    fn put(self, key, value) {
        if float(self.size) / float(self.capacity) > self.load_factor {
            self._resize();
        }
        
        let index = self._hash(key);
        let bucket = self.buckets[index];
        let idx = self._find_index(bucket, key);
        
        if idx >= 0 {
            bucket[idx][1] = value;
        } else {
            push(bucket, [key, value]);
            self.size = self.size + 1;
        }
        
        return self;
    }
    
    fn get(self, key, default = null) {
        let index = self._hash(key);
        let bucket = self.buckets[index];
        let idx = self._find_index(bucket, key);
        
        if idx >= 0 {
            return bucket[idx][1];
        }
        
        return default;
    }
    
    fn remove(self, key) {
        let index = self._hash(key);
        let bucket = self.buckets[index];
        let idx = self._find_index(bucket, key);
        
        if idx >= 0 {
            let value = bucket[idx][1];
            splice(bucket, idx, 1);
            self.size = self.size - 1;
            return value;
        }
        
        return null;
    }
    
    fn contains(self, key) {
        let index = self._hash(key);
        let bucket = self.buckets[index];
        return self._find_index(bucket, key) >= 0;
    }
    
    fn _resize(self) {
        let old_buckets = self.buckets;
        self.capacity = self.capacity * 2;
        self.buckets = [];
        
        for i in range(self.capacity) {
            push(self.buckets, []);
        }
        
        for i in range(len(old_buckets)) {
            let bucket = old_buckets[i];
            for j in range(len(bucket)) {
                self.put(bucket[j][0], bucket[j][1]);
            }
        }
    }
    
    fn keys(self) {
        let result = [];
        for i in range(len(self.buckets)) {
            let bucket = self.buckets[i];
            for j in range(len(bucket)) {
                push(result, bucket[j][0]);
            }
        }
        return result;
    }
    
    fn values(self) {
        let result = [];
        for i in range(len(self.buckets)) {
            let bucket = self.buckets[i];
            for j in range(len(bucket)) {
                push(result, bucket[j][1]);
            }
        }
        return result;
    }
    
    fn entries(self) {
        let result = [];
        for i in range(len(self.buckets)) {
            let bucket = self.buckets[i];
            for j in range(len(bucket)) {
                push(result, bucket[j]);
            }
        }
        return result;
    }
    
    fn is_empty(self) {
        return self.size == 0;
    }
    
    fn clear(self) {
        self.size = 0;
        self.buckets = [];
        for i in range(self.capacity) {
            push(self.buckets, []);
        }
        return self;
    }
}

# ===========================================
# HASH SET
# ===========================================

class HashSet {
    fn init(self, capacity = 16, load_factor = 0.75) {
        self.capacity = capacity;
        self.load_factor = load_factor;
        self.size = 0;
        self.buckets = [];
        
        for i in range(capacity) {
            push(self.buckets, []);
        }
    }
    
    fn _hash(self, value) {
        let str_val = str(value);
        let hash = 0;
        for i in range(len(str_val)) {
            hash = (hash * 31 + int(str_val[i])) % self.capacity;
        }
        return hash;
    }
    
    fn add(self, value) {
        if float(self.size) / float(self.capacity) > self.load_factor {
            self._resize();
        }
        
        let index = self._hash(value);
        let bucket = self.buckets[index];
        
        for i in range(len(bucket)) {
            if bucket[i] == value {
                return self;
            }
        }
        
        push(bucket, value);
        self.size = self.size + 1;
        
        return self;
    }
    
    fn remove(self, value) {
        let index = self._hash(value);
        let bucket = self.buckets[index];
        
        for i in range(len(bucket)) {
            if bucket[i] == value {
                splice(bucket, i, 1);
                self.size = self.size - 1;
                return true;
            }
        }
        
        return false;
    }
    
    fn contains(self, value) {
        let index = self._hash(value);
        let bucket = self.buckets[index];
        
        for i in range(len(bucket)) {
            if bucket[i] == value {
                return true;
            }
        }
        
        return false;
    }
    
    fn _resize(self) {
        let old_buckets = self.buckets;
        self.capacity = self.capacity * 2;
        self.buckets = [];
        
        for i in range(self.capacity) {
            push(self.buckets, []);
        }
        
        for i in range(len(old_buckets)) {
            let bucket = old_buckets[i];
            for j in range(len(bucket)) {
                self.add(bucket[j]);
            }
        }
    }
    
    fn to_list(self) {
        let result = [];
        for i in range(len(self.buckets)) {
            let bucket = self.buckets[i];
            for j in range(len(bucket)) {
                push(result, bucket[j]);
            }
        }
        return result;
    }
    
    fn is_empty(self) {
        return self.size == 0;
    }
    
    fn clear(self) {
        self.size = 0;
        self.buckets = [];
        for i in range(self.capacity) {
            push(self.buckets, []);
        }
        return self;
    }
    
    fn union(self, other) {
        let result = HashSet();
        
        for i in range(len(self.buckets)) {
            let bucket = self.buckets[i];
            for j in range(len(bucket)) {
                result.add(bucket[j]);
            }
        }
        
        for i in range(len(other.buckets)) {
            let bucket = other.buckets[i];
            for j in range(len(bucket)) {
                result.add(bucket[j]);
            }
        }
        
        return result;
    }
    
    fn intersection(self, other) {
        let result = HashSet();
        
        for i in range(len(self.buckets)) {
            let bucket = self.buckets[i];
            for j in range(len(bucket)) {
                if other.contains(bucket[j]) {
                    result.add(bucket[j]);
                }
            }
        }
        
        return result;
    }
    
    fn difference(self, other) {
        let result = HashSet();
        
        for i in range(len(self.buckets)) {
            let bucket = self.buckets[i];
            for j in range(len(bucket)) {
                if !other.contains(bucket[j]) {
                    result.add(bucket[j]);
                }
            }
        }
        
        return result;
    }
}

# ===========================================
# MULTIMAP
# ===========================================

class MultiMap {
    fn init(self) {
        self.map = HashMap();
    }
    
    fn put(self, key, value) {
        if !self.map.contains(key) {
            self.map.put(key, LinkedList());
        }
        self.map.get(key).append(value);
        return self;
    }
    
    fn get(self, key) {
        if self.map.contains(key) {
            return self.map.get(key).to_list();
        }
        return [];
    }
    
    fn get_first(self, key) {
        if self.map.contains(key) {
            return self.map.get(key).get(0);
        }
        return null;
    }
    
    fn remove(self, key) {
        return self.map.remove(key);
    }
    
    fn remove_value(self, key, value) {
        if self.map.contains(key) {
            let list = self.map.get(key);
            let idx = list.index_of(value);
            if idx >= 0 {
                list.remove(idx);
                return true;
            }
        }
        return false;
    }
    
    fn contains_key(self, key) {
        return self.map.contains(key);
    }
    
    fn keys(self) {
        return self.map.keys();
    }
    
    fn size(self) {
        return self.map.size();
    }
    
    fn is_empty(self) {
        return self.map.is_empty();
    }
    
    fn clear(self) {
        self.map.clear();
        return self;
    }
}

# ===========================================
# BITSET
# ===========================================

class BitSet {
    fn init(self, size) {
        self.size = size;
        self.num_words = (size + 63) / 64;
        self.words = [];
        
        for i in range(self.num_words) {
            push(self.words, 0);
        }
    }
    
    fn set(self, index) {
        if index < 0 || index >= self.size {
            throw "Index out of bounds";
        }
        
        let word_index = index / 64;
        let bit_index = index % 64;
        
        self.words[word_index] = self.words[word_index] | (1 << bit_index);
        
        return self;
    }
    
    fn clear(self, index) {
        if index < 0 || index >= self.size {
            throw "Index out of bounds";
        }
        
        let word_index = index / 64;
        let bit_index = index % 64;
        
        self.words[word_index] = self.words[word_index] & ~(1 << bit_index);
        
        return self;
    }
    
    fn get(self, index) {
        if index < 0 || index >= self.size {
            throw "Index out of bounds";
        }
        
        let word_index = index / 64;
        let bit_index = index % 64;
        
        return (self.words[word_index] & (1 << bit_index)) != 0;
    }
    
    fn toggle(self, index) {
        if index < 0 || index >= self.size {
            throw "Index out of bounds";
        }
        
        let word_index = index / 64;
        let bit_index = index % 64;
        
        self.words[word_index] = self.words[word_index] ^ (1 << bit_index);
        
        return self;
    }
    
    fn set_all(self) {
        for i in range(self.num_words) {
            self.words[i] = 0xFFFFFFFFFFFFFFFF;
        }
        return self;
    }
    
    fn clear_all(self) {
        for i in range(self.num_words) {
            self.words[i] = 0;
        }
        return self;
    }
    
    fn count(self) {
        let count = 0;
        for i in range(self.num_words) {
            let word = self.words[i];
            while word != 0 {
                count = count + (word & 1);
                word = word >> 1;
            }
        }
        return count;
    }
    
    fn and(self, other) {
        for i in range(self.num_words) {
            self.words[i] = self.words[i] & other.words[i];
        }
        return self;
    }
    
    fn or(self, other) {
        for i in range(self.num_words) {
            self.words[i] = self.words[i] | other.words[i];
        }
        return self;
    }
    
    fn xor(self, other) {
        for i in range(self.num_words) {
            self.words[i] = self.words[i] ^ other.words[i];
        }
        return self;
    }
    
    fn not(self) {
        for i in range(self.num_words) {
            self.words[i] = ~self.words[i];
        }
        return self;
    }
}

# ===========================================
# ALGORITHMS
# ===========================================

# Bubble sort
fn bubble_sort(arr, comparator = null) {
    if comparator == null {
        comparator = fn(a, b) { return a < b; };
    }
    
    let result = copy(arr);
    let n = len(result);
    
    for i in range(n - 1) {
        for j in range(n - i - 1) {
            if !comparator(result[j], result[j + 1]) {
                let temp = result[j];
                result[j] = result[j + 1];
                result[j + 1] = temp;
            }
        }
    }
    
    return result;
}

# Selection sort
fn selection_sort(arr, comparator = null) {
    if comparator == null {
        comparator = fn(a, b) { return a < b; };
    }
    
    let result = copy(arr);
    let n = len(result);
    
    for i in range(n - 1) {
        let min_idx = i;
        for j in range(i + 1, n) {
            if comparator(result[j], result[min_idx]) {
                min_idx = j;
            }
        }
        
        if min_idx != i {
            let temp = result[i];
            result[i] = result[min_idx];
            result[min_idx] = temp;
        }
    }
    
    return result;
}

# Insertion sort
fn insertion_sort(arr, comparator = null) {
    if comparator == null {
        comparator = fn(a, b) { return a < b; };
    }
    
    let result = copy(arr);
    let n = len(result);
    
    for i in range(1, n) {
        let key = result[i];
        let j = i - 1;
        
        while j >= 0 && !comparator(result[j], key) {
            result[j + 1] = result[j];
            j = j - 1;
        }
        
        result[j + 1] = key;
    }
    
    return result;
}

# Merge sort
fn merge_sort(arr, comparator = null) {
    if comparator == null {
        comparator = fn(a, b) { return a < b; };
    }
    
    if len(arr) <= 1 {
        return copy(arr);
    }
    
    let mid = len(arr) / 2;
    let left = slice(arr, 0, mid);
    let right = slice(arr, mid, len(arr));
    
    left = merge_sort(left, comparator);
    right = merge_sort(right, comparator);
    
    return merge(left, right, comparator);
}

fn merge(left, right, comparator) {
    let result = [];
    let i = 0;
    let j = 0;
    
    while i < len(left) && j < len(right) {
        if comparator(left[i], right[j]) {
            push(result, left[i]);
            i = i + 1;
        } else {
            push(result, right[j]);
            j = j + 1;
        }
    }
    
    while i < len(left) {
        push(result, left[i]);
        i = i + 1;
    }
    
    while j < len(right) {
        push(result, right[j]);
        j = j + 1;
    }
    
    return result;
}

# Quick sort
fn quick_sort(arr, comparator = null) {
    if comparator == null {
        comparator = fn(a, b) { return a < b; };
    }
    
    let result = copy(arr);
    _quick_sort(result, 0, len(result) - 1, comparator);
    return result;
}

fn _quick_sort(arr, low, high, comparator) {
    if low < high {
        let pi = _partition(arr, low, high, comparator);
        _quick_sort(arr, low, pi - 1, comparator);
        _quick_sort(arr, pi + 1, high, comparator);
    }
}

fn _partition(arr, low, high, comparator) {
    let pivot = arr[high];
    let i = low - 1;
    
    for j in range(low, high) {
        if comparator(arr[j], pivot) {
            i = i + 1;
            let temp = arr[i];
            arr[i] = arr[j];
            arr[j] = temp;
        }
    }
    
    let temp = arr[i + 1];
    arr[i + 1] = arr[high];
    arr[high] = temp;
    
    return i + 1;
}

# Heap sort
fn heap_sort(arr, comparator = null) {
    if comparator == null {
        comparator = fn(a, b) { return a < b; };
    }
    
    let result = copy(arr);
    let n = len(result);
    
    # Build max heap
    for i in range(n / 2 - 1, -1, -1) {
        _heapify(result, n, i, comparator);
    }
    
    # Extract elements
    for i in range(n - 1, 0, -1) {
        let temp = result[0];
        result[0] = result[i];
        result[i] = temp;
        
        _heapify(result, i, 0, comparator);
    }
    
    return result;
}

fn _heapify(arr, n, i, comparator) {
    let largest = i;
    let left = 2 * i + 1;
    let right = 2 * i + 2;
    
    if left < n && !comparator(arr[left], arr[largest]) {
        largest = left;
    }
    
    if right < n && !comparator(arr[right], arr[largest]) {
        largest = right;
    }
    
    if largest != i {
        let temp = arr[i];
        arr[i] = arr[largest];
        arr[largest] = temp;
        
        _heapify(arr, n, largest, comparator);
    }
}

# Binary search
fn binary_search(arr, target, comparator = null) {
    if comparator == null {
        comparator = fn(a, b) { return a < b; };
    }
    
    let left = 0;
    let right = len(arr) - 1;
    
    while left <= right {
        let mid = (left + right) / 2;
        
        if arr[mid] == target {
            return mid;
        }
        
        if comparator(arr[mid], target) {
            left = mid + 1;
        } else {
            right = mid - 1;
        }
    }
    
    return -1;
}

# Linear search
fn linear_search(arr, target) {
    for i in range(len(arr)) {
        if arr[i] == target {
            return i;
        }
    }
    return -1;
}

# Jump search
fn jump_search(arr, target, comparator = null) {
    if comparator == null {
        comparator = fn(a, b) { return a < b; };
    }
    
    let n = len(arr);
    let step = sqrt(n);
    let prev = 0;
    
    while arr[min(step, n) - 1] < target {
        prev = step;
        step = step + sqrt(n);
        if prev >= n {
            return -1;
        }
    }
    
    while arr[prev] < target {
        prev = prev + 1;
        if prev == min(step, n) {
            return -1;
        }
    }
    
    if arr[prev] == target {
        return prev;
    }
    
    return -1;
}

# Interpolation search
fn interpolation_search(arr, target) {
    let low = 0;
    let high = len(arr) - 1;
    
    while low <= high && target >= arr[low] && target <= arr[high] {
        if low == high {
            if arr[low] == target {
                return low;
            }
            return -1;
        }
        
        let pos = low + ((target - arr[low]) * (high - low) / (arr[high] - arr[low]));
        
        if arr[pos] == target {
            return pos;
        }
        
        if arr[pos] < target {
            low = pos + 1;
        } else {
            high = pos - 1;
        }
    }
    
    return -1;
}

# Fibonacci search
fn fibonacci_search(arr, target) {
    let n = len(arr);
    
    let fib_m2 = 0;
    let fib_m1 = 1;
    let fib = fib_m1 + fib_m2;
    
    while fib < n {
        fib_m2 = fib_m1;
        fib_m1 = fib;
        fib = fib_m1 + fib_m2;
    }
    
    let offset = -1;
    
    while fib > 1 {
        let i = min(offset + fib_m2, n - 1);
        
        if arr[i] < target {
            fib = fib_m1;
            fib_m1 = fib_m2;
            fib_m2 = fib - fib_m1;
            offset = i;
        } else if arr[i] > target {
            fib = fib_m2;
            fib_m1 = fib_m1 - fib_m2;
            fib_m2 = fib - fib_m1;
        } else {
            return i;
        }
    }
    
    if fib_m1 != 0 && offset + 1 < n && arr[offset + 1] == target {
        return offset + 1;
    }
    
    return -1;
}

# Exponential search
fn exponential_search(arr, target) {
    if arr[0] == target {
        return 0;
    }
    
    let i = 1;
    while i < len(arr) && arr[i] <= target {
        i = i * 2;
    }
    
    return binary_search(slice(arr, i / 2, min(i, len(arr))), target);
}

# ===========================================
# STRING ALGORITHMS
# ===========================================

# KMP Pattern Matching
fn kmp_search(text, pattern) {
    let n = len(text);
    let m = len(pattern);
    
    if m == 0 {
        return 0;
    }
    
    let lps = _compute_lps(pattern);
    
    let i = 0;
    let j = 0;
    
    while i < n {
        if text[i] == pattern[j] {
            i = i + 1;
            j = j + 1;
            
            if j == m {
                return i - j;
            }
        } else {
            if j != 0 {
                j = lps[j - 1];
            } else {
                i = i + 1;
            }
        }
    }
    
    return -1;
}

fn _compute_lps(pattern) {
    let m = len(pattern);
    let lps = [];
    for i in range(m) {
        push(lps, 0);
    }
    
    let length = 0;
    let i = 1;
    
    while i < m {
        if pattern[i] == pattern[length] {
            length = length + 1;
            lps[i] = length;
            i = i + 1;
        } else {
            if length != 0 {
                length = lps[length - 1];
            } else {
                lps[i] = 0;
                i = i + 1;
            }
        }
    }
    
    return lps;
}

# Boyer-Moore Pattern Matching
fn boyer_moore_search(text, pattern) {
    let n = len(text);
    let m = len(pattern);
    
    if m == 0 {
        return 0;
    }
    
    let bad_char = _bad_char_table(pattern);
    let s = 0;
    
    while s <= n - m {
        let j = m - 1;
        
        while j >= 0 && pattern[j] == text[s + j] {
            j = j - 1;
        }
        
        if j < 0 {
            return s;
            s = s + (if s + m < n then m - bad_char[text[s + m]] else 1);
        } else {
            s = s + max(1, j - bad_char[text[s + j]]);
        }
    }
    
    return -1;
}

fn _bad_char_table(pattern) {
    let table = {};
    let m = len(pattern);
    
    for i in range(m) {
        set(table, pattern[i], i);
    }
    
    return table;
}

# Rabin-Karp Pattern Matching
fn rabin_karp_search(text, pattern, base = 256, mod = 101) {
    let n = len(text);
    let m = len(pattern);
    
    if m == 0 {
        return 0;
    }
    
    let hash_p = 0;
    let hash_t = 0;
    let h = 1;
    
    for i in range(m - 1) {
        h = (h * base) % mod;
    }
    
    for i in range(m) {
        hash_p = (base * hash_p + int(pattern[i])) % mod;
        hash_t = (base * hash_t + int(text[i])) % mod;
    }
    
    for s in range(n - m + 1) {
        if hash_p == hash_t {
            let match = true;
            for i in range(m) {
                if text[s + i] != pattern[i] {
                    match = false;
                    break;
                }
            }
            if match {
                return s;
            }
        }
        
        if s < n - m {
            hash_t = (base * (hash_t - int(text[s]) * h) + int(text[s + m])) % mod;
            if hash_t < 0 {
                hash_t = hash_t + mod;
            }
        }
    }
    
    return -1;
}

# Longest Common Substring
fn longest_common_substring(s1, s2) {
    let m = len(s1);
    let n = len(s2);
    let max_length = 0;
    let ending_index = 0;
    
    let dp = [];
    for i in range(m + 1) {
        let row = [];
        for j in range(n + 1) {
            push(row, 0);
        }
        push(dp, row);
    }
    
    for i in range(1, m + 1) {
        for j in range(1, n + 1) {
            if s1[i - 1] == s2[j - 1] {
                dp[i][j] = dp[i - 1][j - 1] + 1;
                
                if dp[i][j] > max_length {
                    max_length = dp[i][j];
                    ending_index = i;
                }
            } else {
                dp[i][j] = 0;
            }
        }
    }
    
    return slice(s1, ending_index - max_length, ending_index);
}

# Longest Common Subsequence
fn longest_common_subsequence(s1, s2) {
    let m = len(s1);
    let n = len(s2);
    
    let dp = [];
    for i in range(m + 1) {
        let row = [];
        for j in range(n + 1) {
            push(row, 0);
        }
        push(dp, row);
    }
    
    for i in range(1, m + 1) {
        for j in range(1, n + 1) {
            if s1[i - 1] == s2[j - 1] {
                dp[i][j] = dp[i - 1][j - 1] + 1;
            } else {
                dp[i][j] = max([dp[i - 1][j], dp[i][j - 1]]);
            }
        }
    }
    
    # Backtrack to find the actual subsequence
    let result = "";
    let i = m;
    let j = n;
    
    while i > 0 && j > 0 {
        if s1[i - 1] == s2[j - 1] {
            result = s1[i - 1] + result;
            i = i - 1;
            j = j - 1;
        } else if dp[i - 1][j] > dp[i][j - 1] {
            i = i - 1;
        } else {
            j = j - 1;
        }
    }
    
    return result;
}

# ===========================================
# UTILITY FUNCTIONS
# ===========================================

fn copy(arr) {
    let result = [];
    for i in range(len(arr)) {
        push(result, arr[i]);
    }
    return result;
}

fn min(arr) {
    if len(arr) == 0 {
        return null;
    }
    let m = arr[0];
    for i in range(1, len(arr)) {
        if arr[i] < m {
            m = arr[i];
        }
    }
    return m;
}

fn max(arr) {
    if len(arr) == 0 {
        return null;
    }
    let m = arr[0];
    for i in range(1, len(arr)) {
        if arr[i] > m {
            m = arr[i];
        }
    }
    return m;
}

# ===========================================
# EXPORTED FUNCTIONS
# ===========================================

let collections_module = {
    "ListNode": ListNode,
    "LinkedList": LinkedList,
    "CircularLinkedList": CircularLinkedList,
    "TreeNode": TreeNode,
    "BinarySearchTree": BinarySearchTree,
    "AVLTree": AVLTree,
    "RBNode": RBNode,
    "RedBlackTree": RedBlackTree,
    "Heap": Heap,
    "MinHeap": MinHeap,
    "MaxHeap": MaxHeap,
    "PriorityQueue": PriorityQueue,
    "Graph": Graph,
    "TrieNode": TrieNode,
    "Trie": Trie,
    "HashMap": HashMap,
    "HashSet": HashSet,
    "MultiMap": MultiMap,
    "BitSet": BitSet,
    "bubble_sort": bubble_sort,
    "selection_sort": selection_sort,
    "insertion_sort": insertion_sort,
    "merge_sort": merge_sort,
    "quick_sort": quick_sort,
    "heap_sort": heap_sort,
    "binary_search": binary_search,
    "linear_search": linear_search,
    "jump_search": jump_search,
    "interpolation_search": interpolation_search,
    "fibonacci_search": fibonacci_search,
    "exponential_search": exponential_search,
    "kmp_search": kmp_search,
    "boyer_moore_search": boyer_moore_search,
    "rabin_karp_search": rabin_karp_search,
    "longest_common_substring": longest_common_substring,
    "longest_common_subsequence": longest_common_subsequence
};

collections_module;
