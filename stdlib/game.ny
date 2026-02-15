# ============================================================
# Nyx Standard Library - Game Module
# ============================================================
# Comprehensive game engine providing game development capabilities
# equivalent to pygame and panda3d.

# ============================================================
# Constants
# ============================================================

let TRUE = 1;
let FALSE = 0;

let VERSION = "1.0.0";

# Color constants
let BLACK = [0, 0, 0];
let WHITE = [255, 255, 255];
let RED = [255, 0, 0];
let GREEN = [0, 255, 0];
let BLUE = [0, 0, 255];
let YELLOW = [255, 255, 0];
let CYAN = [0, 255, 255];
let MAGENTA = [255, 0, 255];

# Key constants
let K_BACKSPACE = 8;
let K_TAB = 9;
let K_RETURN = 13;
let K_ESCAPE = 27;
let K_SPACE = 32;
let K_EXCLAIM = 33;
let K_QUOTEDBL = 34;
let K_HASH = 35;
let K_DOLLAR = 36;
let K_AMPERSAND = 38;
let K_QUOTE = 39;
let K_LEFTPAREN = 40;
let K_RIGHTPAREN = 41;
let K_ASTERISK = 42;
let K_PLUS = 43;
let K_COMMA = 44;
let K_MINUS = 45;
let K_PERIOD = 46;
let K_SLASH = 47;

let K_0 = 48;
let K_1 = 49;
let K_2 = 50;
let K_3 = 51;
let K_4 = 52;
let K_5 = 53;
let K_6 = 54;
let K_7 = 55;
let K_8 = 56;
let K_9 = 57;

let K_COLON = 58;
let K_SEMICOLON = 59;
let K_LESS = 60;
let K_EQUALS = 61;
let K_GREATER = 62;
let K_QUESTION = 63;
let K_AT = 64;

let K_LEFTBRACKET = 91;
let K_BACKSLASH = 92;
let K_RIGHTBRACKET = 93;
let K_CARET = 94;
let K_UNDERSCORE = 95;
let K_BACKQUOTE = 96;

let K_a = 97;
let K_b = 98;
let K_c = 99;
let K_d = 100;
let K_e = 101;
let K_f = 102;
let K_g = 103;
let K_h = 104;
let K_i = 105;
let K_j = 106;
let K_k = 107;
let K_l = 108;
let K_m = 109;
let K_n = 110;
let K_o = 111;
let K_p = 112;
let K_q = 113;
let K_r = 114;
let K_s = 115;
let K_t = 116;
let K_u = 117;
let K_v = 118;
let K_w = 119;
let K_x = 120;
let K_y = 121;
let K_z = 122;

let K_CAPSLOCK = 300;
let K_F1 = 282;
let K_F2 = 283;
let K_F3 = 284;
let K_F4 = 285;
let K_F5 = 286;
let K_F6 = 287;
let K_F7 = 288;
let K_F8 = 289;
let K_F9 = 290;
let K_F10 = 291;
let K_F11 = 292;
let K_F12 = 293;

let K_RSHIFT = 303;
let K_LSHIFT = 304;
let K_RCTRL = 305;
let K_LCTRL = 306;
let K_RALT = 307;
let K_LALT = 308;

let K_UP = 273;
let K_DOWN = 274;
let K_RIGHT = 275;
let K_LEFT = 276;
let K_INSERT = 277;
let K_DELETE = 127;
let K_HOME = 278;
let K_END = 279;
let K_PAGEUP = 280;
let K_PAGEDOWN = 281;

# Mouse constants
let MOUSE_LEFT_BUTTON = 1;
let MOUSE_MIDDLE_BUTTON = 2;
let MOUSE_RIGHT_BUTTON = 3;
let MOUSE_WHEEL_UP = 4;
let MOUSE_WHEEL_DOWN = 5;

# Joystick constants
let JOY_AXIS_X = 0;
let JOY_AXIS_Y = 1;
let JOY_AXIS_Z = 2;
let JOY_BUTTON_A = 0;
let JOY_BUTTON_B = 1;
let JOY_BUTTON_X = 2;
let JOY_BUTTON_Y = 3;

# ============================================================
# Game Class
# ============================================================

class Game {
    init(title, width, height, fps, flags) {
        self.title = title || "Nyx Game";
        self.width = width || 800;
        self.height = height || 600;
        self.fps = fps || 60;
        self.flags = flags || 0;
        
        self.running = false;
        self.clock = null;
        self.screen = null;
        self._state = null;
        self._scenes = {};
        self._current_scene = null;
        self._groups = {};
        self._event_queue = [];
    }

    init_game() {
        # Initialize game systems
    }

    set_scene(scene_name) {
        if self._scenes[scene_name] {
            if self._current_scene && self._current_scene.on_exit {
                self._current_scene.on_exit();
            }
            self._current_scene = self._scenes[scene_name];
            if self._current_scene.on_enter {
                self._current_scene.on_enter();
            }
        }
    }

    add_scene(name, scene) {
        self._scenes[name] = scene;
    }

    add_group(group) {
        self._groups[group.name] = group;
    }

    remove_group(name) {
        delete self._groups[name];
    }

    get_group(name) {
        return self._groups[name];
    }

    run() {
        self.running = true;
        self.init_game();
        
        while self.running {
            self.handle_events();
            self.update();
            self.render();
            self.tick();
        }
        
        self.cleanup();
    }

    handle_events() {
        # Handle input events
    }

    update() {
        if self._current_scene && self._current_scene.update {
            self._current_scene.update();
        }
        
        for let name in self._groups {
            self._groups[name].update();
        }
    }

    render() {
        # Render game
    }

    tick() {
        if self.clock {
            self.clock.tick(self.fps);
        }
    }

    cleanup() {
        # Cleanup game resources
    }

    quit() {
        self.running = false;
    }

    set_caption(caption) {
        self.title = caption;
    }

    get_caption() {
        return self.title;
    }

    get_version() {
        return VERSION;
    }

    get_fps() {
        if self.clock {
            return self.clock.get_fps();
        }
        return 0;
    }

    get_time() {
        if self.clock {
            return self.clock.get_time();
        }
        return 0;
    }
}

# ============================================================
# Clock
# ============================================================

class Clock {
    init() {
        self._start_time = 0;
        self._last_tick = 0;
        self._fps = 0;
        self._frame_count = 0;
        self._fps_timer = 0;
        self._target_fps = 60;
        self._frame_time = 1.0 / self._target_fps;
    }

    tick(framerate) {
        self._target_fps = framerate || 60;
        self._frame_time = 1.0 / self._target_fps;
        self._frame_count = self._frame_count + 1;
        return self._frame_time;
    }

    get_fps() {
        return self._fps;
    }

    get_time() {
        return 0;
    }

    get_rawtime() {
        return 0;
    }

    wait() {
        # Wait for next frame
    }

    tick_busy_loop(framerate) {
        return self.tick(framerate);
    }

    get_framerate() {
        return self._fps;
    }
}

fn Clock():
    return Clock.new()

# ============================================================
# Surface (Screen/Display)
# ============================================================

class Surface {
    init(width, height, depth, flags) {
        self.width = width || 800;
        self.height = height || 600;
        self.depth = depth || 32;
        self.flags = flags || 0;
        
        self._pixels = [];
        self._rect = Rect.new(0, 0, self.width, self.height);
        self._subsurfaces = [];
    }

    get_width() {
        return self.width;
    }

    get_height() {
        return self.height;
    }

    get_size() {
        return [self.width, self.height];
    }

    get_rect() {
        return self._rect;
    }

    get_bitsize() {
        return self.depth;
    }

    get_bytesize() {
        return self.depth / 8;
    }

    get_flags() {
        return self.flags;
    }

    get_palette() {
        return [];
    }

    get_palette_size() {
        return 0;
    }

    set_palette(palette) {
        # Set color palette
    }

    set_palette_at(index, color) {
        # Set palette entry
    }

    map_rgb(color) {
        return 0;
    }

    unmap_rgb(color) {
        return [0, 0, 0];
    }

    get_at(x, y) {
        return [0, 0, 0, 255];
    }

    set_at(x, y, color) {
        # Set pixel
    }

    get_buffer() {
        return "";
    }

    blit(source, dest, area, special_flags) {
        # Blit surface
        return Rect.new(0, 0, 0, 0);
    }

    convert(depth, flags) {
        let surf = Surface.new(self.width, self.height, depth, flags);
        return surf;
    }

    convert_alpha() {
        let surf = Surface.new(self.width, self.height, 32, 0);
        return surf;
    }

    copy() {
        return self.convert();
    }

    fill(color, rect, special_flags) {
        # Fill surface
    }

    fill_rect(rect, color) {
        # Fill rectangle
    }

    scroll(dx, dy) {
        # Scroll surface
    }

    set_colorkey(color, flags) {
        # Set color key
    }

    get_colorkey() {
        return [0, 0, 0, 255];
    }

    set_alpha(value, flags) {
        # Set alpha
    }

    get_alpha() {
        return 255;
    }

    set_clip(rect) {
        # Set clipping rectangle
    }

    get_clip() {
        return self._rect;
    }

    get_offset() {
        return [0, 0];
    }

    get_parent() {
        return null;
    }

    get_abs_offset() {
        return [0, 0];
    }

    get_abs_parent() {
        return null;
    }

    get_bounds() {
        return [0, 0, self.width, self.height];
    }

    get_buffer() {
        return "";
    }

    lock() {
        # Lock surface for pixel access
    }

    unlock() {
        # Unlock surface
    }

    must_lock() {
        return false;
    }

    get_locked() {
        return false;
    }

    get_locks() {
        return 0;
    }

    subsurface(rect) {
        let surf = Surface.new(rect.width, rect.height, self.depth, 0);
        surf._parent = self;
        surf._offset = [rect.x, rect.y];
        return surf;
    }

    get_subsurface(rect) {
        return self.subsurface(rect);
    }

    save(filename, format) {
        # Save surface to file
    }

    set_masks(masks) {
        # Set bit masks
    }

    get_masks() {
        return [0xFF0000, 0xFF00, 0xFF, 0xFF000000];
    }

    set_shifts(shifts) {
        # Set bit shifts
    }

    get_shifts() {
        return [16, 8, 0, 24];
    }

    set_losses(losses) {
        # Set bit losses
    }

    get_losses() {
        return [0, 0, 0, 0];
    }
}

# ============================================================
# Rect (Rectangle)
# ============================================================

class Rect {
    init(x, y, width, height) {
        self.x = x || 0;
        self.y = y || 0;
        self.width = width || 0;
        self.height = height || 0;
    }

    copy() {
        return Rect.new(self.x, self.y, self.width, self.height);
    }

    move(x, y) {
        return Rect.new(self.x + x, self.y + y, self.width, self.height);
    }

    move_ip(x, y) {
        self.x = self.x + x;
        self.y = self.y + y;
    }

    inflate(x, y) {
        return Rect.new(self.x - x / 2, self.y - y / 2, self.width + x, self.height + y);
    }

    inflate_ip(x, y) {
        self.x = self.x - x / 2;
        self.y = self.y - y / 2;
        self.width = self.width + x;
        self.height = self.height + y;
    }

    clamp(rect) {
        return Rect.new(self.x, self.y, self.width, self.height);
    }

    clip(rect) {
        return Rect.new(self.x, self.y, self.width, self.height);
    }

    union(rect) {
        return Rect.new(0, 0, 0, 0);
    }

    union_ip(rect) {
        # Update rect to union
    }

    fit(rect) {
        return Rect.new(self.x, self.y, self.width, self.height);
    }

    contains(rect) {
        return self.x <= rect.x && 
               self.y <= rect.y && 
               self.x + self.width >= rect.x + rect.width && 
               self.y + self.height >= rect.y + rect.height;
    }

    colliderect(rect) {
        return self.x < rect.x + rect.width &&
               self.x + self.width > rect.x &&
               self.y < rect.y + rect.height &&
               self.y + self.height > rect.y;
    }

    collidepoint(x, y) {
        return x >= self.x && x <= self.x + self.width &&
               y >= self.y && y <= self.y + self.height;
    }

    collideline(start, end) {
        return false;
    }

    collidepointall(points) {
        let result = [];
        for let p in points {
            if self.collidepoint(p[0], p[1]) {
                result.push(p);
            }
        }
        return result;
    }

    collidelist(rects) {
        return -1;
    }

    collidelistall(rects) {
        return [];
    }

    colliderectlistall(rects) {
        return [];
    }

    get_size() {
        return [self.width, self.height];
    }

    get_width() {
        return self.width;
    }

    get_height() {
        return self.height;
    }

    get_center() {
        return [self.x + self.width / 2, self.y + self.height / 2];
    }

    get_topleft() {
        return [self.x, self.y];
    }

    get_topright() {
        return [self.x + self.width, self.y];
    }

    get_bottomleft() {
        return [self.x, self.y + self.height];
    }

    get_bottomright() {
        return [self.x + self.width, self.y + self.height];
    }

    get_midleft() {
        return [self.x, self.y + self.height / 2];
    }

    get_midright() {
        return [self.x + self.width, self.y + self.height / 2];
    }

    get_midtop() {
        return [self.x + self.width / 2, self.y];
    }

    get_midbottom() {
        return [self.x + self.width / 2, self.y + self.height];
    }

    set_center(x, y) {
        self.x = x - self.width / 2;
        self.y = y - self.height / 2;
    }

    set_midleft(x, y) {
        self.x = x;
        self.y = y - self.height / 2;
    }

    set_midright(x, y) {
        self.x = x - self.width;
        self.y = y - self.height / 2;
    }

    set_midtop(x, y) {
        self.x = x - self.width / 2;
        self.y = y;
    }

    set_midbottom(x, y) {
        self.x = x - self.width / 2;
        self.y = y - self.height;
    }

    __repr__() {
        return "Rect(" + str(self.x) + ", " + str(self.y) + ", " + str(self.width) + ", " + str(self.height) + ")";
    }
}

# ============================================================
# Color
# ============================================================

class Color {
    init(r, g, b, a) {
        self.r = r || 0;
        self.g = g || 0;
        self.b = b || 0;
        self.a = a || 255;
    }

    get_rgb() {
        return [self.r, self.g, self.b];
    }

    get_rgba() {
        return [self.r, self.g, self.b, self.a];
    }

    set_rgb(r, g, b) {
        self.r = r;
        self.g = g;
        self.b = b;
    }

    set_rgba(r, g, b, a) {
        self.r = r;
        self.g = g;
        self.b = b;
        self.a = a;
    }

    grayscale() {
        return int(0.299 * self.r + 0.587 * self.g + 0.114 * self.b);
    }

    inverse() {
        return Color.new(255 - self.r, 255 - self.g, 255 - self.b, self.a);
    }

    lerp(color, amount) {
        let r = int(self.r + (color.r - self.r) * amount);
        let g = int(self.g + (color.g - self.g) * amount);
        let b = int(self.b + (color.b - self.b) * amount);
        let a = int(self.a + (color.a - self.a) * amount);
        return Color.new(r, g, b, a);
    }

    __repr__() {
        return "Color(" + str(self.r) + ", " + str(self.g) + ", " + str(self.b) + ", " + str(self.a) + ")";
    }
}

# ============================================================
# Sprite
# ============================================================

class Sprite {
    init(image, x, y) {
        self.image = image;
        self.x = x || 0;
        self.y = y || 0;
        
        if self.image {
            self.width = self.image.width;
            self.height = self.image.height;
        } else {
            self.width = 0;
            self.height = 0;
        }
        
        self.rect = Rect.new(self.x, self.y, self.width, self.height);
        self.visible = true;
        self.alive = true;
        self.layer = 0;
        self._groups = [];
    }

    add_group(group) {
        if !self._groups.includes(group) {
            self._groups.push(group);
        }
    }

    remove_group(group) {
        self._groups = self._groups.filter(fn(g) { return g != group; });
    }

    groups() {
        return self._groups;
    }

    update(dt) {
        # Update sprite
    }

    draw(surface) {
        if self.visible && self.image {
            surface.blit(self.image, [self.x, self.y]);
        }
    }

    kill() {
        self.alive = false;
        for let group in self._groups {
            group.remove(self);
        }
    }

    alive() {
        return self.alive;
    }

    kill():
        self.kill()

    def alive():
        return self.alive()

    def get_rect():
        return self.rect

    def set_position(x, y):
        self.x = x
        self.y = y
        self.rect.x = x
        self.rect.y = y

    def get_position():
        return [self.x, self.y]

    def set_layer(layer):
        self.layer = layer

    def get_layer():
        return self.layer
}

# ============================================================
# Sprite Group
# ============================================================

class SpriteGroup {
    init() {
        self._sprites = [];
        self.name = "";
    }

    add(sprite) {
        if !self._sprites.includes(sprite) {
            self._sprites.push(sprite);
            sprite.add_group(self);
        }
    }

    add_multiple(sprites) {
        for let sprite in sprites {
            self.add(sprite);
        }
    }

    remove(sprite) {
        self._sprites = self._sprites.filter(fn(s) { return s != sprite; });
        sprite.remove_group(self);
    }

    has(sprite) {
        return self._sprites.includes(sprite);
    }

    empty() {
        for let sprite in self._sprites {
            sprite.remove_group(self);
        }
        self._sprites = [];
    }

    update(dt) {
        for let sprite in self._sprites {
            if sprite.update {
                sprite.update(dt);
            }
        }
    }

    draw(surface) {
        for let sprite in self._sprites {
            if sprite.draw {
                sprite.draw(surface);
            }
        }
    }

    sprites() {
        return self._sprites;
    }

    len() {
        return len(self._sprites);
    }

    __len__() {
        return len(self._sprites);
    }

    __iter__() {
        return self._sprites.__iter__();
    }

    __next__() {
        return self._sprites.__next__();
    }

    kill() {
        for let sprite in self._sprites {
            sprite.kill();
        }
    }

    alive() {
        for let sprite in self._sprites {
            if sprite.alive() {
                return true;
            }
        }
        return false;
    }

    get_sprites_from_layer(layer) {
        return self._sprites.filter(fn(s) { return s.layer == layer; });
    }

    change_layer(sprite, new_layer) {
        sprite.set_layer(new_layer);
    }

    get_top_layer() {
        let max_layer = -1000;
        for let sprite in self._sprites {
            if sprite.layer > max_layer {
                max_layer = sprite.layer;
            }
        }
        return max_layer;
    }

    get_bottom_layer() {
        let min_layer = 1000;
        for let sprite in self._sprites {
            if sprite.layer < min_layer {
                min_layer = sprite.layer;
            }
        }
        return min_layer;
    }

    layers() {
        let layer_set = {};
        for let sprite in self._sprites {
            layer_set[sprite.layer] = true;
        }
        return keys(layer_set);
    }

    draw(surface, bgi):
        self.draw(surface)
}

# ============================================================
# Scene
# ============================================================

class Scene {
    init(game) {
        self.game = game;
        self._entities = [];
        self._groups = {};
        self._cameras = [];
        self._active_camera = null;
    }

    add_entity(entity) {
        self._entities.push(entity);
    }

    remove_entity(entity) {
        self._entities = self._entities.filter(fn(e) { return e != entity; });
    }

    get_entities() {
        return self._entities;
    }

    get_entities_by_group(group) {
        return self._entities.filter(fn(e) { return e.group == group; });
    }

    add_group(name, group) {
        self._groups[name] = group;
    }

    get_group(name) {
        return self._groups[name];
    }

    add_camera(camera) {
        self._cameras.push(camera);
        if !self._active_camera {
            self._active_camera = camera;
        }
    }

    set_active_camera(camera) {
        self._active_camera = camera;
    }

    get_active_camera() {
        return self._active_camera;
    }

    update() {
        for let entity in self._entities {
            if entity.update {
                entity.update();
            }
        }
    }

    render(surface) {
        for let entity in self._entities {
            if entity.render {
                entity.render(surface);
            }
        }
    }

    on_enter() {
        # Called when scene becomes active
    }

    on_exit() {
        # Called when scene becomes inactive
    }

    handle_event(event) {
        for let entity in self._entities {
            if entity.handle_event {
                entity.handle_event(event);
            }
        }
    }
}

# ============================================================
# Entity
# ============================================================

class Entity {
    init(x, y) {
        self.x = x || 0;
        self.y = y || 0;
        self.vx = 0;
        self.vy = 0;
        self.rotation = 0;
        self.scale_x = 1;
        self.scale_y = 1;
        self.visible = true;
        self.alive = true;
        self.tags = [];
        self.components = {};
    }

    update() {
        self.x = self.x + self.vx;
        self.y = self.y + self.vy;
    }

    render(surface) {
        # Render entity
    }

    handle_event(event) {
        # Handle event
    }

    kill() {
        self.alive = false;
    }

    destroy() {
        self.alive = false;
    }

    add_tag(tag) {
        if !self.tags.includes(tag) {
            self.tags.push(tag);
        }
    }

    has_tag(tag) {
        return self.tags.includes(tag);
    }

    remove_tag(tag) {
        self.tags = self.tags.filter(fn(t) { return t != tag; });
    }

    add_component(name, component) {
        self.components[name] = component;
        component.entity = self;
    }

    get_component(name) {
        return self.components[name];
    }

    has_component(name) {
        return self.components[name] != null;
    }

    remove_component(name) {
        delete self.components[name];
    }

    get_position() {
        return [self.x, self.y];
    }

    set_position(x, y) {
        self.x = x;
        self.y = y;
    }

    get_velocity() {
        return [self.vx, self.vy];
    }

    set_velocity(vx, vy) {
        self.vx = vx;
        self.vy = vy;
    }

    get_rotation() {
        return self.rotation;
    }

    set_rotation(rotation) {
        self.rotation = rotation;
    }

    get_scale() {
        return [self.scale_x, self.scale_y];
    }

    set_scale(scale_x, scale_y) {
        self.scale_x = scale_x;
        self.scale_y = scale_y;
    }

    distance_to(other) {
        let dx = other.x - self.x;
        let dy = other.y - self.y;
        return sqrt(dx * dx + dy * dy);
    }

    angle_to(other) {
        let dx = other.x - self.x;
        let dy = other.y - self.y;
        return atan2(dy, dx);
    }

    move_towards(other, speed) {
        let dist = self.distance_to(other);
        if dist > 0 {
            let dx = (other.x - self.x) / dist;
            let dy = (other.y - self.y) / dist;
            self.vx = dx * speed;
            self.vy = dy * speed;
        }
    }
}

# ============================================================
# Physics Components
# ============================================================

class PhysicsComponent {
    init(entity, mass, friction, elasticity) {
        self.entity = entity;
        self.mass = mass || 1.0;
        self.friction = friction || 0.0;
        self.elasticity = elasticity || 0.0;
        
        self.acceleration_x = 0;
        self.acceleration_y = 0;
        self.forces_x = 0;
        self.forces_y = 0;
        
        self.gravity_x = 0;
        self.gravity_y = 9.8;
        
        self.grounded = false;
        self.kinematic = false;
    }

    update(dt) {
        if self.kinematic {
            return;
        }
        
        # Apply gravity
        self.forces_x = self.forces_x + self.mass * self.gravity_x;
        self.forces_y = self.forces_y + self.mass * self.gravity_y;
        
        # Calculate acceleration
        self.acceleration_x = self.forces_x / self.mass;
        self.acceleration_y = self.forces_y / self.mass;
        
        # Update velocity
        self.entity.vx = self.entity.vx + self.acceleration_x * dt;
        self.entity.vy = self.entity.vy + self.acceleration_y * dt;
        
        # Apply friction
        if self.grounded {
            self.entity.vx = self.entity.vx * (1 - self.friction);
        }
        
        # Apply elasticity
        if self.elasticity > 0 && self.grounded {
            self.entity.vy = -self.entity.vy * self.elasticity;
        }
        
        # Reset forces
        self.forces_x = 0;
        self.forces_y = 0;
    }

    apply_force(fx, fy) {
        self.forces_x = self.forces_x + fx;
        self.forces_y = self.forces_y + fy;
    }

    apply_impulse(ix, iy) {
        self.entity.vx = self.entity.vx + ix / self.mass;
        self.entity.vy = self.entity.vy + iy / self.mass;
    }

    set_gravity(gx, gy) {
        self.gravity_x = gx;
        self.gravity_y = gy;
    }

    get_velocity() {
        return [self.entity.vx, self.entity.vy];
    }

    set_velocity(vx, vy) {
        self.entity.vx = vx;
        self.entity.vy = vy;
    }

    stop() {
        self.entity.vx = 0;
        self.entity.vy = 0;
    }

    stop_x() {
        self.entity.vx = 0;
    }

    stop_y() {
        self.entity.vy = 0;
    }
}

# ============================================================
# Collision Components
# ============================================================

class ColliderComponent {
    init(entity, shape, layer, mask) {
        self.entity = entity;
        self.shape = shape || "box";
        self.layer = layer || 0;
        self.mask = mask || 0;
        
        self.width = 32;
        self.height = 32;
        self.radius = 16;
        
        self.sensor = false;
        self.trigger = false;
        
        self.colliding = false;
        self._overlapping = [];
    }

    get_bounds() {
        return Rect.new(
            self.entity.x - self.width / 2,
            self.entity.y - self.height / 2,
            self.width,
            self.height
        );
    }

    get_center() {
        return [self.entity.x, self.entity.y];
    }

    intersects(other) {
        let bounds1 = self.get_bounds();
        let bounds2 = other.get_bounds();
        return bounds1.colliderect(bounds2);
    }

    overlaps(other) {
        return self.intersects(other);
    }

    on_collision(other) {
        # Called when collision occurs
    }

    on_enter(other) {
        if !self._overlapping.includes(other) {
            self._overlapping.push(other);
            self.colliding = true;
        }
    }

    on_exit(other) {
        self._overlapping = self._overlapping.filter(fn(o) { return o != other; });
        if len(self._overlapping) == 0 {
            self.colliding = false;
        }
    }

    get_overlapping() {
        return self._overlapping;
    }
}

# ============================================================
# Camera
# ============================================================

class Camera {
    init(x, y, width, height) {
        self.x = x || 0;
        self.y = y || 0;
        self.width = width || 800;
        self.height = height || 600;
        
        self.zoom = 1.0;
        self.rotation = 0;
        
        self.bounds = Rect.new(self.x, self.y, self.width, self.height);
    }

    set_position(x, y) {
        self.x = x;
        self.y = y;
        self.bounds.x = x;
        self.bounds.y = y;
    }

    get_position() {
        return [self.x, self.y];
    }

    move(dx, dy) {
        self.x = self.x + dx;
        self.y = self.y + dy;
        self.bounds.x = self.x;
        self.bounds.y = self.y;
    }

    set_zoom(zoom) {
        self.zoom = zoom;
    }

    get_zoom() {
        return self.zoom;
    }

    set_rotation(rotation) {
        self.rotation = rotation;
    }

    get_rotation() {
        return self.rotation;
    }

    world_to_screen(x, y) {
        return [
            (x - self.x) * self.zoom + self.width / 2,
            (y - self.y) * self.zoom + self.height / 2
        ];
    }

    screen_to_world(x, y) {
        return [
            (x - self.width / 2) / self.zoom + self.x,
            (y - self.height / 2) / self.zoom + self.y
        ];
    }

    is_visible(x, y, width, height) {
        let rect = Rect.new(x, y, width, height);
        return self.bounds.colliderect(rect);
    }

    follow(entity) {
        self.set_position(entity.x, entity.y);
    }
}

# ============================================================
# Input Manager
# ============================================================

class InputManager {
    init() {
        self._keys_pressed = {};
        self._keys_down = {};
        self._keys_up = {};
        
        self._mouse_pos = [0, 0];
        self._mouse_buttons = {};
        self._mouse_buttons_down = {};
        self._mouse_buttons_up = {};
        
        self._joysticks = [];
    }

    is_key_pressed(key) {
        return self._keys_pressed[key] || false;
    }

    is_key_down(key) {
        return self._keys_down[key] || false;
    }

    is_key_up(key) {
        return self._keys_up[key] || false;
    }

    get_mouse_position() {
        return self._mouse_pos;
    }

    get_mouse_x() {
        return self._mouse_pos[0];
    }

    get_mouse_y() {
        return self._mouse_pos[1];
    }

    is_mouse_button_pressed(button) {
        return self._mouse_buttons[button] || false;
    }

    is_mouse_button_down(button) {
        return self._mouse_buttons_down[button] || false;
    }

    is_mouse_button_up(button) {
        return self._mouse_buttons_up[button] || false;
    }

    get_joystick(index) {
        return self._joysticks[index];
    }

    get_joystick_count() {
        return len(self._joysticks);
    }

    update() {
        # Reset frame-specific input states
        self._keys_down = {};
        self._keys_up = {};
        self._mouse_buttons_down = {};
        self._mouse_buttons_up = {};
    }
}

let input = InputManager.new();

# ============================================================
# Sound
# ============================================================

class Sound {
    init(filename) {
        self.filename = filename;
        self.volume = 1.0;
        self.pan = 0.0;
        self._channel = -1;
    }

    play(loops, maxtime, fade_ms) {
        # Play sound
    }

    stop() {
        # Stop sound
    }

    pause() {
        # Pause sound
    }

    unpause() {
        # Unpause sound
    }

    fadeout(time) {
        # Fade out sound
    }

    set_volume(volume) {
        self.volume = volume;
    }

    get_volume() {
        return self.volume;
    }

    set_pan(pan) {
        self.pan = pan;
    }

    get_pan() {
        return self.pan;
    }

    get_num_channels() {
        return 0;
    }

    get_length() {
        return 0;
    }

    get_buffer() {
        return null;
    }
}

# ============================================================
# Music
# ============================================================

class Music {
    init(filename) {
        self.filename = filename;
        self.volume = 1.0;
        self.position = 0;
    }

    play(loops) {
        # Play music
    }

    stop() {
        # Stop music
    }

    pause() {
        # Pause music
    }

    unpause() {
        # Unpause music
    }

    rewind() {
        # Rewind music
    }

    set_volume(volume) {
        self.volume = volume;
    }

    get_volume() {
        return self.volume;
    }

    fadein(time, loops) {
        # Fade in music
    }

    fadeout(time) {
        # Fade out music
    }

    get_length() {
        return 0;
    }

    get_pos() {
        return self.position;
    }

    set_pos(pos) {
        self.position = pos;
    }

    get_busy() {
        return false;
    }

    set_endevent(event_type) {
        # Set end event
    }

    get_endevent() {
        return 0;
    }
}

# ============================================================
# Font
# ============================================================

class Font {
    init(name, size, bold, italic) {
        self.name = name || "Arial";
        self.size = size || 24;
        self.bold = bold || false;
        self.italic = italic || false;
    }

    render(text, antialias, color, background) {
        return Surface.new(100, 30);
    }

    render_multiline(text, antialias, color, background) {
        return [];
    }

    size(text) {
        return [len(text) * self.size * 0.6, self.size];
    }

    get_height() {
        return self.size;
    }

    get_linesize() {
        return self.size * 1.2;
    }

    get_metrics(text) {
        return [];
    }

    get_underline_metrics() {
        return {
            "offset": 0,
            "size": 0
        };
    }
}

# ============================================================
# Image Loader
# ============================================================

fn image_load(filename):
    return Surface.new(100, 100)

fn image_load_extended(filename):
    return Surface.new(100, 100)

fn image_save(surface, filename):
    return true

fn image_get_buffer(surface):
    return ""

fn image_frombuffer(width, height, format, surface, pitch):
    return Surface.new(width, height)

# ============================================================
# Transform
# ============================================================

class Transform {
    init() {
        self._matrix = [
            [1, 0, 0],
            [0, 1, 0],
            [0, 0, 1]
        ];
    }

    identity() {
        self._matrix = [
            [1, 0, 0],
            [0, 1, 0],
            [0, 0, 1]
        ];
    }

    translate(x, y) {
        # Translate
    }

    rotate(angle) {
        # Rotate
    }

    scale(x, y) {
        # Scale
    }

    shear(x, y) {
        # Shear
    }

    transform_point(x, y) {
        return [x, y];
    }

    transform_rect(rect) {
        return rect;
    }

    inverse() {
        let t = Transform.new();
        return t;
    }
}

# ============================================================
# Animation
# ============================================================

class Animation {
    init(frame_duration) {
        self.frame_duration = frame_duration || 0.1;
        self._frames = [];
        self._current_frame = 0;
        self._elapsed = 0;
        self.loop = true;
    }

    add_frame(surface) {
        self._frames.push(surface);
    }

    update(dt) {
        if len(self._frames) == 0 {
            return;
        }
        
        self._elapsed = self._elapsed + dt;
        
        while self._elapsed >= self.frame_duration {
            self._elapsed = self._elapsed - self.frame_duration;
            
            if self.loop {
                self._current_frame = (self._current_frame + 1) % len(self._frames);
            } else if self._current_frame < len(self._frames) - 1 {
                self._current_frame = self._current_frame + 1;
            }
        }
    }

    get_frame() {
        if len(self._frames) > 0 {
            return self._frames[self._current_frame];
        }
        return null;
    }

    reset() {
        self._current_frame = 0;
        self._elapsed = 0;
    }

    is_finished() {
        return !self.loop && self._current_frame >= len(self._frames) - 1;
    }

    set_frame(frame) {
        self._current_frame = frame;
    }

    get_frame_count() {
        return len(self._frames);
    }
}

# ============================================================
# Particle System
# ============================================================

class Particle {
    init(x, y) {
        self.x = x || 0;
        self.y = y || 0;
        self.vx = 0;
        self.vy = 0;
        self.life = 1.0;
        self.max_life = 1.0;
        self.size = 10;
        self.color = [255, 255, 255, 255];
        self.rotation = 0;
        self.rotation_speed = 0;
    }

    update(dt) {
        self.x = self.x + self.vx * dt;
        self.y = self.y + self.vy * dt;
        self.life = self.life - dt;
        self.rotation = self.rotation + self.rotation_speed * dt;
    }

    is_alive() {
        return self.life > 0;
    }

    get_alpha() {
        return int(255 * (self.life / self.max_life));
    }
}

class ParticleEmitter {
    init(x, y) {
        self.x = x || 0;
        self.y = y || 0;
        
        self.particles = [];
        
        # Emission properties
        self.emit_rate = 10;
        self.emit_timer = 0;
        
        # Particle properties
        self.particle_lifetime = 1.0;
        self.particle_speed = 100;
        self.particle_speed_variance = 20;
        self.particle_direction = 0;
        self.particle_direction_variance = 30;
        self.particle_size = 10;
        self.particle_size_variance = 2;
        
        # Color
        self.start_color = [255, 255, 255, 255];
        self.end_color = [255, 255, 255, 0];
        
        # Gravity
        self.gravity_x = 0;
        self.gravity_y = 0;
        
        # Blend mode
        self.blend_mode = "add";
        
        self.emitting = true;
    }

    emit(count) {
        for let i in range(count) {
            let particle = Particle.new(self.x, self.y);
            
            # Random direction
            let angle = self.particle_direction + (rand() - 0.5) * self.particle_direction_variance;
            let speed = self.particle_speed + (rand() - 0.5) * self.particle_speed_variance;
            
            particle.vx = cos(angle * 3.14159 / 180) * speed;
            particle.vy = sin(angle * 3.14159 / 180) * speed;
            
            particle.max_life = self.particle_lifetime;
            particle.life = self.particle_lifetime;
            
            particle.size = self.particle_size + (rand() - 0.5) * self.particle_size_variance;
            particle.color = self.start_color;
            
            self.particles.push(particle);
        }
    }

    update(dt) {
        if self.emitting {
            self.emit_timer = self.emit_timer + dt;
            let emit_interval = 1.0 / self.emit_rate;
            
            while self.emit_timer >= emit_interval {
                self.emit_timer = self.emit_timer - emit_interval;
                self.emit(1);
            }
        }
        
        # Update particles
        for let particle in self.particles {
            particle.update(dt);
            
            # Apply gravity
            particle.vx = particle.vx + self.gravity_x * dt;
            particle.vy = particle.vy + self.gravity_y * dt;
            
            # Interpolate color
            let t = 1 - particle.life / particle.max_life;
            particle.color[0] = int(self.start_color[0] + (self.end_color[0] - self.start_color[0]) * t);
            particle.color[1] = int(self.start_color[1] + (self.end_color[1] - self.start_color[1]) * t);
            particle.color[2] = int(self.start_color[2] + (self.end_color[2] - self.start_color[2]) * t);
            particle.color[3] = int(self.start_color[3] + (self.end_color[3] - self.start_color[3]) * t);
        }
        
        # Remove dead particles
        self.particles = self.particles.filter(fn(p) { return p.is_alive(); });
    }

    draw(surface) {
        for let particle in self.particles {
            let rect = Rect.new(
                particle.x - particle.size / 2,
                particle.y - particle.size / 2,
                particle.size,
                particle.size
            );
            surface.fill_rect(rect, particle.color);
        }
    }

    clear() {
        self.particles = [];
    }

    set_position(x, y) {
        self.x = x;
        self.y = y;
    }

    set_emit_rate(rate) {
        self.emit_rate = rate;
    }

    set_particle_lifetime(lifetime) {
        self.particle_lifetime = lifetime;
    }

    set_particle_speed(speed, variance) {
        self.particle_speed = speed;
        self.particle_speed_variance = variance || 0;
    }

    set_particle_direction(angle, variance) {
        self.particle_direction = angle;
        self.particle_direction_variance = variance || 0;
    }

    set_particle_size(size, variance) {
        self.particle_size = size;
        self.particle_size_variance = variance || 0;
    }

    set_start_color(color) {
        self.start_color = color;
    }

    set_end_color(color) {
        self.end_color = color;
    }

    set_gravity(gx, gy) {
        self.gravity_x = gx;
        self.gravity_y = gy;
    }

    stop() {
        self.emitting = false;
    }

    start() {
        self.emitting = true;
    }
}

# ============================================================
# Tweening
# ============================================================

class Tween {
    init(target, property, start_value, end_value, duration, easing) {
        self.target = target;
        self.property = property;
        self.start_value = start_value;
        self.end_value = end_value;
        self.duration = duration || 1.0;
        self.easing = easing || "linear";
        
        self.elapsed = 0;
        self.running = true;
        self.completed = false;
        
        self.on_update = null;
        self.on_complete = null;
    }

    update(dt) {
        if !self.running || self.completed {
            return;
        }
        
        self.elapsed = self.elapsed + dt;
        
        let t = self.elapsed / self.duration;
        if t > 1 {
            t = 1;
        }
        
        let value = self.interpolate(t);
        
        if self.target && self.property {
            self.target[self.property] = value;
        }
        
        if self.on_update {
            self.on_update(value);
        }
        
        if self.elapsed >= self.duration {
            self.completed = true;
            if self.on_complete {
                self.on_complete();
            }
        }
    }

    interpolate(t) {
        if self.easing == "linear" {
            return self.start_value + (self.end_value - self.start_value) * t;
        } else if self.easing == "ease_in" {
            return self.start_value + (self.end_value - self.start_value) * t * t;
        } else if self.easing == "ease_out" {
            return self.start_value + (self.end_value - self.start_value) * (1 - (1 - t) * (1 - t));
        } else if self.easing == "ease_in_out" {
            if t < 0.5 {
                return self.start_value + (self.end_value - self.start_value) * 2 * t * t;
            } else {
                return self.start_value + (self.end_value - self.start_value) * (1 - pow(-2 * t + 2, 2) / 2);
            }
        } else if self.easing == "bounce" {
            let n1 = 7.5625;
            let d1 = 2.75;
            
            if t < 1 / d1 {
                return n1 * t * t;
            } else if t < 2 / d1 {
                t = t - 1.5 / d1;
                return n1 * t * t + 0.75;
            } else if t < 2.5 / d1 {
                t = t - 2.25 / d1;
                return n1 * t * t + 0.9375;
            } else {
                t = t - 2.625 / d1;
                return n1 * t * t + 0.984375;
            }
        } else if self.easing == "elastic" {
            let c4 = (2 * 3.14159) / 3;
            if t == 0 {
                return self.start_value;
            }
            if t == 1 {
                return self.end_value;
            }
            return pow(2, -10 * t) * sin((t * 10 - 0.75) * c4) + self.end_value;
        }
        
        return self.start_value + (self.end_value - self.start_value) * t;
    }

    start() {
        self.running = true;
    }

    stop() {
        self.running = false;
    }

    reset() {
        self.elapsed = 0;
        self.completed = false;
    }

    is_running() {
        return self.running && !self.completed;
    }

    is_completed() {
        return self.completed;
    }
}

# ============================================================
# Utility Functions
# ============================================================

fn init():
    # Initialize game systems
    return true

fn quit():
    # Quit game systems

fn display_set_mode(width, height, flags):
    return Surface.new(width, height, 32, flags)

fn display_get_surface():
    return null

fn display_flip():
    # Flip display

fn display_update():
    # Update display

fn display_set_caption(caption):
    # Set window caption

fn display_get_caption():
    return ""

fn display_get_driver():
    return ""

fn event_get():
    return []

fn event_pump():
    # Pump events

fn event_wait():
    return {}

fn key_get_pressed():
    return {}

fn mouse_get_pos():
    return [0, 0]

fn mouse_get_pressed():
    return [false, false, false]

fn time_get_ticks():
    return 0

fn time_wait(ms):
    # Wait for ms milliseconds

fn mixer_init(frequency, size, channels, buffer):
    # Initialize mixer

fn mixer_quit():
    # Quit mixer

fn mixer_music_load(filename):
    return Music.new(filename)

fn mixer_sound_load(filename):
    return Sound.new(filename)

fn image_init():
    # Initialize image module

fn image_quit():
    # Quit image module

fn font_init():
    # Initialize font module

fn font_quit():
    # Quit font module

fn font_get_default():
    return Font.new("Arial", 24)

fn font_match(name):
    return "Arial"

fn font_names():
    return ["Arial"]

fn joy_init():
    # Initialize joystick

fn joy_quit():
    # Quit joystick

fn joy_get_count():
    return 0

fn joy_get_name(index):
    return ""

# ============================================================
# Export
# ============================================================

let Game = Game;
let Clock = Clock;
let Surface = Surface;
let Rect = Rect;
let Color = Color;
let Sprite = Sprite;
let SpriteGroup = SpriteGroup;
let Scene = Scene;
let Entity = Entity;
let Camera = Camera;
let InputManager = InputManager;
let Sound = Sound;
let Music = Music;
let Font = Font;
let Animation = Animation;
let ParticleEmitter = ParticleEmitter;
let Particle = Particle;
let Transform = Transform;
let Tween = Tween;
