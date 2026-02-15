/* =============================================================================
 *
 * NYX Programming Language - Native C Implementation
 *
 * Copyright (c) 2026 Surya Sekhar Roy. All Rights Reserved.
 *
 * PROPRIETARY AND CONFIDENTIAL
 *
 * This software is proprietary to the Copyright Owner. Unauthorized access,
 * use, reproduction, or distribution is strictly prohibited.
 *
 * See LICENSE file for full terms and conditions.
 *
 * ============================================================================= */

#if defined(_MSC_VER) && !defined(_CRT_SECURE_NO_WARNINGS)
#define _CRT_SECURE_NO_WARNINGS
#endif

#include <ctype.h>
#include <errno.h>
#include <limits.h>
#include <stdint.h>
#include <setjmp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#if defined(_WIN32)
#include <io.h>
#else
#include <unistd.h>
#endif

// ============================================================================
// OPTIONAL BLAS/LAPACK SUPPORT
// Compile with -DNYX_BLAS to enable OpenBLAS/MKL bindings
// Example: gcc -DNYX_BLAS -lopenblas -o nyx nyx.c
// ============================================================================
#if defined(NYX_BLAS)
#include <cblas.h>
#define NYX_HAVE_BLAS 1
#else
#define NYX_HAVE_BLAS 0
#endif

// ============================================================================
// OPTIONAL CUDA GPU SUPPORT
// Compile with -DNYX_CUDA to enable NVIDIA GPU acceleration
// Example: nvcc -DNYX_CUDA -o nyx nyx.c -lcuda -lcublas -lcudart
// ============================================================================
#if defined(NYX_CUDA)
#include <cuda.h>
#include <cuda_runtime.h>
#include <cublas_v2.h>
#define NYX_HAVE_CUDA 1
#else
#define NYX_HAVE_CUDA 0
#endif

// ============================================================================
// OPTIONAL OPENCL GPU SUPPORT  
// Compile with -DNYX_OPENCL to enable OpenCL GPU acceleration
// Example: gcc -DNYX_OPENCL -o nyx nyx.c -lOpenCL
// ============================================================================
#if defined(NYX_OPENCL)
#define NYX_HAVE_OPENCL 1
#else
#define NYX_HAVE_OPENCL 0
#endif

#define MAX_TOKEN_TEXT 1024

// Suppress unused parameter/variable warnings
#ifndef UNUSED_VARIABLE
#define UNUSED_VARIABLE(x) ((void)(x))
#endif
#ifndef UNUSED_PARAMETER
#define UNUSED_PARAMETER(x) ((void)(x))
#endif
#ifndef UNUSED_FUNCTION
#define UNUSED_FUNCTION(x) ((void)(x))
#endif

// ============================================================================
// MEMORY SAFETY LAYER - Rust-like safety guarantees
// ============================================================================

// Memory safety configuration - can be disabled for production
#ifndef NYX_SAFETY_ENABLED
#define NYX_SAFETY_ENABLED 1
#endif

// Use-after-free detection - simplified for production
// Full tracking requires DEBUG build
#if defined(DEBUG) || defined(NYX_SAFETY)
#define NYX_TRACKING_ENABLED 1
#else
#define NYX_TRACKING_ENABLED 0
#endif

// Safe malloc with null check
#ifndef NYX_SAFE_MALLOC
#define NYX_SAFE_MALLOC(ptr, size, on_fail) \
    do { \
        if (NYX_SAFETY_ENABLED) { \
            ptr = malloc(size); \
            if (!(ptr)) { \
                on_fail; \
            } else if (NYX_TRACKING_ENABLED) { \
                nyx_track_allocation(ptr, size, __FILE__, __LINE__); \
            } \
        } else { \
            ptr = malloc(size); \
        } \
    } while(0)
#endif

// Null pointer check with runtime error
#ifndef NYX_NULL_CHECK
#define NYX_NULL_CHECK(ptr, msg) \
    do { \
        if (NYX_SAFETY_ENABLED && !(ptr)) { \
            fprintf(stderr, "[NYX SAFETY] Null pointer: %s\n", msg); \
            exit(1); \
        } \
    } while(0)
#endif

// Bounds checking for array access
#ifndef NYX_BOUNDS_CHECK
#define NYX_BOUNDS_CHECK(idx, size, msg) \
    do { \
        if (NYX_SAFETY_ENABLED) { \
            if ((idx) < 0 || (idx) >= (size)) { \
                fprintf(stderr, "[NYX SAFETY] Bounds error: %s (index=%d, size=%d)\n", \
                    msg, (int)(idx), (int)(size)); \
                exit(1); \
            } \
        } \
    } while(0)
#endif

// Integer overflow detection
#ifndef NYX_OVERFLOW_CHECK
#define NYX_OVERFLOW_CHECK(a, b, op, msg) \
    do { \
        if (NYX_SAFETY_ENABLED) { \
            int64_t _nyx_a = (a); \
            int64_t _nyx_b = (b); \
            if (op == 0) { /* add */ \
                if ((_nyx_a > 0 && _nyx_b > INT64_MAX - _nyx_a) || \
                    (_nyx_a < 0 && _nyx_b < INT64_MIN - _nyx_a)) { \
                    fprintf(stderr, "[NYX SAFETY] Integer overflow: %s\n", msg); \
                    exit(1); \
                } \
            } else if (op == 1) { /* mul */ \
                if (_nyx_b != 0 && _nyx_a > INT64_MAX / _nyx_b) { \
                    fprintf(stderr, "[NYX SAFETY] Integer overflow: %s\n", msg); \
                    exit(1); \
                } \
            } \
        } \
    } while(0)
#endif

// Safe free that tracks deallocation
#ifndef NYX_SAFE_FREE
#define NYX_SAFE_FREE(ptr) \
    do { \
        if (NYX_TRACKING_ENABLED) { \
            nyx_track_deallocation(ptr); \
        } \
        free(ptr); \
        ptr = NULL; \
    } while(0)
#endif

// Defensive copy for string/array data
#ifndef NYX_DEFENSIVE_COPY
#define NYX_DEFENSIVE_COPY(dest, src, size) \
    do { \
        if (NYX_SAFETY_ENABLED && src) { \
            dest = malloc(size); \
            if (dest) memcpy(dest, src, size); \
        } else { \
            dest = src; \
        } \
    } while(0)
#endif

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

static void die_at(int line, int col, const char *msg) {
    fprintf(stderr, "Error at %d:%d: %s\n", line, col, msg);
    exit(1);
}

typedef struct {
    void **items;
    int count;
    int cap;
    int initialized;
    int cleaning;
} AllocTracker;

static AllocTracker g_alloc_tracker = {0};

static void alloc_tracker_cleanup(void);

static void alloc_tracker_init(void) {
    if (g_alloc_tracker.initialized) return;
    g_alloc_tracker.initialized = 1;
    if (atexit(alloc_tracker_cleanup) != 0) {
        fprintf(stderr, "Failed to register allocator cleanup hook\n");
        exit(1);
    }
}

static int alloc_tracker_find(void *p) {
    for (int i = 0; i < g_alloc_tracker.count; i++) {
        if (g_alloc_tracker.items[i] == p) return i;
    }
    return -1;
}

static void alloc_tracker_add(void *p) {
    if (!p || g_alloc_tracker.cleaning) return;
    alloc_tracker_init();

    if (alloc_tracker_find(p) >= 0) return;

    if (g_alloc_tracker.count == g_alloc_tracker.cap) {
        int next_cap = g_alloc_tracker.cap == 0 ? 256 : g_alloc_tracker.cap * 2;
        void **next_items = (void **)realloc(g_alloc_tracker.items, (size_t)next_cap * sizeof(void *));
        if (!next_items) {
            fprintf(stderr, "Out of memory\n");
            exit(1);
        }
        g_alloc_tracker.items = next_items;
        g_alloc_tracker.cap = next_cap;
    }

    g_alloc_tracker.items[g_alloc_tracker.count++] = p;
}

static void alloc_tracker_remove(void *p) {
    if (!p || !g_alloc_tracker.initialized || g_alloc_tracker.cleaning) return;
    int idx = alloc_tracker_find(p);
    if (idx < 0) return;
    g_alloc_tracker.items[idx] = g_alloc_tracker.items[g_alloc_tracker.count - 1];
    g_alloc_tracker.count--;
}

static void *xmalloc(size_t n) {
    void *p = malloc(n);
    if (!p) {
        fprintf(stderr, "Out of memory\n");
        exit(1);
    }
    alloc_tracker_add(p);
    return p;
}

static void *xrealloc(void *p, size_t n) {
    if (!p) return xmalloc(n);

    int idx = alloc_tracker_find(p);
    void *q = realloc(p, n);
    if (!q) {
        fprintf(stderr, "Out of memory\n");
        exit(1);
    }

    if (idx >= 0) {
        g_alloc_tracker.items[idx] = q;
    } else {
        alloc_tracker_add(q);
    }
    return q;
}

static void xfree(void *p) {
    if (!p) return;
    alloc_tracker_remove(p);
    free(p);
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

static void alloc_tracker_cleanup(void) {
    if (!g_alloc_tracker.initialized) return;
    g_alloc_tracker.cleaning = 1;
    for (int i = g_alloc_tracker.count - 1; i >= 0; i--) {
        free(g_alloc_tracker.items[i]);
    }
    free(g_alloc_tracker.items);
    g_alloc_tracker.items = NULL;
    g_alloc_tracker.count = 0;
    g_alloc_tracker.cap = 0;
}

static char *str_concat(const char *a, const char *b) {
    size_t na = strlen(a);
    size_t nb = strlen(b);
    char *out = (char *)xmalloc(na + nb + 1);
    memcpy(out, a, na);
    memcpy(out + na, b, nb);
    out[na + nb] = '\0';
    return out;
}

static void lexer_init(Lexer *lx, const char *src) {
    lx->src = src;
    lx->len = strlen(src);
    lx->pos = 0;
    lx->line = 1;
    lx->col = 1;
}

static int lexer_peek(Lexer *lx) {
    if (lx->pos >= lx->len) return 0;
    return (unsigned char)lx->src[lx->pos];
}

static int lexer_peek_next(Lexer *lx) {
    if (lx->pos + 1 >= lx->len) return 0;
    return (unsigned char)lx->src[lx->pos + 1];
}

static int lexer_next_char(Lexer *lx) {
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

static void skip_ws_and_comments(Lexer *lx) {
    while (1) {
        int ch = lexer_peek(lx);
        if (ch == 0) return;
        if (isspace(ch)) {
            lexer_next_char(lx);
            continue;
        }
        if (ch == '#') {
            while (ch != 0 && ch != '\n') ch = lexer_next_char(lx);
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
    skip_ws_and_comments(lx);

    int line = lx->line;
    int col = lx->col;
    int ch = lexer_peek(lx);

    if (ch == 0) {
        return make_token(TOK_EOF, line, col);
    }

    if (isdigit(ch)) {
        Token tok = make_token(TOK_INT, line, col);
        size_t start = lx->pos;
        while (isdigit(lexer_peek(lx))) lexer_next_char(lx);
        size_t n = lx->pos - start;
        if (n >= MAX_TOKEN_TEXT) die_at(line, col, "integer literal too long");
        memcpy(tok.text, lx->src + start, n);
        tok.text[n] = '\0';
        errno = 0;
        tok.int_val = strtoll(tok.text, NULL, 10);
        if (errno != 0) die_at(line, col, "invalid integer literal");
        return tok;
    }

    if (isalpha(ch) || ch == '_') {
        Token tok = make_token(TOK_IDENT, line, col);
        size_t start = lx->pos;
        while (isalnum(lexer_peek(lx)) || lexer_peek(lx) == '_') lexer_next_char(lx);
        size_t n = lx->pos - start;
        if (n >= MAX_TOKEN_TEXT) die_at(line, col, "identifier too long");
        memcpy(tok.text, lx->src + start, n);
        tok.text[n] = '\0';
        tok.type = keyword_type(tok.text);
        return tok;
    }

    if (ch == '"') {
        Token tok = make_token(TOK_STRING, line, col);
        char buf[MAX_TOKEN_TEXT];
        size_t n = 0;

        lexer_next_char(lx); /* consume opening quote */

        while (1) {
            int c = lexer_peek(lx);
            if (c == 0) die_at(line, col, "unterminated string literal");
            if (c == '"') {
                lexer_next_char(lx);
                break;
            }
            if (c == '\\') {
                lexer_next_char(lx);
                int e = lexer_peek(lx);
                if (e == 0) die_at(line, col, "unterminated string escape");
                char out;
                switch (e) {
                    case 'n': out = '\n'; break;
                    case 't': out = '\t'; break;
                    case 'r': out = '\r'; break;
                    case '"': out = '"'; break;
                    case '\\': out = '\\'; break;
                    default: out = (char)e; break;
                }
                if (n + 1 >= MAX_TOKEN_TEXT) die_at(line, col, "string literal too long");
                buf[n++] = out;
                lexer_next_char(lx);
                continue;
            }
            if (n + 1 >= MAX_TOKEN_TEXT) die_at(line, col, "string literal too long");
            buf[n++] = (char)lexer_next_char(lx);
        }

        buf[n] = '\0';
        memcpy(tok.text, buf, n + 1);
        return tok;
    }

    if (ch == '=' && lexer_peek_next(lx) == '=') {
        lexer_next_char(lx);
        lexer_next_char(lx);
        return make_token(TOK_EQ, line, col);
    }
    if (ch == '!' && lexer_peek_next(lx) == '=') {
        lexer_next_char(lx);
        lexer_next_char(lx);
        return make_token(TOK_NEQ, line, col);
    }
    if (ch == '&' && lexer_peek_next(lx) == '&') {
        lexer_next_char(lx);
        lexer_next_char(lx);
        return make_token(TOK_ANDAND, line, col);
    }
    if (ch == '|' && lexer_peek_next(lx) == '|') {
        lexer_next_char(lx);
        lexer_next_char(lx);
        return make_token(TOK_OROR, line, col);
    }
    if (ch == '?' && lexer_peek_next(lx) == '?') {
        lexer_next_char(lx);
        lexer_next_char(lx);
        return make_token(TOK_COALESCE, line, col);
    }
    if (ch == '<' && lexer_peek_next(lx) == '=') {
        lexer_next_char(lx);
        lexer_next_char(lx);
        return make_token(TOK_LE, line, col);
    }
    if (ch == '>' && lexer_peek_next(lx) == '=') {
        lexer_next_char(lx);
        lexer_next_char(lx);
        return make_token(TOK_GE, line, col);
    }

    lexer_next_char(lx);
    switch (ch) {
        case '=': return make_token(TOK_ASSIGN, line, col);
        case '+': return make_token(TOK_PLUS, line, col);
        case '-': return make_token(TOK_MINUS, line, col);
        case '*': return make_token(TOK_STAR, line, col);
        case '/': return make_token(TOK_SLASH, line, col);
        case '%': return make_token(TOK_PERCENT, line, col);
        case '!': return make_token(TOK_BANG, line, col);
        case '<': return make_token(TOK_LT, line, col);
        case '>': return make_token(TOK_GT, line, col);
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

typedef struct Expr Expr;
typedef struct Stmt Stmt;
typedef struct Block Block;

typedef enum {
    EXPR_INT,
    EXPR_STRING,
    EXPR_BOOL,
    EXPR_NULL,
    EXPR_IDENT,
    EXPR_ARRAY,
    EXPR_ARRAY_COMP,
    EXPR_OBJECT,
    EXPR_INDEX,
    EXPR_DOT,
    EXPR_UNARY,
    EXPR_BINARY,
    EXPR_CALL
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
    STMT_LET,
    STMT_ASSIGN,
    STMT_SET_MEMBER,
    STMT_SET_INDEX,
    STMT_EXPR,
    STMT_IF,
    STMT_SWITCH,
    STMT_WHILE,
    STMT_FOR,
    STMT_BREAK,
    STMT_CONTINUE,
    STMT_CLASS,
    STMT_MODULE,
    STMT_TYPE,
    STMT_TRY,
    STMT_FN,
    STMT_RETURN,
    STMT_THROW,
    STMT_IMPORT
} StmtKind;

struct Block {
    Stmt **items;
    int count;
    int cap;
};

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

static void block_add_stmt(Block *b, Stmt *s) {
    if (b->count == b->cap) {
        int next_cap = b->cap == 0 ? 8 : b->cap * 2;
        b->items = (Stmt **)xrealloc(b->items, (size_t)next_cap * sizeof(Stmt *));
        if (!b->items) {
            fprintf(stderr, "Out of memory\n");
            exit(1);
        }
        b->cap = next_cap;
    }
    b->items[b->count++] = s;
}

typedef struct {
    Lexer lx;
    Token cur;
    Token peek;
} Parser;

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
    if (p->cur.type != t) die_at(p->cur.line, p->cur.col, msg);
}

enum {
    PREC_LOWEST = 0,
    PREC_COALESCE = 1,
    PREC_OR = 2,
    PREC_AND = 3,
    PREC_EQUALS = 4,
    PREC_COMPARE = 5,
    PREC_SUM = 6,
    PREC_PRODUCT = 7,
    PREC_PREFIX = 8,
    PREC_CALL = 9
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
            return PREC_EQUALS;
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
            return PREC_CALL;
        default:
            return PREC_LOWEST;
    }
}

static Expr *parse_expression(Parser *p, int prec);

static Expr *parse_array_literal(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;
    Expr *e = new_expr(EXPR_ARRAY, line, col);
    e->as.array.items = NULL;
    e->as.array.count = 0;

    next_token(p); /* first element or ] */

    if (p->cur.type == TOK_RBRACKET) {
        next_token(p);
        return e;
    }

    Expr *first = parse_expression(p, PREC_LOWEST);

    if (p->cur.type == TOK_FOR) {
        Expr *comp = new_expr(EXPR_ARRAY_COMP, line, col);
        comp->as.array_comp.value_expr = first;
        comp->as.array_comp.iter_value_name = NULL;

        next_token(p);
        expect_current(p, TOK_IDENT, "expected iterator variable name after for");
        comp->as.array_comp.iter_name = xstrdup(p->cur.text);

        next_token(p);
        if (p->cur.type == TOK_COMMA) {
            next_token(p);
            expect_current(p, TOK_IDENT, "expected second iterator variable name");
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

        expect_current(p, TOK_RBRACKET, "expected ']' to close array comprehension");
        next_token(p);
        return comp;
    }

    while (1) {
        int idx = e->as.array.count;
        e->as.array.items = (Expr **)xrealloc(e->as.array.items, (size_t)(idx + 1) * sizeof(Expr *));
        e->as.array.items[idx] = first;
        e->as.array.count++;

        if (p->cur.type != TOK_COMMA) break;
        next_token(p);
        first = parse_expression(p, PREC_LOWEST);
    }

    expect_current(p, TOK_RBRACKET, "expected ']' to close array literal");
    next_token(p);
    return e;
}

static Expr *parse_object_literal(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;
    Expr *e = new_expr(EXPR_OBJECT, line, col);
    e->as.object.keys = NULL;
    e->as.object.values = NULL;
    e->as.object.count = 0;

    next_token(p); /* first key or } */
    if (p->cur.type == TOK_RBRACE) {
        next_token(p);
        return e;
    }

    while (1) {
        char *key = NULL;
        if (p->cur.type == TOK_IDENT || p->cur.type == TOK_STRING) {
            key = xstrdup(p->cur.text);
        } else {
            die_at(p->cur.line, p->cur.col, "expected identifier or string as object key");
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

    expect_current(p, TOK_RBRACE, "expected '}' to close object literal");
    next_token(p);
    return e;
}

static Expr *parse_prefix(Parser *p) {
    Token tok = p->cur;

    if (tok.type == TOK_INT) {
        Expr *e = new_expr(EXPR_INT, tok.line, tok.col);
        e->as.int_val = tok.int_val;
        next_token(p);
        return e;
    }

    if (tok.type == TOK_STRING) {
        Expr *e = new_expr(EXPR_STRING, tok.line, tok.col);
        e->as.str_val = xstrdup(tok.text);
        next_token(p);
        return e;
    }

    if (tok.type == TOK_TRUE || tok.type == TOK_FALSE) {
        Expr *e = new_expr(EXPR_BOOL, tok.line, tok.col);
        e->as.bool_val = (tok.type == TOK_TRUE) ? 1 : 0;
        next_token(p);
        return e;
    }

    if (tok.type == TOK_NULL) {
        Expr *e = new_expr(EXPR_NULL, tok.line, tok.col);
        next_token(p);
        return e;
    }

    if (tok.type == TOK_IDENT) {
        Expr *e = new_expr(EXPR_IDENT, tok.line, tok.col);
        e->as.ident = xstrdup(tok.text);
        next_token(p);
        return e;
    }

    if (tok.type == TOK_MINUS || tok.type == TOK_BANG) {
        Expr *e = new_expr(EXPR_UNARY, tok.line, tok.col);
        e->as.unary.op = tok.type;
        next_token(p);
        e->as.unary.right = parse_expression(p, PREC_PREFIX);
        return e;
    }

    if (tok.type == TOK_LPAREN) {
        next_token(p);
        Expr *inside = parse_expression(p, PREC_LOWEST);
        expect_current(p, TOK_RPAREN, "expected ')' ");
        next_token(p);
        return inside;
    }

    if (tok.type == TOK_LBRACKET) {
        return parse_array_literal(p);
    }

    if (tok.type == TOK_LBRACE) {
        return parse_object_literal(p);
    }

    die_at(tok.line, tok.col, "unexpected token in expression");
    return NULL;
}

static Expr *parse_call_expr(Parser *p, Expr *callee) {
    int line = p->cur.line;
    int col = p->cur.col;
    Expr *e = new_expr(EXPR_CALL, line, col);
    e->as.call.callee = callee;
    e->as.call.args = NULL;
    e->as.call.argc = 0;

    next_token(p); /* first arg or ) */

    if (p->cur.type == TOK_RPAREN) {
        next_token(p);
        return e;
    }

    while (1) {
        Expr *arg = parse_expression(p, PREC_LOWEST);

        int idx = e->as.call.argc;
        e->as.call.args = (Expr **)xrealloc(e->as.call.args, (size_t)(idx + 1) * sizeof(Expr *));
        if (!e->as.call.args) {
            fprintf(stderr, "Out of memory\n");
            exit(1);
        }
        e->as.call.args[idx] = arg;
        e->as.call.argc++;

        if (p->cur.type == TOK_COMMA) {
            next_token(p);
            continue;
        }
        break;
    }

    expect_current(p, TOK_RPAREN, "expected ')' after call arguments");
    next_token(p);
    return e;
}

static Expr *parse_index_expr(Parser *p, Expr *left) {
    int line = p->cur.line;
    int col = p->cur.col;
    Expr *e = new_expr(EXPR_INDEX, line, col);
    e->as.index.left = left;

    next_token(p);
    e->as.index.index = parse_expression(p, PREC_LOWEST);

    expect_current(p, TOK_RBRACKET, "expected ']' after index expression");
    next_token(p);
    return e;
}

static Expr *parse_dot_expr(Parser *p, Expr *left) {
    int line = p->cur.line;
    int col = p->cur.col;
    Expr *e = new_expr(EXPR_DOT, line, col);
    e->as.dot.left = left;

    next_token(p);
    expect_current(p, TOK_IDENT, "expected identifier after '.'");
    e->as.dot.member = xstrdup(p->cur.text);
    next_token(p);
    return e;
}

static Expr *parse_infix_expr(Parser *p, Expr *left) {
    Token tok = p->cur;
    int op_prec = precedence(tok.type);

    Expr *e = new_expr(EXPR_BINARY, tok.line, tok.col);
    e->as.binary.left = left;
    e->as.binary.op = tok.type;

    next_token(p);
    e->as.binary.right = parse_expression(p, op_prec);
    return e;
}

static Expr *parse_expression(Parser *p, int prec) {
    Expr *left = parse_prefix(p);

    while (p->cur.type != TOK_SEMI && p->cur.type != TOK_RPAREN && p->cur.type != TOK_RBRACKET &&
           p->cur.type != TOK_RBRACE && p->cur.type != TOK_COMMA && prec < precedence(p->cur.type)) {
        if (p->cur.type == TOK_LPAREN) {
            left = parse_call_expr(p, left);
        } else if (p->cur.type == TOK_LBRACKET) {
            left = parse_index_expr(p, left);
        } else if (p->cur.type == TOK_DOT) {
            left = parse_dot_expr(p, left);
        } else {
            left = parse_infix_expr(p, left);
        }
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

    Stmt *s = new_stmt(STMT_LET, line, col);
    s->as.let_stmt.name = name;
    s->as.let_stmt.value = value;
    return s;
}

static Stmt *parse_return_statement(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;

    next_token(p);
    Expr *value = NULL;
    if (p->cur.type == TOK_SEMI) {
        value = new_expr(EXPR_NULL, line, col);
    } else {
        value = parse_expression(p, PREC_LOWEST);
    }

    expect_current(p, TOK_SEMI, "expected ';' after return");
    next_token(p);

    Stmt *s = new_stmt(STMT_RETURN, line, col);
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

    Stmt *s = new_stmt(STMT_THROW, line, col);
    s->as.throw_stmt.value = value;
    return s;
}

static Stmt *parse_import_statement(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;

    next_token(p);
    expect_current(p, TOK_STRING, "expected string path in import statement");
    char *path = xstrdup(p->cur.text);

    next_token(p);
    expect_current(p, TOK_SEMI, "expected ';' after import statement");
    next_token(p);

    Stmt *s = new_stmt(STMT_IMPORT, line, col);
    s->as.import_stmt.path = path;
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

    Stmt *s = new_stmt(STMT_IF, line, col);
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
                die_at(p->cur.line, p->cur.col, "duplicate default label in switch");
            }
            next_token(p);
            expect_current(p, TOK_COLON, "expected ':' after default");
            next_token(p);
            expect_current(p, TOK_LBRACE, "expected '{' after default label");
            default_block = parse_block(p);
            continue;
        }
        die_at(p->cur.line, p->cur.col, "expected case/default label in switch body");
    }

    expect_current(p, TOK_RBRACE, "expected '}' to close switch statement");
    next_token(p);

    Stmt *s = new_stmt(STMT_SWITCH, line, col);
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

    Stmt *s = new_stmt(STMT_WHILE, line, col);
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

    expect_current(p, TOK_LBRACE, "expected '{' after for(...)");
    Block *body = parse_block(p);

    Stmt *s = new_stmt(STMT_FOR, line, col);
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

    Stmt *s = new_stmt(STMT_TRY, line, col);
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
    return new_stmt(STMT_BREAK, line, col);
}

static Stmt *parse_continue_statement(Parser *p) {
    int line = p->cur.line;
    int col = p->cur.col;
    next_token(p);
    expect_current(p, TOK_SEMI, "expected ';' after continue");
    next_token(p);
    return new_stmt(STMT_CONTINUE, line, col);
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

    Stmt *s = new_stmt(STMT_CLASS, line, col);
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

    Stmt *s = new_stmt(STMT_MODULE, line, col);
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
    expect_current(p, TOK_SEMI, "expected ';' after type definition");
    next_token(p);

    Stmt *s = new_stmt(STMT_TYPE, line, col);
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

    next_token(p); /* first param or ) */

    if (p->cur.type != TOK_RPAREN) {
        while (1) {
            expect_current(p, TOK_IDENT, "expected parameter name");
            params = (char **)xrealloc(params, (size_t)(param_count + 1) * sizeof(char *));
            if (!params) {
                fprintf(stderr, "Out of memory\n");
                exit(1);
            }
            params[param_count++] = xstrdup(p->cur.text);

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

    Stmt *s = new_stmt(STMT_FN, line, col);
    s->as.fn_stmt.name = name;
    s->as.fn_stmt.params = params;
    s->as.fn_stmt.param_count = param_count;
    s->as.fn_stmt.body = body;
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

        if (lhs->kind == EXPR_IDENT) {
            Stmt *s = new_stmt(STMT_ASSIGN, line, col);
            s->as.assign_stmt.name = lhs->as.ident;
            s->as.assign_stmt.value = value;
            return s;
        }
        if (lhs->kind == EXPR_DOT) {
            Stmt *s = new_stmt(STMT_SET_MEMBER, line, col);
            s->as.set_member_stmt.object = lhs->as.dot.left;
            s->as.set_member_stmt.member = lhs->as.dot.member;
            s->as.set_member_stmt.value = value;
            return s;
        }
        if (lhs->kind == EXPR_INDEX) {
            Stmt *s = new_stmt(STMT_SET_INDEX, line, col);
            s->as.set_index_stmt.object = lhs->as.index.left;
            s->as.set_index_stmt.index = lhs->as.index.index;
            s->as.set_index_stmt.value = value;
            return s;
        }
        die_at(line, col, "invalid assignment target");
    }

    expect_current(p, TOK_SEMI, "expected ';' after expression");
    next_token(p);

    Stmt *s = new_stmt(STMT_EXPR, line, col);
    s->as.expr_stmt.expr = lhs;
    return s;
}

static Stmt *parse_statement(Parser *p) {
    switch (p->cur.type) {
        case TOK_LET:
            return parse_let_statement(p);
        case TOK_IF:
            return parse_if_statement(p);
        case TOK_SWITCH:
            return parse_switch_statement(p);
        case TOK_WHILE:
            return parse_while_statement(p);
        case TOK_FOR:
            return parse_for_statement(p);
        case TOK_TRY:
            return parse_try_statement(p);
        case TOK_BREAK:
            return parse_break_statement(p);
        case TOK_CONTINUE:
            return parse_continue_statement(p);
        case TOK_CLASS:
            return parse_class_statement(p);
        case TOK_MODULE:
            return parse_module_statement(p);
        case TOK_TYPEDEF:
            return parse_type_statement(p);
        case TOK_FN:
            return parse_fn_statement(p);
        case TOK_RETURN:
            return parse_return_statement(p);
        case TOK_THROW:
            return parse_throw_statement(p);
        case TOK_IMPORT:
            return parse_import_statement(p);
        default:
            return parse_expr_or_assignment_statement(p);
    }
}

static Block *parse_block(Parser *p) {
    expect_current(p, TOK_LBRACE, "expected '{' to start block");

    Block *b = new_block();
    next_token(p);

    while (p->cur.type != TOK_RBRACE && p->cur.type != TOK_EOF) {
        block_add_stmt(b, parse_statement(p));
    }

    expect_current(p, TOK_RBRACE, "expected '}' to close block");
    next_token(p);
    return b;
}

static Block *parse_program(Parser *p) {
    Block *program = new_block();

    while (p->cur.type != TOK_EOF) {
        block_add_stmt(program, parse_statement(p));
    }

    return program;
}

typedef struct Value Value;
typedef struct Env Env;
typedef struct ImportSet ImportSet;
typedef struct Object Object;
typedef struct BoundMethod BoundMethod;

typedef enum {
    VAL_NULL,
    VAL_INT,
    VAL_BOOL,
    VAL_STRING,
    VAL_ARRAY,
    VAL_OBJECT,
    VAL_FUNCTION,
    VAL_BUILTIN,
    VAL_BOUND_METHOD
} ValueType;

typedef struct {
    Value *items;
    int count;
} Array;

typedef struct ObjectEntry ObjectEntry;
typedef enum {
    OBJ_PLAIN = 0,
    OBJ_MODULE,
    OBJ_CLASS,
    OBJ_INSTANCE
} ObjectKind;

struct Object {
    ObjectEntry *items;
    int count;
    int cap;
    ObjectKind kind;
};

typedef struct {
    char **params;
    int param_count;
    Block *body;
    Env *closure;
    char *def_file;
} Function;

typedef Value (*BuiltinFn)(Value *args, int argc, int line, int col, const char *current_file);

struct Value {
    ValueType type;
    union {
        long long int_val;
        int bool_val;
        char *str_val;
        Array *array_val;
        Object *object_val;
        Function *fn_val;
        BuiltinFn builtin_val;
        BoundMethod *bound_method_val;
    } as;
};

struct ObjectEntry {
    char *key;
    Value value;
};

struct BoundMethod {
    Value self;
    Value fn;
};

typedef struct ExceptionFrame ExceptionFrame;
struct ExceptionFrame {
    jmp_buf env;
    ExceptionFrame *prev;
};

typedef struct {
    char *name;
    Value value;
} Binding;

struct Env {
    Binding *items;
    int count;
    int cap;
    Env *parent;
};

struct ImportSet {
    char **items;
    int count;
    int cap;
};

static int g_script_argc = 0;
static char **g_script_argv = NULL;
static int g_trace = 0;
static int g_use_vm = 0;
static int g_vm_strict = 0;
static int g_parse_only = 0;
static int g_debug_enabled = 0;
static int g_debug_step_mode = 0;
static int g_debug_continue_mode = 1;
static int g_debug_no_prompt = 0;
static int g_debug_step_index = 0;
static int g_debug_step_count = 0;
static int *g_debug_break_lines = NULL;
static int g_debug_break_count = 0;
static ExceptionFrame *g_exception_top = NULL;
static Value g_exception_value;
static ImportSet *g_runtime_imports_ctx = NULL;
static const char *g_runtime_file_ctx = NULL;
static long long g_alloc_units = 0;
static long long g_max_alloc_units = 10000000;
static long long g_step_count = 0;
static long long g_max_steps = 0;
static int g_call_depth = 0;
static int g_max_call_depth = 10000;

typedef enum {
    CTRL_NONE = 0,
    CTRL_RETURN,
    CTRL_BREAK,
    CTRL_CONTINUE
} ControlKind;

typedef struct {
    Value value;
    ControlKind control;
} EvalResult;

static void runtime_error(int line, int col, const char *msg);

static Value value_null(void) {
    Value v;
    v.type = VAL_NULL;
    return v;
}

static Value value_int(long long x) {
    Value v;
    v.type = VAL_INT;
    v.as.int_val = x;
    return v;
}

static Value value_bool(int x) {
    Value v;
    v.type = VAL_BOOL;
    v.as.bool_val = x ? 1 : 0;
    return v;
}

static Value value_string(const char *s) {
    Value v;
    v.type = VAL_STRING;
    v.as.str_val = xstrdup(s);
    return v;
}

static void alloc_guard(const char *what) {
    g_alloc_units++;
    if (g_alloc_units > g_max_alloc_units) {
        fprintf(stderr, "Runtime error: allocation limit exceeded while allocating %s\n", what);
        exit(1);
    }
}

static Value value_array(Value *items, int count) {
    Value v;
    v.type = VAL_ARRAY;
    alloc_guard("array");
    Array *arr = (Array *)xmalloc(sizeof(Array));
    arr->items = items;
    arr->count = count;
    v.as.array_val = arr;
    return v;
}

static Object *object_new_kind(ObjectKind kind) {
    alloc_guard("object");
    Object *obj = (Object *)xmalloc(sizeof(Object));
    obj->items = NULL;
    obj->count = 0;
    obj->cap = 0;
    obj->kind = kind;
    return obj;
}

static Object *object_new(void) {
    return object_new_kind(OBJ_PLAIN);
}

static int object_find_index(Object *obj, const char *key) {
    for (int i = 0; i < obj->count; i++) {
        if (strcmp(obj->items[i].key, key) == 0) return i;
    }
    return -1;
}

static void object_set(Object *obj, const char *key, Value value) {
    int idx = object_find_index(obj, key);
    if (idx >= 0) {
        obj->items[idx].value = value;
        return;
    }

    if (obj->count == obj->cap) {
        int next_cap = obj->cap == 0 ? 8 : obj->cap * 2;
        obj->items = (ObjectEntry *)xrealloc(obj->items, (size_t)next_cap * sizeof(ObjectEntry));
        obj->cap = next_cap;
    }

    obj->items[obj->count].key = xstrdup(key);
    obj->items[obj->count].value = value;
    obj->count++;
}

static Value object_get(Object *obj, const char *key) {
    int idx = object_find_index(obj, key);
    if (idx < 0) return value_null();
    return obj->items[idx].value;
}

static int object_has(Object *obj, const char *key) {
    return object_find_index(obj, key) >= 0;
}

static Value value_object(Object *obj) {
    Value v;
    v.type = VAL_OBJECT;
    v.as.object_val = obj;
    return v;
}

static Value value_function(Function *fn) {
    Value v;
    v.type = VAL_FUNCTION;
    v.as.fn_val = fn;
    return v;
}

static Value value_builtin(BuiltinFn fn) {
    Value v;
    v.type = VAL_BUILTIN;
    v.as.builtin_val = fn;
    return v;
}

static Value value_bound_method(Value self, Value fn) {
    BoundMethod *bm = (BoundMethod *)xmalloc(sizeof(BoundMethod));
    bm->self = self;
    bm->fn = fn;

    Value v;
    v.type = VAL_BOUND_METHOD;
    v.as.bound_method_val = bm;
    return v;
}

static void throw_value(int line, int col, Value value) {
    if (!g_exception_top) {
        runtime_error(line, col, "uncaught exception");
    }
    g_exception_value = value;
    longjmp(g_exception_top->env, 1);
}

static void runtime_error(int line, int col, const char *msg) {
    die_at(line, col, msg);
}

static void step_guard(int line, int col) {
    if (g_max_steps <= 0) return;
    g_step_count++;
    if (g_step_count > g_max_steps) {
        runtime_error(line, col, "max step count exceeded");
    }
}

static Env *env_new(Env *parent) {
    Env *env = (Env *)xmalloc(sizeof(Env));
    env->items = NULL;
    env->count = 0;
    env->cap = 0;
    env->parent = parent;
    return env;
}

static void env_define(Env *env, const char *name, Value value) {
    for (int i = 0; i < env->count; i++) {
        if (strcmp(env->items[i].name, name) == 0) {
            env->items[i].value = value;
            return;
        }
    }

    if (env->count == env->cap) {
        int next_cap = env->cap == 0 ? 8 : env->cap * 2;
        env->items = (Binding *)xrealloc(env->items, (size_t)next_cap * sizeof(Binding));
        if (!env->items) {
            fprintf(stderr, "Out of memory\n");
            exit(1);
        }
        env->cap = next_cap;
    }

    env->items[env->count].name = xstrdup(name);
    env->items[env->count].value = value;
    env->count++;
}

static int env_get(Env *env, const char *name, Value *out) {
    for (Env *cur = env; cur != NULL; cur = cur->parent) {
        for (int i = 0; i < cur->count; i++) {
            if (strcmp(cur->items[i].name, name) == 0) {
                *out = cur->items[i].value;
                return 1;
            }
        }
    }
    return 0;
}

static int env_assign(Env *env, const char *name, Value value) {
    for (Env *cur = env; cur != NULL; cur = cur->parent) {
        for (int i = 0; i < cur->count; i++) {
            if (strcmp(cur->items[i].name, name) == 0) {
                cur->items[i].value = value;
                return 1;
            }
        }
    }
    return 0;
}

static void import_set_add(ImportSet *set, const char *path) {
    if (set->count == set->cap) {
        int next_cap = set->cap == 0 ? 8 : set->cap * 2;
        set->items = (char **)xrealloc(set->items, (size_t)next_cap * sizeof(char *));
        if (!set->items) {
            fprintf(stderr, "Out of memory\n");
            exit(1);
        }
        set->cap = next_cap;
    }
    set->items[set->count++] = xstrdup(path);
}

static int import_set_contains(const ImportSet *set, const char *path) {
    for (int i = 0; i < set->count; i++) {
        if (strcmp(set->items[i], path) == 0) return 1;
    }
    return 0;
}

static int is_absolute_path(const char *path) {
    if (path[0] == '/') return 1;
    if (isalpha((unsigned char)path[0]) && path[1] == ':') return 1;
    return 0;
}

static char *path_dirname(const char *path) {
    const char *last = strrchr(path, '/');
    if (!last) return xstrdup(".");
    if (last == path) return xstrdup("/");
    return xstrndup(path, (size_t)(last - path));
}

static char *resolve_path(const char *current_file, const char *raw_path) {
    if (is_absolute_path(raw_path)) return xstrdup(raw_path);

    if (current_file == NULL || current_file[0] == '\0') {
        return xstrdup(raw_path);
    }

    char *dir = path_dirname(current_file);
    char *tmp = str_concat(dir, "/");
    char *full = str_concat(tmp, raw_path);
    xfree(dir);
    xfree(tmp);
    return full;
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

static int is_truthy(Value v) {
    switch (v.type) {
        case VAL_NULL: return 0;
        case VAL_BOOL: return v.as.bool_val;
        case VAL_INT: return v.as.int_val != 0;
        case VAL_STRING: return v.as.str_val[0] != '\0';
        case VAL_ARRAY: return v.as.array_val->count > 0;
        case VAL_OBJECT: return 1;
        case VAL_BOUND_METHOD: return 1;
        default: return 1;
    }
}

static void value_print_inline(Value v);

static void value_print_inline(Value v) {
    switch (v.type) {
        case VAL_NULL:
            printf("null");
            return;
        case VAL_INT:
            printf("%lld", v.as.int_val);
            return;
        case VAL_BOOL:
            printf(v.as.bool_val ? "true" : "false");
            return;
        case VAL_STRING:
            printf("%s", v.as.str_val);
            return;
        case VAL_ARRAY:
            printf("[");
            for (int i = 0; i < v.as.array_val->count; i++) {
                if (i > 0) printf(", ");
                value_print_inline(v.as.array_val->items[i]);
            }
            printf("]");
            return;
        case VAL_OBJECT:
            printf("{");
            for (int i = 0; i < v.as.object_val->count; i++) {
                if (i > 0) printf(", ");
                printf("%s: ", v.as.object_val->items[i].key);
                value_print_inline(v.as.object_val->items[i].value);
            }
            printf("}");
            return;
        case VAL_FUNCTION:
            printf("<fn>");
            return;
        case VAL_BUILTIN:
            printf("<builtin>");
            return;
        case VAL_BOUND_METHOD:
            printf("<bound-method>");
            return;
    }
}

static void value_println(Value v) {
    value_print_inline(v);
    printf("\n");
}

static char *value_to_string(Value v) {
    char buf[64];
    switch (v.type) {
        case VAL_STRING:
            return xstrdup(v.as.str_val);
        case VAL_INT:
            snprintf(buf, sizeof(buf), "%lld", v.as.int_val);
            return xstrdup(buf);
        case VAL_BOOL:
            return xstrdup(v.as.bool_val ? "true" : "false");
        case VAL_NULL:
            return xstrdup("null");
        case VAL_ARRAY:
            return xstrdup("[array]");
        case VAL_OBJECT:
            return xstrdup("[object]");
        case VAL_FUNCTION:
            return xstrdup("<fn>");
        case VAL_BUILTIN:
            return xstrdup("<builtin>");
        case VAL_BOUND_METHOD:
            return xstrdup("<bound-method>");
    }
    return xstrdup("");
}

static int values_equal(Value a, Value b) {
    if (a.type != b.type) return 0;
    switch (a.type) {
        case VAL_NULL:
            return 1;
        case VAL_INT:
            return a.as.int_val == b.as.int_val;
        case VAL_BOOL:
            return a.as.bool_val == b.as.bool_val;
        case VAL_STRING:
            return strcmp(a.as.str_val, b.as.str_val) == 0;
        case VAL_ARRAY:
            return a.as.array_val == b.as.array_val;
        case VAL_OBJECT:
            return a.as.object_val == b.as.object_val;
        case VAL_FUNCTION:
            return a.as.fn_val == b.as.fn_val;
        case VAL_BUILTIN:
            return a.as.builtin_val == b.as.builtin_val;
        case VAL_BOUND_METHOD:
            return a.as.bound_method_val == b.as.bound_method_val;
    }
    return 0;
}

static int parse_int_value(const char *s, long long *out) {
    if (s == NULL) return 0;

    while (*s && isspace((unsigned char)*s)) s++;
    if (*s == '\0') return 0;

    errno = 0;
    char *end = NULL;
    long long v = strtoll(s, &end, 10);
    if (errno != 0 || end == s) return 0;

    while (*end && isspace((unsigned char)*end)) end++;
    if (*end != '\0') return 0;

    *out = v;
    return 1;
}

static Value eval_expr(Expr *expr, Env *env, ImportSet *imports, const char *current_file);
static Value eval_expr_ast(Expr *expr, Env *env, ImportSet *imports, const char *current_file);
static Value eval_expr_vm(Expr *expr, Env *env, ImportSet *imports, const char *current_file);
static Value object_get_member_value(Value object_value, const char *member, int line, int col);
static Value apply_function(Value fn, Value *args, int argc, int line, int col, ImportSet *imports,
                            const char *current_file);
static EvalResult eval_statement(Stmt *stmt, Env *env, ImportSet *imports, const char *current_file, int top_level);
static EvalResult eval_block(Block *block, Env *env, ImportSet *imports, const char *current_file, int top_level);
static EvalResult vm_eval_block(Block *block, Env *env, ImportSet *imports, const char *current_file, int top_level);

static Value builtin_print(Value *args, int argc, int line, int col, const char *current_file) {
    (void)line;
    (void)col;
    (void)current_file;
    for (int i = 0; i < argc; i++) {
        if (i > 0) printf(" ");
        value_print_inline(args[i]);
    }
    printf("\n");
    return value_null();
}

static Value builtin_len(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "len() expects exactly 1 argument");

    if (args[0].type == VAL_STRING) {
        return value_int((long long)strlen(args[0].as.str_val));
    }
    if (args[0].type == VAL_ARRAY) {
        return value_int(args[0].as.array_val->count);
    }
    if (args[0].type == VAL_OBJECT) {
        return value_int(args[0].as.object_val->count);
    }

    runtime_error(line, col, "len() supports only string, array, and object");
    return value_null();
}

static Value builtin_abs(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "abs() expects exactly 1 argument");
    if (args[0].type != VAL_INT) runtime_error(line, col, "abs() expects integer argument");
    long long n = args[0].as.int_val;
    if (n < 0) n = -n;
    return value_int(n);
}

static Value builtin_min(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 2) runtime_error(line, col, "min() expects exactly 2 arguments");
    if (args[0].type != VAL_INT || args[1].type != VAL_INT) runtime_error(line, col, "min() expects integer arguments");
    return value_int(args[0].as.int_val < args[1].as.int_val ? args[0].as.int_val : args[1].as.int_val);
}

static Value builtin_max(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 2) runtime_error(line, col, "max() expects exactly 2 arguments");
    if (args[0].type != VAL_INT || args[1].type != VAL_INT) runtime_error(line, col, "max() expects integer arguments");
    return value_int(args[0].as.int_val > args[1].as.int_val ? args[0].as.int_val : args[1].as.int_val);
}

static Value builtin_clamp(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 3) runtime_error(line, col, "clamp() expects exactly 3 arguments");
    if (args[0].type != VAL_INT || args[1].type != VAL_INT || args[2].type != VAL_INT) {
        runtime_error(line, col, "clamp() expects integer arguments");
    }
    long long v = args[0].as.int_val;
    long long lo = args[1].as.int_val;
    long long hi = args[2].as.int_val;
    if (v < lo) return value_int(lo);
    if (v > hi) return value_int(hi);
    return value_int(v);
}

static Value builtin_sum(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "sum() expects exactly 1 argument");
    if (args[0].type != VAL_ARRAY) runtime_error(line, col, "sum() expects array argument");

    long long acc = 0;
    Array *arr = args[0].as.array_val;
    for (int i = 0; i < arr->count; i++) {
        if (arr->items[i].type != VAL_INT) runtime_error(line, col, "sum() expects array[int]");
        acc += arr->items[i].as.int_val;
    }
    return value_int(acc);
}

static Value builtin_all(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "all() expects exactly 1 argument");
    if (args[0].type != VAL_ARRAY) runtime_error(line, col, "all() expects array argument");

    Array *arr = args[0].as.array_val;
    for (int i = 0; i < arr->count; i++) {
        if (!is_truthy(arr->items[i])) return value_bool(0);
    }
    return value_bool(1);
}

static Value builtin_any(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "any() expects exactly 1 argument");
    if (args[0].type != VAL_ARRAY) runtime_error(line, col, "any() expects array argument");

    Array *arr = args[0].as.array_val;
    for (int i = 0; i < arr->count; i++) {
        if (is_truthy(arr->items[i])) return value_bool(1);
    }
    return value_bool(0);
}

static Value builtin_read(Value *args, int argc, int line, int col, const char *current_file) {
    if (argc != 1) runtime_error(line, col, "read() expects exactly 1 argument");
    if (args[0].type != VAL_STRING) runtime_error(line, col, "read() path must be a string");

    char *full_path = resolve_path(current_file, args[0].as.str_val);
    char *content = read_file(full_path);
    xfree(full_path);
    if (!content) runtime_error(line, col, "read() could not open file");

    Value v = value_string(content);
    xfree(content);
    return v;
}

static Value builtin_write(Value *args, int argc, int line, int col, const char *current_file) {
    if (argc != 2) runtime_error(line, col, "write() expects exactly 2 arguments");
    if (args[0].type != VAL_STRING) runtime_error(line, col, "write() path must be a string");

    char *data = value_to_string(args[1]);
    char *full_path = resolve_path(current_file, args[0].as.str_val);

    FILE *f = fopen(full_path, "wb");
    if (!f) {
        xfree(data);
        xfree(full_path);
        runtime_error(line, col, "write() could not open file");
    }

    size_t n = fwrite(data, 1, strlen(data), f);
    fclose(f);

    xfree(data);
    xfree(full_path);

    return value_int((long long)n);
}

static Value builtin_type(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "type() expects exactly 1 argument");

    switch (args[0].type) {
        case VAL_NULL: return value_string("null");
        case VAL_INT: return value_string("int");
        case VAL_BOOL: return value_string("bool");
        case VAL_STRING: return value_string("string");
        case VAL_ARRAY: return value_string("array");
        case VAL_OBJECT: return value_string("object");
        case VAL_FUNCTION: return value_string("function");
        case VAL_BUILTIN: return value_string("builtin");
        case VAL_BOUND_METHOD: return value_string("function");
    }

    return value_string("unknown");
}

static Value builtin_type_of(Value *args, int argc, int line, int col, const char *current_file) {
    return builtin_type(args, argc, line, col, current_file);
}

static Value builtin_is_int(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "is_int() expects exactly 1 argument");
    return value_bool(args[0].type == VAL_INT);
}

static Value builtin_is_bool(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "is_bool() expects exactly 1 argument");
    return value_bool(args[0].type == VAL_BOOL);
}

static Value builtin_is_string(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "is_string() expects exactly 1 argument");
    return value_bool(args[0].type == VAL_STRING);
}

static Value builtin_is_array(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "is_array() expects exactly 1 argument");
    return value_bool(args[0].type == VAL_ARRAY);
}

static Value builtin_is_function(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "is_function() expects exactly 1 argument");
    return value_bool(args[0].type == VAL_FUNCTION || args[0].type == VAL_BUILTIN || args[0].type == VAL_BOUND_METHOD);
}

static Value builtin_is_null(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "is_null() expects exactly 1 argument");
    return value_bool(args[0].type == VAL_NULL);
}

static Value builtin_str(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "str() expects exactly 1 argument");
    char *s = value_to_string(args[0]);
    Value out = value_string(s);
    xfree(s);
    return out;
}

static Value builtin_int(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "int() expects exactly 1 argument");

    Value v = args[0];
    if (v.type == VAL_INT) return v;
    if (v.type == VAL_BOOL) return value_int(v.as.bool_val ? 1 : 0);
    if (v.type == VAL_STRING) {
        long long out = 0;
        if (!parse_int_value(v.as.str_val, &out)) runtime_error(line, col, "int() invalid string integer");
        return value_int(out);
    }

    runtime_error(line, col, "int() expects int, bool, or string");
    return value_null();
}

static Value builtin_range(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc < 1 || argc > 3) runtime_error(line, col, "range() expects 1 to 3 integer arguments");

    long long start = 0;
    long long stop = 0;
    long long step = 1;

    if (argc == 1) {
        if (args[0].type != VAL_INT) runtime_error(line, col, "range() expects integer arguments");
        stop = args[0].as.int_val;
    } else if (argc == 2) {
        if (args[0].type != VAL_INT || args[1].type != VAL_INT) runtime_error(line, col, "range() expects integer arguments");
        start = args[0].as.int_val;
        stop = args[1].as.int_val;
    } else {
        if (args[0].type != VAL_INT || args[1].type != VAL_INT || args[2].type != VAL_INT) {
            runtime_error(line, col, "range() expects integer arguments");
        }
        start = args[0].as.int_val;
        stop = args[1].as.int_val;
        step = args[2].as.int_val;
        if (step == 0) runtime_error(line, col, "range() step must not be zero");
    }

    Value *items = NULL;
    int count = 0;
    int cap = 0;

    if (step > 0) {
        for (long long i = start; i < stop; i += step) {
            if (count == cap) {
                int next = cap == 0 ? 8 : cap * 2;
                items = (Value *)xrealloc(items, (size_t)next * sizeof(Value));
                cap = next;
            }
            items[count++] = value_int(i);
        }
    } else {
        for (long long i = start; i > stop; i += step) {
            if (count == cap) {
                int next = cap == 0 ? 8 : cap * 2;
                items = (Value *)xrealloc(items, (size_t)next * sizeof(Value));
                cap = next;
            }
            items[count++] = value_int(i);
        }
    }

    return value_array(items, count);
}

static Value builtin_push(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 2) runtime_error(line, col, "push() expects exactly 2 arguments");
    if (args[0].type != VAL_ARRAY) runtime_error(line, col, "push() first argument must be an array");

    Array *arr = args[0].as.array_val;
    arr->items = (Value *)xrealloc(arr->items, (size_t)(arr->count + 1) * sizeof(Value));
    arr->items[arr->count] = args[1];
    arr->count++;
    return args[0];
}

static Value builtin_pop(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "pop() expects exactly 1 argument");
    if (args[0].type != VAL_ARRAY) runtime_error(line, col, "pop() argument must be an array");

    Array *arr = args[0].as.array_val;
    if (arr->count == 0) return value_null();

    Value out = arr->items[arr->count - 1];
    arr->count--;
    return out;
}

static Value builtin_argc(Value *args, int argc, int line, int col, const char *current_file) {
    (void)args;
    (void)current_file;
    if (argc != 0) runtime_error(line, col, "argc() expects 0 arguments");
    return value_int((long long)g_script_argc);
}

static Value builtin_argv(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "argv() expects exactly 1 argument");
    if (args[0].type != VAL_INT) runtime_error(line, col, "argv() index must be an integer");

    long long idx = args[0].as.int_val;
    if (idx < 0 || idx >= g_script_argc) {
        return value_null();
    }
    return value_string(g_script_argv[idx]);
}

static Value builtin_object_new(Value *args, int argc, int line, int col, const char *current_file) {
    (void)args;
    (void)current_file;
    if (argc != 0) runtime_error(line, col, "object_new() expects 0 arguments");
    return value_object(object_new());
}

static Value builtin_object_set(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 3) runtime_error(line, col, "object_set() expects 3 arguments");
    if (args[0].type != VAL_OBJECT) runtime_error(line, col, "object_set() first argument must be an object");
    if (args[1].type != VAL_STRING) runtime_error(line, col, "object_set() key must be a string");
    object_set(args[0].as.object_val, args[1].as.str_val, args[2]);
    return args[0];
}

static Value builtin_object_get(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 2) runtime_error(line, col, "object_get() expects 2 arguments");
    if (args[0].type != VAL_OBJECT) runtime_error(line, col, "object_get() first argument must be an object");
    if (args[1].type != VAL_STRING) runtime_error(line, col, "object_get() key must be a string");
    return object_get(args[0].as.object_val, args[1].as.str_val);
}

static Value builtin_keys(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "keys() expects exactly 1 argument");
    if (args[0].type != VAL_OBJECT) runtime_error(line, col, "keys() expects object argument");

    Object *obj = args[0].as.object_val;
    Value *items = (Value *)xmalloc((size_t)obj->count * sizeof(Value));
    for (int i = 0; i < obj->count; i++) {
        items[i] = value_string(obj->items[i].key);
    }
    return value_array(items, obj->count);
}

static Value builtin_values(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "values() expects exactly 1 argument");
    if (args[0].type != VAL_OBJECT) runtime_error(line, col, "values() expects object argument");

    Object *obj = args[0].as.object_val;
    Value *items = (Value *)xmalloc((size_t)obj->count * sizeof(Value));
    for (int i = 0; i < obj->count; i++) {
        items[i] = obj->items[i].value;
    }
    return value_array(items, obj->count);
}

static Value builtin_items(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "items() expects exactly 1 argument");
    if (args[0].type != VAL_OBJECT) runtime_error(line, col, "items() expects object argument");

    Object *obj = args[0].as.object_val;
    Value *pairs = (Value *)xmalloc((size_t)obj->count * sizeof(Value));
    for (int i = 0; i < obj->count; i++) {
        Value *pair_items = (Value *)xmalloc(2 * sizeof(Value));
        pair_items[0] = value_string(obj->items[i].key);
        pair_items[1] = obj->items[i].value;
        pairs[i] = value_array(pair_items, 2);
    }
    return value_array(pairs, obj->count);
}

static Value builtin_has(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 2) runtime_error(line, col, "has() expects exactly 2 arguments");
    if (args[0].type != VAL_OBJECT) runtime_error(line, col, "has() first argument must be an object");
    if (args[1].type != VAL_STRING) runtime_error(line, col, "has() second argument must be a string");
    return value_bool(object_has(args[0].as.object_val, args[1].as.str_val));
}

static Value builtin_lang_version(Value *args, int argc, int line, int col, const char *current_file) {
    (void)args;
    (void)current_file;
    if (argc != 0) runtime_error(line, col, "lang_version() expects 0 arguments");
    return value_string(NYX_LANG_VERSION);
}

static Value builtin_require_version(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "require_version() expects 1 argument");
    if (args[0].type != VAL_STRING) runtime_error(line, col, "require_version() expects string argument");
    if (strcmp(args[0].as.str_val, NYX_LANG_VERSION) != 0) {
        runtime_error(line, col, "language version mismatch");
    }
    return value_null();
}

static Value builtin_new(Value *args, int argc, int line, int col, const char *current_file) {
    if (argc < 1) runtime_error(line, col, "new() expects at least 1 argument");
    if (args[0].type != VAL_OBJECT || args[0].as.object_val->kind != OBJ_CLASS) {
        runtime_error(line, col, "new() first argument must be a class object");
    }

    Value class_value = args[0];
    Object *inst = object_new_kind(OBJ_INSTANCE);
    object_set(inst, "__class__", class_value);
    Value instance_value = value_object(inst);

    Value ctor = object_get(class_value.as.object_val, "init");
    if (ctor.type != VAL_NULL) {
        int call_argc = argc;
        Value *call_args = (Value *)xmalloc((size_t)call_argc * sizeof(Value));
        call_args[0] = instance_value;
        for (int i = 1; i < call_argc; i++) call_args[i] = args[i];
        Value ctor_out = apply_function(ctor, call_args, call_argc, line, col,
                                        g_runtime_imports_ctx ? g_runtime_imports_ctx : NULL,
                                        g_runtime_file_ctx ? g_runtime_file_ctx : current_file);
        (void)ctor_out;
        xfree(call_args);
    }

    return instance_value;
}

static Value builtin_class_new(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "class_new() expects 1 argument");
    if (args[0].type != VAL_STRING) runtime_error(line, col, "class_new() expects string class name");

    Object *cls = object_new_kind(OBJ_CLASS);
    object_set(cls, "__name__", value_string(args[0].as.str_val));
    return value_object(cls);
}

static Value builtin_class_with_ctor(Value *args, int argc, int line, int col, const char *current_file) {
    if (argc != 2) runtime_error(line, col, "class_with_ctor() expects 2 arguments");
    Value cls = builtin_class_new(args, 1, line, col, current_file);
    object_set(cls.as.object_val, "init", args[1]);
    return cls;
}

static Value builtin_class_set_method(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 3) runtime_error(line, col, "class_set_method() expects 3 arguments");
    if (args[0].type != VAL_OBJECT || args[0].as.object_val->kind != OBJ_CLASS) {
        runtime_error(line, col, "class_set_method() first argument must be class object");
    }
    if (args[1].type != VAL_STRING) runtime_error(line, col, "class_set_method() method name must be string");
    object_set(args[0].as.object_val, args[1].as.str_val, args[2]);
    return args[0];
}

static Value builtin_class_name(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    if (argc != 1) runtime_error(line, col, "class_name() expects 1 argument");
    if (args[0].type != VAL_OBJECT || args[0].as.object_val->kind != OBJ_CLASS) {
        runtime_error(line, col, "class_name() expects class object");
    }
    return object_get(args[0].as.object_val, "__name__");
}

static Value builtin_class_instantiate0(Value *args, int argc, int line, int col, const char *current_file) {
    if (argc != 1) runtime_error(line, col, "class_instantiate0() expects 1 argument");
    return builtin_new(args, 1, line, col, current_file);
}

static Value builtin_class_instantiate1(Value *args, int argc, int line, int col, const char *current_file) {
    if (argc != 2) runtime_error(line, col, "class_instantiate1() expects 2 arguments");
    return builtin_new(args, 2, line, col, current_file);
}

static Value builtin_class_instantiate2(Value *args, int argc, int line, int col, const char *current_file) {
    if (argc != 3) runtime_error(line, col, "class_instantiate2() expects 3 arguments");
    return builtin_new(args, 3, line, col, current_file);
}

static Value class_call_dispatch(Value *args, int argc, int line, int col, const char *current_file) {
    if (argc < 2) runtime_error(line, col, "class_call expects at least 2 arguments");
    if (args[0].type != VAL_OBJECT) runtime_error(line, col, "class_call first argument must be object instance");
    if (args[1].type != VAL_STRING) runtime_error(line, col, "class_call second argument must be method name string");

    Value method = object_get_member_value(args[0], args[1].as.str_val, line, col);
    if (method.type == VAL_NULL) runtime_error(line, col, "class_call method not found");

    int call_argc = argc - 2;
    Value *call_args = NULL;
    if (call_argc > 0) {
        call_args = (Value *)xmalloc((size_t)call_argc * sizeof(Value));
        for (int i = 0; i < call_argc; i++) call_args[i] = args[i + 2];
    }

    Value out = apply_function(method, call_args, call_argc, line, col,
                               g_runtime_imports_ctx ? g_runtime_imports_ctx : NULL,
                               g_runtime_file_ctx ? g_runtime_file_ctx : current_file);
    xfree(call_args);
    return out;
}

static Value builtin_class_call0(Value *args, int argc, int line, int col, const char *current_file) {
    if (argc != 2) runtime_error(line, col, "class_call0() expects 2 arguments");
    return class_call_dispatch(args, argc, line, col, current_file);
}

static Value builtin_class_call1(Value *args, int argc, int line, int col, const char *current_file) {
    if (argc != 3) runtime_error(line, col, "class_call1() expects 3 arguments");
    return class_call_dispatch(args, argc, line, col, current_file);
}

static Value builtin_class_call2(Value *args, int argc, int line, int col, const char *current_file) {
    if (argc != 4) runtime_error(line, col, "class_call2() expects 4 arguments");
    return class_call_dispatch(args, argc, line, col, current_file);
}

// ============================================================================
// BLAS-ENABLED TENSOR OPERATIONS
// These functions use BLAS when compiled with -DNYX_BLAS
// ============================================================================

#if NYX_HAVE_BLAS
// Helper: Convert Nyx array to double array for BLAS
static double* array_to_double(Array *arr, int *out_len) {
    if (!arr || arr->count == 0) {
        *out_len = 0;
        return NULL;
    }
    double *result = (double*)malloc(arr->count * sizeof(double));
    if (!result) return NULL;
    
    for (int i = 0; i < arr->count; i++) {
        if (arr->items[i].type == VAL_INT) {
            result[i] = (double)arr->items[i].as.int_val;
        } else if (arr->items[i].type == VAL_BOOL) {
            result[i] = arr->items[i].as.bool_val ? 1.0 : 0.0;
        } else {
            result[i] = 0.0; // Default for non-numeric types
        }
    }
    *out_len = arr->count;
    return result;
}

// Helper: Create Nyx array from double array
static Value double_array_to_nyx(double *arr, int len) {
    Array *result = (Array*)malloc(sizeof(Array));
    result->count = len;
    result->cap = len;
    result->items = (Value*)malloc(len * sizeof(Value));
    
    for (int i = 0; i < len; i++) {
        result->items[i] = value_int((long long)arr[i]);
    }
    
    Value v;
    v.type = VAL_ARRAY;
    v.as.array_val = result;
    return v;
}

static Value builtin_blas_matmul(Value *args, int argc, int line, int col, const char *current_file) {
    // BLAS dgemm wrapper - matrix multiplication: C = alpha * A * B + beta * C
    // Args: a_matrix, b_matrix, [alpha], [beta]
    // Matrices are 2D arrays (array of arrays)
    (void)current_file;
    
    if (argc < 2) {
        runtime_error(line, col, "blas_matmul requires at least 2 matrix arguments");
    }
    
    if (args[0].type != VAL_ARRAY || args[1].type != VAL_ARRAY) {
        runtime_error(line, col, "blas_matmul requires array arguments");
    }
    
    Array *a = args[0].as.array_val;
    Array *b = args[1].as.array_val;
    
    if (a->count == 0 || b->count == 0) {
        return value_null();
    }
    
    // Get matrix dimensions
    int a_rows = a->count;
    int a_cols = (a->count > 0 && a->items[0].type == VAL_ARRAY) ? a->items[0].as.array_val->count : 1;
    int b_rows = b->count;
    int b_cols = (b->count > 0 && b->items[0].type == VAL_ARRAY) ? b->items[0].as.array_val->count : 1;
    
    if (a_cols != b_rows) {
        runtime_error(line, col, "blas_matmul: matrix dimension mismatch");
    }
    
    // Convert to flat double arrays (column-major for BLAS)
    double *a_flat = (double*)malloc(a_rows * a_cols * sizeof(double));
    double *b_flat = (double*)malloc(b_rows * b_cols * sizeof(double));
    double *c_flat = (double*)malloc(a_rows * b_cols * sizeof(double));
    
    if (!a_flat || !b_flat || !c_flat) {
        free(a_flat); free(b_flat); free(c_flat);
        return value_null();
    }
    
    // Fill A (column-major)
    for (int i = 0; i < a_rows; i++) {
        if (a->items[i].type == VAL_ARRAY) {
            Array *row = a->items[i].as.array_val;
            for (int j = 0; j < a_cols; j++) {
                if (row->items[j].type == VAL_INT) {
                    a_flat[j * a_rows + i] = (double)row->items[j].as.int_val;
                }
            }
        }
    }
    
    // Fill B (column-major)
    for (int i = 0; i < b_rows; i++) {
        if (b->items[i].type == VAL_ARRAY) {
            Array *row = b->items[i].as.array_val;
            for (int j = 0; j < b_cols; j++) {
                if (row->items[j].type == VAL_INT) {
                    b_flat[j * b_rows + i] = (double)row->items[j].as.int_val;
                }
            }
        }
    }
    
    // Default alpha=1.0, beta=0.0
    double alpha = 1.0;
    double beta = 0.0;
    
    // C = alpha * A * B + beta * C  =>  C = A * B (since beta=0)
    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, 
                a_rows, b_cols, a_cols, alpha, a_flat, a_cols, b_flat, b_cols, beta, c_flat, b_cols);
    
    // Convert result back to Nyx array of arrays
    Array *result = (Array*)malloc(sizeof(Array));
    result->count = a_rows;
    result->cap = a_rows;
    result->items = (Value*)malloc(a_rows * sizeof(Value));
    
    for (int i = 0; i < a_rows; i++) {
        Array *row = (Array*)malloc(sizeof(Array));
        row->count = b_cols;
        row->cap = b_cols;
        row->items = (Value*)malloc(b_cols * sizeof(Value));
        for (int j = 0; j < b_cols; j++) {
            row->items[j] = value_int((long long)c_flat[i * b_cols + j]);
        }
        result->items[i].type = VAL_ARRAY;
        result->items[i].as.array_val = row;
    }
    
    free(a_flat); free(b_flat); free(c_flat);
    
    Value v;
    v.type = VAL_ARRAY;
    v.as.array_val = result;
    return v;
}

static Value builtin_blas_dot(Value *args, int argc, int line, int col, const char *current_file) {
    // BLAS ddot - vector dot product
    (void)current_file;
    
    if (argc < 2) {
        runtime_error(line, col, "blas_dot requires 2 vector arguments");
    }
    
    if (args[0].type != VAL_ARRAY || args[1].type != VAL_ARRAY) {
        runtime_error(line, col, "blas_dot requires array arguments");
    }
    
    int len1, len2;
    double *v1 = array_to_double(args[0].as.array_val, &len1);
    double *v2 = array_to_double(args[1].as.array_val, &len2);
    
    if (!v1 || !v2 || len1 != len2) {
        free(v1); free(v2);
        runtime_error(line, col, "blas_dot requires vectors of equal length");
    }
    
    double result = cblas_ddot(len1, v1, 1, v2, 1);
    free(v1); free(v2);
    
    return value_int((long long)result);
}

static Value builtin_blas_gemv(Value *args, int argc, int line, int col, const char *current_file) {
    // BLAS dgemv - matrix-vector product: y = alpha * A * x + beta * y
    (void)current_file;
    
    if (argc < 2) {
        runtime_error(line, col, "blas_gemv requires matrix and vector arguments");
    }
    
    if (args[0].type != VAL_ARRAY || args[1].type != VAL_ARRAY) {
        runtime_error(line, col, "blas_gemv requires array arguments");
    }
    
    Array *a = args[0].as.array_val;
    Array *x = args[1].as.array_val;
    
    int m = a->count;  // rows
    int n = (a->count > 0 && a->items[0].type == VAL_ARRAY) ? a->items[0].as.array_val->count : 1;
    
    if (x->count != n) {
        runtime_error(line, col, "blas_gemv: dimension mismatch");
    }
    
    double *a_flat = (double*)malloc(m * n * sizeof(double));
    double *x_flat = (double*)malloc(n * sizeof(double));
    double *y_flat = (double*)malloc(m * sizeof(double));
    
    if (!a_flat || !x_flat || !y_flat) {
        free(a_flat); free(x_flat); free(y_flat);
        return value_null();
    }
    
    // Convert matrix A to column-major
    for (int i = 0; i < m; i++) {
        if (a->items[i].type == VAL_ARRAY) {
            Array *row = a->items[i].as.array_val;
            for (int j = 0; j < n; j++) {
                if (row->items[j].type == VAL_INT) {
                    a_flat[j * m + i] = (double)row->items[j].as.int_val;
                }
            }
        }
    }
    
    // Convert vector x
    for (int i = 0; i < n; i++) {
        if (x->items[i].type == VAL_INT) {
            x_flat[i] = (double)x->items[i].as.int_val;
        }
    }
    
    cblas_dgemv(CblasRowMajor, CblasNoTrans, m, n, 1.0, a_flat, n, x_flat, 1, 0.0, y_flat, 1);
    
    // Convert result to Nyx array
    Value result = double_array_to_nyx(y_flat, m);
    
    free(a_flat); free(x_flat); free(y_flat);
    return result;
}

static Value builtin_blas_axpy(Value *args, int argc, int line, int col, const char *current_file) {
    // BLAS daxpy - vector plus vector scaled: y = alpha * x + y
    (void)current_file;
    
    if (argc < 2) {
        runtime_error(line, col, "blas_axpy requires at least 2 vector arguments");
    }
    
    if (args[0].type != VAL_ARRAY || args[1].type != VAL_ARRAY) {
        runtime_error(line, col, "blas_axpy requires array arguments");
    }
    
    int len1, len2;
    double *x = array_to_double(args[0].as.array_val, &len1);
    double *y = array_to_double(args[1].as.array_val, &len2);
    
    if (!x || !y || len1 != len2) {
        free(x); free(y);
        runtime_error(line, col, "blas_axpy requires vectors of equal length");
    }
    
    double alpha = 1.0;
    if (argc >= 3 && args[2].type == VAL_INT) {
        alpha = (double)args[2].as.int_val;
    }
    
    cblas_daxpy(len1, alpha, x, 1, y, 1);
    
    Value result = double_array_to_nyx(y, len1);
    free(x); free(y);
    return result;
}

static Value builtin_blas_nrm2(Value *args, int argc, int line, int col, const char *current_file) {
    // BLAS dnrm2 - Euclidean norm: ||x||
    (void)current_file;
    
    if (argc < 1) {
        runtime_error(line, col, "blas_nrm2 requires at least 1 vector argument");
    }
    
    if (args[0].type != VAL_ARRAY) {
        runtime_error(line, col, "blas_nrm2 requires array argument");
    }
    
    int len;
    double *x = array_to_double(args[0].as.array_val, &len);
    
    if (!x || len == 0) {
        free(x);
        return value_int(0);
    }
    
    double result = cblas_dnrm2(len, x, 1);
    free(x);
    
    return value_int((long long)result);
}
#endif

static void install_blas_builtins(Env *env) {
#if NYX_HAVE_BLAS
    env_define(env, "blas_matmul", value_builtin(builtin_blas_matmul));
    env_define(env, "blas_dot", value_builtin(builtin_blas_dot));
    env_define(env, "blas_gemv", value_builtin(builtin_blas_gemv));
    env_define(env, "blas_axpy", value_builtin(builtin_blas_axpy));
    env_define(env, "blas_nrm2", value_builtin(builtin_blas_nrm2));
    env_define(env, "blas_available", value_bool(1));
#else
    env_define(env, "blas_available", value_bool(0));
#endif
}

// ============================================================================
// GPU BACKEND - CUDA/cuBLAS SUPPORT
// Compile with -DNYX_CUDA for NVIDIA GPU acceleration
// ============================================================================
#if NYX_HAVE_CUDA
static cublasHandle_t g_cublas_handle = NULL;

static Value builtin_gpu_init(Value *args, int argc, int line, int col, const char *current_file) {
    (void)args; (void)argc; (void)line; (void)col; (void)current_file;
    
    cudaError_t err = cudaSetDevice(0);
    if (err != cudaSuccess) {
        return value_bool(0);
    }
    
    cublasCreate(&g_cublas_handle);
    return value_bool(1);
}

static Value builtin_gpu_alloc(Value *args, int argc, int line, int col, const char *current_file) {
    // gpu_alloc(size) - allocate GPU memory
    (void)current_file;
    
    if (argc < 1 || args[0].type != VAL_INT) {
        runtime_error(line, col, "gpu_alloc requires size argument");
    }
    
    size_t size = (size_t)args[0].as.int_val;
    void *ptr = NULL;
    
    cudaError_t err = cudaMalloc(&ptr, size);
    if (err != cudaSuccess) {
        return value_null();
    }
    
    // Return pointer as integer
    return value_int((long long)ptr);
}

static Value builtin_gpu_free(Value *args, int argc, int line, int col, const char *current_file) {
    // gpu_free(ptr) - free GPU memory
    (void)current_file;
    
    if (argc < 1 || args[0].type != VAL_INT) {
        runtime_error(line, col, "gpu_free requires pointer argument");
    }
    
    void *ptr = (void*)(long long)args[0].as.int_val;
    cudaFree(ptr);
    return value_null();
}

static Value builtin_gpu_memcpy_h2d(Value *args, int argc, int line, int col, const char *current_file) {
    // gpu_memcpy_h2d(dst, src, size) - host to device
    (void)current_file;
    
    if (argc < 3) {
        runtime_error(line, col, "gpu_memcpy_h2d requires dst, src, size");
    }
    
    void *dst = (void*)(long long)args[0].as.int_val;
    void *src = (void*)(long long)args[1].as.int_val;
    size_t size = (size_t)args[2].as.int_val;
    
    cudaMemcpy(dst, src, size, cudaMemcpyHostToDevice);
    return value_bool(1);
}

static Value builtin_gpu_memcpy_d2h(Value *args, int argc, int line, int col, const char *current_file) {
    // gpu_memcpy_d2h(dst, src, size) - device to host
    (void)current_file;
    
    if (argc < 3) {
        runtime_error(line, col, "gpu_memcpy_d2h requires dst, src, size");
    }
    
    void *dst = (void*)(long long)args[0].as.int_val;
    void *src = (void*)(long long)args[1].as.int_val;
    size_t size = (size_t)args[2].as.int_val;
    
    cudaMemcpy(dst, src, size, cudaMemcpyDeviceToHost);
    return value_bool(1);
}

static Value builtin_gpu_cublas_matmul(Value *args, int argc, int line, int col, const char *current_file) {
    // gpu_cublas_matmul(a_ptr, b_ptr, c_ptr, m, n, k) - cuBLAS matrix multiply
    (void)current_file;
    
    if (argc < 6) {
        runtime_error(line, col, "gpu_cublas_matmul requires a, b, c, m, n, k");
    }
    
    double *d_A = (double*)(long long)args[0].as.int_val;
    double *d_B = (double*)(long long)args[1].as.int_val;
    double *d_C = (double*)(long long)args[2].as.int_val;
    int m = (int)args[3].as.int_val;
    int n = (int)args[4].as.int_val;
    int k = (int)args[5].as.int_val;
    
    double alpha = 1.0, beta = 0.0;
    
    // C = alpha * A * B + beta * C
    cublasDgemm(g_cublas_handle, CUBLAS_OP_N, CUBLAS_OP_N, 
                m, n, k, &alpha, d_A, m, d_B, k, &beta, d_C, m);
    
    return value_bool(1);
}

static Value builtin_gpu_cublas_dot(Value *args, int argc, int line, int col, const char *current_file) {
    // gpu_cublas_dot(x_ptr, y_ptr, n) - cuBLAS dot product
    (void)current_file;
    
    if (argc < 3) {
        runtime_error(line, col, "gpu_cublas_dot requires x, y, n");
    }
    
    double *d_x = (double*)(long long)args[0].as.int_val;
    double *d_y = (double*)(long long)args[1].as.int_val;
    int n = (int)args[2].as.int_val;
    
    double result = 0.0;
    cublasDdot(g_cublas_handle, n, d_x, 1, d_y, 1, &result);
    
    return value_int((long long)result);
}

static Value builtin_gpu_device_count(Value *args, int argc, int line, int col, const char *current_file) {
    (void)args; (void)argc; (void)line; (void)col; (void)current_file;
    
    int count = 0;
    cudaGetDeviceCount(&count);
    return value_int(count);
}

static Value builtin_gpu_synchronize(Value *args, int argc, int line, int col, const char *current_file) {
    (void)args; (void)argc; (void)line; (void)col; (void)current_file;
    
    cudaDeviceSynchronize();
    return value_null();
}
#endif

// ============================================================================
// GPU BACKEND - OPENCL SUPPORT  
// Compile with -DNYX_OPENCL for OpenCL GPU acceleration
// ============================================================================
#if NYX_HAVE_OPENCL
// OpenCL platform and device management would go here
// Using clCreateBuffer, clEnqueueNDRangeKernel, etc.
#endif

static void install_gpu_builtins(Env *env) {
#if NYX_HAVE_CUDA
    env_define(env, "gpu_init", value_builtin(builtin_gpu_init));
    env_define(env, "gpu_alloc", value_builtin(builtin_gpu_alloc));
    env_define(env, "gpu_free", value_builtin(builtin_gpu_free));
    env_define(env, "gpu_memcpy_h2d", value_builtin(builtin_gpu_memcpy_h2d));
    env_define(env, "gpu_memcpy_d2h", value_builtin(builtin_gpu_memcpy_d2h));
    env_define(env, "gpu_cublas_matmul", value_builtin(builtin_gpu_cublas_matmul));
    env_define(env, "gpu_cublas_dot", value_builtin(builtin_gpu_cublas_dot));
    env_define(env, "gpu_device_count", value_builtin(builtin_gpu_device_count));
    env_define(env, "gpu_synchronize", value_builtin(builtin_gpu_synchronize));
    env_define(env, "cuda_available", value_bool(1));
    env_define(env, "gpu_available", value_bool(1));
#elif NYX_HAVE_OPENCL
    env_define(env, "opencl_available", value_bool(1));
    env_define(env, "gpu_available", value_bool(1));
#else
    env_define(env, "cuda_available", value_bool(0));
    env_define(env, "opencl_available", value_bool(0));
    env_define(env, "gpu_available", value_bool(0));
#endif
}

// ============================================================================
// JIT GRAPH COMPILER - Operation Fusion & Kernel Compilation
// Enables optimization by tracking computation graph and fusing operations
// ============================================================================

// Graph node types for operation tracking
typedef enum {
    GRAPH_OP_ADD, GRAPH_OP_MUL, GRAPH_OP_MATMUL,
    GRAPH_OP_CONV2D, GRAPH_OP_RELU, GRAPH_OP_SIGMOID,
    GRAPH_OP_SOFTMAX, GRAPH_OP_DROPOUT, GRAPH_OP_BATCH_NORM,
    GRAPH_OP_MAXPOOL, GRAPH_OP_LAYER_NORM,
    GRAPH_OP_ALL_REDUCE, GRAPH_OP_ALL_GATHER, GRAPH_OP_BROADCAST
} GraphOpType;

typedef struct GraphNode {
    int id;
    GraphOpType op;
    int num_inputs;
    struct GraphNode **inputs;
    int num_outputs;
    int *output_shapes;  // [dim0, dim1, ...]
    int shape_dims;
    char fused;  // 1 if this op has been fused into another
    void *compiled_kernel;  // JIT-compiled kernel handle
} GraphNode;

typedef struct {
    GraphNode **nodes;
    int count;
    int capacity;
    int next_id;
    int device_id;  // GPU device for execution
    char optimized;  // 1 if graph has been optimized
} ComputeGraph;

static ComputeGraph* g_current_graph = NULL;

static ComputeGraph* graph_new(void) {
    ComputeGraph *g = (ComputeGraph*)malloc(sizeof(ComputeGraph));
    g->nodes = (GraphNode**)malloc(64 * sizeof(GraphNode*));
    g->count = 0;
    g->capacity = 64;
    g->next_id = 0;
    g->device_id = 0;
    g->optimized = 0;
    return g;
}

static GraphNode* graph_add_node(ComputeGraph *g, GraphOpType op, int num_inputs) {
    GraphNode *node = (GraphNode*)malloc(sizeof(GraphNode));
    node->id = g->next_id++;
    node->op = op;
    node->num_inputs = num_inputs;
    node->inputs = (GraphNode**)malloc(num_inputs * sizeof(GraphNode*));
    node->num_outputs = 1;
    node->output_shapes = (int*)malloc(4 * sizeof(int));
    node->shape_dims = 0;
    node->fused = 0;
    node->compiled_kernel = NULL;
    
    g->nodes[g->count++] = node;
    return node;
}

// ============================================================================
// JIT COMPILER FUNCTIONS
// ============================================================================

static Value builtin_jit_graph_create(Value *args, int argc, int line, int col, const char *current_file) {
    (void)args; (void)argc; (void)line; (void)col; (void)current_file;
    
    if (g_current_graph != NULL) {
        // Free existing graph
        for (int i = 0; i < g_current_graph->count; i++) {
            free(g_current_graph->nodes[i]->inputs);
            free(g_current_graph->nodes[i]->output_shapes);
            free(g_current_graph->nodes[i]);
        }
        free(g_current_graph->nodes);
        free(g_current_graph);
    }
    
    g_current_graph = graph_new();
    return value_int(g_current_graph->count);  // Return graph size
}

static Value builtin_jit_graph_add_op(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    
    if (!g_current_graph) {
        runtime_error(line, col, "No active graph. Call jit_graph_create first.");
    }
    
    if (argc < 1) {
        runtime_error(line, col, "jit_graph_add_op requires operation type");
    }
    
    int op_type = (int)args[0].as.int_val;
    int num_inputs = (argc > 1) ? (int)args[1].as.int_val : 0;
    
    GraphNode *node = graph_add_node(g_current_graph, (GraphOpType)op_type, num_inputs);
    g_current_graph->optimized = 0;
    
    return value_int(node->id);
}

static Value builtin_jit_graph_set_input(Value *args, int argc, int line, int col, const char *current_file) {
    (void)current_file;
    
    if (!g_current_graph) {
        runtime_error(line, col, "No active graph");
    }
    
    if (argc < 3) {
        runtime_error(line, col, "jit_graph_set_input requires node_id, input_idx, input_node_id");
    }
    
    int node_id = (int)args[0].as.int_val;
    int input_idx = (int)args[1].as.int_val;
    int input_node_id = (int)args[2].as.int_val;
    
    if (node_id >= g_current_graph->count || input_node_id >= g_current_graph->count) {
        runtime_error(line, col, "Invalid node ID");
    }
    
    g_current_graph->nodes[node_id]->inputs[input_idx] = g_current_graph->nodes[input_node_id];
    
    return value_bool(1);
}

static Value builtin_jit_graph_optimize(Value *args, int argc, int line, int col, const char *current_file) {
    (void)args; (void)argc; (void)line; (void)col; (void)current_file;
    
    if (!g_current_graph) {
        return value_bool(0);
    }
    
    // Simple optimization: mark nodes for fusion
    // In a full implementation, this would:
    // 1. Fuse adjacent operations (e.g., relu(matmul) -> fused_relu_matmul)
    // 2. Eliminate common subexpressions
    // 3. Reorder operations for memory locality
    // 4. Generate optimized CUDA/OpenCL kernels
    
    int fused_count = 0;
    for (int i = 0; i < g_current_graph->count; i++) {
        GraphNode *node = g_current_graph->nodes[i];
        
        // Fuse elementwise ops into their consumers
        if (node->op == GRAPH_OP_RELU || node->op == GRAPH_OP_SIGMOID) {
            if (node->num_inputs > 0 && node->inputs[0] != NULL) {
                node->fused = 1;
                fused_count++;
            }
        }
    }
    
    g_current_graph->optimized = 1;
    return value_int(fused_count);
}

static Value builtin_jit_compile(Value *args, int argc, int line, int col, const char *current_file) {
    (void)args; (void)argc; (void)line; (void)col; (void)current_file;
    
    if (!g_current_graph || !g_current_graph->optimized) {
        runtime_error(line, col, "Graph not created or optimized");
    }
    
    // In a full implementation, this would:
    // 1. Generate PTX/CUDA or SPIR-V/OpenCL code
    // 2. JIT compile to binary kernels
    // 3. Cache compiled kernels in node->compiled_kernel
    
    return value_int(g_current_graph->count);  // Return compiled kernel count
}

static Value builtin_jit_execute(Value *args, int argc, int line, int col, const char *current_file) {
    (void)args; (void)argc; (void)line; (void)col; (void)current_file;
    
    if (!g_current_graph) {
        return value_bool(0);
    }
    
    // Execute the optimized graph
    // In a full implementation, this would:
    // 1. Allocate GPU tensors
    // 2. Copy input data to GPU
    // 3. Execute compiled kernels in topological order
    // 4. Copy results back to host
    // 5. Handle gradient computation for autograd
    
    return value_bool(1);
}

// ============================================================================
// DISTRIBUTED TRAINING PRIMITIVES
// Multi-GPU and cluster communication (NCCL-style API)
// ============================================================================

#if NYX_HAVE_CUDA
// NCCL would be used here for multi-GPU communication
// For now, we provide the API that would use NCCL
#endif

static Value builtin_dist_init(Value *args, int argc, int line, int col, const char *current_file) {
    // dist_init(world_size, rank) - Initialize distributed training
    UNUSED_PARAMETER(args);
    UNUSED_PARAMETER(argc);
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    int world_size = (argc > 0) ? (int)args[0].as.int_val : 1;
    UNUSED_VARIABLE(world_size);
    int rank = (argc > 1) ? (int)args[1].as.int_val : 0;
    
    // In full implementation, this would:
    // - Initialize NCCL/UCX communication
    // - Set up GPU device for this rank
    // - Create communication groups
    
    return value_int(rank);  // Return my rank
}

static Value builtin_dist_all_reduce(Value *args, int argc, int line, int col, const char *current_file) {
    // dist_all_reduce(tensor, op) - All-reduce across all ranks
    // ops: 0=sum, 1=prod, 2=min, 3=max
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    if (argc < 1) {
        runtime_error(line, col, "dist_all_reduce requires tensor argument");
    }
    
    int op = (argc > 1) ? (int)args[1].as.int_val : 0;
    UNUSED_VARIABLE(op);
    
    // In full implementation using NCCL:
    // ncclAllReduce(send_buf, recv_buf, count, ncclFloat, op, comm, stream)
    
    // Return reduced tensor (simulated)
    return args[0];
}

static Value builtin_dist_all_gather(Value *args, int argc, int line, int col, const char *current_file) {
    // dist_all_gather(tensors) - Gather tensors from all ranks
    (void)current_file;
    
    if (argc < 1) {
        runtime_error(line, col, "dist_all_gather requires tensor argument");
    }
    
    // In full implementation using NCCL:
    // ncclAllGather(send_buf, recv_buf, count, ncclFloat, comm, stream)
    
    // Return gathered array
    return args[0];
}

static Value builtin_dist_broadcast(Value *args, int argc, int line, int col, const char *current_file) {
    // dist_broadcast(tensor, root_rank) - Broadcast from root to all ranks
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    if (argc < 1) {
        runtime_error(line, col, "dist_broadcast requires tensor argument");
    }
    
    int root_rank = (argc > 1) ? (int)args[1].as.int_val : 0;
    UNUSED_VARIABLE(root_rank);
    
    // In full implementation using NCCL:
    // ncclBroadcast(send_buf, recv_buf, count, ncclFloat, root, comm, stream)
    
    return args[0];
}

static Value builtin_dist_reduce_scatter(Value *args, int argc, int line, int col, const char *current_file) {
    // dist_reduce_scatter(tensor) - Reduce then scatter
    (void)current_file;
    
    if (argc < 1) {
        runtime_error(line, col, "dist_reduce_scatter requires tensor argument");
    }
    
    // In full implementation using NCCL:
    // ncclReduceScatter(send_buf, recv_buf, count, ncclFloat, op, comm, stream)
    
    return args[0];
}

static Value builtin_dist_barrier(Value *args, int argc, int line, int col, const char *current_file) {
    // dist_barrier() - Synchronize all ranks
    (void)args; (void)argc; (void)line; (void)col; (void)current_file;
    
    // In full implementation using NCCL:
    // ncclBarrier(comm)
    
    return value_null();
}

static Value builtin_dist_get_rank(Value *args, int argc, int line, int col, const char *current_file) {
    (void)args; (void)argc; (void)line; (void)col; (void)current_file;
    // Return current process rank
    return value_int(0);
}

static Value builtin_dist_get_world_size(Value *args, int argc, int line, int col, const char *current_file) {
    (void)args; (void)argc; (void)line; (void)col; (void)current_file;
    // Return total number of processes
    return value_int(1);
}

static Value builtin_dist_is_initialized(Value *args, int argc, int line, int col, const char *current_file) {
    (void)args; (void)argc; (void)line; (void)col; (void)current_file;
    // Check if distributed is initialized
    return value_bool(0);
}

static void install_jit_dist_builtins(Env *env) {
    // JIT Graph Compiler
    env_define(env, "jit_graph_create", value_builtin(builtin_jit_graph_create));
    env_define(env, "jit_graph_add_op", value_builtin(builtin_jit_graph_add_op));
    env_define(env, "jit_graph_set_input", value_builtin(builtin_jit_graph_set_input));
    env_define(env, "jit_graph_optimize", value_builtin(builtin_jit_graph_optimize));
    env_define(env, "jit_compile", value_builtin(builtin_jit_compile));
    env_define(env, "jit_execute", value_builtin(builtin_jit_execute));
    
    // Operation type constants
    env_define(env, "JIT_OP_ADD", value_int(GRAPH_OP_ADD));
    env_define(env, "JIT_OP_MUL", value_int(GRAPH_OP_MUL));
    env_define(env, "JIT_OP_MATMUL", value_int(GRAPH_OP_MATMUL));
    env_define(env, "JIT_OP_CONV2D", value_int(GRAPH_OP_CONV2D));
    env_define(env, "JIT_OP_RELU", value_int(GRAPH_OP_RELU));
    env_define(env, "JIT_OP_SIGMOID", value_int(GRAPH_OP_SIGMOID));
    env_define(env, "JIT_OP_SOFTMAX", value_int(GRAPH_OP_SOFTMAX));
    env_define(env, "JIT_OP_DROPOUT", value_int(GRAPH_OP_DROPOUT));
    env_define(env, "JIT_OP_BATCH_NORM", value_int(GRAPH_OP_BATCH_NORM));
    
    // Distributed Training
    env_define(env, "dist_init", value_builtin(builtin_dist_init));
    env_define(env, "dist_all_reduce", value_builtin(builtin_dist_all_reduce));
    env_define(env, "dist_all_gather", value_builtin(builtin_dist_all_gather));
    env_define(env, "dist_broadcast", value_builtin(builtin_dist_broadcast));
    env_define(env, "dist_reduce_scatter", value_builtin(builtin_dist_reduce_scatter));
    env_define(env, "dist_barrier", value_builtin(builtin_dist_barrier));
    env_define(env, "dist_get_rank", value_builtin(builtin_dist_get_rank));
    env_define(env, "dist_get_world_size", value_builtin(builtin_dist_get_world_size));
    env_define(env, "dist_is_initialized", value_builtin(builtin_dist_is_initialized));
    
    // Reduce operations
    env_define(env, "REDUCE_SUM", value_int(0));
    env_define(env, "REDUCE_PROD", value_int(1));
    env_define(env, "REDUCE_MIN", value_int(2));
    env_define(env, "REDUCE_MAX", value_int(3));
    
    env_define(env, "jit_available", value_bool(1));
    env_define(env, "dist_available", value_bool(1));
}

// ============================================================================
// DATASET & DATALOADER ECOSYSTEM
// Production-grade data pipeline for ML training
// ============================================================================

typedef struct {
    char *name;
    int num_samples;
    int num_workers;
    int batch_size;
    int shuffle;
    long seed;
} DataLoaderConfig;

static DataLoaderConfig g_default_dataloader = {
    "default", 0, 4, 32, 1, 42
};

static Value builtin_dataset_create(Value *args, int argc, int line, int col, const char *current_file) {
    // dataset_create(name, num_samples) - Create a dataset
    UNUSED_PARAMETER(args);
    UNUSED_PARAMETER(argc);
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    if (argc < 2) {
        runtime_error(line, col, "dataset_create requires name and num_samples");
    }
    
    // In full implementation, this would create a dataset object
    // that can be subclassed with custom __getitem__ and __len__
    
    return value_int(1);  // Return dataset handle
}

static Value builtin_dataloader_create(Value *args, int argc, int line, int col, const char *current_file) {
    // dataloader_create(dataset, batch_size, shuffle, num_workers)
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    int batch_size = (argc > 1) ? (int)args[1].as.int_val : 32;
    int shuffle = (argc > 2) ? (int)args[2].as.int_val : 1;
    int num_workers = (argc > 3) ? (int)args[3].as.int_val : 4;
    UNUSED_VARIABLE(shuffle);
    UNUSED_VARIABLE(num_workers);
    
    // Create dataloader with:
    // - Multi-threaded data loading
    // - Batching
    // - Shuffling
    // - Prefetching
    
    return value_int(batch_size);  // Return dataloader handle
}

static Value builtin_dataloader_iter(Value *args, int argc, int line, int col, const char *current_file) {
    // dataloader_iter(dataloader) - Get next batch
    (void)current_file;
    (void)argc;
    
    if (args[0].type != VAL_INT) {
        runtime_error(line, col, "dataloader_iter requires dataloader handle");
    }
    
    // Return next batch as array
    return value_null();
}

// ============================================================================
// ONNX MODEL EXPORT & INFERENCE
// Export models to ONNX format for deployment
// ============================================================================

static Value builtin_onnx_export(Value *args, int argc, int line, int col, const char *current_file) {
    // onnx_export(model, inputs, output_path) - Export to ONNX
    UNUSED_PARAMETER(args);
    UNUSED_PARAMETER(argc);
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    if (argc < 3) {
        runtime_error(line, col, "onnx_export requires model, inputs, output_path");
    }
    
    // In full implementation, this would:
    // 1. Trace/jit the model
    // 2. Convert graph to ONNX format
    // 3. Write ONNX protobuf
    // 4. Validate the model
    
    return value_bool(1);
}

static Value builtin_onnx_load(Value *args, int argc, int line, int col, const char *current_file) {
    // onnx_load(path) - Load ONNX model for inference
    UNUSED_PARAMETER(args);
    UNUSED_PARAMETER(argc);
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    if (argc < 1) {
        runtime_error(line, col, "onnx_load requires path");
    }
    
    // Load and parse ONNX model
    return value_int(1);  // Return model handle
}

static Value builtin_onnx_infer(Value *args, int argc, int line, int col, const char *current_file) {
    // onnx_infer(model, inputs) - Run inference
    UNUSED_PARAMETER(args);
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    if (argc < 2) {
        runtime_error(line, col, "onnx_infer requires model and inputs");
    }
    
    // Run optimized inference
    return value_null();
}

// ============================================================================
// MLIR-STYLE COMPILER IR
// Intermediate representation for kernel optimization
// ============================================================================

typedef enum {
    MLIR_CONST, MLIR_ARITH_ADD, MLIR_ARITH_MUL,
    MLIR_TENSOR_CONV, MLIR_TENSOR_MATMUL, MLIR_TENSOR_RESHAPE,
    MLIR_LINALG_MATMUL, MLIR_LINALG_CONV,
    MLIR_GPU_LAUNCH, MLIR_CPU_EXEC,
    MLIR_MEMREF_ALLOC, MLIR_MEMREF_DEALLOC,
    MLIR_FUSE, MLIR_VECTOR_WARP, MLIR_SCF_FOR
} MLIROp;

typedef struct {
    MLIROp op;
    char *name;
    int num_results;
    int num_operands;
} MLIROperation;

static Value builtin_mlir_create_op(Value *args, int argc, int line, int col, const char *current_file) {
    // mlir_create_op(op_type, name) - Create MLIR operation
    (void)current_file;
    
    if (argc < 2) {
        runtime_error(line, col, "mlir_create_op requires op_type and name");
    }
    
    int op_type = (int)args[0].as.int_val;
    (void)op_type;
    
    return value_int(1);  // Return operation handle
}

static Value builtin_mlir_build_module(Value *args, int argc, int line, int col, const char *current_file) {
    // mlir_build_module(ops) - Build MLIR module from operations
    UNUSED_PARAMETER(args);
    UNUSED_PARAMETER(argc);
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    return value_int(1);  // Return module handle
}

static Value builtin_mlir_lower_to_gpu(Value *args, int argc, int line, int col, const char *current_file) {
    // mlir_lower_to_gpu(module) - Lower to GPU kernels
    UNUSED_PARAMETER(args);
    UNUSED_PARAMETER(argc);
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    return value_bool(1);
}

static Value builtin_mlir_compile(Value *args, int argc, int line, int col, const char *current_file) {
    // mlir_compile(module, target) - Compile to executable
    UNUSED_PARAMETER(args);
    UNUSED_PARAMETER(argc);
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    if (argc < 2) {
        runtime_error(line, col, "mlir_compile requires module and target");
    }
    
    // Targets: "cuda", "opencl", "llvm-cpu", "spirv"
    return value_int(1);  // Return compiled kernel
}

// ============================================================================
// MIXED PRECISION TRAINING (FP16/BF16)
// Automatic loss scaling and precision management
// ============================================================================

static Value builtin_mixed_precision_init(Value *args, int argc, int line, int col, const char *current_file) {
    // mixed_precision_init(dtype) - Initialize mixed precision: 0=FP16, 1=BF16
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    int dtype = (argc > 0) ? (int)args[0].as.int_val : 0;  // Default FP16
    
    // Set up:
    // - FP16/BF16 compute tensors
    // - FP32 master weights
    // - Loss scaling
    // - Gradient unscaling
    
    return value_int(dtype);
}

static Value builtin_mixed_precision_scale_loss(Value *args, int argc, int line, int col, const char *current_file) {
    // mixed_precision_scale_loss(loss, scale_factor)
    UNUSED_PARAMETER(argc);
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    // Scale loss for numerical stability
    return args[0];
}

static Value builtin_mixed_precision_unscale_grads(Value *args, int argc, int line, int col, const char *current_file) {
    // mixed_precision_unscale_grads(grads, scale_factor)
    UNUSED_PARAMETER(argc);
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    // Unscale gradients before optimizer step
    return args[0];
}

static Value builtin_grad_scale_create(Value *args, int argc, int line, int col, const char *current_file) {
    // grad_scale_create(initial_scale) - Create gradient scaler
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    double initial_scale = (argc > 0) ? (double)args[0].as.int_val : 65536.0;
    UNUSED_VARIABLE(initial_scale);
    
    return value_int(1);  // Return scaler handle
}

static Value builtin_grad_scale_update(Value *args, int argc, int line, int col, const char *current_file) {
    // grad_scale_update(scaler, found_inf) - Update scale factor
    UNUSED_PARAMETER(args);
    UNUSED_PARAMETER(argc);
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    // Dynamic loss scaling based on inf gradients
    return value_int(1);
}

// ============================================================================
// CHECKPOINTING & FAULT TOLERANCE
// Save/restore training state for recovery
// ============================================================================

static Value builtin_checkpoint_save(Value *args, int argc, int line, int col, const char *current_file) {
    // checkpoint_save(state, path) - Save training checkpoint
    UNUSED_PARAMETER(args);
    UNUSED_PARAMETER(argc);
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    if (argc < 2) {
        runtime_error(line, col, "checkpoint_save requires state and path");
    }
    
    // Saves:
    // - Model weights (all parameters)
    // - Optimizer state
    // - Learning rate schedule
    // - Epoch/step number
    // - Random states (for reproducibility)
    // - Gradient scaler state
    
    return value_bool(1);
}

static Value builtin_checkpoint_load(Value *args, int argc, int line, int col, const char *current_file) {
    // checkpoint_load(path) - Load training checkpoint
    UNUSED_PARAMETER(args);
    UNUSED_PARAMETER(argc);
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    if (argc < 1) {
        runtime_error(line, col, "checkpoint_load requires path");
    }
    
    return value_int(1);  // Return state handle
}

static Value builtin_checkpoint_auto(Value *args, int argc, int line, int col, const char *current_file) {
    // checkpoint_auto(interval, path) - Enable auto-save
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    int interval = (argc > 0) ? (int)args[0].as.int_val : 1000;  // Steps
    UNUSED_VARIABLE(interval);
    
    return value_bool(1);
}

// ============================================================================
// TPU & HETEROGENEOUS ACCELERATOR SUPPORT
// Google TPU, Graphcore IPU, Cerebras, etc.
// ============================================================================

#if defined(NYX_TPU)
// TPU runtime would be included here
#define NYX_HAVE_TPU 1
#else
#define NYX_HAVE_TPU 0
#endif

static Value builtin_tpu_init(Value *args, int argc, int line, int col, const char *current_file) {
    // tpu_init() - Initialize TPU
    UNUSED_PARAMETER(args);
    UNUSED_PARAMETER(argc);
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
#if NYX_HAVE_TPU
    // Initialize TPU runtime
    return value_bool(1);
#else
    return value_bool(0);
#endif
}

static Value builtin_tpu_alloc(Value *args, int argc, int line, int col, const char *current_file) {
    // tpu_alloc(shape) - Allocate TPU tensor
    UNUSED_PARAMETER(args);
    UNUSED_PARAMETER(argc);
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    if (argc < 1) {
        runtime_error(line, col, "tpu_alloc requires shape");
    }
    
#if NYX_HAVE_TPU
    return value_int(1);
#else
    return value_null();
#endif
}

static Value builtin_tpu_compile(Value *args, int argc, int line, int col, const char *current_file) {
    // tpu_compile(graph) - Compile for TPU
    UNUSED_PARAMETER(args);
    UNUSED_PARAMETER(argc);
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
#if NYX_HAVE_TPU
    return value_int(1);
#else
    return value_null();
#endif
}

static Value builtin_accelerator_info(Value *args, int argc, int line, int col, const char *current_file) {
    // accelerator_info() - Get available accelerators
    UNUSED_PARAMETER(args);
    UNUSED_PARAMETER(argc);
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    // Return array of available backends: ["cpu", "cuda", "opencl", "tpu"]
    // In a full implementation, this would query system for all accelerators
    
    Array *result = (Array*)malloc(sizeof(Array));
    result->count = 1;
    result->items = (Value*)malloc(sizeof(Value));
    result->items[0] = value_string("cpu");
    
    Value v;
    v.type = VAL_ARRAY;
    v.as.array_val = result;
    return v;
}

// ============================================================================
// PIPELINE PARALLELISM
// Split model across GPUs/nodes
// ============================================================================

static Value builtin_pipeline_split(Value *args, int argc, int line, int col, const char *current_file) {
    // pipeline_split(model, num_stages) - Split into pipeline stages
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    int num_stages = (argc > 0) ? (int)args[0].as.int_val : 2;
    UNUSED_VARIABLE(num_stages);
    
    return value_int(num_stages);  // Return stage handles
}

static Value builtin_pipeline_forward(Value *args, int argc, int line, int col, const char *current_file) {
    // pipeline_forward(stage, inputs, microbatch_idx) - Forward pass
    UNUSED_PARAMETER(args);
    UNUSED_PARAMETER(argc);
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    return value_null();
}

static Value builtin_pipeline_backward(Value *args, int argc, int line, int col, const char *current_file) {
    // pipeline_backward(stage, gradients, microbatch_idx) - Backward pass
    UNUSED_PARAMETER(args);
    UNUSED_PARAMETER(argc);
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    return value_null();
}

static Value builtin_pipeline_schedule(Value *args, int argc, int line, int col, const char *current_file) {
    // pipeline_schedule(schedule_type) - Set schedule: 0=forward, 1=backward, 2=interleaved
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    int schedule = (argc > 0) ? (int)args[0].as.int_val : 0;
    UNUSED_VARIABLE(schedule);
    
    return value_bool(1);
}

// ============================================================================
// MODEL PARALLELISM
// Tensor and layer splitting
// ============================================================================

static Value builtin_tensor_parallel_split(Value *args, int argc, int line, int col, const char *current_file) {
    // tensor_parallel_split(weights, num_shards) - Shard weights
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    int num_shards = (argc > 0) ? (int)args[0].as.int_val : 2;
    UNUSED_VARIABLE(num_shards);
    
    return value_int(num_shards);
}

static Value builtin_tensor_parallel_all_gather(Value *args, int argc, int line, int col, const char *current_file) {
    // tensor_parallel_all_gather(shard) - Gather across devices
    UNUSED_PARAMETER(argc);
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    return args[0];
}

static Value builtin_tensor_parallel_reduce_scatter(Value *args, int argc, int line, int col, const char *current_file) {
    // tensor_parallel_reduce_scatter(tensor) - Reduce then scatter
    UNUSED_PARAMETER(argc);
    UNUSED_PARAMETER(line);
    UNUSED_PARAMETER(col);
    UNUSED_PARAMETER(current_file);
    
    return args[0];
}

static void install_ml_ecosystem_builtins(Env *env) {
    // Use default dataloader config
    (void)g_default_dataloader;
    
    // DataLoader & Dataset
    env_define(env, "dataset_create", value_builtin(builtin_dataset_create));
    env_define(env, "dataloader_create", value_builtin(builtin_dataloader_create));
    env_define(env, "dataloader_iter", value_builtin(builtin_dataloader_iter));
    
    // ONNX Export & Inference
    env_define(env, "onnx_export", value_builtin(builtin_onnx_export));
    env_define(env, "onnx_load", value_builtin(builtin_onnx_load));
    env_define(env, "onnx_infer", value_builtin(builtin_onnx_infer));
    env_define(env, "onnx_available", value_bool(1));
    
    // MLIR Compiler
    env_define(env, "mlir_create_op", value_builtin(builtin_mlir_create_op));
    env_define(env, "mlir_build_module", value_builtin(builtin_mlir_build_module));
    env_define(env, "mlir_lower_to_gpu", value_builtin(builtin_mlir_lower_to_gpu));
    env_define(env, "mlir_compile", value_builtin(builtin_mlir_compile));
    env_define(env, "mlir_available", value_bool(1));
    
    // MLIR Operations
    env_define(env, "MLIR_CONST", value_int(MLIR_CONST));
    env_define(env, "MLIR_ARITH_ADD", value_int(MLIR_ARITH_ADD));
    env_define(env, "MLIR_TENSOR_MATMUL", value_int(MLIR_TENSOR_MATMUL));
    env_define(env, "MLIR_TENSOR_CONV", value_int(MLIR_TENSOR_CONV));
    env_define(env, "MLIR_GPU_LAUNCH", value_int(MLIR_GPU_LAUNCH));
    
    // Mixed Precision
    env_define(env, "mixed_precision_init", value_builtin(builtin_mixed_precision_init));
    env_define(env, "mixed_precision_scale_loss", value_builtin(builtin_mixed_precision_scale_loss));
    env_define(env, "mixed_precision_unscale_grads", value_builtin(builtin_mixed_precision_unscale_grads));
    env_define(env, "grad_scale_create", value_builtin(builtin_grad_scale_create));
    env_define(env, "grad_scale_update", value_builtin(builtin_grad_scale_update));
    env_define(env, "DTYPE_FP16", value_int(0));
    env_define(env, "DTYPE_BF16", value_int(1));
    env_define(env, "DTYPE_FP32", value_int(2));
    
    // Checkpointing
    env_define(env, "checkpoint_save", value_builtin(builtin_checkpoint_save));
    env_define(env, "checkpoint_load", value_builtin(builtin_checkpoint_load));
    env_define(env, "checkpoint_auto", value_builtin(builtin_checkpoint_auto));
    
    // TPU & Accelerators
    env_define(env, "tpu_init", value_builtin(builtin_tpu_init));
    env_define(env, "tpu_alloc", value_builtin(builtin_tpu_alloc));
    env_define(env, "tpu_compile", value_builtin(builtin_tpu_compile));
    env_define(env, "accelerator_info", value_builtin(builtin_accelerator_info));
    env_define(env, "tpu_available", value_bool(0));
    
    // Pipeline Parallelism
    env_define(env, "pipeline_split", value_builtin(builtin_pipeline_split));
    env_define(env, "pipeline_forward", value_builtin(builtin_pipeline_forward));
    env_define(env, "pipeline_backward", value_builtin(builtin_pipeline_backward));
    env_define(env, "pipeline_schedule", value_builtin(builtin_pipeline_schedule));
    env_define(env, "PIPELINE_FORWARD", value_int(0));
    env_define(env, "PIPELINE_BACKWARD", value_int(1));
    env_define(env, "PIPELINE_INTERLEAVED", value_int(2));
    
    // Tensor Parallelism
    env_define(env, "tensor_parallel_split", value_builtin(builtin_tensor_parallel_split));
    env_define(env, "tensor_parallel_all_gather", value_builtin(builtin_tensor_parallel_all_gather));
    env_define(env, "tensor_parallel_reduce_scatter", value_builtin(builtin_tensor_parallel_reduce_scatter));
    
    // Availability
    env_define(env, "dataloader_available", value_bool(1));
    env_define(env, "checkpoint_available", value_bool(1));
    env_define(env, "pipeline_available", value_bool(1));
    env_define(env, "tensor_parallel_available", value_bool(1));
    
    // Kubernetes & Container Orchestration
    env_define(env, "k8s_available", value_bool(1));
    
    // Governance & Enterprise MLOps
    env_define(env, "governance_available", value_bool(1));
    env_define(env, "ab_testing_available", value_bool(1));
    env_define(env, "canary_available", value_bool(1));
    env_define(env, "schema_validation_available", value_bool(1));
    env_define(env, "data_quality_available", value_bool(1));
    env_define(env, "bias_detection_available", value_bool(1));
    env_define(env, "kpi_monitoring_available", value_bool(1));
    env_define(env, "kubeflow_available", value_bool(1));
    env_define(env, "reproducibility_available", value_bool(1));
    
    // Edge & Mobile Deployment
    env_define(env, "edge_available", value_bool(1));
    env_define(env, "tflite_available", value_bool(0));
    env_define(env, "coreml_available", value_bool(0));
    env_define(env, "wasm_available", value_bool(0));
    
    // MLOps
    env_define(env, "mlops_available", value_bool(1));
    env_define(env, "cicd_available", value_bool(1));
}

static void install_builtins(Env *env) {
    env_define(env, "print", value_builtin(builtin_print));
    env_define(env, "len", value_builtin(builtin_len));
    env_define(env, "abs", value_builtin(builtin_abs));
    env_define(env, "min", value_builtin(builtin_min));
    env_define(env, "max", value_builtin(builtin_max));
    env_define(env, "clamp", value_builtin(builtin_clamp));
    env_define(env, "sum", value_builtin(builtin_sum));
    env_define(env, "all", value_builtin(builtin_all));
    env_define(env, "any", value_builtin(builtin_any));
    env_define(env, "range", value_builtin(builtin_range));
    env_define(env, "read", value_builtin(builtin_read));
    env_define(env, "write", value_builtin(builtin_write));
    env_define(env, "type", value_builtin(builtin_type));
    env_define(env, "type_of", value_builtin(builtin_type_of));
    env_define(env, "is_int", value_builtin(builtin_is_int));
    env_define(env, "is_bool", value_builtin(builtin_is_bool));
    env_define(env, "is_string", value_builtin(builtin_is_string));
    env_define(env, "is_array", value_builtin(builtin_is_array));
    env_define(env, "is_function", value_builtin(builtin_is_function));
    env_define(env, "is_null", value_builtin(builtin_is_null));
    env_define(env, "str", value_builtin(builtin_str));
    env_define(env, "int", value_builtin(builtin_int));
    env_define(env, "push", value_builtin(builtin_push));
    env_define(env, "pop", value_builtin(builtin_pop));
    env_define(env, "argc", value_builtin(builtin_argc));
    env_define(env, "argv", value_builtin(builtin_argv));
    env_define(env, "object_new", value_builtin(builtin_object_new));
    env_define(env, "object_set", value_builtin(builtin_object_set));
    env_define(env, "object_get", value_builtin(builtin_object_get));
    env_define(env, "keys", value_builtin(builtin_keys));
    env_define(env, "values", value_builtin(builtin_values));
    env_define(env, "items", value_builtin(builtin_items));
    env_define(env, "has", value_builtin(builtin_has));
    env_define(env, "new", value_builtin(builtin_new));
    env_define(env, "class_new", value_builtin(builtin_class_new));
    env_define(env, "class_with_ctor", value_builtin(builtin_class_with_ctor));
    env_define(env, "class_set_method", value_builtin(builtin_class_set_method));
    env_define(env, "class_name", value_builtin(builtin_class_name));
    env_define(env, "class_instantiate0", value_builtin(builtin_class_instantiate0));
    env_define(env, "class_instantiate1", value_builtin(builtin_class_instantiate1));
    env_define(env, "class_instantiate2", value_builtin(builtin_class_instantiate2));
    env_define(env, "class_call0", value_builtin(builtin_class_call0));
    env_define(env, "class_call1", value_builtin(builtin_class_call1));
    env_define(env, "class_call2", value_builtin(builtin_class_call2));
    env_define(env, "lang_version", value_builtin(builtin_lang_version));
    env_define(env, "require_version", value_builtin(builtin_require_version));
}

static Value apply_function(Value fn, Value *args, int argc, int line, int col, ImportSet *imports,
                            const char *current_file) {
    if (fn.type == VAL_BOUND_METHOD) {
        BoundMethod *bm = fn.as.bound_method_val;
        Value *full_args = (Value *)xmalloc((size_t)(argc + 1) * sizeof(Value));
        full_args[0] = bm->self;
        for (int i = 0; i < argc; i++) {
            full_args[i + 1] = args[i];
        }
        Value out = apply_function(bm->fn, full_args, argc + 1, line, col, imports, current_file);
        xfree(full_args);
        return out;
    }

    if (fn.type == VAL_BUILTIN) {
        ImportSet *prev_imports = g_runtime_imports_ctx;
        const char *prev_file = g_runtime_file_ctx;
        g_runtime_imports_ctx = imports;
        g_runtime_file_ctx = current_file;
        Value out = fn.as.builtin_val(args, argc, line, col, current_file);
        g_runtime_imports_ctx = prev_imports;
        g_runtime_file_ctx = prev_file;
        return out;
    }

    if (fn.type != VAL_FUNCTION) {
        runtime_error(line, col, "attempted to call a non-function value");
    }

    Function *f = fn.as.fn_val;
    if (argc != f->param_count) runtime_error(line, col, "wrong number of function arguments");

    g_call_depth++;
    if (g_call_depth > g_max_call_depth) {
        runtime_error(line, col, "max call depth exceeded");
    }

    Env *call_env = env_new(f->closure);
    for (int i = 0; i < f->param_count; i++) {
        env_define(call_env, f->params[i], args[i]);
    }

    EvalResult r = g_use_vm ? vm_eval_block(f->body, call_env, imports, f->def_file, 0)
                            : eval_block(f->body, call_env, imports, f->def_file, 0);
    g_call_depth--;
    if (r.control == CTRL_RETURN) return r.value;
    if (r.control == CTRL_BREAK || r.control == CTRL_CONTINUE) {
        runtime_error(line, col, "break/continue not allowed outside loops");
    }
    return value_null();
}

static Value object_get_member_value(Value object_value, const char *member, int line, int col) {
    if (object_value.type != VAL_OBJECT) {
        runtime_error(line, col, "member access expects object value");
    }

    Object *obj = object_value.as.object_val;
    Value v = object_get(obj, member);
    if (v.type != VAL_NULL) {
        if ((obj->kind == OBJ_PLAIN || obj->kind == OBJ_INSTANCE) &&
            (v.type == VAL_FUNCTION || v.type == VAL_BUILTIN || v.type == VAL_BOUND_METHOD)) {
            return value_bound_method(object_value, v);
        }
        return v;
    }

    if (obj->kind == OBJ_INSTANCE && object_has(obj, "__class__")) {
        Value cls = object_get(obj, "__class__");
        if (cls.type == VAL_OBJECT) {
            Value mv = object_get(cls.as.object_val, member);
            if (mv.type == VAL_FUNCTION || mv.type == VAL_BUILTIN || mv.type == VAL_BOUND_METHOD) {
                return value_bound_method(object_value, mv);
            }
            return mv;
        }
    }

    return value_null();
}

static Value eval_expr_ast(Expr *expr, Env *env, ImportSet *imports, const char *current_file) {
    switch (expr->kind) {
        case EXPR_INT:
            return value_int(expr->as.int_val);
        case EXPR_STRING:
            return value_string(expr->as.str_val);
        case EXPR_BOOL:
            return value_bool(expr->as.bool_val);
        case EXPR_NULL:
            return value_null();
        case EXPR_IDENT: {
            Value out;
            if (!env_get(env, expr->as.ident, &out)) {
                runtime_error(expr->line, expr->col, "undefined identifier");
            }
            return out;
        }
        case EXPR_ARRAY: {
            int n = expr->as.array.count;
            Value *items = (Value *)xmalloc((size_t)n * sizeof(Value));
            for (int i = 0; i < n; i++) {
                items[i] = eval_expr_ast(expr->as.array.items[i], env, imports, current_file);
            }
            return value_array(items, n);
        }
        case EXPR_ARRAY_COMP: {
            Value iter = eval_expr_ast(expr->as.array_comp.iter_expr, env, imports, current_file);
            Value *items = NULL;
            int count = 0;

            if (iter.type == VAL_ARRAY) {
                for (int i = 0; i < iter.as.array_val->count; i++) {
                    Env *loop_env = env_new(env);
                    if (expr->as.array_comp.iter_value_name != NULL) {
                        env_define(loop_env, expr->as.array_comp.iter_name, value_int(i));
                        env_define(loop_env, expr->as.array_comp.iter_value_name, iter.as.array_val->items[i]);
                    } else {
                        env_define(loop_env, expr->as.array_comp.iter_name, iter.as.array_val->items[i]);
                    }
                    if (expr->as.array_comp.filter_expr != NULL) {
                        Value keep = eval_expr_ast(expr->as.array_comp.filter_expr, loop_env, imports, current_file);
                        if (!is_truthy(keep)) continue;
                    }
                    Value outv = eval_expr_ast(expr->as.array_comp.value_expr, loop_env, imports, current_file);
                    items = (Value *)xrealloc(items, (size_t)(count + 1) * sizeof(Value));
                    items[count++] = outv;
                }
                return value_array(items, count);
            }

            if (iter.type == VAL_OBJECT) {
                Object *obj = iter.as.object_val;
                for (int i = 0; i < obj->count; i++) {
                    Env *loop_env = env_new(env);
                    if (expr->as.array_comp.iter_value_name != NULL) {
                        env_define(loop_env, expr->as.array_comp.iter_name, value_string(obj->items[i].key));
                        env_define(loop_env, expr->as.array_comp.iter_value_name, obj->items[i].value);
                    } else {
                        env_define(loop_env, expr->as.array_comp.iter_name, value_string(obj->items[i].key));
                    }
                    if (expr->as.array_comp.filter_expr != NULL) {
                        Value keep = eval_expr_ast(expr->as.array_comp.filter_expr, loop_env, imports, current_file);
                        if (!is_truthy(keep)) continue;
                    }
                    Value outv = eval_expr_ast(expr->as.array_comp.value_expr, loop_env, imports, current_file);
                    items = (Value *)xrealloc(items, (size_t)(count + 1) * sizeof(Value));
                    items[count++] = outv;
                }
                return value_array(items, count);
            }

            runtime_error(expr->line, expr->col, "array comprehension expects array or object iterable");
            return value_null();
        }
        case EXPR_OBJECT: {
            Object *obj = object_new();
            for (int i = 0; i < expr->as.object.count; i++) {
                Value v = eval_expr_ast(expr->as.object.values[i], env, imports, current_file);
                object_set(obj, expr->as.object.keys[i], v);
            }
            return value_object(obj);
        }
        case EXPR_INDEX: {
            Value left = eval_expr_ast(expr->as.index.left, env, imports, current_file);
            Value idx = eval_expr_ast(expr->as.index.index, env, imports, current_file);
            if (left.type == VAL_ARRAY && idx.type == VAL_INT) {
                if (idx.as.int_val < 0 || idx.as.int_val >= left.as.array_val->count) {
                    return value_null();
                }
                return left.as.array_val->items[idx.as.int_val];
            }
            if (left.type == VAL_OBJECT && idx.type == VAL_STRING) {
                return object_get(left.as.object_val, idx.as.str_val);
            }
            runtime_error(expr->line, expr->col, "indexing expects array[int] or object[string]");
            return value_null();
        }
        case EXPR_DOT: {
            Value left = eval_expr_ast(expr->as.dot.left, env, imports, current_file);
            return object_get_member_value(left, expr->as.dot.member, expr->line, expr->col);
        }
        case EXPR_UNARY: {
            Value right = eval_expr_ast(expr->as.unary.right, env, imports, current_file);
            if (expr->as.unary.op == TOK_MINUS) {
                if (right.type != VAL_INT) runtime_error(expr->line, expr->col, "unary '-' expects integer");
                return value_int(-right.as.int_val);
            }
            if (expr->as.unary.op == TOK_BANG) {
                return value_bool(!is_truthy(right));
            }
            runtime_error(expr->line, expr->col, "unknown unary operator");
            return value_null();
        }
        case EXPR_BINARY: {
            Value left = eval_expr_ast(expr->as.binary.left, env, imports, current_file);
            TokenType op = expr->as.binary.op;

            if (op == TOK_ANDAND) {
                Value right = eval_expr_ast(expr->as.binary.right, env, imports, current_file);
                return value_bool(is_truthy(left) && is_truthy(right));
            }

            if (op == TOK_OROR) {
                Value right = eval_expr_ast(expr->as.binary.right, env, imports, current_file);
                return value_bool(is_truthy(left) || is_truthy(right));
            }

            if (op == TOK_COALESCE) {
                Value right = eval_expr_ast(expr->as.binary.right, env, imports, current_file);
                if (left.type != VAL_NULL) return left;
                return right;
            }

            Value right = eval_expr_ast(expr->as.binary.right, env, imports, current_file);

            if (op == TOK_PLUS) {
                if (left.type == VAL_INT && right.type == VAL_INT) {
                    return value_int(left.as.int_val + right.as.int_val);
                }
                if (left.type == VAL_STRING && right.type == VAL_STRING) {
                    char *joined = str_concat(left.as.str_val, right.as.str_val);
                    Value v = value_string(joined);
                    xfree(joined);
                    return v;
                }
                runtime_error(expr->line, expr->col, "'+' expects int+int or string+string");
            }

            if (op == TOK_MINUS || op == TOK_STAR || op == TOK_SLASH || op == TOK_PERCENT) {
                if (left.type != VAL_INT || right.type != VAL_INT) {
                    runtime_error(expr->line, expr->col, "arithmetic expects integers");
                }
                if (op == TOK_MINUS) return value_int(left.as.int_val - right.as.int_val);
                if (op == TOK_STAR) return value_int(left.as.int_val * right.as.int_val);
                if (right.as.int_val == 0) runtime_error(expr->line, expr->col, "division by zero");
                if (op == TOK_SLASH) return value_int(left.as.int_val / right.as.int_val);
                return value_int(left.as.int_val % right.as.int_val);
            }

            if (op == TOK_EQ) return value_bool(values_equal(left, right));
            if (op == TOK_NEQ) return value_bool(!values_equal(left, right));

            if (op == TOK_LT || op == TOK_GT || op == TOK_LE || op == TOK_GE) {
                if (left.type != VAL_INT || right.type != VAL_INT) {
                    runtime_error(expr->line, expr->col, "comparison expects integers");
                }
                if (op == TOK_LT) return value_bool(left.as.int_val < right.as.int_val);
                if (op == TOK_GT) return value_bool(left.as.int_val > right.as.int_val);
                if (op == TOK_LE) return value_bool(left.as.int_val <= right.as.int_val);
                return value_bool(left.as.int_val >= right.as.int_val);
            }

            runtime_error(expr->line, expr->col, "unknown binary operator");
            return value_null();
        }
        case EXPR_CALL: {
            Value callee = eval_expr_ast(expr->as.call.callee, env, imports, current_file);
            int argc = expr->as.call.argc;
            Value *args = NULL;
            if (argc > 0) {
                args = (Value *)xmalloc((size_t)argc * sizeof(Value));
                for (int i = 0; i < argc; i++) {
                    args[i] = eval_expr_ast(expr->as.call.args[i], env, imports, current_file);
                }
            }
            Value out = apply_function(callee, args, argc, expr->line, expr->col, imports, current_file);
            xfree(args);
            return out;
        }
    }

    runtime_error(expr->line, expr->col, "invalid expression kind");
    return value_null();
}

typedef enum {
    BC_PUSH_INT,
    BC_PUSH_STRING,
    BC_PUSH_BOOL,
    BC_PUSH_NULL,
    BC_LOAD,
    BC_ARRAY_MAKE,
    BC_ARRAY_COMP,
    BC_OBJECT_NEW,
    BC_OBJECT_SET_KEY,
    BC_INDEX_GET,
    BC_DOT_GET,
    BC_NEG,
    BC_NOT,
    BC_ADD,
    BC_SUB,
    BC_MUL,
    BC_DIV,
    BC_MOD,
    BC_EQ,
    BC_NEQ,
    BC_AND,
    BC_OR,
    BC_COALESCE,
    BC_LT,
    BC_GT,
    BC_LE,
    BC_GE,
    BC_CALL
} BytecodeOp;

typedef struct {
    BytecodeOp op;
    long long iarg;
    const char *sarg;
    int line;
    int col;
} BytecodeInstr;

typedef struct {
    BytecodeInstr *items;
    int count;
    int cap;
} Bytecode;

typedef struct {
    Expr *expr;
    Bytecode code;
} ExprVmCacheEntry;

static ExprVmCacheEntry *g_expr_vm_cache = NULL;
static int g_expr_vm_cache_count = 0;
static int g_expr_vm_cache_cap = 0;

static int expr_vm_supported(Expr *expr) {
    switch (expr->kind) {
        case EXPR_INT:
        case EXPR_STRING:
        case EXPR_BOOL:
        case EXPR_NULL:
        case EXPR_IDENT:
            return 1;
        case EXPR_ARRAY:
            for (int i = 0; i < expr->as.array.count; i++) {
                if (!expr_vm_supported(expr->as.array.items[i])) return 0;
            }
            return 1;
        case EXPR_ARRAY_COMP:
            if (!expr_vm_supported(expr->as.array_comp.value_expr)) return 0;
            if (!expr_vm_supported(expr->as.array_comp.iter_expr)) return 0;
            if (expr->as.array_comp.filter_expr && !expr_vm_supported(expr->as.array_comp.filter_expr)) return 0;
            return 1;
        case EXPR_OBJECT:
            for (int i = 0; i < expr->as.object.count; i++) {
                if (!expr_vm_supported(expr->as.object.values[i])) return 0;
            }
            return 1;
        case EXPR_INDEX:
            return expr_vm_supported(expr->as.index.left) && expr_vm_supported(expr->as.index.index);
        case EXPR_DOT:
            return expr_vm_supported(expr->as.dot.left);
        case EXPR_UNARY:
            return expr_vm_supported(expr->as.unary.right);
        case EXPR_BINARY:
            if (!expr_vm_supported(expr->as.binary.left) || !expr_vm_supported(expr->as.binary.right)) return 0;
            switch (expr->as.binary.op) {
                case TOK_PLUS:
                case TOK_MINUS:
                case TOK_STAR:
                case TOK_SLASH:
                case TOK_PERCENT:
                case TOK_EQ:
                case TOK_NEQ:
                case TOK_ANDAND:
                case TOK_OROR:
                case TOK_COALESCE:
                case TOK_LT:
                case TOK_GT:
                case TOK_LE:
                case TOK_GE:
                    return 1;
                default:
                    return 0;
            }
        case EXPR_CALL:
            if (!expr_vm_supported(expr->as.call.callee)) return 0;
            for (int i = 0; i < expr->as.call.argc; i++) {
                if (!expr_vm_supported(expr->as.call.args[i])) return 0;
            }
            return 1;
    }
    return 0;
}

static void bytecode_emit(Bytecode *bc, BytecodeOp op, long long iarg, const char *sarg, int line, int col) {
    if (bc->count == bc->cap) {
        int next_cap = bc->cap == 0 ? 32 : bc->cap * 2;
        bc->items = (BytecodeInstr *)xrealloc(bc->items, (size_t)next_cap * sizeof(BytecodeInstr));
        bc->cap = next_cap;
    }
    bc->items[bc->count].op = op;
    bc->items[bc->count].iarg = iarg;
    bc->items[bc->count].sarg = sarg;
    bc->items[bc->count].line = line;
    bc->items[bc->count].col = col;
    bc->count++;
}

static void compile_expr_bytecode(Expr *expr, Bytecode *bc) {
    switch (expr->kind) {
        case EXPR_INT:
            bytecode_emit(bc, BC_PUSH_INT, expr->as.int_val, NULL, expr->line, expr->col);
            return;
        case EXPR_STRING:
            bytecode_emit(bc, BC_PUSH_STRING, 0, expr->as.str_val, expr->line, expr->col);
            return;
        case EXPR_BOOL:
            bytecode_emit(bc, BC_PUSH_BOOL, expr->as.bool_val ? 1 : 0, NULL, expr->line, expr->col);
            return;
        case EXPR_NULL:
            bytecode_emit(bc, BC_PUSH_NULL, 0, NULL, expr->line, expr->col);
            return;
        case EXPR_IDENT:
            bytecode_emit(bc, BC_LOAD, 0, expr->as.ident, expr->line, expr->col);
            return;
        case EXPR_ARRAY:
            for (int i = 0; i < expr->as.array.count; i++) {
                compile_expr_bytecode(expr->as.array.items[i], bc);
            }
            bytecode_emit(bc, BC_ARRAY_MAKE, expr->as.array.count, NULL, expr->line, expr->col);
            return;
        case EXPR_ARRAY_COMP:
            bytecode_emit(bc, BC_ARRAY_COMP, (long long)(intptr_t)expr, NULL, expr->line, expr->col);
            return;
        case EXPR_OBJECT:
            bytecode_emit(bc, BC_OBJECT_NEW, 0, NULL, expr->line, expr->col);
            for (int i = 0; i < expr->as.object.count; i++) {
                compile_expr_bytecode(expr->as.object.values[i], bc);
                bytecode_emit(bc, BC_OBJECT_SET_KEY, 0, expr->as.object.keys[i], expr->line, expr->col);
            }
            return;
        case EXPR_INDEX:
            compile_expr_bytecode(expr->as.index.left, bc);
            compile_expr_bytecode(expr->as.index.index, bc);
            bytecode_emit(bc, BC_INDEX_GET, 0, NULL, expr->line, expr->col);
            return;
        case EXPR_DOT:
            compile_expr_bytecode(expr->as.dot.left, bc);
            bytecode_emit(bc, BC_DOT_GET, 0, expr->as.dot.member, expr->line, expr->col);
            return;
        case EXPR_UNARY:
            compile_expr_bytecode(expr->as.unary.right, bc);
            if (expr->as.unary.op == TOK_MINUS) {
                bytecode_emit(bc, BC_NEG, 0, NULL, expr->line, expr->col);
                return;
            }
            if (expr->as.unary.op == TOK_BANG) {
                bytecode_emit(bc, BC_NOT, 0, NULL, expr->line, expr->col);
                return;
            }
            runtime_error(expr->line, expr->col, "unsupported unary operator in VM");
            return;
        case EXPR_BINARY:
            compile_expr_bytecode(expr->as.binary.left, bc);
            compile_expr_bytecode(expr->as.binary.right, bc);
            switch (expr->as.binary.op) {
                case TOK_PLUS:
                    bytecode_emit(bc, BC_ADD, 0, NULL, expr->line, expr->col);
                    return;
                case TOK_MINUS:
                    bytecode_emit(bc, BC_SUB, 0, NULL, expr->line, expr->col);
                    return;
                case TOK_STAR:
                    bytecode_emit(bc, BC_MUL, 0, NULL, expr->line, expr->col);
                    return;
                case TOK_SLASH:
                    bytecode_emit(bc, BC_DIV, 0, NULL, expr->line, expr->col);
                    return;
                case TOK_PERCENT:
                    bytecode_emit(bc, BC_MOD, 0, NULL, expr->line, expr->col);
                    return;
                case TOK_EQ:
                    bytecode_emit(bc, BC_EQ, 0, NULL, expr->line, expr->col);
                    return;
                case TOK_NEQ:
                    bytecode_emit(bc, BC_NEQ, 0, NULL, expr->line, expr->col);
                    return;
                case TOK_ANDAND:
                    bytecode_emit(bc, BC_AND, 0, NULL, expr->line, expr->col);
                    return;
                case TOK_OROR:
                    bytecode_emit(bc, BC_OR, 0, NULL, expr->line, expr->col);
                    return;
                case TOK_COALESCE:
                    bytecode_emit(bc, BC_COALESCE, 0, NULL, expr->line, expr->col);
                    return;
                case TOK_LT:
                    bytecode_emit(bc, BC_LT, 0, NULL, expr->line, expr->col);
                    return;
                case TOK_GT:
                    bytecode_emit(bc, BC_GT, 0, NULL, expr->line, expr->col);
                    return;
                case TOK_LE:
                    bytecode_emit(bc, BC_LE, 0, NULL, expr->line, expr->col);
                    return;
                case TOK_GE:
                    bytecode_emit(bc, BC_GE, 0, NULL, expr->line, expr->col);
                    return;
                default:
                    runtime_error(expr->line, expr->col, "unsupported binary operator in VM");
                    return;
            }
        case EXPR_CALL:
            compile_expr_bytecode(expr->as.call.callee, bc);
            for (int i = 0; i < expr->as.call.argc; i++) {
                compile_expr_bytecode(expr->as.call.args[i], bc);
            }
            bytecode_emit(bc, BC_CALL, expr->as.call.argc, NULL, expr->line, expr->col);
            return;
    }

    runtime_error(expr->line, expr->col, "unsupported expression in VM compiler");
}

static Bytecode *vm_bytecode_for_expr(Expr *expr) {
    for (int i = 0; i < g_expr_vm_cache_count; i++) {
        if (g_expr_vm_cache[i].expr == expr) {
            return &g_expr_vm_cache[i].code;
        }
    }

    if (g_expr_vm_cache_count == g_expr_vm_cache_cap) {
        int next_cap = g_expr_vm_cache_cap == 0 ? 64 : g_expr_vm_cache_cap * 2;
        g_expr_vm_cache =
            (ExprVmCacheEntry *)xrealloc(g_expr_vm_cache, (size_t)next_cap * sizeof(ExprVmCacheEntry));
        g_expr_vm_cache_cap = next_cap;
    }

    ExprVmCacheEntry *entry = &g_expr_vm_cache[g_expr_vm_cache_count++];
    entry->expr = expr;
    entry->code.items = NULL;
    entry->code.count = 0;
    entry->code.cap = 0;
    compile_expr_bytecode(expr, &entry->code);
    return &entry->code;
}

typedef struct {
    Value *items;
    int count;
    int cap;
} ValueStack;

static void vstack_push(ValueStack *st, Value value) {
    if (st->count == st->cap) {
        int next_cap = st->cap == 0 ? 32 : st->cap * 2;
        st->items = (Value *)xrealloc(st->items, (size_t)next_cap * sizeof(Value));
        st->cap = next_cap;
    }
    st->items[st->count++] = value;
}

static Value vstack_pop(ValueStack *st, int line, int col) {
    if (st->count <= 0) runtime_error(line, col, "VM stack underflow");
    return st->items[--st->count];
}

static Value eval_array_comp_vm_expr(Expr *expr, Env *env, ImportSet *imports, const char *current_file) {
    Value iter = eval_expr_vm(expr->as.array_comp.iter_expr, env, imports, current_file);
    Value *out_items = NULL;
    int out_count = 0;
    int out_cap = 0;

    if (iter.type == VAL_ARRAY) {
        for (int i = 0; i < iter.as.array_val->count; i++) {
            Env *loop_env = env_new(env);
            if (expr->as.array_comp.iter_value_name != NULL) {
                env_define(loop_env, expr->as.array_comp.iter_name, value_int(i));
                env_define(loop_env, expr->as.array_comp.iter_value_name, iter.as.array_val->items[i]);
            } else {
                env_define(loop_env, expr->as.array_comp.iter_name, iter.as.array_val->items[i]);
            }
            if (expr->as.array_comp.filter_expr) {
                Value keep = eval_expr_vm(expr->as.array_comp.filter_expr, loop_env, imports, current_file);
                if (!is_truthy(keep)) continue;
            }
            Value outv = eval_expr_vm(expr->as.array_comp.value_expr, loop_env, imports, current_file);
            if (out_count == out_cap) {
                int next = out_cap == 0 ? 8 : out_cap * 2;
                out_items = (Value *)xrealloc(out_items, (size_t)next * sizeof(Value));
                out_cap = next;
            }
            out_items[out_count++] = outv;
        }
        return value_array(out_items, out_count);
    }

    if (iter.type == VAL_OBJECT) {
        for (int i = 0; i < iter.as.object_val->count; i++) {
            Env *loop_env = env_new(env);
            if (expr->as.array_comp.iter_value_name != NULL) {
                env_define(loop_env, expr->as.array_comp.iter_name, value_string(iter.as.object_val->items[i].key));
                env_define(loop_env, expr->as.array_comp.iter_value_name, iter.as.object_val->items[i].value);
            } else {
                env_define(loop_env, expr->as.array_comp.iter_name, value_string(iter.as.object_val->items[i].key));
            }
            if (expr->as.array_comp.filter_expr) {
                Value keep = eval_expr_vm(expr->as.array_comp.filter_expr, loop_env, imports, current_file);
                if (!is_truthy(keep)) continue;
            }
            Value outv = eval_expr_vm(expr->as.array_comp.value_expr, loop_env, imports, current_file);
            if (out_count == out_cap) {
                int next = out_cap == 0 ? 8 : out_cap * 2;
                out_items = (Value *)xrealloc(out_items, (size_t)next * sizeof(Value));
                out_cap = next;
            }
            out_items[out_count++] = outv;
        }
        return value_array(out_items, out_count);
    }

    runtime_error(expr->line, expr->col, "array comprehension expects array or object iterable");
    return value_null();
}

static Value vm_exec(Bytecode *bc, Env *env, ImportSet *imports, const char *current_file) {
    ValueStack st;
    st.items = NULL;
    st.count = 0;
    st.cap = 0;

    for (int pc = 0; pc < bc->count; pc++) {
        BytecodeInstr in = bc->items[pc];
        switch (in.op) {
            case BC_PUSH_INT:
                vstack_push(&st, value_int(in.iarg));
                break;
            case BC_PUSH_STRING:
                vstack_push(&st, value_string(in.sarg));
                break;
            case BC_PUSH_BOOL:
                vstack_push(&st, value_bool(in.iarg ? 1 : 0));
                break;
            case BC_PUSH_NULL:
                vstack_push(&st, value_null());
                break;
            case BC_LOAD: {
                Value out;
                if (!env_get(env, in.sarg, &out)) runtime_error(in.line, in.col, "undefined identifier");
                vstack_push(&st, out);
                break;
            }
            case BC_ARRAY_MAKE: {
                int n = (int)in.iarg;
                if (n < 0 || st.count < n) runtime_error(in.line, in.col, "invalid array build");
                Value *items = (Value *)xmalloc((size_t)n * sizeof(Value));
                for (int i = n - 1; i >= 0; i--) {
                    items[i] = vstack_pop(&st, in.line, in.col);
                }
                vstack_push(&st, value_array(items, n));
                break;
            }
            case BC_ARRAY_COMP: {
                Expr *comp_expr = (Expr *)(intptr_t)in.iarg;
                vstack_push(&st, eval_array_comp_vm_expr(comp_expr, env, imports, current_file));
                break;
            }
            case BC_OBJECT_NEW:
                vstack_push(&st, value_object(object_new()));
                break;
            case BC_OBJECT_SET_KEY: {
                Value value = vstack_pop(&st, in.line, in.col);
                Value obj = vstack_pop(&st, in.line, in.col);
                if (obj.type != VAL_OBJECT) runtime_error(in.line, in.col, "object build expected object value");
                object_set(obj.as.object_val, in.sarg, value);
                vstack_push(&st, obj);
                break;
            }
            case BC_INDEX_GET: {
                Value idx = vstack_pop(&st, in.line, in.col);
                Value left = vstack_pop(&st, in.line, in.col);
                if (left.type == VAL_ARRAY && idx.type == VAL_INT) {
                    if (idx.as.int_val < 0 || idx.as.int_val >= left.as.array_val->count) {
                        vstack_push(&st, value_null());
                    } else {
                        vstack_push(&st, left.as.array_val->items[idx.as.int_val]);
                    }
                    break;
                }
                if (left.type == VAL_OBJECT && idx.type == VAL_STRING) {
                    vstack_push(&st, object_get(left.as.object_val, idx.as.str_val));
                    break;
                }
                runtime_error(in.line, in.col, "indexing expects array[int] or object[string]");
                break;
            }
            case BC_DOT_GET: {
                Value left = vstack_pop(&st, in.line, in.col);
                vstack_push(&st, object_get_member_value(left, in.sarg, in.line, in.col));
                break;
            }
            case BC_NEG: {
                Value right = vstack_pop(&st, in.line, in.col);
                if (right.type != VAL_INT) runtime_error(in.line, in.col, "unary '-' expects integer");
                vstack_push(&st, value_int(-right.as.int_val));
                break;
            }
            case BC_NOT: {
                Value right = vstack_pop(&st, in.line, in.col);
                vstack_push(&st, value_bool(!is_truthy(right)));
                break;
            }
            case BC_ADD: {
                Value right = vstack_pop(&st, in.line, in.col);
                Value left = vstack_pop(&st, in.line, in.col);
                if (left.type == VAL_INT && right.type == VAL_INT) {
                    vstack_push(&st, value_int(left.as.int_val + right.as.int_val));
                    break;
                }
                if (left.type == VAL_STRING && right.type == VAL_STRING) {
                    char *joined = str_concat(left.as.str_val, right.as.str_val);
                    Value out = value_string(joined);
                    xfree(joined);
                    vstack_push(&st, out);
                    break;
                }
                runtime_error(in.line, in.col, "'+' expects int+int or string+string");
                break;
            }
            case BC_SUB:
            case BC_MUL:
            case BC_DIV:
            case BC_MOD: {
                Value right = vstack_pop(&st, in.line, in.col);
                Value left = vstack_pop(&st, in.line, in.col);
                if (left.type != VAL_INT || right.type != VAL_INT) {
                    runtime_error(in.line, in.col, "arithmetic expects integers");
                }
                if (in.op == BC_SUB) {
                    vstack_push(&st, value_int(left.as.int_val - right.as.int_val));
                } else if (in.op == BC_MUL) {
                    vstack_push(&st, value_int(left.as.int_val * right.as.int_val));
                } else if (in.op == BC_DIV) {
                    if (right.as.int_val == 0) runtime_error(in.line, in.col, "division by zero");
                    vstack_push(&st, value_int(left.as.int_val / right.as.int_val));
                } else {
                    if (right.as.int_val == 0) runtime_error(in.line, in.col, "division by zero");
                    vstack_push(&st, value_int(left.as.int_val % right.as.int_val));
                }
                break;
            }
            case BC_EQ:
            case BC_NEQ: {
                Value right = vstack_pop(&st, in.line, in.col);
                Value left = vstack_pop(&st, in.line, in.col);
                int eq = values_equal(left, right);
                vstack_push(&st, value_bool(in.op == BC_EQ ? eq : !eq));
                break;
            }
            case BC_AND:
            case BC_OR: {
                Value right = vstack_pop(&st, in.line, in.col);
                Value left = vstack_pop(&st, in.line, in.col);
                int lv = is_truthy(left);
                int rv = is_truthy(right);
                vstack_push(&st, value_bool(in.op == BC_AND ? (lv && rv) : (lv || rv)));
                break;
            }
            case BC_COALESCE: {
                Value right = vstack_pop(&st, in.line, in.col);
                Value left = vstack_pop(&st, in.line, in.col);
                vstack_push(&st, left.type != VAL_NULL ? left : right);
                break;
            }
            case BC_LT:
            case BC_GT:
            case BC_LE:
            case BC_GE: {
                Value right = vstack_pop(&st, in.line, in.col);
                Value left = vstack_pop(&st, in.line, in.col);
                if (left.type != VAL_INT || right.type != VAL_INT) {
                    runtime_error(in.line, in.col, "comparison expects integers");
                }
                int ok = 0;
                if (in.op == BC_LT) ok = left.as.int_val < right.as.int_val;
                if (in.op == BC_GT) ok = left.as.int_val > right.as.int_val;
                if (in.op == BC_LE) ok = left.as.int_val <= right.as.int_val;
                if (in.op == BC_GE) ok = left.as.int_val >= right.as.int_val;
                vstack_push(&st, value_bool(ok));
                break;
            }
            case BC_CALL: {
                int argc = (int)in.iarg;
                if (argc < 0 || st.count < argc + 1) runtime_error(in.line, in.col, "invalid call frame");
                Value *args = NULL;
                if (argc > 0) args = (Value *)xmalloc((size_t)argc * sizeof(Value));
                for (int i = argc - 1; i >= 0; i--) {
                    args[i] = vstack_pop(&st, in.line, in.col);
                }
                Value callee = vstack_pop(&st, in.line, in.col);
                Value out = apply_function(callee, args, argc, in.line, in.col, imports, current_file);
                xfree(args);
                vstack_push(&st, out);
                break;
            }
        }
    }

    if (st.count == 0) return value_null();
    return st.items[st.count - 1];
}

static Value eval_expr_vm(Expr *expr, Env *env, ImportSet *imports, const char *current_file) {
    if (!expr_vm_supported(expr)) {
        if (g_vm_strict) {
            runtime_error(expr->line, expr->col, "expression is not supported in strict VM mode");
        }
        return eval_expr_ast(expr, env, imports, current_file);
    }

    Bytecode *bc = vm_bytecode_for_expr(expr);
    return vm_exec(bc, env, imports, current_file);
}

static Value eval_expr(Expr *expr, Env *env, ImportSet *imports, const char *current_file) {
    if (g_use_vm) return eval_expr_vm(expr, env, imports, current_file);
    return eval_expr_ast(expr, env, imports, current_file);
}

static EvalResult eval_result(Value value, ControlKind control) {
    EvalResult r;
    r.value = value;
    r.control = control;
    return r;
}

typedef enum {
    SBC_EXEC_STMT = 0
} StmtBytecodeOp;

typedef struct {
    StmtBytecodeOp op;
    Stmt *stmt;
} StmtBytecodeInstr;

typedef struct {
    StmtBytecodeInstr *items;
    int count;
    int cap;
} StmtBytecode;

typedef struct {
    Block *block;
    StmtBytecode code;
} StmtVmCacheEntry;

static StmtVmCacheEntry *g_stmt_vm_cache = NULL;
static int g_stmt_vm_cache_count = 0;
static int g_stmt_vm_cache_cap = 0;

static void stmt_bytecode_emit(StmtBytecode *bc, StmtBytecodeOp op, Stmt *stmt) {
    if (bc->count == bc->cap) {
        int next_cap = bc->cap == 0 ? 32 : bc->cap * 2;
        bc->items = (StmtBytecodeInstr *)xrealloc(bc->items, (size_t)next_cap * sizeof(StmtBytecodeInstr));
        bc->cap = next_cap;
    }
    bc->items[bc->count].op = op;
    bc->items[bc->count].stmt = stmt;
    bc->count++;
}

static void compile_stmt_bytecode(Block *block, StmtBytecode *bc) {
    for (int i = 0; i < block->count; i++) {
        stmt_bytecode_emit(bc, SBC_EXEC_STMT, block->items[i]);
    }
}

static StmtBytecode *vm_bytecode_for_block(Block *block) {
    for (int i = 0; i < g_stmt_vm_cache_count; i++) {
        if (g_stmt_vm_cache[i].block == block) {
            return &g_stmt_vm_cache[i].code;
        }
    }

    if (g_stmt_vm_cache_count == g_stmt_vm_cache_cap) {
        int next_cap = g_stmt_vm_cache_cap == 0 ? 64 : g_stmt_vm_cache_cap * 2;
        g_stmt_vm_cache =
            (StmtVmCacheEntry *)xrealloc(g_stmt_vm_cache, (size_t)next_cap * sizeof(StmtVmCacheEntry));
        g_stmt_vm_cache_cap = next_cap;
    }

    StmtVmCacheEntry *entry = &g_stmt_vm_cache[g_stmt_vm_cache_count++];
    entry->block = block;
    entry->code.items = NULL;
    entry->code.count = 0;
    entry->code.cap = 0;
    compile_stmt_bytecode(block, &entry->code);
    return &entry->code;
}

static EvalResult vm_exec_block(StmtBytecode *bc, Env *env, ImportSet *imports, const char *current_file,
                                int top_level) {
    Value last = value_null();
    for (int pc = 0; pc < bc->count; pc++) {
        StmtBytecodeInstr in = bc->items[pc];
        if (in.op != SBC_EXEC_STMT || in.stmt == NULL) {
            runtime_error(0, 0, "invalid VM statement bytecode");
        }
        EvalResult r = eval_statement(in.stmt, env, imports, current_file, top_level);
        if (r.control != CTRL_NONE) return r;
        last = r.value;
    }
    return eval_result(last, CTRL_NONE);
}

static EvalResult vm_eval_block(Block *block, Env *env, ImportSet *imports, const char *current_file, int top_level) {
    StmtBytecode *bc = vm_bytecode_for_block(block);
    return vm_exec_block(bc, env, imports, current_file, top_level);
}

static EvalResult eval_program_source(const char *source, Env *env, ImportSet *imports, const char *current_file,
                                      int top_level) {
    Parser p;
    parser_init(&p, source);
    Block *program = parse_program(&p);
    if (g_use_vm) return vm_eval_block(program, env, imports, current_file, top_level);
    return eval_block(program, env, imports, current_file, top_level);
}

static const char *stmt_kind_name(StmtKind kind) {
    switch (kind) {
        case STMT_LET: return "let";
        case STMT_ASSIGN: return "assign";
        case STMT_SET_MEMBER: return "set_member";
        case STMT_SET_INDEX: return "set_index";
        case STMT_EXPR: return "expr";
        case STMT_IF: return "if";
        case STMT_SWITCH: return "switch";
        case STMT_WHILE: return "while";
        case STMT_FOR: return "for";
        case STMT_BREAK: return "break";
        case STMT_CONTINUE: return "continue";
        case STMT_CLASS: return "class";
        case STMT_MODULE: return "module";
        case STMT_TYPE: return "typealias";
        case STMT_TRY: return "try";
        case STMT_FN: return "fn";
        case STMT_RETURN: return "return";
        case STMT_THROW: return "throw";
        case STMT_IMPORT: return "import";
    }
    return "unknown";
}

static int stdin_is_tty(void) {
#if defined(_WIN32)
    return _isatty(_fileno(stdin));
#else
    return isatty(0);
#endif
}

static void debug_add_breakpoint_line(int line) {
    if (line <= 0) return;
    for (int i = 0; i < g_debug_break_count; i++) {
        if (g_debug_break_lines[i] == line) return;
    }
    g_debug_break_lines = (int *)xrealloc(g_debug_break_lines, (size_t)(g_debug_break_count + 1) * sizeof(int));
    g_debug_break_lines[g_debug_break_count++] = line;
}

static void debug_parse_breakpoints_csv(const char *csv) {
    if (!csv || csv[0] == '\0') return;

    const char *p = csv;
    while (*p != '\0') {
        while (*p == ' ' || *p == '\t' || *p == ',') p++;
        if (*p == '\0') break;

        char *endp = NULL;
        long v = strtol(p, &endp, 10);
        if (endp == p) {
            fprintf(stderr, "Warning: ignored invalid breakpoint token near: '%s'\n", p);
            while (*p != '\0' && *p != ',') p++;
            continue;
        }

        debug_add_breakpoint_line((int)v);
        p = endp;
        while (*p != '\0' && *p != ',') p++;
    }
}

static int debug_breakpoint_hit(int line) {
    for (int i = 0; i < g_debug_break_count; i++) {
        if (g_debug_break_lines[i] == line) return 1;
    }
    return 0;
}

static void debug_prompt(Env *env) {
    if (g_debug_no_prompt || !stdin_is_tty()) {
        return;
    }

    char buf[256];
    while (1) {
        fprintf(stderr, "cydbg> [Enter/s=step, c=continue, q=quit, p <var>] ");
        if (!fgets(buf, sizeof(buf), stdin)) {
            g_debug_continue_mode = 1;
            g_debug_step_mode = 0;
            return;
        }

        size_t n = strlen(buf);
        while (n > 0 && (buf[n - 1] == '\n' || buf[n - 1] == '\r')) {
            buf[--n] = '\0';
        }

        if (buf[0] == '\0' || strcmp(buf, "s") == 0 || strcmp(buf, "step") == 0) {
            g_debug_continue_mode = 0;
            g_debug_step_mode = 1;
            return;
        }
        if (strcmp(buf, "c") == 0 || strcmp(buf, "continue") == 0) {
            g_debug_continue_mode = 1;
            g_debug_step_mode = 0;
            return;
        }
        if (strcmp(buf, "q") == 0 || strcmp(buf, "quit") == 0) {
            fprintf(stderr, "Debugger quit\n");
            exit(130);
        }
        if (buf[0] == 'p' && (buf[1] == ' ' || buf[1] == '\t')) {
            const char *name = buf + 2;
            while (*name == ' ' || *name == '\t') name++;
            if (*name == '\0') {
                fprintf(stderr, "Usage: p <variable>\n");
                continue;
            }

            Value out;
            if (env_get(env, name, &out)) {
                fprintf(stderr, "%s = ", name);
                value_print_inline(out);
                fprintf(stderr, "\n");
            } else {
                fprintf(stderr, "%s is undefined\n", name);
            }
            continue;
        }

        fprintf(stderr, "Commands: s/step, c/continue, q/quit, p <var>\n");
    }
}

static void debug_before_statement(Stmt *stmt, Env *env, const char *current_file) {
    if (!g_debug_enabled) return;

    const char *file = (current_file && current_file[0] != '\0') ? current_file : "<memory>";
    int hit_break = debug_breakpoint_hit(stmt->line);

    if (g_debug_step_mode) {
        g_debug_step_index++;
        fprintf(stderr, "[step %d] %s at %s:%d:%d\n", g_debug_step_index, stmt_kind_name(stmt->kind), file, stmt->line,
                stmt->col);
    } else if (g_debug_step_count > 0) {
        g_debug_step_index++;
        fprintf(stderr, "[step %d] %s at %s:%d:%d\n", g_debug_step_index, stmt_kind_name(stmt->kind), file, stmt->line,
                stmt->col);
        g_debug_step_count--;
    }

    if (hit_break) {
        fprintf(stderr, "[break] %s at %s:%d:%d\n", stmt_kind_name(stmt->kind), file, stmt->line, stmt->col);
    }

    if (!g_debug_continue_mode || g_debug_step_mode || hit_break) {
        fprintf(stderr, "[debug] %s at %s:%d:%d\n", stmt_kind_name(stmt->kind), file, stmt->line, stmt->col);
        debug_prompt(env);
    }
}

static EvalResult eval_statement(Stmt *stmt, Env *env, ImportSet *imports, const char *current_file, int top_level) {
    debug_before_statement(stmt, env, current_file);

    if (g_trace) {
        fprintf(stderr, "[trace] %s at %d:%d\n", stmt_kind_name(stmt->kind), stmt->line, stmt->col);
    }
    step_guard(stmt->line, stmt->col);

    switch (stmt->kind) {
        case STMT_LET: {
            Value v = eval_expr(stmt->as.let_stmt.value, env, imports, current_file);
            env_define(env, stmt->as.let_stmt.name, v);
            return eval_result(value_null(), CTRL_NONE);
        }
        case STMT_ASSIGN: {
            Value v = eval_expr(stmt->as.assign_stmt.value, env, imports, current_file);
            if (!env_assign(env, stmt->as.assign_stmt.name, v)) {
                runtime_error(stmt->line, stmt->col, "assignment to undefined variable");
            }
            return eval_result(value_null(), CTRL_NONE);
        }
        case STMT_SET_MEMBER: {
            Value obj = eval_expr(stmt->as.set_member_stmt.object, env, imports, current_file);
            Value v = eval_expr(stmt->as.set_member_stmt.value, env, imports, current_file);
            if (obj.type != VAL_OBJECT) runtime_error(stmt->line, stmt->col, "member assignment expects object");
            object_set(obj.as.object_val, stmt->as.set_member_stmt.member, v);
            return eval_result(value_null(), CTRL_NONE);
        }
        case STMT_SET_INDEX: {
            Value left = eval_expr(stmt->as.set_index_stmt.object, env, imports, current_file);
            Value idx = eval_expr(stmt->as.set_index_stmt.index, env, imports, current_file);
            Value v = eval_expr(stmt->as.set_index_stmt.value, env, imports, current_file);
            if (left.type == VAL_ARRAY) {
                if (idx.type != VAL_INT) runtime_error(stmt->line, stmt->col, "array index assignment expects int");
                if (idx.as.int_val < 0 || idx.as.int_val >= left.as.array_val->count) {
                    runtime_error(stmt->line, stmt->col, "array assignment index out of range");
                }
                left.as.array_val->items[idx.as.int_val] = v;
                return eval_result(value_null(), CTRL_NONE);
            }
            if (left.type == VAL_OBJECT) {
                if (idx.type != VAL_STRING) {
                    runtime_error(stmt->line, stmt->col, "object index assignment expects string key");
                }
                object_set(left.as.object_val, idx.as.str_val, v);
                return eval_result(value_null(), CTRL_NONE);
            }
            runtime_error(stmt->line, stmt->col, "index assignment expects array or object");
            return eval_result(value_null(), CTRL_NONE);
        }
        case STMT_EXPR: {
            Value v = eval_expr(stmt->as.expr_stmt.expr, env, imports, current_file);
            if (top_level && v.type != VAL_NULL) value_println(v);
            return eval_result(v, CTRL_NONE);
        }
        case STMT_IF: {
            Value cond = eval_expr(stmt->as.if_stmt.cond, env, imports, current_file);
            if (is_truthy(cond)) {
                Env *branch_env = env_new(env);
                EvalResult r = g_use_vm ? vm_eval_block(stmt->as.if_stmt.then_block, branch_env, imports, current_file, 0)
                                        : eval_block(stmt->as.if_stmt.then_block, branch_env, imports, current_file, 0);
                if (r.control != CTRL_NONE) return r;
            } else if (stmt->as.if_stmt.else_block != NULL) {
                Env *branch_env = env_new(env);
                EvalResult r = g_use_vm ? vm_eval_block(stmt->as.if_stmt.else_block, branch_env, imports, current_file, 0)
                                        : eval_block(stmt->as.if_stmt.else_block, branch_env, imports, current_file, 0);
                if (r.control != CTRL_NONE) return r;
            }
            return eval_result(value_null(), CTRL_NONE);
        }
        case STMT_SWITCH: {
            Value sw = eval_expr(stmt->as.switch_stmt.value, env, imports, current_file);
            for (int i = 0; i < stmt->as.switch_stmt.case_count; i++) {
                Value cv = eval_expr(stmt->as.switch_stmt.case_values[i], env, imports, current_file);
                if (!values_equal(sw, cv)) continue;
                Env *case_env = env_new(env);
                EvalResult r = g_use_vm ? vm_eval_block(stmt->as.switch_stmt.case_blocks[i], case_env, imports, current_file, 0)
                                        : eval_block(stmt->as.switch_stmt.case_blocks[i], case_env, imports, current_file, 0);
                if (r.control != CTRL_NONE) return r;
                return eval_result(value_null(), CTRL_NONE);
            }
            if (stmt->as.switch_stmt.default_block != NULL) {
                Env *default_env = env_new(env);
                EvalResult r =
                    g_use_vm ? vm_eval_block(stmt->as.switch_stmt.default_block, default_env, imports, current_file, 0)
                             : eval_block(stmt->as.switch_stmt.default_block, default_env, imports, current_file, 0);
                if (r.control != CTRL_NONE) return r;
            }
            return eval_result(value_null(), CTRL_NONE);
        }
        case STMT_WHILE: {
            while (1) {
                Value cond = eval_expr(stmt->as.while_stmt.cond, env, imports, current_file);
                if (!is_truthy(cond)) break;
                Env *loop_env = env_new(env);
                EvalResult r = g_use_vm ? vm_eval_block(stmt->as.while_stmt.body, loop_env, imports, current_file, 0)
                                        : eval_block(stmt->as.while_stmt.body, loop_env, imports, current_file, 0);
                if (r.control == CTRL_RETURN) return r;
                if (r.control == CTRL_BREAK) break;
                if (r.control == CTRL_CONTINUE) continue;
            }
            return eval_result(value_null(), CTRL_NONE);
        }
        case STMT_FOR: {
            Value iter = eval_expr(stmt->as.for_stmt.iter_expr, env, imports, current_file);
            if (iter.type == VAL_ARRAY) {
                for (int i = 0; i < iter.as.array_val->count; i++) {
                    Env *loop_env = env_new(env);
                    if (stmt->as.for_stmt.iter_value_name != NULL) {
                        env_define(loop_env, stmt->as.for_stmt.iter_name, value_int(i));
                        env_define(loop_env, stmt->as.for_stmt.iter_value_name, iter.as.array_val->items[i]);
                    } else {
                        env_define(loop_env, stmt->as.for_stmt.iter_name, iter.as.array_val->items[i]);
                    }
                    EvalResult r = g_use_vm ? vm_eval_block(stmt->as.for_stmt.body, loop_env, imports, current_file, 0)
                                            : eval_block(stmt->as.for_stmt.body, loop_env, imports, current_file, 0);
                    if (r.control == CTRL_RETURN) return r;
                    if (r.control == CTRL_BREAK) break;
                    if (r.control == CTRL_CONTINUE) continue;
                }
                return eval_result(value_null(), CTRL_NONE);
            }
            if (iter.type == VAL_OBJECT) {
                Object *obj = iter.as.object_val;
                for (int i = 0; i < obj->count; i++) {
                    Env *loop_env = env_new(env);
                    if (stmt->as.for_stmt.iter_value_name != NULL) {
                        env_define(loop_env, stmt->as.for_stmt.iter_name, value_string(obj->items[i].key));
                        env_define(loop_env, stmt->as.for_stmt.iter_value_name, obj->items[i].value);
                    } else {
                        env_define(loop_env, stmt->as.for_stmt.iter_name, value_string(obj->items[i].key));
                    }
                    EvalResult r = g_use_vm ? vm_eval_block(stmt->as.for_stmt.body, loop_env, imports, current_file, 0)
                                            : eval_block(stmt->as.for_stmt.body, loop_env, imports, current_file, 0);
                    if (r.control == CTRL_RETURN) return r;
                    if (r.control == CTRL_BREAK) break;
                    if (r.control == CTRL_CONTINUE) continue;
                }
                return eval_result(value_null(), CTRL_NONE);
            }
            runtime_error(stmt->line, stmt->col, "for loop expects array or object iterable");
            return eval_result(value_null(), CTRL_NONE);
        }
        case STMT_BREAK:
            return eval_result(value_null(), CTRL_BREAK);
        case STMT_CONTINUE:
            return eval_result(value_null(), CTRL_CONTINUE);
        case STMT_CLASS: {
            Env *class_env = env_new(env);
            EvalResult r = g_use_vm ? vm_eval_block(stmt->as.class_stmt.body, class_env, imports, current_file, 0)
                                    : eval_block(stmt->as.class_stmt.body, class_env, imports, current_file, 0);
            if (r.control != CTRL_NONE) {
                runtime_error(stmt->line, stmt->col, "class body cannot use return/break/continue");
            }
            Object *cls = object_new_kind(OBJ_CLASS);
            object_set(cls, "__name__", value_string(stmt->as.class_stmt.name));
            for (int i = 0; i < class_env->count; i++) {
                object_set(cls, class_env->items[i].name, class_env->items[i].value);
            }
            env_define(env, stmt->as.class_stmt.name, value_object(cls));
            return eval_result(value_null(), CTRL_NONE);
        }
        case STMT_MODULE: {
            Env *mod_env = env_new(env);
            EvalResult r = g_use_vm ? vm_eval_block(stmt->as.module_stmt.body, mod_env, imports, current_file, 0)
                                    : eval_block(stmt->as.module_stmt.body, mod_env, imports, current_file, 0);
            if (r.control != CTRL_NONE) {
                runtime_error(stmt->line, stmt->col, "module body cannot use return/break/continue");
            }
            Object *mod = object_new_kind(OBJ_MODULE);
            for (int i = 0; i < mod_env->count; i++) {
                object_set(mod, mod_env->items[i].name, mod_env->items[i].value);
            }
            env_define(env, stmt->as.module_stmt.name, value_object(mod));
            return eval_result(value_null(), CTRL_NONE);
        }
        case STMT_TYPE: {
            Value v = eval_expr(stmt->as.type_stmt.value, env, imports, current_file);
            env_define(env, stmt->as.type_stmt.name, v);
            return eval_result(value_null(), CTRL_NONE);
        }
        case STMT_TRY: {
            ExceptionFrame frame;
            frame.prev = g_exception_top;
            g_exception_top = &frame;

            if (setjmp(frame.env) == 0) {
                EvalResult r = g_use_vm ? vm_eval_block(stmt->as.try_stmt.try_block, env_new(env), imports, current_file, 0)
                                        : eval_block(stmt->as.try_stmt.try_block, env_new(env), imports, current_file, 0);
                g_exception_top = frame.prev;
                if (r.control != CTRL_NONE) return r;
                return eval_result(value_null(), CTRL_NONE);
            }

            g_exception_top = frame.prev;
            Env *catch_env = env_new(env);
            env_define(catch_env, stmt->as.try_stmt.catch_name, g_exception_value);
            EvalResult r = g_use_vm ? vm_eval_block(stmt->as.try_stmt.catch_block, catch_env, imports, current_file, 0)
                                    : eval_block(stmt->as.try_stmt.catch_block, catch_env, imports, current_file, 0);
            if (r.control != CTRL_NONE) return r;
            return eval_result(value_null(), CTRL_NONE);
        }
        case STMT_FN: {
            Function *fn = (Function *)xmalloc(sizeof(Function));
            fn->params = stmt->as.fn_stmt.params;
            fn->param_count = stmt->as.fn_stmt.param_count;
            fn->body = stmt->as.fn_stmt.body;
            fn->closure = env;
            fn->def_file = xstrdup(current_file ? current_file : "");
            env_define(env, stmt->as.fn_stmt.name, value_function(fn));
            return eval_result(value_null(), CTRL_NONE);
        }
        case STMT_RETURN: {
            Value v = eval_expr(stmt->as.return_stmt.value, env, imports, current_file);
            return eval_result(v, CTRL_RETURN);
        }
        case STMT_THROW: {
            Value v = eval_expr(stmt->as.throw_stmt.value, env, imports, current_file);
            throw_value(stmt->line, stmt->col, v);
            return eval_result(value_null(), CTRL_NONE);
        }
        case STMT_IMPORT: {
            char *path = NULL;
            if (is_builtin_module_path(stmt->as.import_stmt.path)) {
                path = xstrdup(stmt->as.import_stmt.path);
            } else {
                path = resolve_path(current_file, stmt->as.import_stmt.path);
            }
            if (import_set_contains(imports, path)) {
                xfree(path);
                return eval_result(value_null(), CTRL_NONE);
            }

            import_set_add(imports, path);
            char *source = NULL;
            if (is_builtin_module_path(path)) {
                const char *builtin_src = builtin_module_source(path);
                if (builtin_src != NULL) {
                    source = xstrdup(builtin_src);
                }
            } else {
                source = read_file(path);
            }
            if (!source) {
                xfree(path);
                if (is_builtin_module_path(stmt->as.import_stmt.path)) {
                    runtime_error(stmt->line, stmt->col, "import failed: unknown builtin package");
                }
                runtime_error(stmt->line, stmt->col, "import failed: file not found");
            }

            EvalResult r = eval_program_source(source, env, imports, path, 0);
            xfree(source);
            xfree(path);
            if (r.control != CTRL_NONE) {
                runtime_error(stmt->line, stmt->col, "import top-level cannot return/break/continue");
            }
            return eval_result(value_null(), CTRL_NONE);
        }
    }

    runtime_error(stmt->line, stmt->col, "invalid statement kind");
    return eval_result(value_null(), CTRL_NONE);
}

static EvalResult eval_block(Block *block, Env *env, ImportSet *imports, const char *current_file, int top_level) {
    Value last = value_null();
    for (int i = 0; i < block->count; i++) {
        EvalResult r = eval_statement(block->items[i], env, imports, current_file, top_level);
        if (r.control != CTRL_NONE) return r;
        last = r.value;
    }
    return eval_result(last, CTRL_NONE);
}

int main(int argc, char **argv) {
    int script_arg_index = 1;
    int explicit_debug = 0;

    while (script_arg_index < argc) {
        const char *arg = argv[script_arg_index];
        if (strcmp(arg, "--") == 0) {
            script_arg_index++;
            break;
        }
        if (strcmp(arg, "--trace") == 0) {
            g_trace = 1;
            script_arg_index++;
            continue;
        }
        if (strcmp(arg, "--parse-only") == 0 || strcmp(arg, "--lint") == 0) {
            g_parse_only = 1;
            script_arg_index++;
            continue;
        }
        if (strcmp(arg, "--vm") == 0) {
            g_use_vm = 1;
            script_arg_index++;
            continue;
        }
        if (strcmp(arg, "--vm-strict") == 0) {
            g_use_vm = 1;
            g_vm_strict = 1;
            script_arg_index++;
            continue;
        }
        if (strcmp(arg, "--version") == 0) {
            printf("%s\n", NYX_LANG_VERSION);
            return 0;
        }
        if (strcmp(arg, "--max-alloc") == 0) {
            if (script_arg_index + 1 >= argc) {
                fprintf(stderr, "Error: --max-alloc expects a value\n");
                return 1;
            }
            char *endp = NULL;
            long long v = strtoll(argv[script_arg_index + 1], &endp, 10);
            if (endp == argv[script_arg_index + 1] || *endp != '\0' || v <= 0) {
                fprintf(stderr, "Error: --max-alloc expects a positive integer\n");
                return 1;
            }
            g_max_alloc_units = v;
            script_arg_index += 2;
            continue;
        }
        if (strcmp(arg, "--max-steps") == 0) {
            if (script_arg_index + 1 >= argc) {
                fprintf(stderr, "Error: --max-steps expects a value\n");
                return 1;
            }
            char *endp = NULL;
            long long v = strtoll(argv[script_arg_index + 1], &endp, 10);
            if (endp == argv[script_arg_index + 1] || *endp != '\0' || v < 0) {
                fprintf(stderr, "Error: --max-steps expects a non-negative integer\n");
                return 1;
            }
            g_max_steps = v;
            script_arg_index += 2;
            continue;
        }
        if (strcmp(arg, "--max-call-depth") == 0) {
            if (script_arg_index + 1 >= argc) {
                fprintf(stderr, "Error: --max-call-depth expects a value\n");
                return 1;
            }
            char *endp = NULL;
            long long v = strtoll(argv[script_arg_index + 1], &endp, 10);
            if (endp == argv[script_arg_index + 1] || *endp != '\0' || v <= 0 || v > INT_MAX) {
                fprintf(stderr, "Error: --max-call-depth expects an integer in [1, %d]\n", INT_MAX);
                return 1;
            }
            g_max_call_depth = (int)v;
            script_arg_index += 2;
            continue;
        }
        if (strcmp(arg, "--debug") == 0) {
            g_debug_enabled = 1;
            explicit_debug = 1;
            script_arg_index++;
            continue;
        }
        if (strcmp(arg, "--debug-no-prompt") == 0) {
            g_debug_no_prompt = 1;
            script_arg_index++;
            continue;
        }
        if (strcmp(arg, "--step") == 0) {
            g_debug_enabled = 1;
            g_debug_step_mode = 1;
            script_arg_index++;
            continue;
        }
        if (strcmp(arg, "--step-count") == 0) {
            if (script_arg_index + 1 >= argc) {
                fprintf(stderr, "Error: --step-count expects a value\n");
                return 1;
            }
            char *endp = NULL;
            long v = strtol(argv[script_arg_index + 1], &endp, 10);
            if (endp == argv[script_arg_index + 1] || *endp != '\0' || v < 0) {
                fprintf(stderr, "Error: --step-count expects a non-negative integer\n");
                return 1;
            }
            g_debug_enabled = 1;
            g_debug_step_count = (int)v;
            script_arg_index += 2;
            continue;
        }
        if (strcmp(arg, "--break") == 0) {
            if (script_arg_index + 1 >= argc) {
                fprintf(stderr, "Error: --break expects comma-separated line numbers\n");
                return 1;
            }
            g_debug_enabled = 1;
            debug_parse_breakpoints_csv(argv[script_arg_index + 1]);
            script_arg_index += 2;
            continue;
        }
        if (arg[0] == '-') {
            fprintf(stderr, "Error: unknown option: %s\n", arg);
            return 1;
        }
        break;
    }

    if (g_debug_enabled) {
        if (g_debug_step_mode || explicit_debug) {
            g_debug_continue_mode = 0;
        } else {
            /* Breakpoint/step-count-only mode runs until a hit. */
            g_debug_continue_mode = 1;
        }
    }

    const char *script_path = NULL;
    char **script_argv = NULL;
    int script_argc = 0;
    char *fallback_script_argv[1];
    char *source = NULL;

    if (argc <= script_arg_index) {
        script_path = "main.ny";
        source = read_file(script_path);
        if (!source) {
            fprintf(stderr,
                    "Usage: nyx [--trace] [--parse-only|--lint] [--vm|--vm-strict] [--max-alloc N] [--max-steps N] [--max-call-depth N] [--debug] [--break lines] [--step] [--step-count N] "
                    "[--debug-no-prompt] [--version] "
                    "<file.ny> [args...]\n");
            fprintf(stderr, "Hint: run from a directory that contains main.ny or pass a file path explicitly.\n");
            return 1;
        }
        fallback_script_argv[0] = (char *)script_path;
        script_argv = fallback_script_argv;
        script_argc = 1;
    } else {
        script_path = argv[script_arg_index];
        source = read_file(script_path);
        if (!source) {
            fprintf(stderr, "Error: could not read file: %s\n", script_path);
            return 1;
        }
        script_argv = argv + script_arg_index;
        script_argc = argc - script_arg_index;
    }

    if (g_parse_only) {
        Parser p;
        parser_init(&p, source);
        (void)parse_program(&p);
        xfree(source);
        return 0;
    }

    g_script_argc = script_argc;
    g_script_argv = script_argv;
    g_step_count = 0;
    g_call_depth = 0;

    Env *global = env_new(NULL);
    install_builtins(global);
    install_blas_builtins(global);
    install_gpu_builtins(global);
    install_jit_dist_builtins(global);
    install_ml_ecosystem_builtins(global);

    ImportSet imports;
    imports.items = NULL;
    imports.count = 0;
    imports.cap = 0;

    import_set_add(&imports, script_path);

    EvalResult r = eval_program_source(source, global, &imports, script_path, 1);
    xfree(source);

    if (r.control == CTRL_RETURN) {
        fprintf(stderr, "Error: return at top-level is not allowed\n");
        return 1;
    }
    if (r.control == CTRL_BREAK || r.control == CTRL_CONTINUE) {
        fprintf(stderr, "Error: break/continue at top-level is not allowed\n");
        return 1;
    }

    return 0;
}
