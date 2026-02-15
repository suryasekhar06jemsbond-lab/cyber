# ============================================================
# Nyx Standard Library - State Machine Module
# ============================================================
# Comprehensive state machine framework providing deterministic state
# machines, hierarchical state machines, state charts, and
# event-driven state transitions.

# ============================================================
# Constants
# ============================================================

let VERSION = "1.0.0";

# State machine types
let FSM = "fsm";
let HSM = "hsm";
let STATE_CHART = "statechart";

# Transition types
let TRANSITION_INTERNAL = "internal";
let TRANSITION_LOCAL = "local";
let TRANSITION_EXTERNAL = "external";

# Event handling
let EVENT_HANDLED = "handled";
let EVENT_IGNORED = "ignored";
let EVENT_DEFERRED = "deferred";
let EVENT_UNHANDLED = "unhandled";

# ============================================================
# Event
# ============================================================

class Event {
    init(name, data) {
        self.name = name;
        self.data = data ?? {};
        self.source = null;
        self.timestamp = time.time();
    }

    getName() {
        return self.name;
    }

    getData() {
        return self.data;
    }

    get(key) {
        return self.data[key];
    }

    setSource(source) {
        self.source = source;
    }

    getSource() {
        return self.source;
    }

    getTimestamp() {
        return self.timestamp;
    }
}

# ============================================================
# State
# ============================================================

class State {
    init(name, parent) {
        self.name = name;
        self.parent = parent;
        self.entryAction = null;
        self.exitAction = null;
        self.transitions = {};
        self.handlers = {};
        self.initial = false;
        self.final = false;
        self.depth = 0;
    }

    setEntryAction(action) {
        self.entryAction = action;
        return self;
    }

    setExitAction(action) {
        self.exitAction = action;
        return self;
    }

    addTransition(eventName, target, action) {
        self.transitions[eventName] = {
            "target": target,
            "action": action,
            "type": TRANSITION_EXTERNAL
        };
        return self;
    }

    addInternalTransition(eventName, action) {
        self.transitions[eventName] = {
            "target": null,
            "action": action,
            "type": TRANSITION_INTERNAL
        };
        return self;
    }

    getTransition(eventName) {
        return self.transitions[eventName];
    }

    hasTransition(eventName) {
        return self.transitions[eventName] != null;
    }

    onEvent(event, context) {
        let transition = self.transitions[event.getName()];
        
        if transition == null {
            return EVENT_UNHANDLED;
        }
        
        # Execute transition action if any
        if transition["action"] != null {
            transition["action"](context, event);
        }
        
        return {
            "handled": true,
            "target": transition["target"],
            "type": transition["type"]
        };
    }

    enter(context) {
        if self.entryAction != null {
            self.entryAction(context);
        }
    }

    exit(context) {
        if self.exitAction != null {
            self.exitAction(context);
        }
    }

    getName() {
        return self.name;
    }

    getParent() {
        return self.parent;
    }

    setDepth(depth) {
        self.depth = depth;
    }

    getDepth() {
        return self.depth;
    }

    isInitial() {
        return self.initial;
    }

    setInitial(isInitial) {
        self.initial = isInitial;
        return self;
    }

    isFinal() {
        return self.final;
    }

    setFinal(isFinal) {
        self.final = isFinal;
        return self;
    }
}

# ============================================================
# Finite State Machine
# ============================================================

class StateMachine {
    init(name, initialState) {
        self.name = name;
        self.states = {};
        self.initialState = initialState;
        self.currentState = null;
        self.previousState = null;
        self.finalStates = {};
        self.active = false;
        self.transitionHistory = [];
        self.context = {};
        self.deferredEvents = [];
        self.listeners = {};
        self.errorHandler = null;
    }

    addState(state) {
        self.states[state.getName()] = state;
        
        if state.isFinal() {
            self.finalStates[state.getName()] = state;
        }
        
        return self;
    }

    addStates(states) {
        for state in states {
            self.addState(state);
        }
        return self;
    }

    setInitialState(stateName) {
        self.initialState = stateName;
        return self;
    }

    setFinalState(stateName) {
        if self.states[stateName] != null {
            self.states[stateName].setFinal(true);
            self.finalStates[stateName] = self.states[stateName];
        }
        return self;
    }

    setContext(ctx) {
        self.context = ctx;
        return self;
    }

    getContext() {
        return self.context;
    }

    start() {
        if self.initialState == null {
            return false;
        }
        
        if self.states[self.initialState] == null {
            return false;
        }
        
        self.currentState = self.states[self.initialState];
        self.currentState.enter(self.context);
        self.active = true;
        
        self._notifyListeners("start", {
            "state": self.currentState.getName()
        });
        
        return true;
    }

    stop() {
        if self.currentState != null {
            self.currentState.exit(self.context);
        }
        
        self.active = false;
        
        self._notifyListeners("stop", {
            "state": self.currentState?.getName()
        });
        
        return true;
    }

    send(event) {
        if not self.active {
            return EVENT_IGNORED;
        }
        
        if type(event) == "string" {
            event = Event(event);
        }
        
        event.setSource(self);
        
        return self._processEvent(event);
    }

    _processEvent(event) {
        let state = self.currentState;
        
        while state != null {
            let result = state.onEvent(event, self.context);
            
            if result != EVENT_UNHANDLED {
                if result["handled"] {
                    self._notifyListeners("transition", {
                        "event": event.getName(),
                        "from": state.getName(),
                        "to": result["target"]
                    });
                    
                    if result["target"] != null {
                        self._changeState(result["target"], event);
                    }
                }
                
                return result;
            }
            
            # Try parent state
            state = state.getParent();
        }
        
        self._notifyListeners("unhandled", {
            "event": event.getName(),
            "state": self.currentState.getName()
        });
        
        return EVENT_UNHANDLED;
    }

    _changeState(targetState, event) {
        let previousState = self.currentState;
        
        # Find target state
        let target = self.states[targetState];
        
        if target == null {
            # Error: target state not found
            if self.errorHandler != null {
                self.errorHandler("Target state not found: " + targetState);
            }
            return false;
        }
        
        # Calculate LCA for entry/exit
        let sourceState = previousState;
        let targetAncestors = self._getAncestors(target);
        
        # Exit states from source to LCA
        while sourceState != null and not self._contains(targetAncestors, sourceState) {
            sourceState.exit(self.context);
            self.transitionHistory = self.transitionHistory + [{
                "type": "exit",
                "state": sourceState.getName(),
                "event": event.getName()
            }];
            sourceState = sourceState.getParent();
        }
        
        # Enter states from LCA to target
        let enterStates = self._getPathToState(target, previousState);
        
        for state in enterStates {
            state.enter(self.context);
            self.transitionHistory = self.transitionHistory + [{
                "type": "entry",
                "state": state.getName(),
                "event": event.getName()
            }];
        }
        
        self.previousState = previousState;
        self.currentState = target;
        
        self._notifyListeners("stateChange", {
            "from": previousState?.getName(),
            "to": target.getName(),
            "event": event.getName()
        });
        
        return true;
    }

    _getAncestors(state) {
        let ancestors = [];
        let current = state;
        
        while current != null {
            ancestors = ancestors + [current];
            current = current.getParent();
        }
        
        return ancestors;
    }

    _contains(states, state) {
        for s in states {
            if s.getName() == state.getName() {
                return true;
            }
        }
        return false;
    }

    _getPathToState(target, fromState) {
        let path = [];
        
        if fromState == null {
            # Starting from initial state
            let targetAncestors = self._getAncestors(target);
            
            # Get path from root to target (excluding already active)
            # This is simplified
            path = path + [target];
        } else {
            let targetAncestors = self._getAncestors(target);
            let fromAncestors = self._getAncestors(fromState);
            
            # Find LCA
            let lca = null;
            for ta in targetAncestors {
                for fa in fromAncestors {
                    if ta.getName() == fa.getName() {
                        lca = ta;
                        break;
                    }
                }
                if lca != null {
                    break;
                }
            }
            
            # Add states from target up to (but not including) LCA
            for ta in targetAncestors {
                if lca != null and ta.getName() == lca.getName() {
                    break;
                }
                path = [ta] + path;
            }
        }
        
        return path;
    }

    getCurrentState() {
        if self.currentState != null {
            return self.currentState.getName();
        }
        return null;
    }

    getPreviousState() {
        if self.previousState != null {
            return self.previousState.getName();
        }
        return null;
    }

    isActive() {
        return self.active;
    }

    isInState(stateName) {
        if self.currentState == null {
            return false;
        }
        
        let current = self.currentState;
        
        while current != null {
            if current.getName() == stateName {
                return true;
            }
            current = current.getParent();
        }
        
        return false;
    }

    isFinished() {
        if self.currentState == null {
            return false;
        }
        
        return self.currentState.isFinal();
    }

    getHistory(stateName) {
        return self.transitionHistory;
    }

    reset() {
        self.currentState = null;
        self.previousState = null;
        self.transitionHistory = [];
        self.active = false;
        self.context = {};
        
        return self;
    }

    on(event, handler) {
        self.listeners[event] = self.listeners[event] ?? [];
        self.listeners[event] = self.listeners[event] + [handler];
        return self;
    }

    onTransition(handler) {
        return self.on("transition", handler);
    }

    onStateChange(handler) {
        return self.on("stateChange", handler);
    }

    onError(handler) {
        self.errorHandler = handler;
        return self;
    }

    _notifyListeners(event, data) {
        if self.listeners[event] != null {
            for handler in self.listeners[event] {
                handler(data);
            }
        }
    }

    toDot() {
        let dot = "digraph " + self.name + " {\n";
        
        # Add states
        for name in keys(self.states) {
            let state = self.states[name];
            let shape = "box";
            
            if state.isInitial() {
                shape = "ellipse";
            }
            if state.isFinal() {
                shape = "doubleoctagon";
            }
            
            dot = dot + "  " + name + " [shape=" + shape + "];\n";
        }
        
        # Add transitions
        for name in keys(self.states) {
            let state = self.states[name];
            
            for eventName in keys(state.transitions) {
                let transition = state.transitions[eventName];
                
                if transition["target"] != null {
                    dot = dot + "  " + name + " -> " + transition["target"];
                    dot = dot + " [label=\"" + eventName + "\"];\n";
                }
            }
        }
        
        dot = dot + "}\n";
        
        return dot;
    }
}

# ============================================================
# Hierarchical State Machine
# ============================================================

class HierarchicalStateMachine < StateMachine {
    init(name, initialState) {
        super(name, initialState);
        self.type = HSM;
        self.configuration = [];
        self.stateCache = {};
    }

    start() {
        # Enter initial state hierarchy
        let initial = self.states[self.initialState];
        
        if initial == null {
            return false;
        }
        
        self._enterState(initial);
        
        self.active = true;
        
        return true;
    }

    _enterState(state) {
        # Enter from root to target state
        let path = self._getPathToRoot(state);
        
        for s in path {
            s.enter(self.context);
            self.configuration = self.configuration + [s.getName()];
        }
        
        self.currentState = state;
    }

    _exitState(state) {
        # Exit from current to root
        let path = self._getPathToRoot(state);
        
        # Reverse order for exit
        for i in range(len(path) - 1, -1, -1) {
            path[i].exit(self.context);
            
            # Remove from configuration
            let newConfig = [];
            for name in self.configuration {
                if name != path[i].getName() {
                    newConfig = newConfig + [name];
                }
            }
            self.configuration = newConfig;
        }
    }

    _getPathToRoot(state) {
        let path = [];
        let current = state;
        
        while current != null {
            path = [current] + path;
            current = current.getParent();
        }
        
        return path;
    }

    _processEvent(event) {
        # Find the deepest state that handles the event
        let handled = false;
        
        # Check states from deepest to shallowest
        for i in range(len(self.configuration) - 1, -1, -1) {
            let stateName = self.configuration[i];
            let state = self.states[stateName];
            
            if state != null {
                let result = state.onEvent(event, self.context);
                
                if result != EVENT_UNHANDLED {
                    handled = true;
                    
                    if result["target"] != null {
                        self._transitionTo(result["target"], event);
                    }
                    
                    break;
                }
            }
        }
        
        return handled;
    }

    _transitionTo(targetName, event) {
        let target = self.states[targetName];
        
        if target == null {
            return false;
        }
        
        # Find LCA
        let lca = self._findLCA(target);
        
        # Exit states above LCA
        let toExit = [];
        
        for stateName in self.configuration {
            if self._isDescendantOf(self.states[stateName], lca) {
                toExit = toExit + [stateName];
            }
        }
        
        for stateName in toExit {
            self.states[stateName].exit(self.context);
            
            # Remove from configuration
            let newConfig = [];
            for name in self.configuration {
                if name != stateName {
                    newConfig = newConfig + [name];
                }
            }
            self.configuration = newConfig;
        }
        
        # Enter new states
        self._enterState(target);
        
        return true;
    }

    _findLCA(state) {
        for candidate in self.configuration {
            if self._isDescendantOf(state, self.states[candidate]) {
                return self.states[candidate];
            }
        }
        
        return null;
    }

    _isDescendantOf(state, ancestor) {
        let current = state;
        
        while current != null {
            if current.getName() == ancestor.getName() {
                return true;
            }
            current = current.getParent();
        }
        
        return false;
    }

    getConfiguration() {
        return self.configuration;
    }
}

# ============================================================
# State Machine Builder
# ============================================================

class StateMachineBuilder {
    init(name) {
        self.name = name;
        self.states = [];
        self.initialState = null;
        self.context = {};
    }

    addState(name, options) {
        let parentName = options["parent"] ?? null;
        let parent = null;
        
        if parentName != null {
            parent = self._findState(parentName);
        }
        
        let state = State(name, parent);
        
        if options["initial"] == true {
            state.setInitial(true);
            self.initialState = name;
        }
        
        if options["final"] == true {
            state.setFinal(true);
        }
        
        if options["entry"] != null {
            state.setEntryAction(options["entry"]);
        }
        
        if options["exit"] != null {
            state.setExitAction(options["exit"]);
        }
        
        self.states = self.states + [state];
        
        return state;
    }

    addStates(stateDefs) {
        for def in stateDefs {
            self.addState(def["name"], def);
        }
        
        return self;
    }

    on(eventName, fromState, toState, action) {
        let state = self._findState(fromState);
        
        if state != null {
            state.addTransition(eventName, toState, action);
        }
        
        return self;
    }

    onAny(eventName, toState, action) {
        for state in self.states {
            if not state.hasTransition(eventName) {
                state.addTransition(eventName, toState, action);
            }
        }
        
        return self;
    }

    internal(eventName, stateName, action) {
        let state = self._findState(stateName);
        
        if state != null {
            state.addInternalTransition(eventName, action);
        }
        
        return self;
    }

    setInitial(stateName) {
        self.initialState = stateName;
        
        for state in self.states {
            if state.getName() == stateName {
                state.setInitial(true);
            }
        }
        
        return self;
    }

    setContext(ctx) {
        self.context = ctx;
        return self;
    }

    build(type) {
        let machine = null;
        
        if type == HSM {
            machine = HierarchicalStateMachine(self.name, self.initialState);
        } else {
            machine = StateMachine(self.name, self.initialState);
        }
        
        for state in self.states {
            machine.addState(state);
        }
        
        machine.setContext(self.context);
        
        return machine;
    }

    buildFSM() {
        return self.build(FSM);
    }

    buildHSM() {
        return self.build(HSM);
    }

    _findState(name) {
        for state in self.states {
            if state.getName() == name {
                return state;
            }
        }
        return null;
    }
}

# ============================================================
# State Machine Utilities
# ============================================================

fn createStateMachine(name) {
    return StateMachineBuilder(name);
}

fn createFSM(name) {
    return StateMachineBuilder(name).buildFSM();
}

fn createHSM(name) {
    return StateMachineBuilder(name).buildHSM();
}

fn createEvent(name, data) {
    return Event(name, data);
}

fn createState(name, parent) {
    return State(name, parent);
}

# ============================================================
# Predefined State Machines
# ============================================================

# Connection State Machine
let ConnectionStates = {
    "disconnected": {
        "transitions": {
            "connect": "connecting"
        }
    },
    "connecting": {
        "transitions": {
            "connected": "connected",
            "error": "disconnected",
            "timeout": "disconnected"
        }
    },
    "connected": {
        "transitions": {
            "disconnect": "disconnected",
            "error": "error",
            "reconnect": "connecting"
        }
    },
    "error": {
        "transitions": {
            "retry": "connecting",
            "disconnect": "disconnected"
        }
    }
};

# Authentication State Machine
let AuthStates = {
    "anonymous": {
        "transitions": {
            "login": "authenticating"
        }
    },
    "authenticating": {
        "transitions": {
            "success": "authenticated",
            "failure": "anonymous",
            "timeout": "anonymous"
        }
    },
    "authenticated": {
        "transitions": {
            "logout": "anonymous",
            "token_expired": "anonymous",
            "refresh": "refreshing"
        }
    },
    "refreshing": {
        "transitions": {
            "success": "authenticated",
            "failure": "anonymous"
        }
    }
};

# Order Processing State Machine
let OrderStates = {
    "created": {
        "transitions": {
            "submit": "pending",
            "cancel": "cancelled"
        }
    },
    "pending": {
        "transitions": {
            "confirm": "confirmed",
            "cancel": "cancelled",
            "fail": "failed"
        }
    },
    "confirmed": {
        "transitions": {
            "process": "processing",
            "cancel": "cancelled"
        }
    },
    "processing": {
        "transitions": {
            "complete": "completed",
            "fail": "failed"
        }
    },
    "completed": {
        "transitions": {},
        "final": true
    },
    "cancelled": {
        "transitions": {},
        "final": true
    },
    "failed": {
        "transitions": {},
        "final": true
    }
};

# ============================================================
# Factory Functions for Common State Machines
# ============================================================

fn createConnectionMachine() {
    let builder = createStateMachine("connection");
    
    builder.addState("disconnected", {"initial": true});
    builder.addState("connecting", {});
    builder.addState("connected", {});
    builder.addState("error", {});
    
    builder.on("connect", "disconnected", "connecting", null);
    builder.on("connected", "connecting", "connected", null);
    builder.on("error", "connecting", "disconnected", null);
    builder.on("timeout", "connecting", "disconnected", null);
    builder.on("disconnect", "connected", "disconnected", null);
    builder.on("error", "connected", "error", null);
    builder.on("reconnect", "error", "connecting", null);
    builder.on("retry", "error", "connecting", null);
    
    return builder.buildFSM();
}

fn createAuthMachine() {
    let builder = createStateMachine("auth");
    
    builder.addState("anonymous", {"initial": true});
    builder.addState("authenticating", {});
    builder.addState("authenticated", {});
    builder.addState("refreshing", {});
    
    builder.on("login", "anonymous", "authenticating", null);
    builder.on("success", "authenticating", "authenticated", null);
    builder.on("failure", "authenticating", "anonymous", null);
    builder.on("timeout", "authenticating", "anonymous", null);
    builder.on("logout", "authenticated", "anonymous", null);
    builder.on("token_expired", "authenticated", "anonymous", null);
    builder.on("refresh", "authenticated", "refreshing", null);
    builder.on("success", "refreshing", "authenticated", null);
    builder.on("failure", "refreshing", "anonymous", null);
    
    return builder.buildFSM();
}

fn createOrderMachine() {
    let builder = createStateMachine("order");
    
    builder.addState("created", {"initial": true});
    builder.addState("pending", {});
    builder.addState("confirmed", {});
    builder.addState("processing", {});
    builder.addState("completed", {"final": true});
    builder.addState("cancelled", {"final": true});
    builder.addState("failed", {"final": true});
    
    builder.on("submit", "created", "pending", null);
    builder.on("cancel", "created", "cancelled", null);
    builder.on("confirm", "pending", "confirmed", null);
    builder.on("cancel", "pending", "cancelled", null);
    builder.on("fail", "pending", "failed", null);
    builder.on("process", "confirmed", "processing", null);
    builder.on("cancel", "confirmed", "cancelled", null);
    builder.on("complete", "processing", "completed", null);
    builder.on("fail", "processing", "failed", null);
    
    return builder.buildFSM();
}

# ============================================================
# State Machine Executor
# ============================================================

class StateMachineExecutor {
    init(machine) {
        self.machine = machine;
        self.running = false;
        self.eventQueue = [];
        self.processors = {};
    }

    start() {
        self.running = true;
        self.machine.start();
        
        # Process event queue
        while len(self.eventQueue) > 0 and self.running {
            let event = self.eventQueue[0];
            self.eventQueue = self.eventQueue[1:];
            self.machine.send(event);
        }
        
        return self;
    }

    stop() {
        self.running = false;
        self.machine.stop();
        
        return self;
    }

    send(event) {
        if type(event) == "string" {
            event = Event(event);
        }
        
        if self.running {
            return self.machine.send(event);
        } else {
            self.eventQueue = self.eventQueue + [event];
        }
    }

    addProcessor(stateName, processor) {
        self.processors[stateName] = processor;
        return self;
    }

    getState() {
        return self.machine.getCurrentState();
    }

    isFinished() {
        return self.machine.isFinished();
    }

    waitForState(stateName, timeout) {
        # Would wait for state to be reached
        return true;
    }
}

# ============================================================
# Export
# ============================================================

{
    "Event": Event,
    "State": State,
    "StateMachine": StateMachine,
    "HierarchicalStateMachine": HierarchicalStateMachine,
    "StateMachineBuilder": StateMachineBuilder,
    "StateMachineExecutor": StateMachineExecutor,
    "createStateMachine": createStateMachine,
    "createFSM": createFSM,
    "createHSM": createHSM,
    "createEvent": createEvent,
    "createState": createState,
    "createConnectionMachine": createConnectionMachine,
    "createAuthMachine": createAuthMachine,
    "createOrderMachine": createOrderMachine,
    "ConnectionStates": ConnectionStates,
    "AuthStates": AuthStates,
    "OrderStates": OrderStates,
    "FSM": FSM,
    "HSM": HSM,
    "STATE_CHART": STATE_CHART,
    "TRANSITION_INTERNAL": TRANSITION_INTERNAL,
    "TRANSITION_LOCAL": TRANSITION_LOCAL,
    "TRANSITION_EXTERNAL": TRANSITION_EXTERNAL,
    "EVENT_HANDLED": EVENT_HANDLED,
    "EVENT_IGNORED": EVENT_IGNORED,
    "EVENT_DEFERRED": EVENT_DEFERRED,
    "EVENT_UNHANDLED": EVENT_UNHANDLED,
    "VERSION": VERSION
}
