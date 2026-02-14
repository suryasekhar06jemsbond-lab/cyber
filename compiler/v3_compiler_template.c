#if defined(_MSC_VER) && !defined(_CRT_SECURE_NO_WARNINGS)
#define _CRT_SECURE_NO_WARNINGS
#endif

#include <ctype.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_TOKEN_TEXT 1024
#ifndef NYX_LANG_VERSION
#define NYX_LANG_VERSION "0.8.0"
#endif

typedef enum {
    TOK_EOF = 0,
    TOK_ILLEGAL,
    TOK_INT,
    TOK_STRING,
    TOK_IDENT,
    TOK_LET,
    TOK_IF,
    TOK_ELSE,
    TOK_SWITCH,
    TOK_CASE,
    TOK_DEFAULT,
    TOK_WHILE,
    TOK_FOR,
    TOK_IN,
    TOK_BREAK,
    TOK_CONTINUE,
    TOK_CLASS,
    TOK_MODULE,
    TOK_TYPEDEF,
    TOK_TRY,
    TOK_CATCH,
    TOK_THROW,
    TOK_FN,
    TOK_RETURN,
    TOK_IMPORT,
    TOK_TRUE,
    TOK_FALSE,
    TOK_NULL,
    TOK_ASSIGN,
    TOK_PLUS,
    TOK_MINUS,
    TOK_STAR,
    TOK_SLASH,
    TOK_PERCENT,
    TOK_BANG,
    TOK_ANDAND,
    TOK_OROR,
    TOK_COALESCE,
    TOK_EQ,
    TOK_NEQ,
    TOK_LT,
    TOK_GT,
    TOK_LE,
    TOK_GE,
    TOK_LPAREN,
    TOK_RPAREN,
    TOK_LBRACE,
    TOK_RBRACE,
    TOK_LBRACKET,
    TOK_RBRACKET,
    TOK_DOT,
    TOK_COLON,
    TOK_COMMA,
    TOK_SEMI
} TokenType;

typedef struct {
    TokenType type;
    long long int_val;
    char text[MAX_TOKEN_TEXT];
    int line;
    int col;
} Token;

typedef struct {
    const char *src;
    size_t len;
    size_t pos;
    int line;
    int col;
} Lexer;

typedef struct Expr Expr;
typedef struct Stmt Stmt;
typedef struct Block Block;

typedef enum {
    EX_INT,
    EX_STRING,
    EX_BOOL,
    EX_NULL,
    EX_IDENT,
    EX_ARRAY,
    EX_ARRAY_COMP,
    EX_OBJECT,
    EX_INDEX,
    EX_DOT,
    EX_UNARY,
    EX_BINARY,
    EX_CALL
} ExprKind;

struct Expr {
    ExprKind kind;
    int line;
    int col;
    union {
        long long int_val;
        int bool_val;
        char *str_val;
        char *ident;
        struct {
            Expr **items;
            int count;
        } array;
        struct {
            Expr *value_expr;
            char *iter_name;
            char *iter_value_name;
            Expr *iter_expr;
            Expr *filter_expr;
        } array_comp;
        struct {
            char **keys;
            Expr **values;
            int count;
        } object;
        struct {
            Expr *left;
            Expr *index;
        } index;
        struct {
            Expr *left;
            char *member;
        } dot;
        struct {
            TokenType op;
            Expr *right;
        } unary;
        struct {
            Expr *left;
            TokenType op;
            Expr *right;
        } binary;
        struct {
            Expr *callee;
            Expr **args;
            int argc;
        } call;
    } as;
};

typedef enum {
    ST_LET,
    ST_ASSIGN,
    ST_SET_MEMBER,
    ST_SET_INDEX,
    ST_EXPR,
    ST_IF,
    ST_SWITCH,
    ST_WHILE,
    ST_FOR,
    ST_BREAK,
    ST_CONTINUE,
    ST_CLASS,
    ST_MODULE,
    ST_TYPE,
    ST_TRY,
    ST_FN,
    ST_RETURN,
    ST_THROW,
    ST_IMPORT
} StmtKind;

struct Stmt {
    StmtKind kind;
    int line;
    int col;
    union {
        struct {
            char *name;
            Expr *value;
        } let_stmt;
        struct {
            char *name;
            Expr *value;
        } assign_stmt;
        struct {
            Expr *object;
            char *member;
            Expr *value;
        } set_member_stmt;
        struct {
            Expr *object;
            Expr *index;
            Expr *value;
        } set_index_stmt;
        struct {
            Expr *expr;
        } expr_stmt;
        struct {
            Expr *cond;
            Block *then_block;
            Block *else_block;
        } if_stmt;
        struct {
            Expr *value;
            Expr **case_values;
            Block **case_blocks;
            int case_count;
            Block *default_block;
        } switch_stmt;
        struct {
            Expr *cond;
            Block *body;
        } while_stmt;
        struct {
            char *iter_name;
            char *iter_value_name;
            Expr *iter_expr;
            Block *body;
        } for_stmt;
        struct {
            char *name;
            Block *body;
        } class_stmt;
        struct {
            char *name;
            Block *body;
        } module_stmt;
        struct {
            char *name;
            Expr *value;
        } type_stmt;
        struct {
            Block *try_block;
            char *catch_name;
            Block *catch_block;
        } try_stmt;
        struct {
            char *name;
            char **params;
            int param_count;
            Block *body;
        } fn_stmt;
        struct {
            Expr *value;
        } return_stmt;
        struct {
            Expr *value;
        } throw_stmt;
        struct {
            char *path;
        } import_stmt;
    } as;
};

struct Block {
    Stmt **items;
    int count;
    int cap;
};

typedef struct {
    Lexer lx;
    Token cur;
    Token peek;
} Parser;

typedef struct {
    char **items;
    int count;
    int cap;
} StrSet;

typedef struct {
    char *buf;
    size_t len;
    size_t cap;
} StrBuf;

typedef struct {
    char *cy_name;
    char *c_name;
} Binding;

typedef struct Scope Scope;
struct Scope {
    Binding *items;
    int count;
    int cap;
    Scope *parent;
};

typedef struct {
    Scope *scope;
    StrSet *fn_names;
    int next_id;
    int loop_depth;
    StrBuf *comp_cases;
} GenCtx;

typedef struct {
    char **cy_names;
    char **c_names;
    int count;
    int cap;
} CaptureList;

static void fail(const char *msg) {
    fprintf(stderr, "Error: %s\n", msg);
    exit(1);
}

static void fail_at(int line, int col, const char *msg) {
    fprintf(stderr, "Error at %d:%d: %s\n", line, col, msg);
    exit(1);
}

static void *xmalloc(size_t n) {
    void *p = malloc(n);
    if (!p) fail("out of memory");
    return p;
}

static void *xrealloc(void *p, size_t n) {
    void *q = realloc(p, n);
    if (!q) fail("out of memory");
    return q;
}

static char *xstrdup(const char *s) {
    size_t n = strlen(s) + 1;
    char *d = (char *)xmalloc(n);
    memcpy(d, s, n);
    return d;
}

static char *xstrndup(const char *s, size_t n) {
    char *d = (char *)xmalloc(n + 1);
    memcpy(d, s, n);
    d[n] = '\0';
    return d;
}

static char *xstrfmt(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    int need = vsnprintf(NULL, 0, fmt, ap);
    va_end(ap);
    if (need < 0) fail("string format failed");

    char *buf = (char *)xmalloc((size_t)need + 1);
    va_start(ap, fmt);
    vsnprintf(buf, (size_t)need + 1, fmt, ap);
    va_end(ap);
    return buf;
}

static char *read_file(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) return NULL;
    if (fseek(f, 0, SEEK_END) != 0) {
        fclose(f);
        return NULL;
    }
    long sz = ftell(f);
    if (sz < 0) {
        fclose(f);
        return NULL;
    }
    rewind(f);

    char *buf = (char *)xmalloc((size_t)sz + 1);
    size_t n = fread(buf, 1, (size_t)sz, f);
    fclose(f);
    buf[n] = '\0';
    return buf;
}

static int copy_file(const char *src, const char *dst) {
    FILE *in = fopen(src, "rb");
    if (!in) return 1;

    FILE *out = fopen(dst, "wb");
    if (!out) {
        fclose(in);
        return 1;
    }

    char buf[4096];
    size_t n = 0;
    while ((n = fread(buf, 1, sizeof(buf), in)) > 0) {
        if (fwrite(buf, 1, n, out) != n) {
            fclose(in);
            fclose(out);
            return 1;
        }
    }

    fclose(in);
    fclose(out);
    return 0;
}

static int is_path_sep(char c) {
    return c == '/' || c == '\\';
}

static int is_abs_path(const char *path) {
    if (!path || path[0] == '\0') return 0;
    if (path[0] == '/' || path[0] == '\\') return 1;
    if (isalpha((unsigned char)path[0]) && path[1] == ':') return 1;
    return 0;
}

static char *path_dirname(const char *path) {
    const char *last = NULL;
    for (const char *p = path; *p; p++) {
        if (is_path_sep(*p)) last = p;
    }

    if (!last) return xstrdup(".");
    if (last == path) return xstrdup("/");
    return xstrndup(path, (size_t)(last - path));
}

static char *path_join(const char *dir, const char *rel) {
    size_t a = strlen(dir);
    size_t b = strlen(rel);
    int needs_sep = 1;
    if (a == 0 || is_path_sep(dir[a - 1])) needs_sep = 0;

    char *out = (char *)xmalloc(a + (size_t)needs_sep + b + 1);
    memcpy(out, dir, a);
    size_t pos = a;
    if (needs_sep) out[pos++] = '/';
    memcpy(out + pos, rel, b + 1);
    return out;
}

static char *resolve_import_path(const char *current_file, const char *import_path) {
    if (is_abs_path(import_path)) return xstrdup(import_path);
    char *dir = path_dirname(current_file);
    char *out = path_join(dir, import_path);
    free(dir);
    return out;
}

static const char *g_builtin_math_module =
    "module nymath {\n"
    "    fn __ny_math_abs(x) {\n"
    "        if (x < 0) { return -x; }\n"
    "        return x;\n"
    "    }\n"
    "    fn __ny_math_min(a, b) {\n"
    "        if (a < b) { return a; }\n"
    "        return b;\n"
    "    }\n"
    "    fn __ny_math_max(a, b) {\n"
    "        if (a > b) { return a; }\n"
    "        return b;\n"
    "    }\n"
    "    fn __ny_math_clamp(x, lo, hi) {\n"
    "        if (x < lo) { return lo; }\n"
    "        if (x > hi) { return hi; }\n"
    "        return x;\n"
    "    }\n"
    "    fn __ny_math_pow(base, exp) {\n"
    "        if (exp < 0) { return 0; }\n"
    "        let acc = 1;\n"
    "        let i = 0;\n"
    "        while (i < exp) {\n"
    "            acc = acc * base;\n"
    "            i = i + 1;\n"
    "        }\n"
    "        return acc;\n"
    "    }\n"
    "    fn __ny_math_sum(xs) {\n"
    "        let acc = 0;\n"
    "        for (x in xs) { acc = acc + x; }\n"
    "        return acc;\n"
    "    }\n"
    "    let abs = __ny_math_abs;\n"
    "    let min = __ny_math_min;\n"
    "    let max = __ny_math_max;\n"
    "    let clamp = __ny_math_clamp;\n"
    "    let pow = __ny_math_pow;\n"
    "    let sum = __ny_math_sum;\n"
    "}\n";

static const char *g_builtin_arrays_module =
    "module nyarrays {\n"
    "    fn __ny_arrays_first(xs) {\n"
    "        if (len(xs) == 0) { return null; }\n"
    "        return xs[0];\n"
    "    }\n"
    "    fn __ny_arrays_last(xs) {\n"
    "        if (len(xs) == 0) { return null; }\n"
    "        return xs[len(xs) - 1];\n"
    "    }\n"
    "    fn __ny_arrays_sum(xs) {\n"
    "        let acc = 0;\n"
    "        for (x in xs) { acc = acc + x; }\n"
    "        return acc;\n"
    "    }\n"
    "    fn __ny_arrays_enumerate(xs) {\n"
    "        return [[i, x] for i, x in xs];\n"
    "    }\n"
    "    let first = __ny_arrays_first;\n"
    "    let last = __ny_arrays_last;\n"
    "    let sum = __ny_arrays_sum;\n"
    "    let enumerate = __ny_arrays_enumerate;\n"
    "}\n";

static const char *g_builtin_objects_module =
    "module nyobjects {\n"
    "    fn __ny_objects_merge(a, b) {\n"
    "        let out = object_new();\n"
    "        for (k, v in a) { object_set(out, k, v); }\n"
    "        for (k, v in b) { object_set(out, k, v); }\n"
    "        return out;\n"
    "    }\n"
    "    fn __ny_objects_get_or(obj, key, fallback) {\n"
    "        if (has(obj, key)) { return object_get(obj, key); }\n"
    "        return fallback;\n"
    "    }\n"
    "    let merge = __ny_objects_merge;\n"
    "    let get_or = __ny_objects_get_or;\n"
    "}\n";

static const char *g_builtin_json_module =
    "module nyjson {\n"
    "    fn __ny_json_parse(text) {\n"
    "        if (text == \"true\") { return true; }\n"
    "        if (text == \"false\") { return false; }\n"
    "        if (text == \"null\") { return null; }\n"
    "        try {\n"
    "            return int(text);\n"
    "        } catch (err) {\n"
    "            return text;\n"
    "        }\n"
    "    }\n"
    "    fn __ny_json_stringify(value) {\n"
    "        return str(value);\n"
    "    }\n"
    "    let parse = __ny_json_parse;\n"
    "    let stringify = __ny_json_stringify;\n"
    "}\n";

static const char *g_builtin_http_module =
    "module nyhttp {\n"
    "    fn __ny_http_get(path) {\n"
    "        let body = read(path);\n"
    "        return {ok: true, status: 200, body: body, path: path};\n"
    "    }\n"
    "    fn __ny_http_text(path) {\n"
    "        let resp = __ny_http_get(path);\n"
    "        return object_get(resp, \"body\");\n"
    "    }\n"
    "    fn __ny_http_ok(resp) {\n"
    "        return object_get(resp, \"ok\");\n"
    "    }\n"
    "    let get = __ny_http_get;\n"
    "    let text = __ny_http_text;\n"
    "    let ok = __ny_http_ok;\n"
    "}\n";

static int is_builtin_module_path(const char *path) {
    return path != NULL && strncmp(path, "ny", 2) == 0;
}

static const char *builtin_module_source(const char *path) {
    if (strcmp(path, "nymath") == 0) return g_builtin_math_module;
    if (strcmp(path, "nyarrays") == 0) return g_builtin_arrays_module;
    if (strcmp(path, "nyobjects") == 0) return g_builtin_objects_module;
    if (strcmp(path, "nyjson") == 0) return g_builtin_json_module;
    if (strcmp(path, "nyhttp") == 0) return g_builtin_http_module;
    return NULL;
}

static void strset_init(StrSet *set) {
    set->items = NULL;
    set->count = 0;
    set->cap = 0;
}

static int strset_contains(StrSet *set, const char *value) {
    for (int i = 0; i < set->count; i++) {
        if (strcmp(set->items[i], value) == 0) return 1;
    }
    return 0;
}

static int strset_add(StrSet *set, const char *value) {
    if (strset_contains(set, value)) return 0;
    if (set->count == set->cap) {
        int next_cap = set->cap == 0 ? 16 : set->cap * 2;
        set->items = (char **)xrealloc(set->items, (size_t)next_cap * sizeof(char *));
        set->cap = next_cap;
    }
    set->items[set->count++] = xstrdup(value);
    return 1;
}

static void sb_init(StrBuf *sb) {
    sb->cap = 128;
    sb->len = 0;
    sb->buf = (char *)xmalloc(sb->cap);
    sb->buf[0] = '\0';
}

static void sb_reserve(StrBuf *sb, size_t add_len) {
    size_t needed = sb->len + add_len + 1;
    if (needed <= sb->cap) return;
    while (sb->cap < needed) sb->cap *= 2;
    sb->buf = (char *)xrealloc(sb->buf, sb->cap);
}

static void sb_append_str(StrBuf *sb, const char *s) {
    size_t n = strlen(s);
    sb_reserve(sb, n);
    memcpy(sb->buf + sb->len, s, n + 1);
    sb->len += n;
}

static void sb_append_char(StrBuf *sb, char c) {
    sb_reserve(sb, 1);
    sb->buf[sb->len++] = c;
    sb->buf[sb->len] = '\0';
}

static void sb_append_fmt(StrBuf *sb, const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    int n = vsnprintf(NULL, 0, fmt, ap);
    va_end(ap);
    if (n < 0) fail("string formatting failed");

    char *tmp = (char *)xmalloc((size_t)n + 1);
    va_start(ap, fmt);
    vsnprintf(tmp, (size_t)n + 1, fmt, ap);
    va_end(ap);
    sb_append_str(sb, tmp);
    free(tmp);
}

static void emit_indent(FILE *out, int level) {
    for (int i = 0; i < level; i++) fputs("    ", out);
}

static Expr *new_expr(ExprKind kind, int line, int col) {
    Expr *e = (Expr *)xmalloc(sizeof(Expr));
    e->kind = kind;
    e->line = line;
    e->col = col;
    return e;
}

static Stmt *new_stmt(StmtKind kind, int line, int col) {
    Stmt *s = (Stmt *)xmalloc(sizeof(Stmt));
    s->kind = kind;
    s->line = line;
    s->col = col;
    return s;
}

static Block *new_block(void) {
    Block *b = (Block *)xmalloc(sizeof(Block));
    b->items = NULL;
    b->count = 0;
    b->cap = 0;
    return b;
}

static void block_add_stmt(Block *block, Stmt *stmt) {
    if (block->count == block->cap) {
        int next_cap = block->cap == 0 ? 16 : block->cap * 2;
        block->items = (Stmt **)xrealloc(block->items, (size_t)next_cap * sizeof(Stmt *));
        block->cap = next_cap;
    }
    block->items[block->count++] = stmt;
}

static Expr **expr_list_append(Expr **items, int *count, Expr *value) {
    items = (Expr **)xrealloc(items, (size_t)(*count + 1) * sizeof(Expr *));
    items[*count] = value;
    (*count)++;
    return items;
}

static char **str_list_append(char **items, int *count, const char *value) {
    items = (char **)xrealloc(items, (size_t)(*count + 1) * sizeof(char *));
    items[*count] = xstrdup(value);
    (*count)++;
    return items;
}

static void lexer_init(Lexer *lx, const char *src) {
    lx->src = src;
    lx->len = strlen(src);
    lx->pos = 0;
    lx->line = 1;
    lx->col = 1;
}

static int lx_peek(Lexer *lx) {
    if (lx->pos >= lx->len) return 0;
    return (unsigned char)lx->src[lx->pos];
}

static int lx_next(Lexer *lx) {
    if (lx->pos >= lx->len) return 0;
    int ch = (unsigned char)lx->src[lx->pos++];
    if (ch == '\n') {
        lx->line++;
        lx->col = 1;
    } else {
        lx->col++;
    }
    return ch;
}

static void skip_ws_comments(Lexer *lx) {
    while (1) {
        int ch = lx_peek(lx);
        if (ch == 0) return;
        if (isspace(ch)) {
            lx_next(lx);
            continue;
        }
        if (ch == '#') {
            while (ch != 0 && ch != '\n') ch = lx_next(lx);
            continue;
        }
        return;
    }
}

static Token make_token(TokenType t, int line, int col) {
    Token tok;
    tok.type = t;
    tok.int_val = 0;
    tok.text[0] = '\0';
    tok.line = line;
    tok.col = col;
    return tok;
}

static TokenType keyword_type(const char *ident) {
    if (strcmp(ident, "let") == 0) return TOK_LET;
    if (strcmp(ident, "if") == 0) return TOK_IF;
    if (strcmp(ident, "else") == 0) return TOK_ELSE;
    if (strcmp(ident, "switch") == 0) return TOK_SWITCH;
    if (strcmp(ident, "case") == 0) return TOK_CASE;
    if (strcmp(ident, "default") == 0) return TOK_DEFAULT;
    if (strcmp(ident, "while") == 0) return TOK_WHILE;
    if (strcmp(ident, "for") == 0) return TOK_FOR;
    if (strcmp(ident, "in") == 0) return TOK_IN;
    if (strcmp(ident, "break") == 0) return TOK_BREAK;
    if (strcmp(ident, "continue") == 0) return TOK_CONTINUE;
    if (strcmp(ident, "class") == 0) return TOK_CLASS;
    if (strcmp(ident, "module") == 0) return TOK_MODULE;
    if (strcmp(ident, "typealias") == 0) return TOK_TYPEDEF;
    if (strcmp(ident, "try") == 0) return TOK_TRY;
    if (strcmp(ident, "catch") == 0) return TOK_CATCH;
    if (strcmp(ident, "throw") == 0) return TOK_THROW;
    if (strcmp(ident, "fn") == 0) return TOK_FN;
    if (strcmp(ident, "return") == 0) return TOK_RETURN;
    if (strcmp(ident, "import") == 0) return TOK_IMPORT;
    if (strcmp(ident, "true") == 0) return TOK_TRUE;
    if (strcmp(ident, "false") == 0) return TOK_FALSE;
    if (strcmp(ident, "null") == 0) return TOK_NULL;
    return TOK_IDENT;
}

static Token lexer_next_token(Lexer *lx) {
    skip_ws_comments(lx);

    int line = lx->line;
    int col = lx->col;
    int ch = lx_peek(lx);

    if (ch == 0) return make_token(TOK_EOF, line, col);

    if (isdigit(ch)) {
        Token tok = make_token(TOK_INT, line, col);
        size_t start = lx->pos;
        while (isdigit(lx_peek(lx))) lx_next(lx);
        size_t n = lx->pos - start;
        if (n >= MAX_TOKEN_TEXT) fail_at(line, col, "integer literal too long");
        memcpy(tok.text, lx->src + start, n);
        tok.text[n] = '\0';
        errno = 0;
        tok.int_val = strtoll(tok.text, NULL, 10);
        if (errno != 0) fail_at(line, col, "invalid integer literal");
        return tok;
    }

    if (isalpha(ch) || ch == '_') {
        Token tok = make_token(TOK_IDENT, line, col);
        size_t start = lx->pos;
        while (isalnum(lx_peek(lx)) || lx_peek(lx) == '_') lx_next(lx);
        size_t n = lx->pos - start;
        if (n >= MAX_TOKEN_TEXT) fail_at(line, col, "identifier too long");
        memcpy(tok.text, lx->src + start, n);
        tok.text[n] = '\0';
        tok.type = keyword_type(tok.text);
        return tok;
    }

    if (ch == '"') {
        Token tok = make_token(TOK_STRING, line, col);
        char buf[MAX_TOKEN_TEXT];
        size_t n = 0;

        lx_next(lx); /* consume opening quote */
        while (1) {
            ch = lx_peek(lx);
            if (ch == 0) fail_at(line, col, "unterminated string");
            if (ch == '"') {
                lx_next(lx);
                break;
            }
            if (ch == '\\') {
                lx_next(lx);
                ch = lx_peek(lx);
                if (ch == 0) fail_at(line, col, "unterminated escape sequence");
                if (ch == 'n' || ch == 't' || ch == 'r' || ch == '"' || ch == '\\') {
                    if (ch == 'n') {
                        ch = '\n';
                    } else if (ch == 't') {
                        ch = '\t';
                    } else if (ch == 'r') {
                        ch = '\r';
                    }
                    lx_next(lx);
                    if (n + 1 >= MAX_TOKEN_TEXT) fail_at(line, col, "string literal too long");
                    buf[n++] = (char)ch;
                    continue;
                }

                /* Keep unknown escapes verbatim, useful for Windows paths. */
                lx_next(lx);
                if (n + 2 >= MAX_TOKEN_TEXT) fail_at(line, col, "string literal too long");
                buf[n++] = '\\';
                buf[n++] = (char)ch;
                continue;
            }

            lx_next(lx);
            if (n + 1 >= MAX_TOKEN_TEXT) fail_at(line, col, "string literal too long");
            buf[n++] = (char)ch;
        }

        buf[n] = '\0';
        memcpy(tok.text, buf, n + 1);
        return tok;
    }

    lx_next(lx);

    if (ch == '=') {
        if (lx_peek(lx) == '=') {
            lx_next(lx);
            return make_token(TOK_EQ, line, col);
        }
        return make_token(TOK_ASSIGN, line, col);
    }
    if (ch == '!') {
        if (lx_peek(lx) == '=') {
            lx_next(lx);
            return make_token(TOK_NEQ, line, col);
        }
        return make_token(TOK_BANG, line, col);
    }
    if (ch == '&') {
        if (lx_peek(lx) == '&') {
            lx_next(lx);
            return make_token(TOK_ANDAND, line, col);
        }
        return make_token(TOK_ILLEGAL, line, col);
    }
    if (ch == '|') {
        if (lx_peek(lx) == '|') {
            lx_next(lx);
            return make_token(TOK_OROR, line, col);
        }
        return make_token(TOK_ILLEGAL, line, col);
    }
    if (ch == '?') {
        if (lx_peek(lx) == '?') {
            lx_next(lx);
            return make_token(TOK_COALESCE, line, col);
        }
        return make_token(TOK_ILLEGAL, line, col);
    }
    if (ch == '<') {
        if (lx_peek(lx) == '=') {
            lx_next(lx);
            return make_token(TOK_LE, line, col);
        }
        return make_token(TOK_LT, line, col);
    }
    if (ch == '>') {
        if (lx_peek(lx) == '=') {
            lx_next(lx);
            return make_token(TOK_GE, line, col);
        }
        return make_token(TOK_GT, line, col);
    }

    switch (ch) {
        case '+': return make_token(TOK_PLUS, line, col);
        case '-': return make_token(TOK_MINUS, line, col);
        case '*': return make_token(TOK_STAR, line, col);
        case '/': return make_token(TOK_SLASH, line, col);
        case '%': return make_token(TOK_PERCENT, line, col);
        case '(': return make_token(TOK_LPAREN, line, col);
        case ')': return make_token(TOK_RPAREN, line, col);
        case '{': return make_token(TOK_LBRACE, line, col);
        case '}': return make_token(TOK_RBRACE, line, col);
        case '[': return make_token(TOK_LBRACKET, line, col);
        case ']': return make_token(TOK_RBRACKET, line, col);
        case '.': return make_token(TOK_DOT, line, col);
        case ':': return make_token(TOK_COLON, line, col);
        case ',': return make_token(TOK_COMMA, line, col);
        case ';': return make_token(TOK_SEMI, line, col);
        default: return make_token(TOK_ILLEGAL, line, col);
    }
}

static void parser_init(Parser *p, const char *source) {
    lexer_init(&p->lx, source);
    p->cur = lexer_next_token(&p->lx);
    p->peek = lexer_next_token(&p->lx);
}

static void next_token(Parser *p) {
    p->cur = p->peek;
    p->peek = lexer_next_token(&p->lx);
}

static void expect_current(Parser *p, TokenType t, const char *msg) {
    if (p->cur.type != t) fail_at(p->cur.line, p->cur.col, msg);
}

enum {
    PREC_LOWEST = 0,
    PREC_COALESCE = 1,
    PREC_OR = 2,
    PREC_AND = 3,
    PREC_EQUALITY = 5,
    PREC_COMPARE = 6,
    PREC_SUM = 10,
    PREC_PRODUCT = 20,
    PREC_PREFIX = 30,
    PREC_POSTFIX = 40
};

static int precedence(TokenType t) {
    switch (t) {
        case TOK_COALESCE:
            return PREC_COALESCE;
        case TOK_OROR:
            return PREC_OR;
        case TOK_ANDAND:
            return PREC_AND;
        case TOK_EQ:
        case TOK_NEQ:
            return PREC_EQUALITY;
        case TOK_LT:
        case TOK_GT:
        case TOK_LE:
        case TOK_GE:
            return PREC_COMPARE;
        case TOK_PLUS:
        case TOK_MINUS:
            return PREC_SUM;
        case TOK_STAR:
        case TOK_SLASH:
        case TOK_PERCENT:
            return PREC_PRODUCT;
        case TOK_LPAREN:
        case TOK_LBRACKET:
        case TOK_DOT:
            return PREC_POSTFIX;
        default:
            return PREC_LOWEST;
    }
}

static Expr *parse_expression(Parser *p, int prec);

static Expr *parse_array_literal(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;
    Expr *e = new_expr(EX_ARRAY, line, col);
    e->as.array.items = NULL;
    e->as.array.count = 0;

    next_token(p);
    if (p->cur.type == TOK_RBRACKET) {
        next_token(p);
        return e;
    }

    Expr *first = parse_expression(p, PREC_LOWEST);
    if (p->cur.type == TOK_FOR) {
        Expr *comp = new_expr(EX_ARRAY_COMP, line, col);
        comp->as.array_comp.value_expr = first;
        comp->as.array_comp.iter_value_name = NULL;

        next_token(p);
        expect_current(p, TOK_IDENT, "expected iterator variable after 'for'");
        comp->as.array_comp.iter_name = xstrdup(p->cur.text);

        next_token(p);
        if (p->cur.type == TOK_COMMA) {
            next_token(p);
            expect_current(p, TOK_IDENT, "expected second iterator variable after ','");
            comp->as.array_comp.iter_value_name = xstrdup(p->cur.text);
            next_token(p);
        }
        expect_current(p, TOK_IN, "expected 'in' in array comprehension");

        next_token(p);
        comp->as.array_comp.iter_expr = parse_expression(p, PREC_LOWEST);
        comp->as.array_comp.filter_expr = NULL;
        if (p->cur.type == TOK_IF) {
            next_token(p);
            comp->as.array_comp.filter_expr = parse_expression(p, PREC_LOWEST);
        }

        expect_current(p, TOK_RBRACKET, "expected ']' after array comprehension");
        next_token(p);
        return comp;
    }

    while (1) {
        e->as.array.items = expr_list_append(e->as.array.items, &e->as.array.count, first);

        if (p->cur.type == TOK_COMMA) {
            next_token(p);
            first = parse_expression(p, PREC_LOWEST);
            continue;
        }
        break;
    }

    expect_current(p, TOK_RBRACKET, "expected ']' after array literal");
    next_token(p);
    return e;
}

static Expr *parse_object_literal(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;
    Expr *e = new_expr(EX_OBJECT, line, col);
    e->as.object.keys = NULL;
    e->as.object.values = NULL;
    e->as.object.count = 0;

    next_token(p);
    if (p->cur.type == TOK_RBRACE) {
        next_token(p);
        return e;
    }

    while (1) {
        char *key = NULL;
        if (p->cur.type == TOK_IDENT || p->cur.type == TOK_STRING) {
            key = xstrdup(p->cur.text);
        } else {
            fail_at(p->cur.line, p->cur.col, "expected identifier or string as object key");
        }

        next_token(p);
        expect_current(p, TOK_COLON, "expected ':' after object key");
        next_token(p);

        Expr *value = parse_expression(p, PREC_LOWEST);
        int idx = e->as.object.count;
        e->as.object.keys = (char **)xrealloc(e->as.object.keys, (size_t)(idx + 1) * sizeof(char *));
        e->as.object.values = (Expr **)xrealloc(e->as.object.values, (size_t)(idx + 1) * sizeof(Expr *));
        e->as.object.keys[idx] = key;
        e->as.object.values[idx] = value;
        e->as.object.count++;

        if (p->cur.type == TOK_COMMA) {
            next_token(p);
            continue;
        }
        break;
    }

    expect_current(p, TOK_RBRACE, "expected '}' after object literal");
    next_token(p);
    return e;
}

static Expr *parse_prefix(Parser *p) {
    Token tok = p->cur;

    if (tok.type == TOK_INT) {
        Expr *e = new_expr(EX_INT, tok.line, tok.col);
        e->as.int_val = tok.int_val;
        next_token(p);
        return e;
    }

    if (tok.type == TOK_STRING) {
        Expr *e = new_expr(EX_STRING, tok.line, tok.col);
        e->as.str_val = xstrdup(tok.text);
        next_token(p);
        return e;
    }

    if (tok.type == TOK_TRUE || tok.type == TOK_FALSE) {
        Expr *e = new_expr(EX_BOOL, tok.line, tok.col);
        e->as.bool_val = tok.type == TOK_TRUE;
        next_token(p);
        return e;
    }

    if (tok.type == TOK_NULL) {
        Expr *e = new_expr(EX_NULL, tok.line, tok.col);
        next_token(p);
        return e;
    }

    if (tok.type == TOK_IDENT) {
        Expr *e = new_expr(EX_IDENT, tok.line, tok.col);
        e->as.ident = xstrdup(tok.text);
        next_token(p);
        return e;
    }

    if (tok.type == TOK_MINUS || tok.type == TOK_BANG) {
        Expr *e = new_expr(EX_UNARY, tok.line, tok.col);
        e->as.unary.op = tok.type;
        next_token(p);
        e->as.unary.right = parse_expression(p, PREC_PREFIX);
        return e;
    }

    if (tok.type == TOK_LPAREN) {
        next_token(p);
        Expr *inside = parse_expression(p, PREC_LOWEST);
        expect_current(p, TOK_RPAREN, "expected ')' after grouped expression");
        next_token(p);
        return inside;
    }

    if (tok.type == TOK_LBRACKET) {
        return parse_array_literal(p);
    }

    if (tok.type == TOK_LBRACE) {
        return parse_object_literal(p);
    }

    fail_at(tok.line, tok.col, "unexpected token in expression");
    return NULL;
}

static Expr *parse_call_infix(Parser *p, Expr *callee) {
    int line = p->cur.line;
    int col = p->cur.col;
    Expr *e = new_expr(EX_CALL, line, col);
    e->as.call.callee = callee;
    e->as.call.args = NULL;
    e->as.call.argc = 0;

    next_token(p);
    if (p->cur.type == TOK_RPAREN) {
        next_token(p);
        return e;
    }

    while (1) {
        Expr *arg = parse_expression(p, PREC_LOWEST);
        e->as.call.args = expr_list_append(e->as.call.args, &e->as.call.argc, arg);
        if (p->cur.type == TOK_COMMA) {
            next_token(p);
            continue;
        }
        break;
    }

    expect_current(p, TOK_RPAREN, "expected ')' after argument list");
    next_token(p);
    return e;
}

static Expr *parse_index_infix(Parser *p, Expr *left) {
    int line = p->cur.line;
    int col = p->cur.col;
    Expr *e = new_expr(EX_INDEX, line, col);
    e->as.index.left = left;

    next_token(p);
    e->as.index.index = parse_expression(p, PREC_LOWEST);

    expect_current(p, TOK_RBRACKET, "expected ']' after index expression");
    next_token(p);
    return e;
}

static Expr *parse_dot_infix(Parser *p, Expr *left) {
    int line = p->cur.line;
    int col = p->cur.col;
    Expr *e = new_expr(EX_DOT, line, col);
    e->as.dot.left = left;

    next_token(p);
    expect_current(p, TOK_IDENT, "expected identifier after '.'");
    e->as.dot.member = xstrdup(p->cur.text);
    next_token(p);
    return e;
}

static Expr *parse_infix(Parser *p, Expr *left) {
    Token tok = p->cur;
    Expr *e = new_expr(EX_BINARY, tok.line, tok.col);
    e->as.binary.left = left;
    e->as.binary.op = tok.type;

    int op_prec = precedence(tok.type);
    next_token(p);
    e->as.binary.right = parse_expression(p, op_prec);
    return e;
}

static Expr *parse_expression(Parser *p, int prec) {
    Expr *left = parse_prefix(p);

    while (1) {
        if (p->cur.type == TOK_LPAREN && precedence(TOK_LPAREN) > prec) {
            left = parse_call_infix(p, left);
            continue;
        }
        if (p->cur.type == TOK_LBRACKET && precedence(TOK_LBRACKET) > prec) {
            left = parse_index_infix(p, left);
            continue;
        }
        if (p->cur.type == TOK_DOT && precedence(TOK_DOT) > prec) {
            left = parse_dot_infix(p, left);
            continue;
        }
        if (p->cur.type == TOK_RBRACE) break;

        int cur_prec = precedence(p->cur.type);
        if (cur_prec <= prec) break;
        left = parse_infix(p, left);
    }

    return left;
}

static Block *parse_block(Parser *p);

static Stmt *parse_let_statement(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;

    next_token(p);
    expect_current(p, TOK_IDENT, "expected identifier after let");
    char *name = xstrdup(p->cur.text);

    next_token(p);
    expect_current(p, TOK_ASSIGN, "expected '=' after identifier");

    next_token(p);
    Expr *value = parse_expression(p, PREC_LOWEST);

    expect_current(p, TOK_SEMI, "expected ';' after let statement");
    next_token(p);

    Stmt *s = new_stmt(ST_LET, line, col);
    s->as.let_stmt.name = name;
    s->as.let_stmt.value = value;
    return s;
}

static Stmt *parse_if_statement(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;

    next_token(p);
    expect_current(p, TOK_LPAREN, "expected '(' after if");

    next_token(p);
    Expr *cond = parse_expression(p, PREC_LOWEST);
    expect_current(p, TOK_RPAREN, "expected ')' after if condition");

    next_token(p);
    expect_current(p, TOK_LBRACE, "expected '{' after if condition");
    Block *then_block = parse_block(p);

    Block *else_block = NULL;
    if (p->cur.type == TOK_ELSE) {
        next_token(p);
        if (p->cur.type == TOK_IF) {
            Stmt *else_if_stmt = parse_if_statement(p);
            else_block = new_block();
            block_add_stmt(else_block, else_if_stmt);
        } else {
            expect_current(p, TOK_LBRACE, "expected '{' after else");
            else_block = parse_block(p);
        }
    }

    Stmt *s = new_stmt(ST_IF, line, col);
    s->as.if_stmt.cond = cond;
    s->as.if_stmt.then_block = then_block;
    s->as.if_stmt.else_block = else_block;
    return s;
}

static Stmt *parse_switch_statement(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;

    next_token(p);
    expect_current(p, TOK_LPAREN, "expected '(' after switch");
    next_token(p);
    Expr *value = parse_expression(p, PREC_LOWEST);
    expect_current(p, TOK_RPAREN, "expected ')' after switch expression");
    next_token(p);
    expect_current(p, TOK_LBRACE, "expected '{' after switch(...)");

    Expr **case_values = NULL;
    Block **case_blocks = NULL;
    int case_count = 0;
    Block *default_block = NULL;

    next_token(p);
    while (p->cur.type != TOK_RBRACE && p->cur.type != TOK_EOF) {
        if (p->cur.type == TOK_CASE) {
            next_token(p);
            Expr *case_value = parse_expression(p, PREC_LOWEST);
            expect_current(p, TOK_COLON, "expected ':' after case expression");
            next_token(p);
            expect_current(p, TOK_LBRACE, "expected '{' after case label");
            Block *case_block = parse_block(p);

            int idx = case_count;
            case_values = (Expr **)xrealloc(case_values, (size_t)(idx + 1) * sizeof(Expr *));
            case_blocks = (Block **)xrealloc(case_blocks, (size_t)(idx + 1) * sizeof(Block *));
            case_values[idx] = case_value;
            case_blocks[idx] = case_block;
            case_count++;
            continue;
        }
        if (p->cur.type == TOK_DEFAULT) {
            if (default_block != NULL) {
                fail_at(p->cur.line, p->cur.col, "duplicate default label in switch");
            }
            next_token(p);
            expect_current(p, TOK_COLON, "expected ':' after default");
            next_token(p);
            expect_current(p, TOK_LBRACE, "expected '{' after default label");
            default_block = parse_block(p);
            continue;
        }
        fail_at(p->cur.line, p->cur.col, "expected case/default label in switch body");
    }

    expect_current(p, TOK_RBRACE, "expected '}' after switch body");
    next_token(p);

    Stmt *s = new_stmt(ST_SWITCH, line, col);
    s->as.switch_stmt.value = value;
    s->as.switch_stmt.case_values = case_values;
    s->as.switch_stmt.case_blocks = case_blocks;
    s->as.switch_stmt.case_count = case_count;
    s->as.switch_stmt.default_block = default_block;
    return s;
}

static Stmt *parse_while_statement(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;

    next_token(p);
    expect_current(p, TOK_LPAREN, "expected '(' after while");

    next_token(p);
    Expr *cond = parse_expression(p, PREC_LOWEST);
    expect_current(p, TOK_RPAREN, "expected ')' after while condition");

    next_token(p);
    expect_current(p, TOK_LBRACE, "expected '{' after while condition");
    Block *body = parse_block(p);

    Stmt *s = new_stmt(ST_WHILE, line, col);
    s->as.while_stmt.cond = cond;
    s->as.while_stmt.body = body;
    return s;
}

static Stmt *parse_for_statement(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;

    next_token(p);
    expect_current(p, TOK_LPAREN, "expected '(' after for");

    next_token(p);
    expect_current(p, TOK_IDENT, "expected iterator variable in for statement");
    char *iter_name = xstrdup(p->cur.text);
    char *iter_value_name = NULL;

    next_token(p);
    if (p->cur.type == TOK_COMMA) {
        next_token(p);
        expect_current(p, TOK_IDENT, "expected second iterator variable in for statement");
        iter_value_name = xstrdup(p->cur.text);
        next_token(p);
    }
    expect_current(p, TOK_IN, "expected 'in' in for statement");

    next_token(p);
    Expr *iter_expr = parse_expression(p, PREC_LOWEST);

    expect_current(p, TOK_RPAREN, "expected ')' after for iterator");
    next_token(p);

    expect_current(p, TOK_LBRACE, "expected '{' after for statement");
    Block *body = parse_block(p);

    Stmt *s = new_stmt(ST_FOR, line, col);
    s->as.for_stmt.iter_name = iter_name;
    s->as.for_stmt.iter_value_name = iter_value_name;
    s->as.for_stmt.iter_expr = iter_expr;
    s->as.for_stmt.body = body;
    return s;
}

static Stmt *parse_try_statement(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;

    next_token(p);
    expect_current(p, TOK_LBRACE, "expected '{' after try");
    Block *try_block = parse_block(p);

    expect_current(p, TOK_CATCH, "expected catch after try block");
    next_token(p);
    expect_current(p, TOK_LPAREN, "expected '(' after catch");

    next_token(p);
    expect_current(p, TOK_IDENT, "expected catch variable name");
    char *catch_name = xstrdup(p->cur.text);

    next_token(p);
    expect_current(p, TOK_RPAREN, "expected ')' after catch variable");

    next_token(p);
    expect_current(p, TOK_LBRACE, "expected '{' after catch(...)");
    Block *catch_block = parse_block(p);

    Stmt *s = new_stmt(ST_TRY, line, col);
    s->as.try_stmt.try_block = try_block;
    s->as.try_stmt.catch_name = catch_name;
    s->as.try_stmt.catch_block = catch_block;
    return s;
}

static Stmt *parse_break_statement(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;
    next_token(p);
    expect_current(p, TOK_SEMI, "expected ';' after break");
    next_token(p);
    return new_stmt(ST_BREAK, line, col);
}

static Stmt *parse_continue_statement(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;
    next_token(p);
    expect_current(p, TOK_SEMI, "expected ';' after continue");
    next_token(p);
    return new_stmt(ST_CONTINUE, line, col);
}

static Stmt *parse_class_statement(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;

    next_token(p);
    expect_current(p, TOK_IDENT, "expected class name after class");
    char *name = xstrdup(p->cur.text);

    next_token(p);
    expect_current(p, TOK_LBRACE, "expected '{' after class name");
    Block *body = parse_block(p);

    Stmt *s = new_stmt(ST_CLASS, line, col);
    s->as.class_stmt.name = name;
    s->as.class_stmt.body = body;
    return s;
}

static Stmt *parse_module_statement(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;

    next_token(p);
    expect_current(p, TOK_IDENT, "expected module name after module");
    char *name = xstrdup(p->cur.text);

    next_token(p);
    expect_current(p, TOK_LBRACE, "expected '{' after module name");
    Block *body = parse_block(p);

    Stmt *s = new_stmt(ST_MODULE, line, col);
    s->as.module_stmt.name = name;
    s->as.module_stmt.body = body;
    return s;
}

static Stmt *parse_type_statement(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;

    next_token(p);
    expect_current(p, TOK_IDENT, "expected type name after typealias");
    char *name = xstrdup(p->cur.text);

    next_token(p);
    expect_current(p, TOK_ASSIGN, "expected '=' after type name");
    next_token(p);
    Expr *value = parse_expression(p, PREC_LOWEST);
    expect_current(p, TOK_SEMI, "expected ';' after typealias statement");
    next_token(p);

    Stmt *s = new_stmt(ST_TYPE, line, col);
    s->as.type_stmt.name = name;
    s->as.type_stmt.value = value;
    return s;
}

static Stmt *parse_fn_statement(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;

    next_token(p);
    expect_current(p, TOK_IDENT, "expected function name after fn");
    char *name = xstrdup(p->cur.text);

    next_token(p);
    expect_current(p, TOK_LPAREN, "expected '(' after function name");

    char **params = NULL;
    int param_count = 0;

    next_token(p);
    if (p->cur.type != TOK_RPAREN) {
        while (1) {
            expect_current(p, TOK_IDENT, "expected parameter name");
            params = str_list_append(params, &param_count, p->cur.text);
            next_token(p);
            if (p->cur.type == TOK_COMMA) {
                next_token(p);
                continue;
            }
            break;
        }
    }

    expect_current(p, TOK_RPAREN, "expected ')' after parameter list");
    next_token(p);

    expect_current(p, TOK_LBRACE, "expected '{' before function body");
    Block *body = parse_block(p);

    Stmt *s = new_stmt(ST_FN, line, col);
    s->as.fn_stmt.name = name;
    s->as.fn_stmt.params = params;
    s->as.fn_stmt.param_count = param_count;
    s->as.fn_stmt.body = body;
    return s;
}

static Stmt *parse_return_statement(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;

    next_token(p);
    Expr *value = NULL;
    if (p->cur.type == TOK_SEMI) {
        value = new_expr(EX_NULL, line, col);
    } else {
        value = parse_expression(p, PREC_LOWEST);
    }

    expect_current(p, TOK_SEMI, "expected ';' after return");
    next_token(p);

    Stmt *s = new_stmt(ST_RETURN, line, col);
    s->as.return_stmt.value = value;
    return s;
}

static Stmt *parse_throw_statement(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;

    next_token(p);
    Expr *value = parse_expression(p, PREC_LOWEST);

    expect_current(p, TOK_SEMI, "expected ';' after throw");
    next_token(p);

    Stmt *s = new_stmt(ST_THROW, line, col);
    s->as.throw_stmt.value = value;
    return s;
}

static Stmt *parse_import_statement(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;

    next_token(p);
    expect_current(p, TOK_STRING, "expected string path after import");
    char *path = xstrdup(p->cur.text);

    next_token(p);
    expect_current(p, TOK_SEMI, "expected ';' after import");
    next_token(p);

    Stmt *s = new_stmt(ST_IMPORT, line, col);
    s->as.import_stmt.path = path;
    return s;
}

static Stmt *parse_expr_or_assignment_statement(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;

    Expr *lhs = parse_expression(p, PREC_LOWEST);
    if (p->cur.type == TOK_ASSIGN) {
        next_token(p);
        Expr *value = parse_expression(p, PREC_LOWEST);
        expect_current(p, TOK_SEMI, "expected ';' after assignment");
        next_token(p);

        if (lhs->kind == EX_IDENT) {
            Stmt *s = new_stmt(ST_ASSIGN, line, col);
            s->as.assign_stmt.name = lhs->as.ident;
            s->as.assign_stmt.value = value;
            return s;
        }
        if (lhs->kind == EX_DOT) {
            Stmt *s = new_stmt(ST_SET_MEMBER, line, col);
            s->as.set_member_stmt.object = lhs->as.dot.left;
            s->as.set_member_stmt.member = lhs->as.dot.member;
            s->as.set_member_stmt.value = value;
            return s;
        }
        if (lhs->kind == EX_INDEX) {
            Stmt *s = new_stmt(ST_SET_INDEX, line, col);
            s->as.set_index_stmt.object = lhs->as.index.left;
            s->as.set_index_stmt.index = lhs->as.index.index;
            s->as.set_index_stmt.value = value;
            return s;
        }
        fail_at(line, col, "invalid assignment target");
    }

    expect_current(p, TOK_SEMI, "expected ';' after expression");
    next_token(p);

    Stmt *s = new_stmt(ST_EXPR, line, col);
    s->as.expr_stmt.expr = lhs;
    return s;
}

static Stmt *parse_statement(Parser *p) {
    if (p->cur.type == TOK_LET) return parse_let_statement(p);
    if (p->cur.type == TOK_IF) return parse_if_statement(p);
    if (p->cur.type == TOK_SWITCH) return parse_switch_statement(p);
    if (p->cur.type == TOK_WHILE) return parse_while_statement(p);
    if (p->cur.type == TOK_FOR) return parse_for_statement(p);
    if (p->cur.type == TOK_TRY) return parse_try_statement(p);
    if (p->cur.type == TOK_BREAK) return parse_break_statement(p);
    if (p->cur.type == TOK_CONTINUE) return parse_continue_statement(p);
    if (p->cur.type == TOK_CLASS) return parse_class_statement(p);
    if (p->cur.type == TOK_MODULE) return parse_module_statement(p);
    if (p->cur.type == TOK_TYPEDEF) return parse_type_statement(p);
    if (p->cur.type == TOK_FN) return parse_fn_statement(p);
    if (p->cur.type == TOK_RETURN) return parse_return_statement(p);
    if (p->cur.type == TOK_THROW) return parse_throw_statement(p);
    if (p->cur.type == TOK_IMPORT) return parse_import_statement(p);
    return parse_expr_or_assignment_statement(p);
}

static Block *parse_block(Parser *p) {
    expect_current(p, TOK_LBRACE, "expected '{'");
    next_token(p);

    Block *block = new_block();
    while (p->cur.type != TOK_RBRACE && p->cur.type != TOK_EOF) {
        if (p->cur.type == TOK_ILLEGAL) fail_at(p->cur.line, p->cur.col, "illegal token");
        block_add_stmt(block, parse_statement(p));
    }

    expect_current(p, TOK_RBRACE, "expected '}' after block");
    next_token(p);
    return block;
}

static Block *parse_program(Parser *p) {
    Block *program = new_block();
    while (p->cur.type != TOK_EOF) {
        if (p->cur.type == TOK_ILLEGAL) fail_at(p->cur.line, p->cur.col, "illegal token");
        block_add_stmt(program, parse_statement(p));
    }
    return program;
}

static void load_program_recursive(const char *path, Block *out, StrSet *visited) {
    if (!strset_add(visited, path)) return;

    char *source = NULL;
    const char *builtin_src = builtin_module_source(path);
    if (builtin_src) {
        source = xstrdup(builtin_src);
    } else {
        source = read_file(path);
    }
    if (!source) {
        fprintf(stderr, "Error: could not read input source: %s\n", path);
        exit(1);
    }

    Parser p;
    parser_init(&p, source);
    Block *program = parse_program(&p);

    for (int i = 0; i < program->count; i++) {
        Stmt *s = program->items[i];
        if (s->kind == ST_IMPORT) {
            char *child = NULL;
            if (is_builtin_module_path(s->as.import_stmt.path)) {
                child = xstrdup(s->as.import_stmt.path);
            } else {
                child = resolve_import_path(path, s->as.import_stmt.path);
            }
            load_program_recursive(child, out, visited);
            free(child);
            continue;
        }
        block_add_stmt(out, s);
    }

    free(source);
}

static void scope_push(GenCtx *ctx) {
    Scope *s = (Scope *)xmalloc(sizeof(Scope));
    s->items = NULL;
    s->count = 0;
    s->cap = 0;
    s->parent = ctx->scope;
    ctx->scope = s;
}

static void scope_pop(GenCtx *ctx) {
    Scope *s = ctx->scope;
    if (!s) return;
    ctx->scope = s->parent;
}

static void scope_add(GenCtx *ctx, const char *cy_name, const char *c_name) {
    Scope *s = ctx->scope;
    if (!s) fail("scope_add on empty scope");

    if (s->count == s->cap) {
        int next_cap = s->cap == 0 ? 8 : s->cap * 2;
        s->items = (Binding *)xrealloc(s->items, (size_t)next_cap * sizeof(Binding));
        s->cap = next_cap;
    }

    s->items[s->count].cy_name = xstrdup(cy_name);
    s->items[s->count].c_name = xstrdup(c_name);
    s->count++;
}

static const char *scope_lookup(GenCtx *ctx, const char *cy_name) {
    for (Scope *s = ctx->scope; s != NULL; s = s->parent) {
        for (int i = s->count - 1; i >= 0; i--) {
            if (strcmp(s->items[i].cy_name, cy_name) == 0) return s->items[i].c_name;
        }
    }
    return NULL;
}

static char *make_temp_name(GenCtx *ctx, const char *prefix) {
    return xstrfmt("__cy_%s_%d", prefix, ctx->next_id++);
}

static void capture_list_init(CaptureList *caps) {
    caps->cy_names = NULL;
    caps->c_names = NULL;
    caps->count = 0;
    caps->cap = 0;
}

static int capture_list_find(CaptureList *caps, const char *cy_name) {
    for (int i = 0; i < caps->count; i++) {
        if (strcmp(caps->cy_names[i], cy_name) == 0) return i;
    }
    return -1;
}

static void capture_list_add(CaptureList *caps, const char *cy_name, const char *c_name) {
    if (capture_list_find(caps, cy_name) >= 0) return;
    if (caps->count == caps->cap) {
        int next_cap = caps->cap == 0 ? 8 : caps->cap * 2;
        caps->cy_names = (char **)xrealloc(caps->cy_names, (size_t)next_cap * sizeof(char *));
        caps->c_names = (char **)xrealloc(caps->c_names, (size_t)next_cap * sizeof(char *));
        caps->cap = next_cap;
    }
    caps->cy_names[caps->count] = xstrdup(cy_name);
    caps->c_names[caps->count] = xstrdup(c_name);
    caps->count++;
}

static void capture_list_free(CaptureList *caps) {
    for (int i = 0; i < caps->count; i++) {
        free(caps->cy_names[i]);
        free(caps->c_names[i]);
    }
    free(caps->cy_names);
    free(caps->c_names);
}

static void scope_collect_visible_bindings(GenCtx *ctx, CaptureList *caps) {
    for (Scope *s = ctx->scope; s != NULL; s = s->parent) {
        for (int i = s->count - 1; i >= 0; i--) {
            capture_list_add(caps, s->items[i].cy_name, s->items[i].c_name);
        }
    }
}

typedef enum {
    BUILTIN_NONE = 0,
    BUILTIN_PRINT,
    BUILTIN_LEN,
    BUILTIN_ABS,
    BUILTIN_MIN,
    BUILTIN_MAX,
    BUILTIN_CLAMP,
    BUILTIN_SUM,
    BUILTIN_ALL,
    BUILTIN_ANY,
    BUILTIN_RANGE,
    BUILTIN_READ,
    BUILTIN_WRITE,
    BUILTIN_TYPE,
    BUILTIN_TYPE_OF,
    BUILTIN_IS_INT,
    BUILTIN_IS_BOOL,
    BUILTIN_IS_STRING,
    BUILTIN_IS_ARRAY,
    BUILTIN_IS_FUNCTION,
    BUILTIN_IS_NULL,
    BUILTIN_STR,
    BUILTIN_INT,
    BUILTIN_PUSH,
    BUILTIN_POP,
    BUILTIN_ARGC,
    BUILTIN_ARGV,
    BUILTIN_OBJECT_NEW,
    BUILTIN_OBJECT_SET,
    BUILTIN_OBJECT_GET,
    BUILTIN_KEYS,
    BUILTIN_VALUES,
    BUILTIN_ITEMS,
    BUILTIN_HAS,
    BUILTIN_NEW,
    BUILTIN_LANG_VERSION,
    BUILTIN_REQUIRE_VERSION,
    BUILTIN_CLASS_NEW,
    BUILTIN_CLASS_WITH_CTOR,
    BUILTIN_CLASS_SET_METHOD,
    BUILTIN_CLASS_NAME,
    BUILTIN_CLASS_INSTANTIATE0,
    BUILTIN_CLASS_INSTANTIATE1,
    BUILTIN_CLASS_INSTANTIATE2,
    BUILTIN_CLASS_CALL0,
    BUILTIN_CLASS_CALL1,
    BUILTIN_CLASS_CALL2
} BuiltinKind;

static BuiltinKind builtin_kind(const char *name) {
    if (strcmp(name, "print") == 0) return BUILTIN_PRINT;
    if (strcmp(name, "len") == 0) return BUILTIN_LEN;
    if (strcmp(name, "abs") == 0) return BUILTIN_ABS;
    if (strcmp(name, "min") == 0) return BUILTIN_MIN;
    if (strcmp(name, "max") == 0) return BUILTIN_MAX;
    if (strcmp(name, "clamp") == 0) return BUILTIN_CLAMP;
    if (strcmp(name, "sum") == 0) return BUILTIN_SUM;
    if (strcmp(name, "all") == 0) return BUILTIN_ALL;
    if (strcmp(name, "any") == 0) return BUILTIN_ANY;
    if (strcmp(name, "range") == 0) return BUILTIN_RANGE;
    if (strcmp(name, "read") == 0) return BUILTIN_READ;
    if (strcmp(name, "write") == 0) return BUILTIN_WRITE;
    if (strcmp(name, "type") == 0) return BUILTIN_TYPE;
    if (strcmp(name, "type_of") == 0) return BUILTIN_TYPE_OF;
    if (strcmp(name, "is_int") == 0) return BUILTIN_IS_INT;
    if (strcmp(name, "is_bool") == 0) return BUILTIN_IS_BOOL;
    if (strcmp(name, "is_string") == 0) return BUILTIN_IS_STRING;
    if (strcmp(name, "is_array") == 0) return BUILTIN_IS_ARRAY;
    if (strcmp(name, "is_function") == 0) return BUILTIN_IS_FUNCTION;
    if (strcmp(name, "is_null") == 0) return BUILTIN_IS_NULL;
    if (strcmp(name, "str") == 0) return BUILTIN_STR;
    if (strcmp(name, "int") == 0) return BUILTIN_INT;
    if (strcmp(name, "push") == 0) return BUILTIN_PUSH;
    if (strcmp(name, "pop") == 0) return BUILTIN_POP;
    if (strcmp(name, "argc") == 0) return BUILTIN_ARGC;
    if (strcmp(name, "argv") == 0) return BUILTIN_ARGV;
    if (strcmp(name, "object_new") == 0) return BUILTIN_OBJECT_NEW;
    if (strcmp(name, "object_set") == 0) return BUILTIN_OBJECT_SET;
    if (strcmp(name, "object_get") == 0) return BUILTIN_OBJECT_GET;
    if (strcmp(name, "keys") == 0) return BUILTIN_KEYS;
    if (strcmp(name, "values") == 0) return BUILTIN_VALUES;
    if (strcmp(name, "items") == 0) return BUILTIN_ITEMS;
    if (strcmp(name, "has") == 0) return BUILTIN_HAS;
    if (strcmp(name, "new") == 0) return BUILTIN_NEW;
    if (strcmp(name, "lang_version") == 0) return BUILTIN_LANG_VERSION;
    if (strcmp(name, "require_version") == 0) return BUILTIN_REQUIRE_VERSION;
    if (strcmp(name, "class_new") == 0) return BUILTIN_CLASS_NEW;
    if (strcmp(name, "class_with_ctor") == 0) return BUILTIN_CLASS_WITH_CTOR;
    if (strcmp(name, "class_set_method") == 0) return BUILTIN_CLASS_SET_METHOD;
    if (strcmp(name, "class_name") == 0) return BUILTIN_CLASS_NAME;
    if (strcmp(name, "class_instantiate0") == 0) return BUILTIN_CLASS_INSTANTIATE0;
    if (strcmp(name, "class_instantiate1") == 0) return BUILTIN_CLASS_INSTANTIATE1;
    if (strcmp(name, "class_instantiate2") == 0) return BUILTIN_CLASS_INSTANTIATE2;
    if (strcmp(name, "class_call0") == 0) return BUILTIN_CLASS_CALL0;
    if (strcmp(name, "class_call1") == 0) return BUILTIN_CLASS_CALL1;
    if (strcmp(name, "class_call2") == 0) return BUILTIN_CLASS_CALL2;
    return BUILTIN_NONE;
}

static const char *builtin_callee_name(BuiltinKind kind) {
    switch (kind) {
        case BUILTIN_PRINT: return "cy_builtin_print";
        case BUILTIN_LEN: return "cy_builtin_len";
        case BUILTIN_ABS: return "cy_builtin_abs";
        case BUILTIN_MIN: return "cy_builtin_min";
        case BUILTIN_MAX: return "cy_builtin_max";
        case BUILTIN_CLAMP: return "cy_builtin_clamp";
        case BUILTIN_SUM: return "cy_builtin_sum";
        case BUILTIN_ALL: return "cy_builtin_all";
        case BUILTIN_ANY: return "cy_builtin_any";
        case BUILTIN_RANGE: return "cy_builtin_range";
        case BUILTIN_READ: return "cy_builtin_read";
        case BUILTIN_WRITE: return "cy_builtin_write";
        case BUILTIN_TYPE:
        case BUILTIN_TYPE_OF:
            return "cy_builtin_type";
        case BUILTIN_IS_INT: return "cy_builtin_is_int";
        case BUILTIN_IS_BOOL: return "cy_builtin_is_bool";
        case BUILTIN_IS_STRING: return "cy_builtin_is_string";
        case BUILTIN_IS_ARRAY: return "cy_builtin_is_array";
        case BUILTIN_IS_FUNCTION: return "cy_builtin_is_function";
        case BUILTIN_IS_NULL: return "cy_builtin_is_null";
        case BUILTIN_STR: return "cy_builtin_str";
        case BUILTIN_INT: return "cy_builtin_int";
        case BUILTIN_PUSH: return "cy_builtin_push";
        case BUILTIN_POP: return "cy_builtin_pop";
        case BUILTIN_ARGC: return "cy_builtin_argc";
        case BUILTIN_ARGV: return "cy_builtin_argv";
        case BUILTIN_OBJECT_NEW: return "cy_builtin_object_new";
        case BUILTIN_OBJECT_SET: return "cy_builtin_object_set";
        case BUILTIN_OBJECT_GET: return "cy_builtin_object_get";
        case BUILTIN_KEYS: return "cy_builtin_keys";
        case BUILTIN_VALUES: return "cy_builtin_values";
        case BUILTIN_ITEMS: return "cy_builtin_items";
        case BUILTIN_HAS: return "cy_builtin_has";
        case BUILTIN_NEW: return "cy_builtin_new";
        case BUILTIN_LANG_VERSION: return "cy_builtin_lang_version";
        case BUILTIN_REQUIRE_VERSION: return "cy_builtin_require_version";
        case BUILTIN_CLASS_NEW: return "cy_builtin_class_new";
        case BUILTIN_CLASS_WITH_CTOR: return "cy_builtin_class_with_ctor";
        case BUILTIN_CLASS_SET_METHOD: return "cy_builtin_class_set_method";
        case BUILTIN_CLASS_NAME: return "cy_builtin_class_name";
        case BUILTIN_CLASS_INSTANTIATE0: return "cy_builtin_class_instantiate0";
        case BUILTIN_CLASS_INSTANTIATE1: return "cy_builtin_class_instantiate1";
        case BUILTIN_CLASS_INSTANTIATE2: return "cy_builtin_class_instantiate2";
        case BUILTIN_CLASS_CALL0: return "cy_builtin_class_call0";
        case BUILTIN_CLASS_CALL1: return "cy_builtin_class_call1";
        case BUILTIN_CLASS_CALL2: return "cy_builtin_class_call2";
        case BUILTIN_NONE: break;
    }
    return NULL;
}

static void append_c_string_literal(StrBuf *sb, const char *s) {
    sb_append_char(sb, '"');
    for (const unsigned char *p = (const unsigned char *)s; *p; p++) {
        unsigned char ch = *p;
        if (ch == '\\') {
            sb_append_str(sb, "\\\\");
        } else if (ch == '"') {
            sb_append_str(sb, "\\\"");
        } else if (ch == '\n') {
            sb_append_str(sb, "\\n");
        } else if (ch == '\r') {
            sb_append_str(sb, "\\r");
        } else if (ch == '\t') {
            sb_append_str(sb, "\\t");
        } else if (ch < 32 || ch > 126) {
            sb_append_fmt(sb, "\\x%02X", (unsigned int)ch);
        } else {
            sb_append_char(sb, (char)ch);
        }
    }
    sb_append_char(sb, '"');
}

static void gen_expr(Expr *e, StrBuf *sb, GenCtx *ctx);
static void gen_array_comp_expr(Expr *e, StrBuf *sb, GenCtx *ctx);
static int expr_uses_ident(Expr *e, const char *name);

static void gen_args_vector(Expr **args, int argc, StrBuf *sb, GenCtx *ctx) {
    sb_append_fmt(sb, "%d, ", argc);
    if (argc == 0) {
        sb_append_str(sb, "NULL");
        return;
    }

    sb_append_str(sb, "(CyValue[]){");
    for (int i = 0; i < argc; i++) {
        if (i != 0) sb_append_str(sb, ", ");
        gen_expr(args[i], sb, ctx);
    }
    sb_append_char(sb, '}');
}

static void gen_call_expr(Expr *e, StrBuf *sb, GenCtx *ctx) {
    Expr *callee = e->as.call.callee;
    int argc = e->as.call.argc;
    Expr **args = e->as.call.args;

    if (callee->kind == EX_IDENT) {
        const char *name = callee->as.ident;
        const char *var_name = scope_lookup(ctx, name);
        if (var_name) {
            sb_append_str(sb, "cy_call_value(");
            sb_append_str(sb, var_name);
            sb_append_str(sb, ", ");
            gen_args_vector(args, argc, sb, ctx);
            sb_append_char(sb, ')');
            return;
        }

        BuiltinKind b = builtin_kind(name);
        if (b != BUILTIN_NONE) {
            sb_append_str(sb, builtin_callee_name(b));
            sb_append_char(sb, '(');
            gen_args_vector(args, argc, sb, ctx);
            sb_append_char(sb, ')');
            return;
        }

        if (strset_contains(ctx->fn_names, name)) {
            sb_append_fmt(sb, "fn_%s(", name);
            gen_args_vector(args, argc, sb, ctx);
            sb_append_char(sb, ')');
            return;
        }

        fail_at(callee->line, callee->col, "unknown function in call expression");
    }

    sb_append_str(sb, "cy_call_value(");
    gen_expr(callee, sb, ctx);
    sb_append_str(sb, ", ");
    gen_args_vector(args, argc, sb, ctx);
    sb_append_char(sb, ')');
}

static int expr_uses_ident(Expr *e, const char *name) {
    switch (e->kind) {
        case EX_INT:
        case EX_STRING:
        case EX_BOOL:
        case EX_NULL:
            return 0;
        case EX_IDENT:
            return strcmp(e->as.ident, name) == 0;
        case EX_ARRAY:
            for (int i = 0; i < e->as.array.count; i++) {
                if (expr_uses_ident(e->as.array.items[i], name)) return 1;
            }
            return 0;
        case EX_ARRAY_COMP:
            if (expr_uses_ident(e->as.array_comp.iter_expr, name)) return 1;
            if (strcmp(e->as.array_comp.iter_name, name) == 0) return 0;
            if (e->as.array_comp.iter_value_name && strcmp(e->as.array_comp.iter_value_name, name) == 0) return 0;
            if (expr_uses_ident(e->as.array_comp.value_expr, name)) return 1;
            if (e->as.array_comp.filter_expr && expr_uses_ident(e->as.array_comp.filter_expr, name)) return 1;
            return 0;
        case EX_OBJECT:
            for (int i = 0; i < e->as.object.count; i++) {
                if (expr_uses_ident(e->as.object.values[i], name)) return 1;
            }
            return 0;
        case EX_INDEX:
            return expr_uses_ident(e->as.index.left, name) || expr_uses_ident(e->as.index.index, name);
        case EX_DOT:
            return expr_uses_ident(e->as.dot.left, name);
        case EX_UNARY:
            return expr_uses_ident(e->as.unary.right, name);
        case EX_BINARY:
            return expr_uses_ident(e->as.binary.left, name) || expr_uses_ident(e->as.binary.right, name);
        case EX_CALL:
            if (expr_uses_ident(e->as.call.callee, name)) return 1;
            for (int i = 0; i < e->as.call.argc; i++) {
                if (expr_uses_ident(e->as.call.args[i], name)) return 1;
            }
            return 0;
    }
    return 0;
}

static void gen_array_comp_expr(Expr *e, StrBuf *sb, GenCtx *ctx) {
    if (!ctx->comp_cases) {
        fail_at(e->line, e->col, "internal error: missing comprehension codegen buffer");
    }

    CaptureList visible;
    CaptureList caps;
    capture_list_init(&visible);
    capture_list_init(&caps);
    scope_collect_visible_bindings(ctx, &visible);
    for (int i = 0; i < visible.count; i++) {
        const char *name = visible.cy_names[i];
        if (strcmp(name, e->as.array_comp.iter_name) == 0) continue;
        if (e->as.array_comp.iter_value_name && strcmp(name, e->as.array_comp.iter_value_name) == 0) continue;
        int used = 0;
        if (expr_uses_ident(e->as.array_comp.iter_expr, name)) used = 1;
        if (!used && expr_uses_ident(e->as.array_comp.value_expr, name)) used = 1;
        if (!used && e->as.array_comp.filter_expr && expr_uses_ident(e->as.array_comp.filter_expr, name)) used = 1;
        if (used) capture_list_add(&caps, visible.cy_names[i], visible.c_names[i]);
    }
    capture_list_free(&visible);

    int comp_id = ctx->next_id++;

    GenCtx hctx;
    hctx.scope = NULL;
    hctx.fn_names = ctx->fn_names;
    hctx.next_id = ctx->next_id;
    hctx.loop_depth = 0;
    hctx.comp_cases = ctx->comp_cases;

    scope_push(&hctx);

    char **cap_locals = NULL;
    if (caps.count > 0) {
        cap_locals = (char **)xmalloc((size_t)caps.count * sizeof(char *));
    }

    sb_append_fmt(ctx->comp_cases, "        case %d: {\n", comp_id);
    sb_append_str(ctx->comp_cases,
                  "            if (__cy_env.type != CY_OBJECT) "
                  "cy_runtime_error(\"internal error: comprehension env must be object\");\n");

    for (int i = 0; i < caps.count; i++) {
        cap_locals[i] = make_temp_name(&hctx, caps.cy_names[i]);
        scope_add(&hctx, caps.cy_names[i], cap_locals[i]);

        StrBuf key_lit;
        sb_init(&key_lit);
        append_c_string_literal(&key_lit, caps.cy_names[i]);
        sb_append_fmt(ctx->comp_cases, "            CyValue %s = cy_object_get_raw(__cy_env.as.object_val, %s);\n",
                      cap_locals[i], key_lit.buf);
        free(key_lit.buf);
    }

    char *out_tmp = make_temp_name(&hctx, "comp_out");
    char *iter_tmp = make_temp_name(&hctx, "comp_iter");
    char *idx_tmp = make_temp_name(&hctx, "comp_i");

    StrBuf iter_expr;
    sb_init(&iter_expr);
    gen_expr(e->as.array_comp.iter_expr, &iter_expr, &hctx);

    sb_append_fmt(ctx->comp_cases, "            CyValue %s = cy_array_make(0, NULL);\n", out_tmp);
    sb_append_fmt(ctx->comp_cases, "            CyValue %s = %s;\n", iter_tmp, iter_expr.buf);
    sb_append_fmt(ctx->comp_cases, "            if (%s.type == CY_ARRAY) {\n", iter_tmp);
    sb_append_fmt(ctx->comp_cases, "                for (int %s = 0; %s < %s.as.array_val->count; %s++) {\n", idx_tmp,
                  idx_tmp, iter_tmp, idx_tmp);

    scope_push(&hctx);
    char *item_tmp = NULL;
    char *index_tmp = NULL;
    if (e->as.array_comp.iter_value_name) {
        index_tmp = make_temp_name(&hctx, e->as.array_comp.iter_name);
        item_tmp = make_temp_name(&hctx, e->as.array_comp.iter_value_name);
        scope_add(&hctx, e->as.array_comp.iter_name, index_tmp);
        scope_add(&hctx, e->as.array_comp.iter_value_name, item_tmp);
        sb_append_fmt(ctx->comp_cases, "                    CyValue %s = cy_int(%s);\n", index_tmp, idx_tmp);
        sb_append_fmt(ctx->comp_cases, "                    (void)%s;\n", index_tmp);
        sb_append_fmt(ctx->comp_cases, "                    CyValue %s = %s.as.array_val->items[%s];\n", item_tmp, iter_tmp,
                      idx_tmp);
        sb_append_fmt(ctx->comp_cases, "                    (void)%s;\n", item_tmp);
    } else {
        item_tmp = make_temp_name(&hctx, e->as.array_comp.iter_name);
        scope_add(&hctx, e->as.array_comp.iter_name, item_tmp);
        sb_append_fmt(ctx->comp_cases, "                    CyValue %s = %s.as.array_val->items[%s];\n", item_tmp, iter_tmp,
                      idx_tmp);
        sb_append_fmt(ctx->comp_cases, "                    (void)%s;\n", item_tmp);
    }

    if (e->as.array_comp.filter_expr) {
        StrBuf filter_expr;
        sb_init(&filter_expr);
        gen_expr(e->as.array_comp.filter_expr, &filter_expr, &hctx);
        sb_append_fmt(ctx->comp_cases, "                    if (!cy_truthy(%s)) continue;\n", filter_expr.buf);
        free(filter_expr.buf);
    }

    StrBuf value_expr;
    sb_init(&value_expr);
    gen_expr(e->as.array_comp.value_expr, &value_expr, &hctx);
    sb_append_fmt(ctx->comp_cases, "                    cy_builtin_push(2, (CyValue[]){%s, %s});\n", out_tmp,
                  value_expr.buf);
    free(value_expr.buf);
    scope_pop(&hctx);
    free(index_tmp);
    free(item_tmp);

    sb_append_str(ctx->comp_cases, "                }\n");
    sb_append_fmt(ctx->comp_cases, "            } else if (%s.type == CY_OBJECT) {\n", iter_tmp);
    sb_append_fmt(ctx->comp_cases, "                for (int %s = 0; %s < %s.as.object_val->count; %s++) {\n", idx_tmp,
                  idx_tmp, iter_tmp, idx_tmp);

    scope_push(&hctx);
    char *obj_key_tmp = make_temp_name(&hctx, e->as.array_comp.iter_name);
    char *obj_value_tmp = NULL;
    scope_add(&hctx, e->as.array_comp.iter_name, obj_key_tmp);
    sb_append_fmt(ctx->comp_cases, "                    CyValue %s = cy_string(%s.as.object_val->items[%s].key);\n",
                  obj_key_tmp, iter_tmp, idx_tmp);
    sb_append_fmt(ctx->comp_cases, "                    (void)%s;\n", obj_key_tmp);
    if (e->as.array_comp.iter_value_name) {
        obj_value_tmp = make_temp_name(&hctx, e->as.array_comp.iter_value_name);
        scope_add(&hctx, e->as.array_comp.iter_value_name, obj_value_tmp);
        sb_append_fmt(ctx->comp_cases, "                    CyValue %s = %s.as.object_val->items[%s].value;\n",
                      obj_value_tmp, iter_tmp, idx_tmp);
        sb_append_fmt(ctx->comp_cases, "                    (void)%s;\n", obj_value_tmp);
    }

    if (e->as.array_comp.filter_expr) {
        StrBuf filter_expr_obj;
        sb_init(&filter_expr_obj);
        gen_expr(e->as.array_comp.filter_expr, &filter_expr_obj, &hctx);
        sb_append_fmt(ctx->comp_cases, "                    if (!cy_truthy(%s)) continue;\n", filter_expr_obj.buf);
        free(filter_expr_obj.buf);
    }

    StrBuf value_expr_obj;
    sb_init(&value_expr_obj);
    gen_expr(e->as.array_comp.value_expr, &value_expr_obj, &hctx);
    sb_append_fmt(ctx->comp_cases, "                    cy_builtin_push(2, (CyValue[]){%s, %s});\n", out_tmp,
                  value_expr_obj.buf);
    free(value_expr_obj.buf);
    scope_pop(&hctx);
    free(obj_key_tmp);
    free(obj_value_tmp);

    sb_append_str(ctx->comp_cases, "                }\n");
    sb_append_str(ctx->comp_cases, "            } else {\n");
    sb_append_str(ctx->comp_cases,
                  "                cy_runtime_error(\"array comprehension expects array or object iterable\");\n");
    sb_append_str(ctx->comp_cases, "            }\n");
    sb_append_fmt(ctx->comp_cases, "            return %s;\n", out_tmp);
    sb_append_str(ctx->comp_cases, "        }\n");

    ctx->next_id = hctx.next_id;

    free(iter_expr.buf);
    free(out_tmp);
    free(iter_tmp);
    free(idx_tmp);
    for (int i = 0; i < caps.count; i++) {
        free(cap_locals[i]);
    }
    free(cap_locals);
    scope_pop(&hctx);

    sb_append_fmt(sb, "cy_eval_comp(%d, cy_object_literal(", comp_id);
    if (caps.count == 0) {
        sb_append_str(sb, "0, NULL, NULL");
    } else {
        sb_append_fmt(sb, "%d, (const char*[]){", caps.count);
        for (int i = 0; i < caps.count; i++) {
            if (i != 0) sb_append_str(sb, ", ");
            append_c_string_literal(sb, caps.cy_names[i]);
        }
        sb_append_str(sb, "}, (CyValue[]){");
        for (int i = 0; i < caps.count; i++) {
            if (i != 0) sb_append_str(sb, ", ");
            sb_append_str(sb, caps.c_names[i]);
        }
        sb_append_char(sb, '}');
    }
    sb_append_str(sb, "))");

    capture_list_free(&caps);
}

static void gen_expr(Expr *e, StrBuf *sb, GenCtx *ctx) {
    switch (e->kind) {
        case EX_INT:
            sb_append_fmt(sb, "cy_int(%lld)", e->as.int_val);
            return;
        case EX_STRING:
            sb_append_str(sb, "cy_string(");
            append_c_string_literal(sb, e->as.str_val);
            sb_append_char(sb, ')');
            return;
        case EX_BOOL:
            sb_append_fmt(sb, "cy_bool(%d)", e->as.bool_val ? 1 : 0);
            return;
        case EX_NULL:
            sb_append_str(sb, "cy_null()");
            return;
        case EX_IDENT: {
            const char *var_name = scope_lookup(ctx, e->as.ident);
            if (var_name) {
                sb_append_str(sb, var_name);
                return;
            }
            if (strset_contains(ctx->fn_names, e->as.ident)) {
                sb_append_str(sb, "cy_fn(");
                append_c_string_literal(sb, e->as.ident);
                sb_append_char(sb, ')');
                return;
            }
            fail_at(e->line, e->col, "undefined identifier");
            return;
        }
        case EX_ARRAY:
            sb_append_str(sb, "cy_array_make(");
            if (e->as.array.count == 0) {
                sb_append_str(sb, "0, NULL");
            } else {
                sb_append_fmt(sb, "%d, (CyValue[]){", e->as.array.count);
                for (int i = 0; i < e->as.array.count; i++) {
                    if (i != 0) sb_append_str(sb, ", ");
                    gen_expr(e->as.array.items[i], sb, ctx);
                }
                sb_append_char(sb, '}');
            }
            sb_append_char(sb, ')');
            return;
        case EX_ARRAY_COMP:
            gen_array_comp_expr(e, sb, ctx);
            return;
        case EX_OBJECT:
            sb_append_str(sb, "cy_object_literal(");
            if (e->as.object.count == 0) {
                sb_append_str(sb, "0, NULL, NULL");
            } else {
                sb_append_fmt(sb, "%d, (const char*[]){", e->as.object.count);
                for (int i = 0; i < e->as.object.count; i++) {
                    if (i != 0) sb_append_str(sb, ", ");
                    append_c_string_literal(sb, e->as.object.keys[i]);
                }
                sb_append_str(sb, "}, (CyValue[]){");
                for (int i = 0; i < e->as.object.count; i++) {
                    if (i != 0) sb_append_str(sb, ", ");
                    gen_expr(e->as.object.values[i], sb, ctx);
                }
                sb_append_char(sb, '}');
            }
            sb_append_char(sb, ')');
            return;
        case EX_INDEX:
            sb_append_str(sb, "cy_array_get(");
            gen_expr(e->as.index.left, sb, ctx);
            sb_append_str(sb, ", ");
            gen_expr(e->as.index.index, sb, ctx);
            sb_append_char(sb, ')');
            return;
        case EX_DOT:
            sb_append_str(sb, "cy_object_get_member(");
            gen_expr(e->as.dot.left, sb, ctx);
            sb_append_str(sb, ", ");
            append_c_string_literal(sb, e->as.dot.member);
            sb_append_char(sb, ')');
            return;
        case EX_UNARY:
            if (e->as.unary.op == TOK_MINUS) {
                sb_append_str(sb, "cy_neg(");
                gen_expr(e->as.unary.right, sb, ctx);
                sb_append_char(sb, ')');
                return;
            }
            if (e->as.unary.op == TOK_BANG) {
                sb_append_str(sb, "cy_not(");
                gen_expr(e->as.unary.right, sb, ctx);
                sb_append_char(sb, ')');
                return;
            }
            fail_at(e->line, e->col, "unsupported unary operator");
            return;
        case EX_BINARY:
            if (e->as.binary.op == TOK_ANDAND) {
                sb_append_str(sb, "cy_bool(cy_truthy(");
                gen_expr(e->as.binary.left, sb, ctx);
                sb_append_str(sb, ") && cy_truthy(");
                gen_expr(e->as.binary.right, sb, ctx);
                sb_append_str(sb, "))");
                return;
            }
            if (e->as.binary.op == TOK_OROR) {
                sb_append_str(sb, "cy_bool(cy_truthy(");
                gen_expr(e->as.binary.left, sb, ctx);
                sb_append_str(sb, ") || cy_truthy(");
                gen_expr(e->as.binary.right, sb, ctx);
                sb_append_str(sb, "))");
                return;
            }
            if (e->as.binary.op == TOK_COALESCE) {
                sb_append_str(sb, "cy_coalesce(");
                gen_expr(e->as.binary.left, sb, ctx);
                sb_append_str(sb, ", ");
                gen_expr(e->as.binary.right, sb, ctx);
                sb_append_char(sb, ')');
                return;
            }
            switch (e->as.binary.op) {
                case TOK_PLUS:
                    sb_append_str(sb, "cy_add(");
                    break;
                case TOK_MINUS:
                    sb_append_str(sb, "cy_sub(");
                    break;
                case TOK_STAR:
                    sb_append_str(sb, "cy_mul(");
                    break;
                case TOK_SLASH:
                    sb_append_str(sb, "cy_div(");
                    break;
                case TOK_PERCENT:
                    sb_append_str(sb, "cy_mod(");
                    break;
                case TOK_EQ:
                    sb_append_str(sb, "cy_eq(");
                    break;
                case TOK_NEQ:
                    sb_append_str(sb, "cy_neq(");
                    break;
                case TOK_LT:
                    sb_append_str(sb, "cy_lt(");
                    break;
                case TOK_GT:
                    sb_append_str(sb, "cy_gt(");
                    break;
                case TOK_LE:
                    sb_append_str(sb, "cy_le(");
                    break;
                case TOK_GE:
                    sb_append_str(sb, "cy_ge(");
                    break;
                default:
                    fail_at(e->line, e->col, "unsupported binary operator");
                    return;
            }
            gen_expr(e->as.binary.left, sb, ctx);
            sb_append_str(sb, ", ");
            gen_expr(e->as.binary.right, sb, ctx);
            sb_append_char(sb, ')');
            return;
        case EX_CALL:
            gen_call_expr(e, sb, ctx);
            return;
    }

    fail_at(e->line, e->col, "unknown expression kind");
}

static void emit_stmt(FILE *out, Stmt *s, GenCtx *ctx, int indent, int top_level, int in_function);

static void emit_block(FILE *out, Block *block, GenCtx *ctx, int indent, int top_level, int in_function) {
    scope_push(ctx);
    for (int i = 0; i < block->count; i++) {
        emit_stmt(out, block->items[i], ctx, indent, top_level, in_function);
    }
    scope_pop(ctx);
}

static void emit_scope_bindings_to_object(FILE *out, Scope *scope, const char *obj_c_name, int indent) {
    for (int i = 0; i < scope->count; i++) {
        StrBuf key_lit;
        sb_init(&key_lit);
        append_c_string_literal(&key_lit, scope->items[i].cy_name);
        emit_indent(out, indent);
        fprintf(out, "cy_object_set_raw(%s, %s, %s);\n", obj_c_name, key_lit.buf, scope->items[i].c_name);
        free(key_lit.buf);
    }
}

static void emit_stmt(FILE *out, Stmt *s, GenCtx *ctx, int indent, int top_level, int in_function) {
    StrBuf expr;
    char *tmp = NULL;

    switch (s->kind) {
        case ST_LET:
            sb_init(&expr);
            gen_expr(s->as.let_stmt.value, &expr, ctx);
            tmp = make_temp_name(ctx, s->as.let_stmt.name);
            scope_add(ctx, s->as.let_stmt.name, tmp);
            emit_indent(out, indent);
            fprintf(out, "CyValue %s = %s;\n", tmp, expr.buf);
            emit_indent(out, indent);
            fprintf(out, "(void)%s;\n", tmp);
            free(tmp);
            free(expr.buf);
            return;

        case ST_ASSIGN: {
            const char *target = scope_lookup(ctx, s->as.assign_stmt.name);
            if (!target) fail_at(s->line, s->col, "assignment to undefined variable");
            sb_init(&expr);
            gen_expr(s->as.assign_stmt.value, &expr, ctx);
            emit_indent(out, indent);
            fprintf(out, "%s = %s;\n", target, expr.buf);
            free(expr.buf);
            return;
        }

        case ST_SET_MEMBER: {
            StrBuf obj_expr;
            StrBuf val_expr;
            sb_init(&obj_expr);
            sb_init(&val_expr);
            gen_expr(s->as.set_member_stmt.object, &obj_expr, ctx);
            gen_expr(s->as.set_member_stmt.value, &val_expr, ctx);

            char *obj_tmp = make_temp_name(ctx, "obj");
            char *val_tmp = make_temp_name(ctx, "val");
            StrBuf key_lit;
            sb_init(&key_lit);
            append_c_string_literal(&key_lit, s->as.set_member_stmt.member);

            emit_indent(out, indent);
            fprintf(out, "CyValue %s = %s;\n", obj_tmp, obj_expr.buf);
            emit_indent(out, indent);
            fprintf(out, "CyValue %s = %s;\n", val_tmp, val_expr.buf);
            emit_indent(out, indent);
            fprintf(out, "if (%s.type != CY_OBJECT) cy_runtime_error(\"member assignment expects object\");\n", obj_tmp);
            emit_indent(out, indent);
            fprintf(out, "cy_object_set_raw(%s.as.object_val, %s, %s);\n", obj_tmp, key_lit.buf, val_tmp);

            free(obj_tmp);
            free(val_tmp);
            free(obj_expr.buf);
            free(val_expr.buf);
            free(key_lit.buf);
            return;
        }

        case ST_SET_INDEX: {
            StrBuf base_expr;
            StrBuf idx_expr;
            StrBuf val_expr;
            sb_init(&base_expr);
            sb_init(&idx_expr);
            sb_init(&val_expr);
            gen_expr(s->as.set_index_stmt.object, &base_expr, ctx);
            gen_expr(s->as.set_index_stmt.index, &idx_expr, ctx);
            gen_expr(s->as.set_index_stmt.value, &val_expr, ctx);

            char *base_tmp = make_temp_name(ctx, "base");
            char *idx_tmp = make_temp_name(ctx, "idx");
            char *val_tmp = make_temp_name(ctx, "val");

            emit_indent(out, indent);
            fprintf(out, "CyValue %s = %s;\n", base_tmp, base_expr.buf);
            emit_indent(out, indent);
            fprintf(out, "CyValue %s = %s;\n", idx_tmp, idx_expr.buf);
            emit_indent(out, indent);
            fprintf(out, "CyValue %s = %s;\n", val_tmp, val_expr.buf);
            emit_indent(out, indent);
            fprintf(out, "if (%s.type == CY_ARRAY) {\n", base_tmp);
            emit_indent(out, indent + 1);
            fprintf(out, "long long __cy_index = cy_expect_int(%s, \"array index assignment\");\n", idx_tmp);
            emit_indent(out, indent + 1);
            fprintf(out, "if (__cy_index < 0 || __cy_index >= %s.as.array_val->count) ", base_tmp);
            fprintf(out, "cy_runtime_error(\"array assignment index out of range\");\n");
            emit_indent(out, indent + 1);
            fprintf(out, "%s.as.array_val->items[__cy_index] = %s;\n", base_tmp, val_tmp);
            emit_indent(out, indent);
            fprintf(out, "} else if (%s.type == CY_OBJECT && %s.type == CY_STRING) {\n", base_tmp, idx_tmp);
            emit_indent(out, indent + 1);
            fprintf(out, "cy_object_set_raw(%s.as.object_val, %s.as.str_val, %s);\n", base_tmp, idx_tmp, val_tmp);
            emit_indent(out, indent);
            fprintf(out, "} else {\n");
            emit_indent(out, indent + 1);
            fprintf(out, "cy_runtime_error(\"index assignment expects array[int] or object[string]\");\n");
            emit_indent(out, indent);
            fprintf(out, "}\n");

            free(base_tmp);
            free(idx_tmp);
            free(val_tmp);
            free(base_expr.buf);
            free(idx_expr.buf);
            free(val_expr.buf);
            return;
        }

        case ST_EXPR:
            sb_init(&expr);
            gen_expr(s->as.expr_stmt.expr, &expr, ctx);
            tmp = make_temp_name(ctx, "expr");
            emit_indent(out, indent);
            fprintf(out, "CyValue %s = %s;\n", tmp, expr.buf);
            if (top_level) {
                emit_indent(out, indent);
                fprintf(out, "if (%s.type != CY_NULL) {\n", tmp);
                emit_indent(out, indent + 1);
                fprintf(out, "cy_builtin_print(1, (CyValue[]){%s});\n", tmp);
                emit_indent(out, indent);
                fprintf(out, "}\n");
            } else {
                emit_indent(out, indent);
                fprintf(out, "(void)%s;\n", tmp);
            }
            free(tmp);
            free(expr.buf);
            return;

        case ST_IF:
            sb_init(&expr);
            gen_expr(s->as.if_stmt.cond, &expr, ctx);
            emit_indent(out, indent);
            fprintf(out, "if (cy_truthy(%s)) {\n", expr.buf);
            emit_block(out, s->as.if_stmt.then_block, ctx, indent + 1, 0, in_function);
            emit_indent(out, indent);
            fprintf(out, "}");
            if (s->as.if_stmt.else_block) {
                fprintf(out, " else {\n");
                emit_block(out, s->as.if_stmt.else_block, ctx, indent + 1, 0, in_function);
                emit_indent(out, indent);
                fprintf(out, "}");
            }
            fprintf(out, "\n");
            free(expr.buf);
            return;

        case ST_SWITCH: {
            sb_init(&expr);
            gen_expr(s->as.switch_stmt.value, &expr, ctx);
            char *sw_tmp = make_temp_name(ctx, "switch_value");
            char *matched_tmp = make_temp_name(ctx, "switch_matched");
            emit_indent(out, indent);
            fprintf(out, "CyValue %s = %s;\n", sw_tmp, expr.buf);
            emit_indent(out, indent);
            fprintf(out, "int %s = 0;\n", matched_tmp);
            free(expr.buf);

            for (int i = 0; i < s->as.switch_stmt.case_count; i++) {
                StrBuf case_expr;
                sb_init(&case_expr);
                gen_expr(s->as.switch_stmt.case_values[i], &case_expr, ctx);
                emit_indent(out, indent);
                fprintf(out, "if (!%s && cy_value_equal(%s, %s)) {\n", matched_tmp, sw_tmp, case_expr.buf);
                emit_indent(out, indent + 1);
                fprintf(out, "%s = 1;\n", matched_tmp);
                emit_block(out, s->as.switch_stmt.case_blocks[i], ctx, indent + 1, 0, in_function);
                emit_indent(out, indent);
                fprintf(out, "}\n");
                free(case_expr.buf);
            }

            if (s->as.switch_stmt.default_block) {
                emit_indent(out, indent);
                fprintf(out, "if (!%s) {\n", matched_tmp);
                emit_block(out, s->as.switch_stmt.default_block, ctx, indent + 1, 0, in_function);
                emit_indent(out, indent);
                fprintf(out, "}\n");
            }

            free(sw_tmp);
            free(matched_tmp);
            return;
        }

        case ST_WHILE: {
            emit_indent(out, indent);
            fprintf(out, "while (1) {\n");
            sb_init(&expr);
            gen_expr(s->as.while_stmt.cond, &expr, ctx);
            emit_indent(out, indent + 1);
            fprintf(out, "if (!cy_truthy(%s)) break;\n", expr.buf);
            free(expr.buf);

            int prev_depth = ctx->loop_depth;
            ctx->loop_depth++;
            emit_block(out, s->as.while_stmt.body, ctx, indent + 1, 0, in_function);
            ctx->loop_depth = prev_depth;

            emit_indent(out, indent);
            fprintf(out, "}\n");
            return;
        }

        case ST_FOR: {
            sb_init(&expr);
            gen_expr(s->as.for_stmt.iter_expr, &expr, ctx);
            char *iter_tmp = make_temp_name(ctx, "iter");
            char *idx_tmp = make_temp_name(ctx, "i");
            char *item_tmp = NULL;
            char *index_tmp = NULL;
            emit_indent(out, indent);
            fprintf(out, "CyValue %s = %s;\n", iter_tmp, expr.buf);
            free(expr.buf);

            emit_indent(out, indent);
            fprintf(out, "if (%s.type == CY_ARRAY) {\n", iter_tmp);
            emit_indent(out, indent + 1);
            fprintf(out, "for (int %s = 0; %s < %s.as.array_val->count; %s++) {\n", idx_tmp, idx_tmp, iter_tmp, idx_tmp);

            scope_push(ctx);
            if (s->as.for_stmt.iter_value_name) {
                index_tmp = make_temp_name(ctx, s->as.for_stmt.iter_name);
                item_tmp = make_temp_name(ctx, s->as.for_stmt.iter_value_name);
                scope_add(ctx, s->as.for_stmt.iter_name, index_tmp);
                scope_add(ctx, s->as.for_stmt.iter_value_name, item_tmp);
                emit_indent(out, indent + 2);
                fprintf(out, "CyValue %s = cy_int(%s);\n", index_tmp, idx_tmp);
                emit_indent(out, indent + 2);
                fprintf(out, "(void)%s;\n", index_tmp);
                emit_indent(out, indent + 2);
                fprintf(out, "CyValue %s = %s.as.array_val->items[%s];\n", item_tmp, iter_tmp, idx_tmp);
                emit_indent(out, indent + 2);
                fprintf(out, "(void)%s;\n", item_tmp);
            } else {
                item_tmp = make_temp_name(ctx, s->as.for_stmt.iter_name);
                scope_add(ctx, s->as.for_stmt.iter_name, item_tmp);
                emit_indent(out, indent + 2);
                fprintf(out, "CyValue %s = %s.as.array_val->items[%s];\n", item_tmp, iter_tmp, idx_tmp);
                emit_indent(out, indent + 2);
                fprintf(out, "(void)%s;\n", item_tmp);
            }
            int prev_depth = ctx->loop_depth;
            ctx->loop_depth++;
            emit_block(out, s->as.for_stmt.body, ctx, indent + 2, 0, in_function);
            ctx->loop_depth = prev_depth;
            scope_pop(ctx);
            free(index_tmp);
            free(item_tmp);
            index_tmp = NULL;
            item_tmp = NULL;

            emit_indent(out, indent + 1);
            fprintf(out, "}\n");
            emit_indent(out, indent);
            fprintf(out, "} else if (%s.type == CY_OBJECT) {\n", iter_tmp);
            emit_indent(out, indent + 1);
            fprintf(out, "for (int %s = 0; %s < %s.as.object_val->count; %s++) {\n", idx_tmp, idx_tmp, iter_tmp, idx_tmp);

            scope_push(ctx);
            item_tmp = make_temp_name(ctx, s->as.for_stmt.iter_name);
            scope_add(ctx, s->as.for_stmt.iter_name, item_tmp);
            emit_indent(out, indent + 2);
            fprintf(out, "CyValue %s = cy_string(%s.as.object_val->items[%s].key);\n", item_tmp, iter_tmp, idx_tmp);
            emit_indent(out, indent + 2);
            fprintf(out, "(void)%s;\n", item_tmp);
            if (s->as.for_stmt.iter_value_name) {
                index_tmp = make_temp_name(ctx, s->as.for_stmt.iter_value_name);
                scope_add(ctx, s->as.for_stmt.iter_value_name, index_tmp);
                emit_indent(out, indent + 2);
                fprintf(out, "CyValue %s = %s.as.object_val->items[%s].value;\n", index_tmp, iter_tmp, idx_tmp);
                emit_indent(out, indent + 2);
                fprintf(out, "(void)%s;\n", index_tmp);
            }
            prev_depth = ctx->loop_depth;
            ctx->loop_depth++;
            emit_block(out, s->as.for_stmt.body, ctx, indent + 2, 0, in_function);
            ctx->loop_depth = prev_depth;
            scope_pop(ctx);
            free(index_tmp);
            free(item_tmp);
            index_tmp = NULL;
            item_tmp = NULL;

            emit_indent(out, indent + 1);
            fprintf(out, "}\n");
            emit_indent(out, indent);
            fprintf(out, "} else {\n");
            emit_indent(out, indent + 1);
            fprintf(out, "cy_runtime_error(\"for loop expects array or object iterable\");\n");
            emit_indent(out, indent);
            fprintf(out, "}\n");

            free(iter_tmp);
            free(idx_tmp);
            return;
        }

        case ST_BREAK:
            if (ctx->loop_depth <= 0) fail_at(s->line, s->col, "break is only allowed inside loops");
            emit_indent(out, indent);
            fprintf(out, "break;\n");
            return;

        case ST_CONTINUE:
            if (ctx->loop_depth <= 0) fail_at(s->line, s->col, "continue is only allowed inside loops");
            emit_indent(out, indent);
            fprintf(out, "continue;\n");
            return;

        case ST_CLASS: {
            char *obj_tmp = make_temp_name(ctx, "class_obj");
            StrBuf name_lit;
            sb_init(&name_lit);
            append_c_string_literal(&name_lit, s->as.class_stmt.name);
            emit_indent(out, indent);
            fprintf(out, "CyObject *%s = cy_object_alloc_kind(CY_OBJ_CLASS);\n", obj_tmp);
            emit_indent(out, indent);
            fprintf(out, "cy_object_set_raw(%s, \"__name__\", cy_string(%s));\n", obj_tmp, name_lit.buf);

            scope_push(ctx);
            for (int i = 0; i < s->as.class_stmt.body->count; i++) {
                emit_stmt(out, s->as.class_stmt.body->items[i], ctx, indent, 0, 0);
            }
            emit_scope_bindings_to_object(out, ctx->scope, obj_tmp, indent);
            scope_pop(ctx);

            tmp = make_temp_name(ctx, s->as.class_stmt.name);
            scope_add(ctx, s->as.class_stmt.name, tmp);
            emit_indent(out, indent);
            fprintf(out, "CyValue %s = cy_object_value(%s);\n", tmp, obj_tmp);
            emit_indent(out, indent);
            fprintf(out, "(void)%s;\n", tmp);

            free(name_lit.buf);
            free(obj_tmp);
            free(tmp);
            return;
        }

        case ST_MODULE: {
            char *obj_tmp = make_temp_name(ctx, "module_obj");
            emit_indent(out, indent);
            fprintf(out, "CyObject *%s = cy_object_alloc_kind(CY_OBJ_MODULE);\n", obj_tmp);

            scope_push(ctx);
            for (int i = 0; i < s->as.module_stmt.body->count; i++) {
                emit_stmt(out, s->as.module_stmt.body->items[i], ctx, indent, 0, 0);
            }
            emit_scope_bindings_to_object(out, ctx->scope, obj_tmp, indent);
            scope_pop(ctx);

            tmp = make_temp_name(ctx, s->as.module_stmt.name);
            scope_add(ctx, s->as.module_stmt.name, tmp);
            emit_indent(out, indent);
            fprintf(out, "CyValue %s = cy_object_value(%s);\n", tmp, obj_tmp);
            emit_indent(out, indent);
            fprintf(out, "(void)%s;\n", tmp);

            free(obj_tmp);
            free(tmp);
            return;
        }

        case ST_TYPE:
            sb_init(&expr);
            gen_expr(s->as.type_stmt.value, &expr, ctx);
            tmp = make_temp_name(ctx, s->as.type_stmt.name);
            scope_add(ctx, s->as.type_stmt.name, tmp);
            emit_indent(out, indent);
            fprintf(out, "CyValue %s = %s;\n", tmp, expr.buf);
            emit_indent(out, indent);
            fprintf(out, "(void)%s;\n", tmp);
            free(tmp);
            free(expr.buf);
            return;

        case ST_TRY: {
            char *try_tmp = make_temp_name(ctx, "try");
            emit_indent(out, indent);
            fprintf(out, "{\n");
            emit_indent(out, indent + 1);
            fprintf(out, "CyTryFrame %s;\n", try_tmp);
            emit_indent(out, indent + 1);
            fprintf(out, "cy_try_link(&%s);\n", try_tmp);
            emit_indent(out, indent + 1);
            fprintf(out, "if (setjmp(%s.env) == 0) {\n", try_tmp);
            emit_block(out, s->as.try_stmt.try_block, ctx, indent + 2, 0, in_function);
            emit_indent(out, indent + 2);
            fprintf(out, "cy_try_unlink(&%s);\n", try_tmp);
            emit_indent(out, indent + 1);
            fprintf(out, "} else {\n");
            emit_indent(out, indent + 2);
            fprintf(out, "cy_try_unlink(&%s);\n", try_tmp);

            scope_push(ctx);
            char *catch_tmp = make_temp_name(ctx, s->as.try_stmt.catch_name);
            scope_add(ctx, s->as.try_stmt.catch_name, catch_tmp);
            emit_indent(out, indent + 2);
            fprintf(out, "CyValue %s = cy_exception_current();\n", catch_tmp);
            emit_block(out, s->as.try_stmt.catch_block, ctx, indent + 2, 0, in_function);
            free(catch_tmp);
            scope_pop(ctx);

            emit_indent(out, indent + 1);
            fprintf(out, "}\n");
            emit_indent(out, indent);
            fprintf(out, "}\n");
            free(try_tmp);
            return;
        }

        case ST_RETURN:
            if (!in_function) fail_at(s->line, s->col, "return is only allowed inside functions");
            sb_init(&expr);
            gen_expr(s->as.return_stmt.value, &expr, ctx);
            emit_indent(out, indent);
            fprintf(out, "return %s;\n", expr.buf);
            free(expr.buf);
            return;

        case ST_THROW:
            sb_init(&expr);
            gen_expr(s->as.throw_stmt.value, &expr, ctx);
            emit_indent(out, indent);
            fprintf(out, "cy_throw(%s);\n", expr.buf);
            free(expr.buf);
            return;

        case ST_FN:
            if (in_function) fail_at(s->line, s->col, "nested function declarations are not supported");
            tmp = make_temp_name(ctx, s->as.fn_stmt.name);
            scope_add(ctx, s->as.fn_stmt.name, tmp);
            emit_indent(out, indent);
            fprintf(out, "CyValue %s = cy_fn(\"%s\");\n", tmp, s->as.fn_stmt.name);
            emit_indent(out, indent);
            fprintf(out, "(void)%s;\n", tmp);
            free(tmp);
            return;

        case ST_IMPORT:
            fail_at(s->line, s->col, "unexpected import after import resolution");
            return;
    }
}

static void collect_function_names_stmt(Stmt *s, StrSet *fn_names);

static void collect_function_names_block(Block *block, StrSet *fn_names) {
    for (int i = 0; i < block->count; i++) {
        collect_function_names_stmt(block->items[i], fn_names);
    }
}

static void collect_function_names_stmt(Stmt *s, StrSet *fn_names) {
    switch (s->kind) {
        case ST_FN:
            if (!strset_add(fn_names, s->as.fn_stmt.name)) {
                fail_at(s->line, s->col, "duplicate function declaration");
            }
            return;
        case ST_IF:
            collect_function_names_block(s->as.if_stmt.then_block, fn_names);
            if (s->as.if_stmt.else_block) collect_function_names_block(s->as.if_stmt.else_block, fn_names);
            return;
        case ST_SWITCH:
            for (int i = 0; i < s->as.switch_stmt.case_count; i++) {
                collect_function_names_block(s->as.switch_stmt.case_blocks[i], fn_names);
            }
            if (s->as.switch_stmt.default_block) collect_function_names_block(s->as.switch_stmt.default_block, fn_names);
            return;
        case ST_WHILE:
            collect_function_names_block(s->as.while_stmt.body, fn_names);
            return;
        case ST_FOR:
            collect_function_names_block(s->as.for_stmt.body, fn_names);
            return;
        case ST_TRY:
            collect_function_names_block(s->as.try_stmt.try_block, fn_names);
            collect_function_names_block(s->as.try_stmt.catch_block, fn_names);
            return;
        case ST_CLASS:
            collect_function_names_block(s->as.class_stmt.body, fn_names);
            return;
        case ST_MODULE:
            collect_function_names_block(s->as.module_stmt.body, fn_names);
            return;
        case ST_LET:
        case ST_ASSIGN:
        case ST_SET_MEMBER:
        case ST_SET_INDEX:
        case ST_EXPR:
        case ST_BREAK:
        case ST_CONTINUE:
        case ST_TYPE:
        case ST_RETURN:
        case ST_THROW:
        case ST_IMPORT:
            return;
    }
}

static void collect_function_names(Block *program, StrSet *fn_names) {
    collect_function_names_block(program, fn_names);
}

static void emit_generated_runtime(FILE *out) {
    fputs("#if defined(_MSC_VER) && !defined(_CRT_SECURE_NO_WARNINGS)\n", out);
    fputs("#define _CRT_SECURE_NO_WARNINGS\n", out);
    fputs("#endif\n\n", out);
    fputs("#if defined(__GNUC__) || defined(__clang__)\n", out);
    fputs("#pragma GCC diagnostic push\n", out);
    fputs("#pragma GCC diagnostic ignored \"-Wunused-function\"\n", out);
    fputs("#endif\n\n", out);
    fputs("#include <setjmp.h>\n", out);
    fputs("#include <stdio.h>\n", out);
    fputs("#include <stdlib.h>\n", out);
    fputs("#include <string.h>\n\n", out);
    fprintf(out, "#define NYX_LANG_VERSION \"%s\"\n\n", NYX_LANG_VERSION);

    fputs("typedef enum { CY_NULL = 0, CY_INT, CY_BOOL, CY_STRING, CY_ARRAY, CY_OBJECT, CY_FNREF, CY_BOUND_FN } CyType;\n", out);
    fputs("typedef enum { CY_OBJ_PLAIN = 0, CY_OBJ_MODULE, CY_OBJ_CLASS, CY_OBJ_INSTANCE } CyObjectKind;\n", out);
    fputs("typedef struct CyValue CyValue;\n", out);
    fputs("typedef struct CyArray CyArray;\n", out);
    fputs("typedef struct CyObject CyObject;\n", out);
    fputs("typedef struct CyObjectEntry CyObjectEntry;\n\n", out);
    fputs("typedef struct CyTryFrame CyTryFrame;\n\n", out);

    fputs("struct CyValue {\n", out);
    fputs("    CyType type;\n", out);
    fputs("    union {\n", out);
    fputs("        long long int_val;\n", out);
    fputs("        int bool_val;\n", out);
    fputs("        char *str_val;\n", out);
    fputs("        CyArray *array_val;\n", out);
    fputs("        CyObject *object_val;\n", out);
    fputs("        const char *fn_name;\n", out);
    fputs("        struct {\n", out);
    fputs("            CyObject *self_obj;\n", out);
    fputs("            const char *fn_name;\n", out);
    fputs("        } bound_fn;\n", out);
    fputs("    } as;\n", out);
    fputs("};\n\n", out);

    fputs("struct CyArray {\n", out);
    fputs("    CyValue *items;\n", out);
    fputs("    int count;\n", out);
    fputs("    int cap;\n", out);
    fputs("};\n\n", out);

    fputs("struct CyObjectEntry {\n", out);
    fputs("    char *key;\n", out);
    fputs("    CyValue value;\n", out);
    fputs("};\n\n", out);

    fputs("struct CyObject {\n", out);
    fputs("    CyObjectEntry *items;\n", out);
    fputs("    int count;\n", out);
    fputs("    int cap;\n", out);
    fputs("    CyObjectKind kind;\n", out);
    fputs("};\n\n", out);

    fputs("struct CyTryFrame {\n", out);
    fputs("    jmp_buf env;\n", out);
    fputs("    CyTryFrame *prev;\n", out);
    fputs("};\n\n", out);

    fputs("static int cy_argc = 0;\n", out);
    fputs("static char **cy_argv = NULL;\n\n", out);
    fputs("static CyTryFrame *cy_try_top = NULL;\n", out);
    fputs("static CyValue cy_exception_value;\n\n", out);

    fputs("static CyValue cy_call_user(const char *name, int argc, CyValue *argv);\n", out);
    fputs("static CyValue cy_call_value(CyValue callee, int argc, CyValue *argv);\n\n", out);
    fputs("static CyValue cy_eval_comp(int comp_id, CyValue __cy_env);\n\n", out);

    fputs("static void cy_runtime_error(const char *msg) {\n", out);
    fputs("    fprintf(stderr, \"Runtime error: %s\\n\", msg);\n", out);
    fputs("    exit(1);\n", out);
    fputs("}\n\n", out);

    fputs("static void cy_try_link(CyTryFrame *frame) {\n", out);
    fputs("    frame->prev = cy_try_top;\n", out);
    fputs("    cy_try_top = frame;\n", out);
    fputs("}\n\n", out);

    fputs("static void cy_try_unlink(CyTryFrame *frame) {\n", out);
    fputs("    if (cy_try_top == frame) {\n", out);
    fputs("        cy_try_top = frame->prev;\n", out);
    fputs("    }\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_exception_current(void) {\n", out);
    fputs("    return cy_exception_value;\n", out);
    fputs("}\n\n", out);

    fputs("static void cy_throw(CyValue value) {\n", out);
    fputs("    if (!cy_try_top) cy_runtime_error(\"uncaught exception\");\n", out);
    fputs("    cy_exception_value = value;\n", out);
    fputs("    longjmp(cy_try_top->env, 1);\n", out);
    fputs("}\n\n", out);

    fputs("static void *cy_xmalloc(size_t n) {\n", out);
    fputs("    void *p = malloc(n);\n", out);
    fputs("    if (!p) cy_runtime_error(\"out of memory\");\n", out);
    fputs("    return p;\n", out);
    fputs("}\n\n", out);

    fputs("static void *cy_xrealloc(void *p, size_t n) {\n", out);
    fputs("    void *q = realloc(p, n);\n", out);
    fputs("    if (!q) cy_runtime_error(\"out of memory\");\n", out);
    fputs("    return q;\n", out);
    fputs("}\n\n", out);

    fputs("static char *cy_strdup(const char *s) {\n", out);
    fputs("    size_t n = strlen(s) + 1;\n", out);
    fputs("    char *d = (char *)cy_xmalloc(n);\n", out);
    fputs("    memcpy(d, s, n);\n", out);
    fputs("    return d;\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_null(void) {\n", out);
    fputs("    CyValue v;\n", out);
    fputs("    v.type = CY_NULL;\n", out);
    fputs("    return v;\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_int(long long n) {\n", out);
    fputs("    CyValue v;\n", out);
    fputs("    v.type = CY_INT;\n", out);
    fputs("    v.as.int_val = n;\n", out);
    fputs("    return v;\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_bool(int b) {\n", out);
    fputs("    CyValue v;\n", out);
    fputs("    v.type = CY_BOOL;\n", out);
    fputs("    v.as.bool_val = b ? 1 : 0;\n", out);
    fputs("    return v;\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_string(const char *s) {\n", out);
    fputs("    CyValue v;\n", out);
    fputs("    v.type = CY_STRING;\n", out);
    fputs("    v.as.str_val = cy_strdup(s);\n", out);
    fputs("    return v;\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_fn(const char *name) {\n", out);
    fputs("    CyValue v;\n", out);
    fputs("    v.type = CY_FNREF;\n", out);
    fputs("    v.as.fn_name = name;\n", out);
    fputs("    return v;\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_bound_fn(CyValue self, const char *name) {\n", out);
    fputs("    if (self.type != CY_OBJECT) cy_runtime_error(\"bound method receiver must be object\");\n", out);
    fputs("    CyValue v;\n", out);
    fputs("    v.type = CY_BOUND_FN;\n", out);
    fputs("    v.as.bound_fn.self_obj = self.as.object_val;\n", out);
    fputs("    v.as.bound_fn.fn_name = name;\n", out);
    fputs("    return v;\n", out);
    fputs("}\n\n", out);

    fputs("static const char *cy_callable_name(CyValue v) {\n", out);
    fputs("    if (v.type == CY_FNREF) return v.as.fn_name;\n", out);
    fputs("    if (v.type == CY_BOUND_FN) return v.as.bound_fn.fn_name;\n", out);
    fputs("    return NULL;\n", out);
    fputs("}\n\n", out);

    fputs("static int cy_truthy(CyValue v) {\n", out);
    fputs("    switch (v.type) {\n", out);
    fputs("        case CY_NULL: return 0;\n", out);
    fputs("        case CY_BOOL: return v.as.bool_val != 0;\n", out);
    fputs("        case CY_INT: return v.as.int_val != 0;\n", out);
    fputs("        case CY_STRING: return v.as.str_val[0] != '\\0';\n", out);
    fputs("        case CY_ARRAY: return v.as.array_val->count != 0;\n", out);
    fputs("        case CY_OBJECT: return 1;\n", out);
    fputs("        case CY_FNREF: return 1;\n", out);
    fputs("        case CY_BOUND_FN: return 1;\n", out);
    fputs("    }\n", out);
    fputs("    return 0;\n", out);
    fputs("}\n\n", out);

    fputs("static const char *cy_type_name(CyValue v) {\n", out);
    fputs("    switch (v.type) {\n", out);
    fputs("        case CY_NULL: return \"null\";\n", out);
    fputs("        case CY_INT: return \"int\";\n", out);
    fputs("        case CY_BOOL: return \"bool\";\n", out);
    fputs("        case CY_STRING: return \"string\";\n", out);
    fputs("        case CY_ARRAY: return \"array\";\n", out);
    fputs("        case CY_OBJECT: return \"object\";\n", out);
    fputs("        case CY_FNREF: return \"function\";\n", out);
    fputs("        case CY_BOUND_FN: return \"function\";\n", out);
    fputs("    }\n", out);
    fputs("    return \"unknown\";\n", out);
    fputs("}\n\n", out);

    fputs("static long long cy_expect_int(CyValue v, const char *ctx) {\n", out);
    fputs("    if (v.type != CY_INT) {\n", out);
    fputs("        char buf[256];\n", out);
    fputs("        snprintf(buf, sizeof(buf), \"%s expects integer\", ctx);\n", out);
    fputs("        cy_runtime_error(buf);\n", out);
    fputs("    }\n", out);
    fputs("    return v.as.int_val;\n", out);
    fputs("}\n\n", out);

    fputs("static CyArray *cy_array_alloc(void) {\n", out);
    fputs("    CyArray *arr = (CyArray *)cy_xmalloc(sizeof(CyArray));\n", out);
    fputs("    arr->items = NULL;\n", out);
    fputs("    arr->count = 0;\n", out);
    fputs("    arr->cap = 0;\n", out);
    fputs("    return arr;\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_array_value(CyArray *arr) {\n", out);
    fputs("    CyValue v;\n", out);
    fputs("    v.type = CY_ARRAY;\n", out);
    fputs("    v.as.array_val = arr;\n", out);
    fputs("    return v;\n", out);
    fputs("}\n\n", out);

    fputs("static void cy_array_push_raw(CyArray *arr, CyValue value) {\n", out);
    fputs("    if (arr->count == arr->cap) {\n", out);
    fputs("        int next = arr->cap == 0 ? 8 : arr->cap * 2;\n", out);
    fputs("        arr->items = (CyValue *)cy_xrealloc(arr->items, (size_t)next * sizeof(CyValue));\n", out);
    fputs("        arr->cap = next;\n", out);
    fputs("    }\n", out);
    fputs("    arr->items[arr->count++] = value;\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_array_make(int argc, CyValue *items) {\n", out);
    fputs("    CyArray *arr = cy_array_alloc();\n", out);
    fputs("    for (int i = 0; i < argc; i++) cy_array_push_raw(arr, items[i]);\n", out);
    fputs("    return cy_array_value(arr);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_object_get_raw(CyObject *obj, const char *key);\n\n", out);

    fputs("static CyValue cy_array_get(CyValue base_value, CyValue index_value) {\n", out);
    fputs("    if (base_value.type == CY_ARRAY) {\n", out);
    fputs("        long long idx = cy_expect_int(index_value, \"array index\");\n", out);
    fputs("        if (idx < 0 || idx >= base_value.as.array_val->count) return cy_null();\n", out);
    fputs("        return base_value.as.array_val->items[idx];\n", out);
    fputs("    }\n", out);
    fputs("    if (base_value.type == CY_OBJECT && index_value.type == CY_STRING) {\n", out);
    fputs("        return cy_object_get_raw(base_value.as.object_val, index_value.as.str_val);\n", out);
    fputs("    }\n", out);
    fputs("    cy_runtime_error(\"indexing expects array[int] or object[string]\");\n", out);
    fputs("    return cy_null();\n", out);
    fputs("}\n\n", out);

    fputs("static CyObject *cy_object_alloc_kind(CyObjectKind kind) {\n", out);
    fputs("    CyObject *obj = (CyObject *)cy_xmalloc(sizeof(CyObject));\n", out);
    fputs("    obj->items = NULL;\n", out);
    fputs("    obj->count = 0;\n", out);
    fputs("    obj->cap = 0;\n", out);
    fputs("    obj->kind = kind;\n", out);
    fputs("    return obj;\n", out);
    fputs("}\n\n", out);

    fputs("static CyObject *cy_object_alloc(void) { return cy_object_alloc_kind(CY_OBJ_PLAIN); }\n\n", out);

    fputs("static CyValue cy_object_value(CyObject *obj) {\n", out);
    fputs("    CyValue v;\n", out);
    fputs("    v.type = CY_OBJECT;\n", out);
    fputs("    v.as.object_val = obj;\n", out);
    fputs("    return v;\n", out);
    fputs("}\n\n", out);

    fputs("static int cy_object_find_index(CyObject *obj, const char *key) {\n", out);
    fputs("    for (int i = 0; i < obj->count; i++) {\n", out);
    fputs("        if (strcmp(obj->items[i].key, key) == 0) return i;\n", out);
    fputs("    }\n", out);
    fputs("    return -1;\n", out);
    fputs("}\n\n", out);

    fputs("static void cy_object_set_raw(CyObject *obj, const char *key, CyValue value) {\n", out);
    fputs("    int idx = cy_object_find_index(obj, key);\n", out);
    fputs("    if (idx >= 0) {\n", out);
    fputs("        obj->items[idx].value = value;\n", out);
    fputs("        return;\n", out);
    fputs("    }\n", out);
    fputs("    if (obj->count == obj->cap) {\n", out);
    fputs("        int next = obj->cap == 0 ? 8 : obj->cap * 2;\n", out);
    fputs("        obj->items = (CyObjectEntry *)cy_xrealloc(obj->items, (size_t)next * sizeof(CyObjectEntry));\n", out);
    fputs("        obj->cap = next;\n", out);
    fputs("    }\n", out);
    fputs("    obj->items[obj->count].key = cy_strdup(key);\n", out);
    fputs("    obj->items[obj->count].value = value;\n", out);
    fputs("    obj->count++;\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_object_get_raw(CyObject *obj, const char *key) {\n", out);
    fputs("    int idx = cy_object_find_index(obj, key);\n", out);
    fputs("    if (idx < 0) return cy_null();\n", out);
    fputs("    return obj->items[idx].value;\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_object_literal(int count, const char **keys, CyValue *values) {\n", out);
    fputs("    CyObject *obj = cy_object_alloc();\n", out);
    fputs("    for (int i = 0; i < count; i++) {\n", out);
    fputs("        cy_object_set_raw(obj, keys[i], values[i]);\n", out);
    fputs("    }\n", out);
    fputs("    return cy_object_value(obj);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_object_get_member(CyValue object_value, const char *key) {\n", out);
    fputs("    if (object_value.type != CY_OBJECT) cy_runtime_error(\"member access expects object value\");\n", out);
    fputs("    CyObject *obj = object_value.as.object_val;\n", out);
    fputs("    CyValue value = cy_object_get_raw(obj, key);\n", out);
    fputs("    if (value.type != CY_NULL) {\n", out);
    fputs("        if ((obj->kind == CY_OBJ_PLAIN || obj->kind == CY_OBJ_INSTANCE) &&\n", out);
    fputs("            (value.type == CY_FNREF || value.type == CY_BOUND_FN)) {\n", out);
    fputs("            return cy_bound_fn(object_value, cy_callable_name(value));\n", out);
    fputs("        }\n", out);
    fputs("        return value;\n", out);
    fputs("    }\n", out);
    fputs("    if (obj->kind == CY_OBJ_INSTANCE) {\n", out);
    fputs("        CyValue cls = cy_object_get_raw(obj, \"__class__\");\n", out);
    fputs("        if (cls.type == CY_OBJECT) {\n", out);
    fputs("            CyValue mv = cy_object_get_raw(cls.as.object_val, key);\n", out);
    fputs("            if (mv.type == CY_FNREF || mv.type == CY_BOUND_FN) return cy_bound_fn(object_value, cy_callable_name(mv));\n", out);
    fputs("            return mv;\n", out);
    fputs("        }\n", out);
    fputs("    }\n", out);
    fputs("    return cy_null();\n", out);
    fputs("}\n\n", out);

    fputs("static int cy_value_equal(CyValue a, CyValue b) {\n", out);
    fputs("    if (a.type != b.type) return 0;\n", out);
    fputs("    switch (a.type) {\n", out);
    fputs("        case CY_NULL: return 1;\n", out);
    fputs("        case CY_INT: return a.as.int_val == b.as.int_val;\n", out);
    fputs("        case CY_BOOL: return a.as.bool_val == b.as.bool_val;\n", out);
    fputs("        case CY_STRING: return strcmp(a.as.str_val, b.as.str_val) == 0;\n", out);
    fputs("        case CY_ARRAY: return a.as.array_val == b.as.array_val;\n", out);
    fputs("        case CY_OBJECT: return a.as.object_val == b.as.object_val;\n", out);
    fputs("        case CY_FNREF: return strcmp(a.as.fn_name, b.as.fn_name) == 0;\n", out);
    fputs("        case CY_BOUND_FN:\n", out);
    fputs("            return a.as.bound_fn.self_obj == b.as.bound_fn.self_obj &&\n", out);
    fputs("                   strcmp(a.as.bound_fn.fn_name, b.as.bound_fn.fn_name) == 0;\n", out);
    fputs("    }\n", out);
    fputs("    return 0;\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_add(CyValue a, CyValue b) {\n", out);
    fputs("    if (a.type == CY_INT && b.type == CY_INT) return cy_int(a.as.int_val + b.as.int_val);\n", out);
    fputs("    if (a.type == CY_STRING && b.type == CY_STRING) {\n", out);
    fputs("        size_t na = strlen(a.as.str_val);\n", out);
    fputs("        size_t nb = strlen(b.as.str_val);\n", out);
    fputs("        char *joined = (char *)cy_xmalloc(na + nb + 1);\n", out);
    fputs("        memcpy(joined, a.as.str_val, na);\n", out);
    fputs("        memcpy(joined + na, b.as.str_val, nb + 1);\n", out);
    fputs("        CyValue v;\n", out);
    fputs("        v.type = CY_STRING;\n", out);
    fputs("        v.as.str_val = joined;\n", out);
    fputs("        return v;\n", out);
    fputs("    }\n", out);
    fputs("    cy_runtime_error(\"'+' expects int+int or string+string\");\n", out);
    fputs("    return cy_null();\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_sub(CyValue a, CyValue b) { return cy_int(cy_expect_int(a, \"'-'\") - cy_expect_int(b, \"'-'\")); }\n", out);
    fputs("static CyValue cy_mul(CyValue a, CyValue b) { return cy_int(cy_expect_int(a, \"'*'\") * cy_expect_int(b, \"'*'\")); }\n", out);
    fputs("static CyValue cy_div(CyValue a, CyValue b) {\n", out);
    fputs("    long long lhs = cy_expect_int(a, \"'/'\");\n", out);
    fputs("    long long rhs = cy_expect_int(b, \"'/'\");\n", out);
    fputs("    if (rhs == 0) cy_runtime_error(\"division by zero\");\n", out);
    fputs("    return cy_int(lhs / rhs);\n", out);
    fputs("}\n\n", out);
    fputs("static CyValue cy_mod(CyValue a, CyValue b) {\n", out);
    fputs("    long long lhs = cy_expect_int(a, \"'%'\");\n", out);
    fputs("    long long rhs = cy_expect_int(b, \"'%'\");\n", out);
    fputs("    if (rhs == 0) cy_runtime_error(\"division by zero\");\n", out);
    fputs("    return cy_int(lhs % rhs);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_neg(CyValue v) { return cy_int(-cy_expect_int(v, \"unary '-'\")); }\n", out);
    fputs("static CyValue cy_not(CyValue v) { return cy_bool(!cy_truthy(v)); }\n", out);
    fputs("static CyValue cy_eq(CyValue a, CyValue b) { return cy_bool(cy_value_equal(a, b)); }\n", out);
    fputs("static CyValue cy_neq(CyValue a, CyValue b) { return cy_bool(!cy_value_equal(a, b)); }\n", out);
    fputs("static CyValue cy_lt(CyValue a, CyValue b) { return cy_bool(cy_expect_int(a, \"'<'\") < cy_expect_int(b, \"'<'\")); }\n", out);
    fputs("static CyValue cy_gt(CyValue a, CyValue b) { return cy_bool(cy_expect_int(a, \"'>'\") > cy_expect_int(b, \"'>'\")); }\n", out);
    fputs("static CyValue cy_le(CyValue a, CyValue b) { return cy_bool(cy_expect_int(a, \"'<='\") <= cy_expect_int(b, \"'<='\")); }\n", out);
    fputs("static CyValue cy_ge(CyValue a, CyValue b) { return cy_bool(cy_expect_int(a, \"'>='\") >= cy_expect_int(b, \"'>='\")); }\n", out);
    fputs("static CyValue cy_coalesce(CyValue a, CyValue b) { return a.type != CY_NULL ? a : b; }\n\n", out);

    fputs("static void cy_print_value(CyValue v);\n", out);

    fputs("static void cy_print_array(CyArray *arr) {\n", out);
    fputs("    putchar('[');\n", out);
    fputs("    for (int i = 0; i < arr->count; i++) {\n", out);
    fputs("        if (i != 0) printf(\", \" );\n", out);
    fputs("        cy_print_value(arr->items[i]);\n", out);
    fputs("    }\n", out);
    fputs("    putchar(']');\n", out);
    fputs("}\n\n", out);

    fputs("static void cy_print_object(CyObject *obj) {\n", out);
    fputs("    putchar('{');\n", out);
    fputs("    for (int i = 0; i < obj->count; i++) {\n", out);
    fputs("        if (i != 0) printf(\", \" );\n", out);
    fputs("        printf(\"%s: \", obj->items[i].key);\n", out);
    fputs("        cy_print_value(obj->items[i].value);\n", out);
    fputs("    }\n", out);
    fputs("    putchar('}');\n", out);
    fputs("}\n\n", out);

    fputs("static void cy_print_value(CyValue v) {\n", out);
    fputs("    switch (v.type) {\n", out);
    fputs("        case CY_NULL: printf(\"null\"); return;\n", out);
    fputs("        case CY_INT: printf(\"%lld\", v.as.int_val); return;\n", out);
    fputs("        case CY_BOOL: printf(v.as.bool_val ? \"true\" : \"false\"); return;\n", out);
    fputs("        case CY_STRING: printf(\"%s\", v.as.str_val); return;\n", out);
    fputs("        case CY_ARRAY: cy_print_array(v.as.array_val); return;\n", out);
    fputs("        case CY_OBJECT: cy_print_object(v.as.object_val); return;\n", out);
    fputs("        case CY_FNREF: printf(\"<fn:%s>\", v.as.fn_name); return;\n", out);
    fputs("        case CY_BOUND_FN: printf(\"<bound-fn:%s>\", v.as.bound_fn.fn_name); return;\n", out);
    fputs("    }\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_print(int argc, CyValue *args) {\n", out);
    fputs("    for (int i = 0; i < argc; i++) {\n", out);
    fputs("        if (i != 0) putchar(' ');\n", out);
    fputs("        cy_print_value(args[i]);\n", out);
    fputs("    }\n", out);
    fputs("    putchar('\\n');\n", out);
    fputs("    return cy_null();\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_len(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"len() expects exactly 1 argument\");\n", out);
    fputs("    if (args[0].type == CY_STRING) return cy_int((long long)strlen(args[0].as.str_val));\n", out);
    fputs("    if (args[0].type == CY_ARRAY) return cy_int(args[0].as.array_val->count);\n", out);
    fputs("    if (args[0].type == CY_OBJECT) return cy_int(args[0].as.object_val->count);\n", out);
    fputs("    cy_runtime_error(\"len() supports only string, array, and object\");\n", out);
    fputs("    return cy_null();\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_abs(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"abs() expects exactly 1 argument\");\n", out);
    fputs("    return cy_int(llabs(cy_expect_int(args[0], \"abs\")));\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_min(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 2) cy_runtime_error(\"min() expects exactly 2 arguments\");\n", out);
    fputs("    long long a = cy_expect_int(args[0], \"min\");\n", out);
    fputs("    long long b = cy_expect_int(args[1], \"min\");\n", out);
    fputs("    return cy_int(a < b ? a : b);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_max(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 2) cy_runtime_error(\"max() expects exactly 2 arguments\");\n", out);
    fputs("    long long a = cy_expect_int(args[0], \"max\");\n", out);
    fputs("    long long b = cy_expect_int(args[1], \"max\");\n", out);
    fputs("    return cy_int(a > b ? a : b);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_clamp(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 3) cy_runtime_error(\"clamp() expects exactly 3 arguments\");\n", out);
    fputs("    long long v = cy_expect_int(args[0], \"clamp\");\n", out);
    fputs("    long long lo = cy_expect_int(args[1], \"clamp\");\n", out);
    fputs("    long long hi = cy_expect_int(args[2], \"clamp\");\n", out);
    fputs("    if (v < lo) return cy_int(lo);\n", out);
    fputs("    if (v > hi) return cy_int(hi);\n", out);
    fputs("    return cy_int(v);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_sum(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"sum() expects exactly 1 argument\");\n", out);
    fputs("    if (args[0].type != CY_ARRAY) cy_runtime_error(\"sum() expects array argument\");\n", out);
    fputs("    long long acc = 0;\n", out);
    fputs("    CyArray *arr = args[0].as.array_val;\n", out);
    fputs("    for (int i = 0; i < arr->count; i++) acc += cy_expect_int(arr->items[i], \"sum item\");\n", out);
    fputs("    return cy_int(acc);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_all(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"all() expects exactly 1 argument\");\n", out);
    fputs("    if (args[0].type != CY_ARRAY) cy_runtime_error(\"all() expects array argument\");\n", out);
    fputs("    CyArray *arr = args[0].as.array_val;\n", out);
    fputs("    for (int i = 0; i < arr->count; i++) {\n", out);
    fputs("        if (!cy_truthy(arr->items[i])) return cy_bool(0);\n", out);
    fputs("    }\n", out);
    fputs("    return cy_bool(1);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_any(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"any() expects exactly 1 argument\");\n", out);
    fputs("    if (args[0].type != CY_ARRAY) cy_runtime_error(\"any() expects array argument\");\n", out);
    fputs("    CyArray *arr = args[0].as.array_val;\n", out);
    fputs("    for (int i = 0; i < arr->count; i++) {\n", out);
    fputs("        if (cy_truthy(arr->items[i])) return cy_bool(1);\n", out);
    fputs("    }\n", out);
    fputs("    return cy_bool(0);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_range(int argc, CyValue *args) {\n", out);
    fputs("    if (argc < 1 || argc > 3) cy_runtime_error(\"range() expects 1 to 3 integer arguments\");\n", out);
    fputs("    long long start = 0;\n", out);
    fputs("    long long stop = 0;\n", out);
    fputs("    long long step = 1;\n", out);
    fputs("    if (argc == 1) {\n", out);
    fputs("        stop = cy_expect_int(args[0], \"range\");\n", out);
    fputs("    } else if (argc == 2) {\n", out);
    fputs("        start = cy_expect_int(args[0], \"range\");\n", out);
    fputs("        stop = cy_expect_int(args[1], \"range\");\n", out);
    fputs("    } else {\n", out);
    fputs("        start = cy_expect_int(args[0], \"range\");\n", out);
    fputs("        stop = cy_expect_int(args[1], \"range\");\n", out);
    fputs("        step = cy_expect_int(args[2], \"range\");\n", out);
    fputs("        if (step == 0) cy_runtime_error(\"range() step must not be zero\");\n", out);
    fputs("    }\n", out);
    fputs("    CyArray *arr = cy_array_alloc();\n", out);
    fputs("    if (step > 0) {\n", out);
    fputs("        for (long long i = start; i < stop; i += step) cy_array_push_raw(arr, cy_int(i));\n", out);
    fputs("    } else {\n", out);
    fputs("        for (long long i = start; i > stop; i += step) cy_array_push_raw(arr, cy_int(i));\n", out);
    fputs("    }\n", out);
    fputs("    return cy_array_value(arr);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_read(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"read() expects exactly 1 argument\");\n", out);
    fputs("    if (args[0].type != CY_STRING) cy_runtime_error(\"read() path must be string\");\n", out);
    fputs("    const char *path = args[0].as.str_val;\n", out);
    fputs("    FILE *f = fopen(path, \"rb\");\n", out);
    fputs("    if (!f) cy_runtime_error(\"read() could not open file\");\n", out);
    fputs("    if (fseek(f, 0, SEEK_END) != 0) {\n", out);
    fputs("        fclose(f);\n", out);
    fputs("        cy_runtime_error(\"read() failed\");\n", out);
    fputs("    }\n", out);
    fputs("    long sz = ftell(f);\n", out);
    fputs("    if (sz < 0) {\n", out);
    fputs("        fclose(f);\n", out);
    fputs("        cy_runtime_error(\"read() failed\");\n", out);
    fputs("    }\n", out);
    fputs("    rewind(f);\n", out);
    fputs("    char *buf = (char *)cy_xmalloc((size_t)sz + 1);\n", out);
    fputs("    size_t n = fread(buf, 1, (size_t)sz, f);\n", out);
    fputs("    fclose(f);\n", out);
    fputs("    buf[n] = '\\0';\n", out);
    fputs("    CyValue outv = cy_string(buf);\n", out);
    fputs("    free(buf);\n", out);
    fputs("    return outv;\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_write(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 2) cy_runtime_error(\"write() expects exactly 2 arguments\");\n", out);
    fputs("    if (args[0].type != CY_STRING) cy_runtime_error(\"write() path must be string\");\n", out);
    fputs("    const char *path = args[0].as.str_val;\n", out);
    fputs("    const char *data = NULL;\n", out);
    fputs("    char num_buf[64];\n", out);
    fputs("    if (args[1].type == CY_STRING) {\n", out);
    fputs("        data = args[1].as.str_val;\n", out);
    fputs("    } else if (args[1].type == CY_INT) {\n", out);
    fputs("        snprintf(num_buf, sizeof(num_buf), \"%lld\", args[1].as.int_val);\n", out);
    fputs("        data = num_buf;\n", out);
    fputs("    } else if (args[1].type == CY_BOOL) {\n", out);
    fputs("        data = args[1].as.bool_val ? \"true\" : \"false\";\n", out);
    fputs("    } else if (args[1].type == CY_NULL) {\n", out);
    fputs("        data = \"null\";\n", out);
    fputs("    } else {\n", out);
    fputs("        cy_runtime_error(\"write() supports string/int/bool/null payloads\");\n", out);
    fputs("    }\n", out);
    fputs("    FILE *f = fopen(path, \"wb\");\n", out);
    fputs("    if (!f) cy_runtime_error(\"write() could not open file\");\n", out);
    fputs("    size_t n = fwrite(data, 1, strlen(data), f);\n", out);
    fputs("    fclose(f);\n", out);
    fputs("    return cy_int((long long)n);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_type(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"type() expects exactly 1 argument\");\n", out);
    fputs("    return cy_string(cy_type_name(args[0]));\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_is_int(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"is_int() expects exactly 1 argument\");\n", out);
    fputs("    return cy_bool(args[0].type == CY_INT);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_is_bool(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"is_bool() expects exactly 1 argument\");\n", out);
    fputs("    return cy_bool(args[0].type == CY_BOOL);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_is_string(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"is_string() expects exactly 1 argument\");\n", out);
    fputs("    return cy_bool(args[0].type == CY_STRING);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_is_array(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"is_array() expects exactly 1 argument\");\n", out);
    fputs("    return cy_bool(args[0].type == CY_ARRAY);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_is_function(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"is_function() expects exactly 1 argument\");\n", out);
    fputs("    return cy_bool(args[0].type == CY_FNREF || args[0].type == CY_BOUND_FN);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_is_null(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"is_null() expects exactly 1 argument\");\n", out);
    fputs("    return cy_bool(args[0].type == CY_NULL);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_str(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"str() expects exactly 1 argument\");\n", out);
    fputs("    char buf[64];\n", out);
    fputs("    switch (args[0].type) {\n", out);
    fputs("        case CY_STRING: return cy_string(args[0].as.str_val);\n", out);
    fputs("        case CY_INT:\n", out);
    fputs("            snprintf(buf, sizeof(buf), \"%lld\", args[0].as.int_val);\n", out);
    fputs("            return cy_string(buf);\n", out);
    fputs("        case CY_BOOL: return cy_string(args[0].as.bool_val ? \"true\" : \"false\");\n", out);
    fputs("        case CY_NULL: return cy_string(\"null\");\n", out);
    fputs("        case CY_ARRAY: return cy_string(\"[array]\");\n", out);
    fputs("        case CY_OBJECT: return cy_string(\"[object]\");\n", out);
    fputs("        case CY_FNREF: return cy_string(\"<fn>\");\n", out);
    fputs("        case CY_BOUND_FN: return cy_string(\"<bound-fn>\");\n", out);
    fputs("    }\n", out);
    fputs("    return cy_string(\"\");\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_int(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"int() expects exactly 1 argument\");\n", out);
    fputs("    if (args[0].type == CY_INT) return args[0];\n", out);
    fputs("    if (args[0].type == CY_BOOL) return cy_int(args[0].as.bool_val ? 1 : 0);\n", out);
    fputs("    if (args[0].type == CY_STRING) {\n", out);
    fputs("        char *endp = NULL;\n", out);
    fputs("        long long v = strtoll(args[0].as.str_val, &endp, 10);\n", out);
    fputs("        if (endp == args[0].as.str_val || *endp != '\\0') cy_runtime_error(\"int() invalid string integer\");\n", out);
    fputs("        return cy_int(v);\n", out);
    fputs("    }\n", out);
    fputs("    cy_runtime_error(\"int() expects int, bool, or string\");\n", out);
    fputs("    return cy_null();\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_push(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 2) cy_runtime_error(\"push() expects exactly 2 arguments\");\n", out);
    fputs("    if (args[0].type != CY_ARRAY) cy_runtime_error(\"push() first argument must be an array\");\n", out);
    fputs("    cy_array_push_raw(args[0].as.array_val, args[1]);\n", out);
    fputs("    return args[0];\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_pop(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"pop() expects exactly 1 argument\");\n", out);
    fputs("    if (args[0].type != CY_ARRAY) cy_runtime_error(\"pop() argument must be an array\");\n", out);
    fputs("    CyArray *arr = args[0].as.array_val;\n", out);
    fputs("    if (arr->count == 0) return cy_null();\n", out);
    fputs("    CyValue outv = arr->items[arr->count - 1];\n", out);
    fputs("    arr->count--;\n", out);
    fputs("    return outv;\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_argc(int argc, CyValue *args) {\n", out);
    fputs("    (void)args;\n", out);
    fputs("    if (argc != 0) cy_runtime_error(\"argc() expects 0 arguments\");\n", out);
    fputs("    return cy_int(cy_argc);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_argv(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"argv() expects exactly 1 argument\");\n", out);
    fputs("    long long idx = cy_expect_int(args[0], \"argv index\");\n", out);
    fputs("    if (idx < 0 || idx >= cy_argc) return cy_null();\n", out);
    fputs("    return cy_string(cy_argv[idx]);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_object_new(int argc, CyValue *args) {\n", out);
    fputs("    (void)args;\n", out);
    fputs("    if (argc != 0) cy_runtime_error(\"object_new() expects 0 arguments\");\n", out);
    fputs("    return cy_object_value(cy_object_alloc());\n", out);
    fputs("}\n\n", out);

    fputs("static CyObject *cy_expect_object(CyValue value, const char *ctx) {\n", out);
    fputs("    if (value.type != CY_OBJECT) {\n", out);
    fputs("        char buf[256];\n", out);
    fputs("        snprintf(buf, sizeof(buf), \"%s expects object\", ctx);\n", out);
    fputs("        cy_runtime_error(buf);\n", out);
    fputs("    }\n", out);
    fputs("    return value.as.object_val;\n", out);
    fputs("}\n\n", out);

    fputs("static const char *cy_expect_string(CyValue value, const char *ctx) {\n", out);
    fputs("    if (value.type != CY_STRING) {\n", out);
    fputs("        char buf[256];\n", out);
    fputs("        snprintf(buf, sizeof(buf), \"%s expects string\", ctx);\n", out);
    fputs("        cy_runtime_error(buf);\n", out);
    fputs("    }\n", out);
    fputs("    return value.as.str_val;\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_object_set(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 3) cy_runtime_error(\"object_set() expects 3 arguments\");\n", out);
    fputs("    CyObject *obj = cy_expect_object(args[0], \"object_set\");\n", out);
    fputs("    const char *key = cy_expect_string(args[1], \"object_set\");\n", out);
    fputs("    cy_object_set_raw(obj, key, args[2]);\n", out);
    fputs("    return args[0];\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_object_get(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 2) cy_runtime_error(\"object_get() expects 2 arguments\");\n", out);
    fputs("    CyObject *obj = cy_expect_object(args[0], \"object_get\");\n", out);
    fputs("    const char *key = cy_expect_string(args[1], \"object_get\");\n", out);
    fputs("    return cy_object_get_raw(obj, key);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_keys(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"keys() expects exactly 1 argument\");\n", out);
    fputs("    CyObject *obj = cy_expect_object(args[0], \"keys\");\n", out);
    fputs("    CyArray *arr = cy_array_alloc();\n", out);
    fputs("    for (int i = 0; i < obj->count; i++) {\n", out);
    fputs("        cy_array_push_raw(arr, cy_string(obj->items[i].key));\n", out);
    fputs("    }\n", out);
    fputs("    return cy_array_value(arr);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_values(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"values() expects exactly 1 argument\");\n", out);
    fputs("    CyObject *obj = cy_expect_object(args[0], \"values\");\n", out);
    fputs("    CyArray *arr = cy_array_alloc();\n", out);
    fputs("    for (int i = 0; i < obj->count; i++) {\n", out);
    fputs("        cy_array_push_raw(arr, obj->items[i].value);\n", out);
    fputs("    }\n", out);
    fputs("    return cy_array_value(arr);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_items(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"items() expects exactly 1 argument\");\n", out);
    fputs("    CyObject *obj = cy_expect_object(args[0], \"items\");\n", out);
    fputs("    CyArray *arr = cy_array_alloc();\n", out);
    fputs("    for (int i = 0; i < obj->count; i++) {\n", out);
    fputs("        CyValue pair = cy_array_make(2, (CyValue[]){cy_string(obj->items[i].key), obj->items[i].value});\n", out);
    fputs("        cy_array_push_raw(arr, pair);\n", out);
    fputs("    }\n", out);
    fputs("    return cy_array_value(arr);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_has(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 2) cy_runtime_error(\"has() expects exactly 2 arguments\");\n", out);
    fputs("    CyObject *obj = cy_expect_object(args[0], \"has\");\n", out);
    fputs("    const char *key = cy_expect_string(args[1], \"has\");\n", out);
    fputs("    return cy_bool(cy_object_find_index(obj, key) >= 0);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_lang_version(int argc, CyValue *args) {\n", out);
    fputs("    (void)args;\n", out);
    fputs("    if (argc != 0) cy_runtime_error(\"lang_version() expects 0 arguments\");\n", out);
    fputs("    return cy_string(NYX_LANG_VERSION);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_require_version(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"require_version() expects 1 argument\");\n", out);
    fputs("    const char *v = cy_expect_string(args[0], \"require_version\");\n", out);
    fputs("    if (strcmp(v, NYX_LANG_VERSION) != 0) cy_runtime_error(\"language version mismatch\");\n", out);
    fputs("    return cy_null();\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_new(int argc, CyValue *args) {\n", out);
    fputs("    if (argc < 1) cy_runtime_error(\"new() expects at least 1 argument\");\n", out);
    fputs("    CyObject *cls = cy_expect_object(args[0], \"new\");\n", out);
    fputs("    if (cls->kind != CY_OBJ_CLASS) cy_runtime_error(\"new() first argument must be a class object\");\n", out);
    fputs("    CyValue inst = cy_object_value(cy_object_alloc_kind(CY_OBJ_INSTANCE));\n", out);
    fputs("    cy_object_set_raw(inst.as.object_val, \"__class__\", args[0]);\n", out);
    fputs("    CyValue init = cy_object_get_raw(cls, \"init\");\n", out);
    fputs("    if (init.type == CY_FNREF || init.type == CY_BOUND_FN) {\n", out);
    fputs("        CyValue *call_args = (CyValue *)cy_xmalloc((size_t)argc * sizeof(CyValue));\n", out);
    fputs("        call_args[0] = inst;\n", out);
    fputs("        for (int i = 1; i < argc; i++) call_args[i] = args[i];\n", out);
    fputs("        (void)cy_call_value(init, argc, call_args);\n", out);
    fputs("    }\n", out);
    fputs("    return inst;\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_class_new(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"class_new() expects 1 argument\");\n", out);
    fputs("    const char *name = cy_expect_string(args[0], \"class_new\");\n", out);
    fputs("    CyObject *cls = cy_object_alloc_kind(CY_OBJ_CLASS);\n", out);
    fputs("    cy_object_set_raw(cls, \"__name__\", cy_string(name));\n", out);
    fputs("    cy_object_set_raw(cls, \"__ctor__\", cy_null());\n", out);
    fputs("    return cy_object_value(cls);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_class_with_ctor(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 2) cy_runtime_error(\"class_with_ctor() expects 2 arguments\");\n", out);
    fputs("    CyValue cls = cy_builtin_class_new(1, args);\n", out);
    fputs("    cy_object_set_raw(cls.as.object_val, \"__ctor__\", args[1]);\n", out);
    fputs("    return cls;\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_class_set_method(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 3) cy_runtime_error(\"class_set_method() expects 3 arguments\");\n", out);
    fputs("    CyObject *cls = cy_expect_object(args[0], \"class_set_method\");\n", out);
    fputs("    const char *name = cy_expect_string(args[1], \"class_set_method\");\n", out);
    fputs("    cy_object_set_raw(cls, name, args[2]);\n", out);
    fputs("    return args[0];\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_class_name(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"class_name() expects 1 argument\");\n", out);
    fputs("    CyObject *cls = cy_expect_object(args[0], \"class_name\");\n", out);
    fputs("    return cy_object_get_raw(cls, \"__name__\");\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_class_instantiate(CyValue cls_value, int argc, CyValue *ctor_args) {\n", out);
    fputs("    CyObject *cls = cy_expect_object(cls_value, \"class_instantiate\");\n", out);
    fputs("    CyValue inst = cy_object_value(cy_object_alloc_kind(CY_OBJ_INSTANCE));\n", out);
    fputs("    cy_object_set_raw(inst.as.object_val, \"__class__\", cls_value);\n", out);
    fputs("    CyValue ctor = cy_object_get_raw(cls, \"__ctor__\");\n", out);
    fputs("    if (ctor.type == CY_FNREF || ctor.type == CY_BOUND_FN) {\n", out);
    fputs("        CyValue *call_args = (CyValue *)cy_xmalloc((size_t)(argc + 1) * sizeof(CyValue));\n", out);
    fputs("        call_args[0] = inst;\n", out);
    fputs("        for (int i = 0; i < argc; i++) call_args[i + 1] = ctor_args[i];\n", out);
    fputs("        (void)cy_call_value(ctor, argc + 1, call_args);\n", out);
    fputs("    }\n", out);
    fputs("    return inst;\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_class_instantiate0(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 1) cy_runtime_error(\"class_instantiate0() expects 1 argument\");\n", out);
    fputs("    return cy_class_instantiate(args[0], 0, NULL);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_class_instantiate1(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 2) cy_runtime_error(\"class_instantiate1() expects 2 arguments\");\n", out);
    fputs("    return cy_class_instantiate(args[0], 1, args + 1);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_class_instantiate2(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 3) cy_runtime_error(\"class_instantiate2() expects 3 arguments\");\n", out);
    fputs("    return cy_class_instantiate(args[0], 2, args + 1);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_class_call(CyValue inst, const char *method_name, int argc, CyValue *args) {\n", out);
    fputs("    CyObject *obj = cy_expect_object(inst, \"class_call\");\n", out);
    fputs("    CyValue cls_value = cy_object_get_raw(obj, \"__class__\");\n", out);
    fputs("    CyObject *cls = cy_expect_object(cls_value, \"class_call\");\n", out);
    fputs("    CyValue method = cy_object_get_raw(cls, method_name);\n", out);
    fputs("    if (method.type != CY_FNREF) cy_runtime_error(\"class method is not callable\");\n", out);
    fputs("    CyValue *call_args = (CyValue *)cy_xmalloc((size_t)(argc + 1) * sizeof(CyValue));\n", out);
    fputs("    call_args[0] = inst;\n", out);
    fputs("    for (int i = 0; i < argc; i++) call_args[i + 1] = args[i];\n", out);
    fputs("    return cy_call_value(method, argc + 1, call_args);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_class_call0(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 2) cy_runtime_error(\"class_call0() expects 2 arguments\");\n", out);
    fputs("    const char *name = cy_expect_string(args[1], \"class_call0\");\n", out);
    fputs("    return cy_class_call(args[0], name, 0, NULL);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_class_call1(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 3) cy_runtime_error(\"class_call1() expects 3 arguments\");\n", out);
    fputs("    const char *name = cy_expect_string(args[1], \"class_call1\");\n", out);
    fputs("    return cy_class_call(args[0], name, 1, args + 2);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_builtin_class_call2(int argc, CyValue *args) {\n", out);
    fputs("    if (argc != 4) cy_runtime_error(\"class_call2() expects 4 arguments\");\n", out);
    fputs("    const char *name = cy_expect_string(args[1], \"class_call2\");\n", out);
    fputs("    return cy_class_call(args[0], name, 2, args + 2);\n", out);
    fputs("}\n\n", out);

    fputs("static CyValue cy_call_value(CyValue callee, int argc, CyValue *argv) {\n", out);
    fputs("    if (callee.type == CY_FNREF) {\n", out);
    fputs("        return cy_call_user(callee.as.fn_name, argc, argv);\n", out);
    fputs("    }\n", out);
    fputs("    if (callee.type == CY_BOUND_FN) {\n", out);
    fputs("        CyValue *full = (CyValue *)cy_xmalloc((size_t)(argc + 1) * sizeof(CyValue));\n", out);
    fputs("        CyValue self;\n", out);
    fputs("        self.type = CY_OBJECT;\n", out);
    fputs("        self.as.object_val = callee.as.bound_fn.self_obj;\n", out);
    fputs("        full[0] = self;\n", out);
    fputs("        for (int i = 0; i < argc; i++) full[i + 1] = argv[i];\n", out);
    fputs("        return cy_call_user(callee.as.bound_fn.fn_name, argc + 1, full);\n", out);
    fputs("    }\n", out);
    fputs("    cy_runtime_error(\"attempted to call non-function value\");\n", out);
    fputs("    return cy_null();\n", out);
    fputs("}\n\n", out);
}

static void emit_fn_prototypes_stmt(FILE *out, Stmt *s);

static void emit_fn_prototypes_block(FILE *out, Block *block) {
    for (int i = 0; i < block->count; i++) {
        emit_fn_prototypes_stmt(out, block->items[i]);
    }
}

static void emit_fn_prototypes_stmt(FILE *out, Stmt *s) {
    switch (s->kind) {
        case ST_FN:
            fprintf(out, "static CyValue fn_%s(int argc, CyValue *argv);\n", s->as.fn_stmt.name);
            return;
        case ST_IF:
            emit_fn_prototypes_block(out, s->as.if_stmt.then_block);
            if (s->as.if_stmt.else_block) emit_fn_prototypes_block(out, s->as.if_stmt.else_block);
            return;
        case ST_SWITCH:
            for (int i = 0; i < s->as.switch_stmt.case_count; i++) {
                emit_fn_prototypes_block(out, s->as.switch_stmt.case_blocks[i]);
            }
            if (s->as.switch_stmt.default_block) emit_fn_prototypes_block(out, s->as.switch_stmt.default_block);
            return;
        case ST_WHILE:
            emit_fn_prototypes_block(out, s->as.while_stmt.body);
            return;
        case ST_FOR:
            emit_fn_prototypes_block(out, s->as.for_stmt.body);
            return;
        case ST_TRY:
            emit_fn_prototypes_block(out, s->as.try_stmt.try_block);
            emit_fn_prototypes_block(out, s->as.try_stmt.catch_block);
            return;
        case ST_CLASS:
            emit_fn_prototypes_block(out, s->as.class_stmt.body);
            return;
        case ST_MODULE:
            emit_fn_prototypes_block(out, s->as.module_stmt.body);
            return;
        case ST_LET:
        case ST_ASSIGN:
        case ST_SET_MEMBER:
        case ST_SET_INDEX:
        case ST_EXPR:
        case ST_BREAK:
        case ST_CONTINUE:
        case ST_TYPE:
        case ST_RETURN:
        case ST_THROW:
        case ST_IMPORT:
            return;
    }
}

static void emit_fn_prototypes(FILE *out, Block *program) {
    emit_fn_prototypes_block(out, program);
    fputs("\n", out);
}

static void emit_fn_dispatch_cases_stmt(FILE *out, Stmt *s);

static void emit_fn_dispatch_cases_block(FILE *out, Block *block) {
    for (int i = 0; i < block->count; i++) {
        emit_fn_dispatch_cases_stmt(out, block->items[i]);
    }
}

static void emit_fn_dispatch_cases_stmt(FILE *out, Stmt *s) {
    switch (s->kind) {
        case ST_FN:
            fprintf(out, "    if (strcmp(name, \"%s\") == 0) return fn_%s(argc, argv);\n", s->as.fn_stmt.name,
                    s->as.fn_stmt.name);
            return;
        case ST_IF:
            emit_fn_dispatch_cases_block(out, s->as.if_stmt.then_block);
            if (s->as.if_stmt.else_block) emit_fn_dispatch_cases_block(out, s->as.if_stmt.else_block);
            return;
        case ST_SWITCH:
            for (int i = 0; i < s->as.switch_stmt.case_count; i++) {
                emit_fn_dispatch_cases_block(out, s->as.switch_stmt.case_blocks[i]);
            }
            if (s->as.switch_stmt.default_block) emit_fn_dispatch_cases_block(out, s->as.switch_stmt.default_block);
            return;
        case ST_WHILE:
            emit_fn_dispatch_cases_block(out, s->as.while_stmt.body);
            return;
        case ST_FOR:
            emit_fn_dispatch_cases_block(out, s->as.for_stmt.body);
            return;
        case ST_TRY:
            emit_fn_dispatch_cases_block(out, s->as.try_stmt.try_block);
            emit_fn_dispatch_cases_block(out, s->as.try_stmt.catch_block);
            return;
        case ST_CLASS:
            emit_fn_dispatch_cases_block(out, s->as.class_stmt.body);
            return;
        case ST_MODULE:
            emit_fn_dispatch_cases_block(out, s->as.module_stmt.body);
            return;
        case ST_LET:
        case ST_ASSIGN:
        case ST_SET_MEMBER:
        case ST_SET_INDEX:
        case ST_EXPR:
        case ST_BREAK:
        case ST_CONTINUE:
        case ST_TYPE:
        case ST_RETURN:
        case ST_THROW:
        case ST_IMPORT:
            return;
    }
}

static void emit_fn_dispatch(FILE *out, Block *program) {
    fputs("static CyValue cy_call_user(const char *name, int argc, CyValue *argv) {\n", out);
    fputs("    (void)name;\n", out);
    fputs("    (void)argc;\n", out);
    fputs("    (void)argv;\n", out);
    emit_fn_dispatch_cases_block(out, program);
    fputs("    cy_runtime_error(\"unknown function\");\n", out);
    fputs("    return cy_null();\n", out);
    fputs("}\n\n", out);
}

static void emit_fn_defs_stmt(FILE *out, Stmt *s, StrSet *fn_names, int *next_id, StrBuf *comp_cases);

static void emit_fn_defs_block(FILE *out, Block *block, StrSet *fn_names, int *next_id, StrBuf *comp_cases) {
    for (int i = 0; i < block->count; i++) {
        emit_fn_defs_stmt(out, block->items[i], fn_names, next_id, comp_cases);
    }
}

static void emit_fn_defs_stmt(FILE *out, Stmt *s, StrSet *fn_names, int *next_id, StrBuf *comp_cases) {
    switch (s->kind) {
        case ST_FN: {
            fprintf(out, "static CyValue fn_%s(int argc, CyValue *argv) {\n", s->as.fn_stmt.name);
            fprintf(out, "    if (argc != %d) cy_runtime_error(\"wrong number of function arguments\");\n",
                    s->as.fn_stmt.param_count);
            if (s->as.fn_stmt.param_count == 0) {
                fputs("    (void)argv;\n", out);
            }

            GenCtx ctx;
            ctx.scope = NULL;
            ctx.fn_names = fn_names;
            ctx.next_id = *next_id;
            ctx.loop_depth = 0;
            ctx.comp_cases = comp_cases;

            scope_push(&ctx);
            for (int p = 0; p < s->as.fn_stmt.param_count; p++) {
                char *cname = make_temp_name(&ctx, s->as.fn_stmt.params[p]);
                scope_add(&ctx, s->as.fn_stmt.params[p], cname);
                fprintf(out, "    CyValue %s = argv[%d];\n", cname, p);
                free(cname);
            }

            emit_block(out, s->as.fn_stmt.body, &ctx, 1, 0, 1);
            fputs("    return cy_null();\n", out);
            fputs("}\n\n", out);

            *next_id = ctx.next_id;
            return;
        }
        case ST_IF:
            emit_fn_defs_block(out, s->as.if_stmt.then_block, fn_names, next_id, comp_cases);
            if (s->as.if_stmt.else_block) emit_fn_defs_block(out, s->as.if_stmt.else_block, fn_names, next_id, comp_cases);
            return;
        case ST_SWITCH:
            for (int i = 0; i < s->as.switch_stmt.case_count; i++) {
                emit_fn_defs_block(out, s->as.switch_stmt.case_blocks[i], fn_names, next_id, comp_cases);
            }
            if (s->as.switch_stmt.default_block) {
                emit_fn_defs_block(out, s->as.switch_stmt.default_block, fn_names, next_id, comp_cases);
            }
            return;
        case ST_WHILE:
            emit_fn_defs_block(out, s->as.while_stmt.body, fn_names, next_id, comp_cases);
            return;
        case ST_FOR:
            emit_fn_defs_block(out, s->as.for_stmt.body, fn_names, next_id, comp_cases);
            return;
        case ST_TRY:
            emit_fn_defs_block(out, s->as.try_stmt.try_block, fn_names, next_id, comp_cases);
            emit_fn_defs_block(out, s->as.try_stmt.catch_block, fn_names, next_id, comp_cases);
            return;
        case ST_CLASS:
            emit_fn_defs_block(out, s->as.class_stmt.body, fn_names, next_id, comp_cases);
            return;
        case ST_MODULE:
            emit_fn_defs_block(out, s->as.module_stmt.body, fn_names, next_id, comp_cases);
            return;
        case ST_LET:
        case ST_ASSIGN:
        case ST_SET_MEMBER:
        case ST_SET_INDEX:
        case ST_EXPR:
        case ST_BREAK:
        case ST_CONTINUE:
        case ST_TYPE:
        case ST_RETURN:
        case ST_THROW:
        case ST_IMPORT:
            return;
    }
}

static void emit_fn_defs(FILE *out, Block *program, StrSet *fn_names, int *next_id, StrBuf *comp_cases) {
    emit_fn_defs_block(out, program, fn_names, next_id, comp_cases);
}

static void emit_comp_dispatch(FILE *out, StrBuf *comp_cases) {
    fputs("static CyValue cy_eval_comp(int comp_id, CyValue __cy_env) {\n", out);
    fputs("    (void)__cy_env;\n", out);
    fputs("    switch (comp_id) {\n", out);
    if (comp_cases && comp_cases->buf && comp_cases->len > 0) {
        fputs(comp_cases->buf, out);
    }
    fputs("        default:\n", out);
    fputs("            cy_runtime_error(\"internal error: unknown comprehension id\");\n", out);
    fputs("    }\n", out);
    fputs("    return cy_null();\n", out);
    fputs("}\n\n", out);
}

static int compile_file(const char *input_path, const char *output_path) {
    Block *program = new_block();
    StrSet visited;
    strset_init(&visited);
    load_program_recursive(input_path, program, &visited);

    StrSet fn_names;
    strset_init(&fn_names);
    collect_function_names(program, &fn_names);

    FILE *out = fopen(output_path, "wb");
    if (!out) {
        fprintf(stderr, "Error: could not open output file: %s\n", output_path);
        return 1;
    }

    emit_generated_runtime(out);
    emit_fn_prototypes(out, program);
    emit_fn_dispatch(out, program);

    int next_id = 1;
    StrBuf comp_cases;
    sb_init(&comp_cases);

    emit_fn_defs(out, program, &fn_names, &next_id, &comp_cases);

    fputs("int main(int argc, char **argv) {\n", out);
    fputs("    cy_argc = argc;\n", out);
    fputs("    cy_argv = argv;\n", out);

    GenCtx top;
    top.scope = NULL;
    top.fn_names = &fn_names;
    top.next_id = next_id;
    top.loop_depth = 0;
    top.comp_cases = &comp_cases;

    scope_push(&top);
    for (int i = 0; i < program->count; i++) {
        Stmt *s = program->items[i];
        if (s->kind == ST_FN) continue;
        emit_stmt(out, s, &top, 1, 1, 0);
    }
    scope_pop(&top);

    fputs("    return 0;\n", out);
    fputs("}\n", out);
    fputs("\n", out);

    emit_comp_dispatch(out, &comp_cases);

    fclose(out);
    free(comp_cases.buf);
    return 0;
}

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "Usage: v3_compiler <input.ny> <output.c> [--emit-self]\n");
        return 1;
    }

    if (argc >= 4 && strcmp(argv[3], "--emit-self") == 0) {
        return copy_file(__FILE__, argv[2]);
    }

    return compile_file(argv[1], argv[2]);
}
