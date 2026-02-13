// Minimal Ergo-compatible runtime for Cogito; mirrors Ergo's runtime layout.
#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef enum {
  EVT_NULL = 0,
  EVT_INT,
  EVT_FLOAT,
  EVT_BOOL,
  EVT_STR,
  EVT_ARR,
  EVT_OBJ,
  EVT_FN
} ErgoTag;

typedef struct ErgoVal ErgoVal;

typedef struct ErgoStr {
  int ref;
  size_t len;
  char* data;
} ErgoStr;

typedef struct ErgoArr {
  int ref;
  size_t len;
  size_t cap;
  ErgoVal* items;
} ErgoArr;

typedef struct ErgoObj {
  int ref;
  void (*drop)(struct ErgoObj* o);
} ErgoObj;

typedef struct ErgoFn {
  int ref;
  int arity;
  ErgoVal (*fn)(void* env, int argc, ErgoVal* argv);
  void* env;
} ErgoFn;

typedef ErgoVal (*ErgoFnImpl)(void* env, int argc, ErgoVal* argv);

struct ErgoVal {
  ErgoTag tag;
  union {
    int64_t i;
    double f;
    bool b;
    void* p;
  } as;
};

#define EV_NULLV ((ErgoVal){ .tag = EVT_NULL })
#define EV_INT(v) ((ErgoVal){ .tag = EVT_INT, .as.i = (int64_t)(v) })
#define EV_FLOAT(v) ((ErgoVal){ .tag = EVT_FLOAT, .as.f = (double)(v) })
#define EV_BOOL(v) ((ErgoVal){ .tag = EVT_BOOL, .as.b = (bool)(v) })
#define EV_STR(v) ((ErgoVal){ .tag = EVT_STR, .as.p = (void*)(v) })
#define EV_ARR(v) ((ErgoVal){ .tag = EVT_ARR, .as.p = (void*)(v) })
#define EV_OBJ(v) ((ErgoVal){ .tag = EVT_OBJ, .as.p = (void*)(v) })
#define EV_FN(v) ((ErgoVal){ .tag = EVT_FN, .as.p = (void*)(v) })

void* cogito_compat_obj_new(size_t size, void (*drop)(ErgoObj* o));
void cogito_compat_retain_val(ErgoVal v);
void cogito_compat_release_val(ErgoVal v);
void cogito_compat_trap(const char* msg);

int64_t cogito_compat_as_int(ErgoVal v);
double cogito_compat_as_float(ErgoVal v);
bool cogito_compat_as_bool(ErgoVal v);

ErgoVal cogito_compat_call(ErgoVal fnv, int argc, ErgoVal* argv);

ErgoStr* cogito_compat_str_from_slice(const char* s, size_t len);
ErgoStr* cogito_compat_str_lit(const char* s);
ErgoStr* cogito_compat_to_string(ErgoVal v);

ErgoArr* cogito_compat_arr_new(size_t len);
void cogito_compat_arr_set(ErgoArr* a, size_t idx, ErgoVal v);
ErgoVal cogito_compat_arr_get(ErgoArr* a, int64_t idx);
