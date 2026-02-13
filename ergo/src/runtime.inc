// ---- Ergo runtime (minimal) ----
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdarg.h>
#include <ctype.h>
#include <math.h>
#include <limits.h>
#include <time.h>
#include <sys/stat.h>
#if defined(__APPLE__)
#include <CoreGraphics/CoreGraphics.h>
#endif
#if defined(_WIN32)
#include <windows.h>
#include <io.h>
#else
int isatty(int);
int fileno(FILE*);
#endif

static int ergo_stdout_isatty = 0;

static bool cogito_debug_enabled(void);
static const char* cogito_font_path_active = NULL;

static void ergo_runtime_init(void) {
#if defined(__APPLE__)
  if (cogito_debug_enabled()) {
    fprintf(stderr, "cogito: runtime_init\n");
    fflush(stderr);
  }
#endif
#if defined(_WIN32)
  ergo_stdout_isatty = _isatty(_fileno(stdout));
#else
  ergo_stdout_isatty = isatty(fileno(stdout));
#endif
  if (!ergo_stdout_isatty) {
    setvbuf(stdout, NULL, _IOFBF, 1 << 16);
  }
}

typedef enum {
  EVT_NULL,
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
  void (*drop)(struct ErgoObj*);
} ErgoObj;

typedef struct ErgoFn {
  int ref;
  int arity;
  ErgoVal (*fn)(void* env, int argc, ErgoVal* argv);
  void* env;
  int env_size;
} ErgoFn;

struct ErgoVal {
  ErgoTag tag;
  union {
    int64_t i;
    double f;
    bool b;
    void* p;
  } as;
};

#define EV_NULLV ((ErgoVal){.tag=EVT_NULL})
#define EV_INT(x) ((ErgoVal){.tag=EVT_INT, .as.i=(int64_t)(x)})
#define EV_FLOAT(x) ((ErgoVal){.tag=EVT_FLOAT, .as.f=(double)(x)})
#define EV_BOOL(x) ((ErgoVal){.tag=EVT_BOOL, .as.b=(x)?true:false})
#define EV_STR(x) ((ErgoVal){.tag=EVT_STR, .as.p=(x)})
#define EV_ARR(x) ((ErgoVal){.tag=EVT_ARR, .as.p=(x)})
#define EV_OBJ(x) ((ErgoVal){.tag=EVT_OBJ, .as.p=(x)})
#define EV_FN(x) ((ErgoVal){.tag=EVT_FN, .as.p=(x)})

static void ergo_trap(const char* msg) {
  fprintf(stderr, "runtime error: %s\n", msg ? msg : "unknown error");
  fprintf(stderr, "  (run with debugger for stack trace)\n");
  abort();
}

static void ergo_retain_val(ErgoVal v);
static void ergo_release_val(ErgoVal v);

static ErgoStr* stdr_str_lit(const char* s) {
  size_t n = strlen(s);
  ErgoStr* st = (ErgoStr*)malloc(sizeof(ErgoStr));
  st->ref = 1;
  st->len = n;
  st->data = (char*)malloc(n + 1);
  memcpy(st->data, s, n + 1);
  return st;
}

static ErgoStr* stdr_str_from_parts(int n, ErgoVal* parts);
static ErgoStr* stdr_to_string(ErgoVal v);
static ErgoStr* stdr_str_from_slice(const char* s, size_t len);
static ErgoArr* stdr_arr_new(int n);
static void ergo_arr_add(ErgoArr* a, ErgoVal v);
static ErgoVal ergo_arr_get(ErgoArr* a, int64_t idx);
static void ergo_arr_set(ErgoArr* a, int64_t idx, ErgoVal v);
static ErgoVal ergo_arr_remove(ErgoArr* a, int64_t idx);

static ErgoVal stdr_str_at(ErgoVal v, int64_t idx) {
  if (v.tag != EVT_STR) ergo_trap("str_at expects string");
  ErgoStr* s = (ErgoStr*)v.as.p;
  if (idx < 0 || (size_t)idx >= s->len) return EV_STR(stdr_str_lit(""));
  return EV_STR(stdr_str_from_slice(s->data + idx, 1));
}

static int stdr_len(ErgoVal v) {
  if (v.tag == EVT_STR) return (int)((ErgoStr*)v.as.p)->len;
  if (v.tag == EVT_ARR) return (int)((ErgoArr*)v.as.p)->len;
  return 0;
}

static bool stdr_is_null(ErgoVal v) { return v.tag == EVT_NULL; }

static void stdr_write(ErgoVal v) {
  ErgoStr* s = stdr_to_string(v);
  fwrite(s->data, 1, s->len, stdout);
  if (ergo_stdout_isatty) fflush(stdout);
  ergo_release_val(EV_STR(s));
}

static void writef(ErgoVal fmt, int argc, ErgoVal* argv) {
  if (fmt.tag != EVT_STR) ergo_trap("writef expects string");
  ErgoStr* s = (ErgoStr*)fmt.as.p;
  size_t i = 0;
  size_t seg = 0;
  int argi = 0;
  while (i < s->len) {
    if (i + 1 < s->len && s->data[i] == '{' && s->data[i + 1] == '}') {
      if (i > seg) fwrite(s->data + seg, 1, i - seg, stdout);
      if (argi < argc) {
        ErgoStr* ps = stdr_to_string(argv[argi++]);
        fwrite(ps->data, 1, ps->len, stdout);
        ergo_release_val(EV_STR(ps));
      }
      i += 2;
      seg = i;
      continue;
    }
    i++;
  }
  if (i > seg) fwrite(s->data + seg, 1, i - seg, stdout);
  if (ergo_stdout_isatty) fflush(stdout);
}

static void stdr_writef_args(ErgoVal fmt, ErgoVal args) {
  if (args.tag != EVT_ARR) ergo_trap("writef expects args tuple");
  ErgoArr* a = (ErgoArr*)args.as.p;
  writef(fmt, (int)a->len, a->items);
}

static ErgoStr* stdr_read_line(void) {
  size_t cap = 128;
  size_t len = 0;
  char* buf = (char*)malloc(cap);
  if (!buf) ergo_trap("out of memory");
  int c;
  while ((c = fgetc(stdin)) != EOF) {
    if (c == '\n') break;
    if (len + 1 >= cap) {
      cap *= 2;
      buf = (char*)realloc(buf, cap);
      if (!buf) ergo_trap("out of memory");
    }
    buf[len++] = (char)c;
  }
  if (len > 0 && buf[len - 1] == '\r') len--;
  buf[len] = 0;
  ErgoStr* s = (ErgoStr*)malloc(sizeof(ErgoStr));
  if (!s) ergo_trap("out of memory");
  s->ref = 1;
  s->len = len;
  s->data = buf;
  return s;
}

static ErgoVal stdr_read_text_file(ErgoVal pathv) {
  if (pathv.tag != EVT_STR) ergo_trap("read_text_file expects string path");
  ErgoStr* path = (ErgoStr*)pathv.as.p;
  FILE* f = fopen(path->data, "rb");
  if (!f) return EV_NULLV;
  if (fseek(f, 0, SEEK_END) != 0) {
    fclose(f);
    return EV_NULLV;
  }
  long sz = ftell(f);
  if (sz < 0) {
    fclose(f);
    return EV_NULLV;
  }
  if (fseek(f, 0, SEEK_SET) != 0) {
    fclose(f);
    return EV_NULLV;
  }
  size_t len = (size_t)sz;
  ErgoStr* out = (ErgoStr*)malloc(sizeof(ErgoStr));
  if (!out) {
    fclose(f);
    ergo_trap("out of memory");
  }
  out->data = (char*)malloc(len + 1);
  if (!out->data) {
    fclose(f);
    free(out);
    ergo_trap("out of memory");
  }
  size_t n = 0;
  if (len > 0) n = fread(out->data, 1, len, f);
  fclose(f);
  if (n != len) {
    free(out->data);
    free(out);
    return EV_NULLV;
  }
  out->ref = 1;
  out->len = len;
  out->data[len] = 0;
  return EV_STR(out);
}

static ErgoVal stdr_write_text_file(ErgoVal pathv, ErgoVal textv) {
  if (pathv.tag != EVT_STR) ergo_trap("write_text_file expects string path");
  if (textv.tag != EVT_STR) ergo_trap("write_text_file expects string text");
  ErgoStr* path = (ErgoStr*)pathv.as.p;
  ErgoStr* text = (ErgoStr*)textv.as.p;
  FILE* f = fopen(path->data, "wb");
  if (!f) return EV_BOOL(false);
  size_t n = 0;
  if (text->len > 0) n = fwrite(text->data, 1, text->len, f);
  bool ok = (n == text->len) && (fclose(f) == 0);
  return EV_BOOL(ok);
}

static ErgoVal stdr_capture_shell_first_line(const char* cmd) {
  if (!cmd || !cmd[0]) return EV_NULLV;
#if defined(_WIN32)
  FILE* p = _popen(cmd, "r");
#else
  FILE* p = popen(cmd, "r");
#endif
  if (!p) return EV_NULLV;
  char buf[4096];
  if (!fgets(buf, sizeof(buf), p)) {
#if defined(_WIN32)
    _pclose(p);
#else
    pclose(p);
#endif
    return EV_NULLV;
  }
#if defined(_WIN32)
  _pclose(p);
#else
  pclose(p);
#endif
  size_t len = strlen(buf);
  while (len > 0 && (buf[len - 1] == '\n' || buf[len - 1] == '\r')) len--;
  if (len == 0) return EV_NULLV;
  return EV_STR(stdr_str_from_slice(buf, len));
}

static ErgoVal stdr_open_file_dialog(ErgoVal promptv, ErgoVal extv) {
  if (promptv.tag != EVT_STR) ergo_trap("open_file_dialog expects prompt string");
  if (extv.tag != EVT_STR) ergo_trap("open_file_dialog expects extension string");
  ErgoStr* prompt = (ErgoStr*)promptv.as.p;
  ErgoStr* ext = (ErgoStr*)extv.as.p;
#if defined(__APPLE__)
  char cmd[8192];
  snprintf(cmd, sizeof(cmd),
           "osascript -e 'set _p to POSIX path of (choose file of type {\"%s\"} with prompt \"%s\")' -e 'return _p' 2>/dev/null",
           ext ? ext->data : "", prompt ? prompt->data : "");
  return stdr_capture_shell_first_line(cmd);
#else
  (void)prompt;
  (void)ext;
  return EV_NULLV;
#endif
}

static ErgoVal stdr_save_file_dialog(ErgoVal promptv, ErgoVal default_namev, ErgoVal extv) {
  if (promptv.tag != EVT_STR) ergo_trap("save_file_dialog expects prompt string");
  if (default_namev.tag != EVT_STR) ergo_trap("save_file_dialog expects default_name string");
  if (extv.tag != EVT_STR) ergo_trap("save_file_dialog expects extension string");
  ErgoStr* prompt = (ErgoStr*)promptv.as.p;
  ErgoStr* def = (ErgoStr*)default_namev.as.p;
  ErgoStr* ext = (ErgoStr*)extv.as.p;
#if defined(__APPLE__)
  char cmd[8192];
  snprintf(cmd, sizeof(cmd),
           "osascript -e 'set _p to POSIX path of (choose file name with prompt \"%s\" default name \"%s\")' -e 'return _p' 2>/dev/null",
           prompt ? prompt->data : "", def ? def->data : "");
  ErgoVal out = stdr_capture_shell_first_line(cmd);
  (void)ext;
  return out;
#else
  (void)prompt;
  (void)def;
  (void)ext;
  return EV_NULLV;
#endif
}

static size_t stdr_find_sub(const char* s, size_t slen, const char* sub, size_t sublen, size_t start) {
  if (sublen == 0) return start;
  if (start > slen) return (size_t)-1;
  for (size_t i = start; i + sublen <= slen; i++) {
    if (memcmp(s + i, sub, sublen) == 0) return i;
  }
  return (size_t)-1;
}

static void stdr_trim_span(const char* s, size_t len, size_t* out_start, size_t* out_len) {
  size_t a = 0;
  while (a < len && (s[a] == ' ' || s[a] == '\t')) a++;
  size_t b = len;
  while (b > a && (s[b - 1] == ' ' || s[b - 1] == '\t')) b--;
  *out_start = a;
  *out_len = b - a;
}

static ErgoStr* stdr_str_from_slice(const char* s, size_t len) {
  ErgoStr* st = (ErgoStr*)malloc(sizeof(ErgoStr));
  if (!st) ergo_trap("out of memory");
  st->ref = 1;
  st->len = len;
  st->data = (char*)malloc(len + 1);
  if (!st->data) ergo_trap("out of memory");
  if (len > 0) memcpy(st->data, s, len);
  st->data[len] = 0;
  return st;
}

static int64_t stdr_parse_int_slice(const char* s, size_t len) {
  if (len == 0) return 0;
  char* tmp = (char*)malloc(len + 1);
  if (!tmp) ergo_trap("out of memory");
  memcpy(tmp, s, len);
  tmp[len] = 0;
  char* end = NULL;
  long long v = strtoll(tmp, &end, 10);
  free(tmp);
  if (end == tmp) return 0;
  return (int64_t)v;
}

static double stdr_parse_float_slice(const char* s, size_t len) {
  if (len == 0) return 0.0;
  char* tmp = (char*)malloc(len + 1);
  if (!tmp) ergo_trap("out of memory");
  memcpy(tmp, s, len);
  tmp[len] = 0;
  char* end = NULL;
  double v = strtod(tmp, &end);
  free(tmp);
  if (end == tmp) return 0.0;
  return v;
}

static bool stdr_parse_bool_slice(const char* s, size_t len) {
  if (len == 1) {
    if (s[0] == '1') return true;
    if (s[0] == '0') return false;
  }
  if (len == 4) {
    return ((s[0] == 't' || s[0] == 'T') &&
            (s[1] == 'r' || s[1] == 'R') &&
            (s[2] == 'u' || s[2] == 'U') &&
            (s[3] == 'e' || s[3] == 'E'));
  }
  return false;
}

static ErgoVal stdr_readf_parse(ErgoVal fmt, ErgoVal line, ErgoVal args) {
  if (fmt.tag != EVT_STR) ergo_trap("readf expects string format");
  if (line.tag != EVT_STR) ergo_trap("readf expects string input");
  if (args.tag != EVT_ARR) ergo_trap("readf expects args tuple");

  ErgoStr* fs = (ErgoStr*)fmt.as.p;
  ErgoStr* ls = (ErgoStr*)line.as.p;
  ErgoArr* a = (ErgoArr*)args.as.p;

  const char* f = fs->data;
  size_t flen = fs->len;
  const char* s = ls->data;
  size_t slen = ls->len;

  int segs = 1;
  for (size_t i = 0; i + 1 < flen; i++) {
    if (f[i] == '{' && f[i + 1] == '}') {
      segs++;
      i++;
    }
  }

  const char** seg_ptrs = (const char**)malloc(sizeof(char*) * segs);
  size_t* seg_lens = (size_t*)malloc(sizeof(size_t) * segs);
  if (!seg_ptrs || !seg_lens) ergo_trap("out of memory");

  size_t seg_start = 0;
  int seg_idx = 0;
  for (size_t i = 0; i + 1 < flen; i++) {
    if (f[i] == '{' && f[i + 1] == '}') {
      seg_ptrs[seg_idx] = f + seg_start;
      seg_lens[seg_idx] = i - seg_start;
      seg_idx++;
      i++;
      seg_start = i + 1;
    }
  }
  seg_ptrs[seg_idx] = f + seg_start;
  seg_lens[seg_idx] = flen - seg_start;

  int placeholders = segs - 1;

  size_t spos = 0;
  if (seg_lens[0] > 0) {
    size_t found = stdr_find_sub(s, slen, seg_ptrs[0], seg_lens[0], 0);
    if (found != (size_t)-1) spos = found + seg_lens[0];
  }

  ErgoArr* out = stdr_arr_new((int)a->len);

  for (size_t i = 0; i < a->len; i++) {
    size_t cap_start = spos;
    size_t cap_len = 0;
    if ((int)i < placeholders) {
      size_t found = stdr_find_sub(s, slen, seg_ptrs[i + 1], seg_lens[i + 1], spos);
      if (found == (size_t)-1) {
        cap_len = slen - spos;
        spos = slen;
      } else {
        cap_len = found - spos;
        spos = found + seg_lens[i + 1];
      }
    }

    size_t trim_start = 0;
    size_t trim_len = cap_len;
    stdr_trim_span(s + cap_start, cap_len, &trim_start, &trim_len);
    const char* cap = (cap_len > 0) ? (s + cap_start + trim_start) : "";

    ErgoVal hint = a->items[i];
    ErgoVal v;
    if (hint.tag == EVT_INT) {
      v = EV_INT(stdr_parse_int_slice(cap, trim_len));
    } else if (hint.tag == EVT_FLOAT) {
      v = EV_FLOAT(stdr_parse_float_slice(cap, trim_len));
    } else if (hint.tag == EVT_BOOL) {
      v = EV_BOOL(stdr_parse_bool_slice(cap, trim_len));
    } else if (hint.tag == EVT_STR) {
      v = EV_STR(stdr_str_from_slice(cap, trim_len));
    } else {
      v = EV_STR(stdr_str_from_slice(cap, trim_len));
    }
    ergo_arr_add(out, v);
  }

  free(seg_ptrs);
  free(seg_lens);

  return EV_ARR(out);
}

static ErgoStr* stdr_to_string(ErgoVal v) {
  char buf[64];
  if (v.tag == EVT_NULL) return stdr_str_lit("null");
  if (v.tag == EVT_BOOL) return stdr_str_lit(v.as.b ? "true" : "false");
  if (v.tag == EVT_INT) {
    snprintf(buf, sizeof(buf), "%lld", (long long)v.as.i);
    return stdr_str_lit(buf);
  }
  if (v.tag == EVT_FLOAT) {
    snprintf(buf, sizeof(buf), "%.6f", v.as.f);
    return stdr_str_lit(buf);
  }
  if (v.tag == EVT_STR) {
    ergo_retain_val(v);
    return (ErgoStr*)v.as.p;
  }
  if (v.tag == EVT_ARR) return stdr_str_lit("[array]");
  if (v.tag == EVT_OBJ) return stdr_str_lit("[object]");
  if (v.tag == EVT_FN) return stdr_str_lit("[function]");
  return stdr_str_lit("<?>");
}

static ErgoStr* stdr_str_from_parts(int n, ErgoVal* parts) {
  size_t total = 0;
  ErgoStr** strs = (ErgoStr**)malloc(sizeof(ErgoStr*) * (size_t)n);
  for (int i = 0; i < n; i++) {
    strs[i] = stdr_to_string(parts[i]);
    total += strs[i]->len;
  }
  ErgoStr* out = (ErgoStr*)malloc(sizeof(ErgoStr));
  out->ref = 1;
  out->len = total;
  out->data = (char*)malloc(total + 1);
  size_t off = 0;
  for (int i = 0; i < n; i++) {
    memcpy(out->data + off, strs[i]->data, strs[i]->len);
    off += strs[i]->len;
    ergo_release_val(EV_STR(strs[i]));
  }
  out->data[total] = 0;
  free(strs);
  return out;
}

static void ergo_retain_val(ErgoVal v) {
  if (v.tag == EVT_STR) ((ErgoStr*)v.as.p)->ref++;
  else if (v.tag == EVT_ARR) ((ErgoArr*)v.as.p)->ref++;
  else if (v.tag == EVT_OBJ) ((ErgoObj*)v.as.p)->ref++;
  else if (v.tag == EVT_FN) ((ErgoFn*)v.as.p)->ref++;
}

static void ergo_release_val(ErgoVal v) {
  if (v.tag == EVT_STR) {
    ErgoStr* s = (ErgoStr*)v.as.p;
    if (--s->ref == 0) {
      free(s->data);
      free(s);
    }
  } else if (v.tag == EVT_ARR) {
    ErgoArr* a = (ErgoArr*)v.as.p;
    if (--a->ref == 0) {
      for (size_t i = 0; i < a->len; i++) ergo_release_val(a->items[i]);
      free(a->items);
      free(a);
    }
  } else if (v.tag == EVT_OBJ) {
    ErgoObj* o = (ErgoObj*)v.as.p;
    if (--o->ref == 0) {
      if (o->drop) o->drop(o);
      free(o);
    }
  } else if (v.tag == EVT_FN) {
    ErgoFn* f = (ErgoFn*)v.as.p;
    if (--f->ref == 0) {
      if (f->env && f->env_size > 0) {
        ErgoVal* caps = (ErgoVal*)f->env;
        for (int i = 0; i < f->env_size; i++) ergo_release_val(caps[i]);
        free(f->env);
      }
      free(f);
    }
  }
}

static ErgoVal ergo_move(ErgoVal* slot) {
  ErgoVal v = *slot;
  *slot = EV_NULLV;
  return v;
}

static void ergo_move_into(ErgoVal* slot, ErgoVal v) {
  ergo_release_val(*slot);
  *slot = v;
}

static int64_t ergo_as_int(ErgoVal v) {
  if (v.tag == EVT_INT) return v.as.i;
  if (v.tag == EVT_BOOL) return v.as.b ? 1 : 0;
  if (v.tag == EVT_FLOAT) return (int64_t)v.as.f;
  ergo_trap("type mismatch: expected int");
  return 0;
}

static double ergo_as_float(ErgoVal v) {
  if (v.tag == EVT_FLOAT) return v.as.f;
  if (v.tag == EVT_INT) return (double)v.as.i;
  ergo_trap("type mismatch: expected float");
  return 0.0;
}

static bool ergo_as_bool(ErgoVal v) {
  if (v.tag == EVT_BOOL) return v.as.b;
  if (v.tag == EVT_NULL) return false;
  if (v.tag == EVT_INT) return v.as.i != 0;
  if (v.tag == EVT_FLOAT) return v.as.f != 0.0;
  if (v.tag == EVT_STR) return ((ErgoStr*)v.as.p)->len != 0;
  if (v.tag == EVT_ARR) return ((ErgoArr*)v.as.p)->len != 0;
  return true;
}

static ErgoVal ergo_add(ErgoVal a, ErgoVal b) {
  if (a.tag == EVT_FLOAT || b.tag == EVT_FLOAT) return EV_FLOAT(ergo_as_float(a) + ergo_as_float(b));
  return EV_INT(ergo_as_int(a) + ergo_as_int(b));
}

static ErgoVal ergo_sub(ErgoVal a, ErgoVal b) {
  if (a.tag == EVT_FLOAT || b.tag == EVT_FLOAT) return EV_FLOAT(ergo_as_float(a) - ergo_as_float(b));
  return EV_INT(ergo_as_int(a) - ergo_as_int(b));
}

static ErgoVal ergo_mul(ErgoVal a, ErgoVal b) {
  if (a.tag == EVT_FLOAT || b.tag == EVT_FLOAT) return EV_FLOAT(ergo_as_float(a) * ergo_as_float(b));
  return EV_INT(ergo_as_int(a) * ergo_as_int(b));
}

static ErgoVal ergo_div(ErgoVal a, ErgoVal b) {
  if (a.tag == EVT_FLOAT || b.tag == EVT_FLOAT) return EV_FLOAT(ergo_as_float(a) / ergo_as_float(b));
  return EV_INT(ergo_as_int(a) / ergo_as_int(b));
}

static ErgoVal ergo_mod(ErgoVal a, ErgoVal b) {
  if (a.tag == EVT_FLOAT || b.tag == EVT_FLOAT) ergo_trap("% expects integer");
  return EV_INT(ergo_as_int(a) % ergo_as_int(b));
}

static ErgoVal ergo_neg(ErgoVal a) {
  if (a.tag == EVT_FLOAT) return EV_FLOAT(-a.as.f);
  return EV_INT(-ergo_as_int(a));
}

static ErgoVal ergo_eq(ErgoVal a, ErgoVal b) {
  if (a.tag != b.tag) return EV_BOOL(false);
  switch (a.tag) {
    case EVT_NULL: return EV_BOOL(true);
    case EVT_BOOL: return EV_BOOL(a.as.b == b.as.b);
    case EVT_INT: return EV_BOOL(a.as.i == b.as.i);
    case EVT_FLOAT: return EV_BOOL(a.as.f == b.as.f);
    case EVT_STR: {
      ErgoStr* sa = (ErgoStr*)a.as.p;
      ErgoStr* sb = (ErgoStr*)b.as.p;
      if (sa->len != sb->len) return EV_BOOL(false);
      return EV_BOOL(memcmp(sa->data, sb->data, sa->len) == 0);
    }
    default: return EV_BOOL(a.as.p == b.as.p);
  }
}

static ErgoVal ergo_ne(ErgoVal a, ErgoVal b) {
  ErgoVal v = ergo_eq(a, b);
  return EV_BOOL(!v.as.b);
}

static ErgoVal ergo_lt(ErgoVal a, ErgoVal b) { return EV_BOOL(ergo_as_float(a) < ergo_as_float(b)); }
static ErgoVal ergo_le(ErgoVal a, ErgoVal b) { return EV_BOOL(ergo_as_float(a) <= ergo_as_float(b)); }
static ErgoVal ergo_gt(ErgoVal a, ErgoVal b) { return EV_BOOL(ergo_as_float(a) > ergo_as_float(b)); }
static ErgoVal ergo_ge(ErgoVal a, ErgoVal b) { return EV_BOOL(ergo_as_float(a) >= ergo_as_float(b)); }

static ErgoArr* stdr_arr_new(int n) {
  ErgoArr* a = (ErgoArr*)malloc(sizeof(ErgoArr));
  a->ref = 1;
  a->len = 0;
  a->cap = (n > 0) ? (size_t)n : 4;
  a->items = (ErgoVal*)malloc(sizeof(ErgoVal) * a->cap);
  return a;
}

static void ergo_arr_add(ErgoArr* a, ErgoVal v) {
  if (a->len >= a->cap) {
    a->cap *= 2;
    a->items = (ErgoVal*)realloc(a->items, sizeof(ErgoVal) * a->cap);
  }
  a->items[a->len++] = v;
}

static ErgoVal ergo_arr_get(ErgoArr* a, int64_t idx) {
  if (idx < 0 || (size_t)idx >= a->len) return EV_NULLV;
  ErgoVal v = a->items[idx];
  ergo_retain_val(v);
  return v;
}

static void ergo_arr_set(ErgoArr* a, int64_t idx, ErgoVal v) {
  if (idx < 0 || (size_t)idx >= a->len) return;
  ergo_release_val(a->items[idx]);
  a->items[idx] = v;
}

static ErgoVal ergo_arr_remove(ErgoArr* a, int64_t idx) {
  if (idx < 0 || (size_t)idx >= a->len) return EV_NULLV;
  ErgoVal v = a->items[idx];
  for (size_t i = (size_t)idx; i + 1 < a->len; i++) {
    a->items[i] = a->items[i + 1];
  }
  a->len--;
  return v;
}

static ErgoObj* ergo_obj_new(size_t size, void (*drop)(ErgoObj*)) {
  ErgoObj* o = (ErgoObj*)malloc(size);
  o->ref = 1;
  o->drop = drop;
  return o;
}

static ErgoFn* ergo_fn_new(ErgoVal (*fn)(void* env, int argc, ErgoVal* argv), int arity) {
  ErgoFn* f = (ErgoFn*)malloc(sizeof(ErgoFn));
  f->ref = 1;
  f->arity = arity;
  f->fn = fn;
  f->env = NULL;
  f->env_size = 0;
  return f;
}

static ErgoFn* ergo_fn_new_with_env(ErgoVal (*fn)(void* env, int argc, ErgoVal* argv), int arity, void* env, int env_size) {
  ErgoFn* f = (ErgoFn*)malloc(sizeof(ErgoFn));
  f->ref = 1;
  f->arity = arity;
  f->fn = fn;
  f->env = env;
  f->env_size = env_size;
  return f;
}

static ErgoVal ergo_call(ErgoVal fval, int argc, ErgoVal* argv) {
  if (fval.tag != EVT_FN) ergo_trap("call expects function");
  ErgoFn* f = (ErgoFn*)fval.as.p;
  if (f->arity >= 0 && f->arity != argc) ergo_trap("arity mismatch");
  return f->fn(f->env, argc, argv);
}

// ---- Cogito GUI (shared library bindings) ----
// @include "cogito_bindings.inc"
