// ---- Cogito bindings (shared library) ----
#include <cogito.h>

#undef cogito_app_new
#undef cogito_app_free
#undef cogito_app_run
#undef cogito_app_set_appid
#undef cogito_app_set_app_name
#undef cogito_app_set_accent_color
#undef cogito_open_url
#undef cogito_window_new
#undef cogito_window_free
#undef cogito_window_set_resizable
#undef cogito_window_set_autosize
#undef cogito_window_set_a11y_label
#undef cogito_window_set_builder
#undef cogito_rebuild_active_window
#undef cogito_node_new
#undef cogito_grid_new_with_cols
#undef cogito_label_new
#undef cogito_button_new
#undef cogito_iconbtn_new
#undef cogito_checkbox_new
#undef cogito_switch_new
#undef cogito_textfield_new
#undef cogito_textview_new
#undef cogito_searchfield_new
#undef cogito_dropdown_new
#undef cogito_slider_new
#undef cogito_tabs_new
#undef cogito_view_switcher_new
#undef cogito_progress_new
#undef cogito_datepicker_new
#undef cogito_colorpicker_new
#undef cogito_stepper_new
#undef cogito_segmented_new
#undef cogito_treeview_new
#undef cogito_toasts_new
#undef cogito_toast_new
#undef cogito_bottom_toolbar_new
#undef cogito_dialog_new
#undef cogito_dialog_slot_new
#undef cogito_appbar_new
#undef cogito_image_new
#undef cogito_node_add
#undef cogito_node_remove
#undef cogito_node_free
#undef cogito_node_set_margins
#undef cogito_node_set_padding
#undef cogito_node_set_align
#undef cogito_node_set_halign
#undef cogito_node_set_valign
#undef cogito_node_set_id
#undef cogito_node_set_text
#undef cogito_node_get_text
#undef cogito_node_set_disabled
#undef cogito_node_set_editable
#undef cogito_node_get_editable
#undef cogito_node_set_class
#undef cogito_node_set_a11y_label
#undef cogito_node_set_a11y_role
#undef cogito_node_set_tooltip
#undef cogito_node_build
#undef cogito_node_on_click
#undef cogito_node_on_change
#undef cogito_node_on_select
#undef cogito_node_on_activate
#undef cogito_pointer_capture
#undef cogito_pointer_release
#undef cogito_dropdown_set_items
#undef cogito_dropdown_get_selected
#undef cogito_dropdown_set_selected
#undef cogito_tabs_set_items
#undef cogito_tabs_set_ids
#undef cogito_tabs_get_selected
#undef cogito_tabs_set_selected
#undef cogito_tabs_bind
#undef cogito_slider_get_value
#undef cogito_slider_set_value
#undef cogito_checkbox_get_checked
#undef cogito_checkbox_set_checked
#undef cogito_switch_get_checked
#undef cogito_switch_set_checked
#undef cogito_textfield_set_text
#undef cogito_textfield_get_text
#undef cogito_textview_set_text
#undef cogito_textview_get_text
#undef cogito_searchfield_set_text
#undef cogito_searchfield_get_text
#undef cogito_progress_set_value
#undef cogito_progress_get_value
#undef cogito_stepper_set_value
#undef cogito_stepper_get_value
#undef cogito_stepper_on_change
#undef cogito_segmented_on_select
#undef cogito_load_sum_file
#undef cogito_label_set_text
#undef cogito_label_set_wrap
#undef cogito_label_set_ellipsis
#undef cogito_label_set_align
#undef cogito_image_set_icon
#undef cogito_appbar_add_button
#undef cogito_appbar_set_controls
#undef cogito_appbar_set_title
#undef cogito_appbar_set_subtitle
#undef cogito_dialog_slot_show
#undef cogito_dialog_slot_clear
#undef cogito_window_set_dialog
#undef cogito_window_clear_dialog
#undef cogito_fixed_set_pos
#undef cogito_scroller_set_axes
#undef cogito_grid_set_gap
#undef cogito_grid_set_span
#undef cogito_grid_set_align
#undef cogito_button_set_text
#undef cogito_button_add_menu
#undef cogito_iconbtn_add_menu
#undef cogito_checkbox_on_change
#undef cogito_switch_on_change
#undef cogito_textfield_on_change
#undef cogito_textview_on_change
#undef cogito_searchfield_on_change
#undef cogito_dropdown_on_change
#undef cogito_slider_on_change
#undef cogito_tabs_on_change
#undef cogito_datepicker_on_change
#undef cogito_colorpicker_on_change
#undef cogito_list_on_select
#undef cogito_list_on_activate
#undef cogito_grid_on_select
#undef cogito_grid_on_activate
#undef cogito_view_switcher_set_active
#undef cogito_toast_on_click
#undef cogito_toast_set_action
#undef cogito_node_window
#undef cogito_find_parent
#undef cogito_find_children

static bool cogito_debug_enabled(void) {
  const char* env = getenv("COGITO_DEBUG");
  return env && env[0] && env[0] != '0';
}

typedef enum {
  COGITO_HANDLE_APP = 1,
  COGITO_HANDLE_WINDOW,
  COGITO_HANDLE_NODE,
  COGITO_HANDLE_STATE
} CogitoHandleKind;

typedef struct CogitoHandle {
  ErgoObj base;
  void* ptr;
  int kind;
  ErgoVal on_click;
  ErgoVal on_change;
  ErgoVal on_select;
  ErgoVal on_activate;
  ErgoVal on_action;
  ErgoVal builder;
} CogitoHandle;

typedef struct CogitoHandleEntry {
  cogito_node* node;
  CogitoHandle* handle;
  struct CogitoHandleEntry* next;
} CogitoHandleEntry;

typedef struct CogitoMenuHandler {
  ErgoVal fn;
} CogitoMenuHandler;

static void __cogito_button_on_click(ErgoVal btnv, ErgoVal handler);

typedef struct CogitoState {
  ErgoObj base;
  ErgoVal value;
} CogitoState;

static CogitoHandleEntry* cogito_handle_entries = NULL;

static CogitoHandle* cogito_handle_lookup(cogito_node* node) {
  for (CogitoHandleEntry* e = cogito_handle_entries; e; e = e->next) {
    if (e->node == node) return e->handle;
  }
  return NULL;
}

static void cogito_handle_register(cogito_node* node, CogitoHandle* handle) {
  CogitoHandleEntry* e = (CogitoHandleEntry*)malloc(sizeof(*e));
  e->node = node;
  e->handle = handle;
  e->next = cogito_handle_entries;
  cogito_handle_entries = e;
}

static void cogito_handle_unregister(cogito_node* node) {
  CogitoHandleEntry** cur = &cogito_handle_entries;
  while (*cur) {
    CogitoHandleEntry* e = *cur;
    if (e->node == node) {
      *cur = e->next;
      free(e);
      return;
    }
    cur = &e->next;
  }
}

static void cogito_handle_drop(ErgoObj* o) {
  CogitoHandle* h = (CogitoHandle*)o;
  if (!h) return;
  if (h->on_click.tag != EVT_NULL) ergo_release_val(h->on_click);
  if (h->on_change.tag != EVT_NULL) ergo_release_val(h->on_change);
  if (h->on_select.tag != EVT_NULL) ergo_release_val(h->on_select);
  if (h->on_activate.tag != EVT_NULL) ergo_release_val(h->on_activate);
  if (h->builder.tag != EVT_NULL) ergo_release_val(h->builder);
  if (h->kind == COGITO_HANDLE_WINDOW || h->kind == COGITO_HANDLE_NODE) {
    cogito_handle_unregister((cogito_node*)h->ptr);
  }
  h->ptr = NULL;
}

static CogitoHandle* cogito_handle_new(void* ptr, int kind) {
  CogitoHandle* h = (CogitoHandle*)ergo_obj_new(sizeof(CogitoHandle), cogito_handle_drop);
  h->ptr = ptr;
  h->kind = kind;
  h->on_click = EV_NULLV;
  h->on_change = EV_NULLV;
  h->on_select = EV_NULLV;
  h->on_activate = EV_NULLV;
  h->builder = EV_NULLV;
  return h;
}

static ErgoVal cogito_wrap_node(cogito_node* node, int kind) {
  if (!node) return EV_NULLV;
  CogitoHandle* h = cogito_handle_lookup(node);
  if (!h) {
    h = cogito_handle_new(node, kind);
    cogito_handle_register(node, h);
  }
  return EV_OBJ(h);
}

static CogitoHandle* cogito_handle_from_val(ErgoVal v, const char* what) {
  if (v.tag != EVT_OBJ) ergo_trap(what);
  return (CogitoHandle*)v.as.p;
}

static cogito_app* cogito_app_from_val(ErgoVal v) {
  CogitoHandle* h = cogito_handle_from_val(v, "cogito.app expects app");
  return (cogito_app*)h->ptr;
}

static cogito_window* cogito_window_from_val(ErgoVal v) {
  CogitoHandle* h = cogito_handle_from_val(v, "cogito.window expects window");
  return (cogito_window*)h->ptr;
}

static cogito_node* cogito_node_from_val(ErgoVal v) {
  CogitoHandle* h = cogito_handle_from_val(v, "cogito.node expects node");
  return (cogito_node*)h->ptr;
}

static const char* cogito_required_cstr(ErgoVal v, ErgoStr** tmp) {
  if (v.tag == EVT_NULL) return "";
  if (v.tag == EVT_STR) return ((ErgoStr*)v.as.p)->data;
  ErgoStr* s = stdr_to_string(v);
  if (tmp) *tmp = s;
  return s ? s->data : "";
}

static const char* cogito_optional_cstr(ErgoVal v, ErgoStr** tmp) {
  if (v.tag == EVT_NULL) return NULL;
  if (v.tag == EVT_STR) return ((ErgoStr*)v.as.p)->data;
  ErgoStr* s = stdr_to_string(v);
  if (tmp) *tmp = s;
  return s ? s->data : NULL;
}

static void cogito_set_handler(CogitoHandle* h, ErgoVal* slot, ErgoVal handler) {
  bool had = slot->tag != EVT_NULL;
  if (had) ergo_release_val(*slot);
  *slot = handler;
  bool has = handler.tag != EVT_NULL;
  if (has) ergo_retain_val(handler);
  if (h) {
    if (!had && has) ergo_retain_val(EV_OBJ(h));
    if (had && !has) ergo_release_val(EV_OBJ(h));
  }
}

static void cogito_invoke_node_handler(ErgoVal handler, cogito_node* node) {
  if (handler.tag != EVT_FN) return;
  ErgoVal arg = cogito_wrap_node(node, COGITO_HANDLE_NODE);
  ergo_retain_val(arg);
  ErgoVal ret = ergo_call(handler, 1, &arg);
  ergo_release_val(arg);
  ergo_release_val(ret);
}

static void cogito_invoke_index_handler(ErgoVal handler, int idx) {
  if (handler.tag != EVT_FN) return;
  ErgoVal arg = EV_INT(idx);
  ErgoVal ret = ergo_call(handler, 1, &arg);
  ergo_release_val(ret);
}

static void cogito_cb_click(cogito_node* node, void* user) {
  CogitoHandle* h = (CogitoHandle*)user;
  if (!h) return;
  cogito_invoke_node_handler(h->on_click, node);
}

static void cogito_cb_change(cogito_node* node, void* user) {
  CogitoHandle* h = (CogitoHandle*)user;
  if (!h) return;
  cogito_invoke_node_handler(h->on_change, node);
}

static void cogito_cb_action(cogito_node* node, void* user) {
  CogitoHandle* h = (CogitoHandle*)user;
  if (!h) return;
  cogito_invoke_node_handler(h->on_action, node);
}

static void cogito_cb_select(cogito_node* node, int idx, void* user) {
  (void)node;
  CogitoHandle* h = (CogitoHandle*)user;
  if (!h) return;
  cogito_invoke_index_handler(h->on_select, idx);
}

static void cogito_cb_activate(cogito_node* node, int idx, void* user) {
  (void)node;
  CogitoHandle* h = (CogitoHandle*)user;
  if (!h) return;
  cogito_invoke_index_handler(h->on_activate, idx);
}

static void cogito_cb_builder(cogito_node* node, void* user) {
  CogitoHandle* h = (CogitoHandle*)user;
  if (!h) return;
  cogito_invoke_node_handler(h->builder, node);
}

static CogitoMenuHandler* cogito_menu_handler_new(ErgoVal handler) {
  CogitoMenuHandler* mh = (CogitoMenuHandler*)calloc(1, sizeof(*mh));
  mh->fn = handler;
  if (handler.tag != EVT_NULL) ergo_retain_val(handler);
  return mh;
}

static void cogito_cb_menu(cogito_node* node, void* user) {
  CogitoMenuHandler* mh = (CogitoMenuHandler*)user;
  if (!mh) return;
  cogito_invoke_node_handler(mh->fn, node);
}

static void cogito_state_drop(ErgoObj* o) {
  CogitoState* s = (CogitoState*)o;
  if (s->value.tag != EVT_NULL) {
    ergo_release_val(s->value);
    s->value = EV_NULLV;
  }
}

static ErgoVal cogito_state_new_val(ErgoVal initial) {
  CogitoState* s = (CogitoState*)ergo_obj_new(sizeof(CogitoState), cogito_state_drop);
  s->value = initial;
  if (initial.tag != EVT_NULL) ergo_retain_val(initial);
  return EV_OBJ(s);
}

static ErgoVal cogito_state_get_val(ErgoVal sv) {
  if (sv.tag != EVT_OBJ) ergo_trap("cogito.state_get expects state");
  CogitoState* s = (CogitoState*)sv.as.p;
  ErgoVal v = s->value;
  if (v.tag != EVT_NULL) ergo_retain_val(v);
  return v;
}

static void cogito_state_set_val(ErgoVal sv, ErgoVal nv) {
  if (sv.tag != EVT_OBJ) ergo_trap("cogito.state_set expects state");
  CogitoState* s = (CogitoState*)sv.as.p;
  if (s->value.tag != EVT_NULL) ergo_release_val(s->value);
  s->value = nv;
  if (nv.tag != EVT_NULL) ergo_retain_val(nv);
  cogito_rebuild_active_window();
}

static ErgoVal __cogito_app(void) {
  cogito_app* app = cogito_app_new();
  CogitoHandle* h = cogito_handle_new(app, COGITO_HANDLE_APP);
  return EV_OBJ(h);
}

static void __cogito_app_set_appid(ErgoVal appv, ErgoVal idv) {
  cogito_app* app = cogito_app_from_val(appv);
  ErgoStr* tmp = NULL;
  const char* id = cogito_optional_cstr(idv, &tmp);
  if (id) cogito_app_set_appid(app, id);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static void __cogito_app_set_app_name(ErgoVal appv, ErgoVal namev) {
  cogito_app* app = cogito_app_from_val(appv);
  ErgoStr* tmp = NULL;
  const char* name = cogito_optional_cstr(namev, &tmp);
  if (name) cogito_app_set_app_name(app, name);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static void __cogito_app_set_accent_color(ErgoVal appv, ErgoVal colorv, ErgoVal overridev) {
  cogito_app* app = cogito_app_from_val(appv);
  ErgoStr* tmp = NULL;
  const char* color = cogito_optional_cstr(colorv, &tmp);
  bool ov = overridev.tag == EVT_BOOL ? overridev.as.b : false;
  if (color) cogito_app_set_accent_color(app, color, ov);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static ErgoVal __cogito_window(ErgoVal titlev, ErgoVal wv, ErgoVal hv) {
  ErgoStr* tmp = NULL;
  const char* title = cogito_required_cstr(titlev, &tmp);
  int w = (int)ergo_as_int(wv);
  int h = (int)ergo_as_int(hv);
  cogito_window* win = cogito_window_new(title, w, h);
  if (tmp) ergo_release_val(EV_STR(tmp));
  return cogito_wrap_node((cogito_node*)win, COGITO_HANDLE_WINDOW);
}

static void __cogito_window_set_resizable(ErgoVal winv, ErgoVal onv) {
  cogito_window* win = cogito_window_from_val(winv);
  cogito_window_set_resizable(win, onv.tag == EVT_BOOL ? onv.as.b : false);
}

static void __cogito_window_set_autosize(ErgoVal winv, ErgoVal onv) {
  cogito_window* win = cogito_window_from_val(winv);
  cogito_window_set_autosize(win, onv.tag == EVT_BOOL ? onv.as.b : false);
}

static void __cogito_window_set_a11y_label(ErgoVal winv, ErgoVal labelv) {
  cogito_window* win = cogito_window_from_val(winv);
  ErgoStr* tmp = NULL;
  const char* label = cogito_optional_cstr(labelv, &tmp);
  if (label) cogito_window_set_a11y_label(win, label);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static void __cogito_window_set_builder(ErgoVal winv, ErgoVal builder) {
  cogito_window* win = cogito_window_from_val(winv);
  CogitoHandle* h = (CogitoHandle*)winv.as.p;
  if (builder.tag != EVT_FN) {
    cogito_set_handler(h, &h->builder, builder);
    cogito_window_set_builder(win, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->builder, builder);
  cogito_window_set_builder(win, cogito_cb_builder, h);
}

static ErgoVal __cogito_label(ErgoVal textv) {
  ErgoStr* tmp = NULL;
  const char* text = cogito_required_cstr(textv, &tmp);
  cogito_node* n = cogito_label_new(text);
  if (tmp) ergo_release_val(EV_STR(tmp));
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_button(ErgoVal textv) {
  ErgoStr* tmp = NULL;
  const char* text = cogito_required_cstr(textv, &tmp);
  cogito_node* n = cogito_button_new(text);
  if (tmp) ergo_release_val(EV_STR(tmp));
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_iconbtn(ErgoVal textv) {
  ErgoStr* tmp = NULL;
  const char* text = cogito_required_cstr(textv, &tmp);
  cogito_node* n = cogito_iconbtn_new(text);
  if (tmp) ergo_release_val(EV_STR(tmp));
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_fab(ErgoVal iconv) {
  ErgoStr* tmp = NULL;
  const char* icon = cogito_required_cstr(iconv, &tmp);
  cogito_node* n = cogito_fab_new(icon);
  if (tmp) ergo_release_val(EV_STR(tmp));
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static void __cogito_fab_set_extended(ErgoVal fabv, ErgoVal extendedv, ErgoVal labelv) {
  cogito_node* fab = cogito_node_from_val(fabv);
  bool extended = ergo_as_bool(extendedv);
  ErgoStr* tmp = NULL;
  const char* label = cogito_optional_cstr(labelv, &tmp);
  cogito_fab_set_extended(fab, extended, label ? label : "");
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static void __cogito_fab_on_click(ErgoVal fabv, ErgoVal handler) {
  cogito_node* fab = cogito_node_from_val(fabv);
  CogitoHandle* h = (CogitoHandle*)fabv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_click, handler);
    cogito_fab_on_click(fab, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_click, handler);
  cogito_fab_on_click(fab, cogito_cb_click, h);
}

static ErgoVal __cogito_chip(ErgoVal textv) {
  ErgoStr* tmp = NULL;
  const char* text = cogito_required_cstr(textv, &tmp);
  cogito_node* n = cogito_chip_new(text);
  if (tmp) ergo_release_val(EV_STR(tmp));
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static void __cogito_chip_set_selected(ErgoVal chipv, ErgoVal sel) {
  cogito_node* n = cogito_node_from_val(chipv);
  cogito_chip_set_selected(n, ergo_as_bool(sel));
}

static ErgoVal __cogito_chip_get_selected(ErgoVal chipv) {
  cogito_node* n = cogito_node_from_val(chipv);
  return EV_BOOL(cogito_chip_get_selected(n));
}

static void __cogito_chip_set_closable(ErgoVal chipv, ErgoVal closable) {
  cogito_node* n = cogito_node_from_val(chipv);
  cogito_chip_set_closable(n, ergo_as_bool(closable));
}

static void __cogito_chip_on_click(ErgoVal chipv, ErgoVal handler) {
  cogito_node* chip = cogito_node_from_val(chipv);
  CogitoHandle* h = (CogitoHandle*)chipv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_click, handler);
    cogito_chip_on_click(chip, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_click, handler);
  cogito_chip_on_click(chip, cogito_cb_click, h);
}

static void __cogito_chip_on_close(ErgoVal chipv, ErgoVal handler) {
  cogito_node* chip = cogito_node_from_val(chipv);
  CogitoHandle* h = (CogitoHandle*)chipv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_action, handler);
    cogito_chip_on_close(chip, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_action, handler);
  cogito_chip_on_close(chip, cogito_cb_action, h);
}

static ErgoVal __cogito_image(ErgoVal iconv) {
  ErgoStr* tmp = NULL;
  const char* icon = cogito_required_cstr(iconv, &tmp);
  cogito_node* n = cogito_image_new(icon);
  if (tmp) ergo_release_val(EV_STR(tmp));
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static void __cogito_image_set_icon(ErgoVal imgv, ErgoVal iconv) {
  cogito_node* n = cogito_node_from_val(imgv);
  ErgoStr* tmp = NULL;
  const char* icon = cogito_required_cstr(iconv, &tmp);
  cogito_image_set_icon(n, icon);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static ErgoVal __cogito_appbar(ErgoVal titlev, ErgoVal subtitlev) {
  ErgoStr* ttmp = NULL;
  ErgoStr* stmp = NULL;
  const char* title = cogito_required_cstr(titlev, &ttmp);
  const char* subtitle = cogito_required_cstr(subtitlev, &stmp);
  cogito_node* n = cogito_appbar_new(title, subtitle);
  if (ttmp) ergo_release_val(EV_STR(ttmp));
  if (stmp) ergo_release_val(EV_STR(stmp));
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_appbar_add_button(ErgoVal appbarv, ErgoVal iconv, ErgoVal handler) {
  cogito_node* appbar = cogito_node_from_val(appbarv);
  ErgoStr* tmp = NULL;
  const char* icon = cogito_required_cstr(iconv, &tmp);
  cogito_node* btn = cogito_appbar_add_button(appbar, icon, NULL, NULL);
  if (tmp) ergo_release_val(EV_STR(tmp));
  ErgoVal btnv = cogito_wrap_node(btn, COGITO_HANDLE_NODE);
  if (handler.tag == EVT_FN) __cogito_button_on_click(btnv, handler);
  return btnv;
}

static void __cogito_appbar_set_controls(ErgoVal appbarv, ErgoVal layoutv) {
  cogito_node* appbar = cogito_node_from_val(appbarv);
  ErgoStr* tmp = NULL;
  const char* layout = cogito_optional_cstr(layoutv, &tmp);
  if (layout) cogito_appbar_set_controls(appbar, layout);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static void __cogito_appbar_set_title(ErgoVal appbarv, ErgoVal titlev) {
  cogito_node* appbar = cogito_node_from_val(appbarv);
  ErgoStr* tmp = NULL;
  const char* title = cogito_optional_cstr(titlev, &tmp);
  cogito_appbar_set_title(appbar, title ? title : "");
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static void __cogito_appbar_set_subtitle(ErgoVal appbarv, ErgoVal subtitlev) {
  cogito_node* appbar = cogito_node_from_val(appbarv);
  ErgoStr* tmp = NULL;
  const char* subtitle = cogito_optional_cstr(subtitlev, &tmp);
  cogito_appbar_set_subtitle(appbar, subtitle ? subtitle : "");
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static ErgoVal __cogito_dialog(ErgoVal titlev) {
  ErgoStr* tmp = NULL;
  const char* title = cogito_required_cstr(titlev, &tmp);
  cogito_node* n = cogito_dialog_new(title);
  if (tmp) ergo_release_val(EV_STR(tmp));
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_dialog_slot(void) {
  cogito_node* n = cogito_dialog_slot_new();
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static void __cogito_dialog_slot_show(ErgoVal slotv, ErgoVal dialogv) {
  cogito_node* slot = cogito_node_from_val(slotv);
  cogito_node* dialog = cogito_node_from_val(dialogv);
  cogito_dialog_slot_show(slot, dialog);
}

static void __cogito_dialog_slot_clear(ErgoVal slotv) {
  cogito_node* slot = cogito_node_from_val(slotv);
  cogito_dialog_slot_clear(slot);
}

static void __cogito_window_set_dialog(ErgoVal winv, ErgoVal dialogv) {
  cogito_window* win = cogito_window_from_val(winv);
  cogito_node* dialog = cogito_node_from_val(dialogv);
  cogito_window_set_dialog(win, dialog);
}

static void __cogito_window_clear_dialog(ErgoVal winv) {
  cogito_window* win = cogito_window_from_val(winv);
  cogito_window_clear_dialog(win);
}

static ErgoVal __cogito_node_window(ErgoVal nodev) {
  cogito_node* n = cogito_node_from_val(nodev);
  cogito_window* win = cogito_node_window(n);
  return cogito_wrap_node((cogito_node*)win, COGITO_HANDLE_WINDOW);
}

static ErgoVal __cogito_find_parent(ErgoVal nodev) {
  cogito_node* n = cogito_node_from_val(nodev);
  cogito_node* p = cogito_node_get_parent(n);
  if (!p) return EV_NULLV;
  return cogito_wrap_node(p, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_find_children(ErgoVal nodev) {
  cogito_node* n = cogito_node_from_val(nodev);
  size_t count = cogito_node_get_child_count(n);
  ErgoArr* arr = stdr_arr_new((int)count);
  for (size_t i = 0; i < count; i++) {
    cogito_node* child = cogito_node_get_child(n, i);
    ergo_arr_add(arr, cogito_wrap_node(child, COGITO_HANDLE_NODE));
  }
  return EV_ARR(arr);
}

static void __cogito_label_set_class(ErgoVal labelv, ErgoVal classv) {
  cogito_node* n = cogito_node_from_val(labelv);
  ErgoStr* tmp = NULL;
  const char* cls = cogito_optional_cstr(classv, &tmp);
  if (cls) cogito_node_set_class(n, cls);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static void __cogito_label_set_text(ErgoVal labelv, ErgoVal textv) {
  cogito_node* n = cogito_node_from_val(labelv);
  ErgoStr* tmp = NULL;
  const char* text = cogito_optional_cstr(textv, &tmp);
  if (text) cogito_node_set_text(n, text);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static void __cogito_node_set_class(ErgoVal nodev, ErgoVal classv) {
  cogito_node* n = cogito_node_from_val(nodev);
  ErgoStr* tmp = NULL;
  const char* cls = cogito_optional_cstr(classv, &tmp);
  if (cls) cogito_node_set_class(n, cls);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static void __cogito_node_set_a11y_label(ErgoVal nodev, ErgoVal labelv) {
  cogito_node* n = cogito_node_from_val(nodev);
  ErgoStr* tmp = NULL;
  const char* label = cogito_optional_cstr(labelv, &tmp);
  if (label) cogito_node_set_a11y_label(n, label);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static void __cogito_node_set_a11y_role(ErgoVal nodev, ErgoVal rolev) {
  cogito_node* n = cogito_node_from_val(nodev);
  ErgoStr* tmp = NULL;
  const char* role = cogito_optional_cstr(rolev, &tmp);
  if (role) cogito_node_set_a11y_role(n, role);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static void __cogito_node_set_tooltip(ErgoVal nodev, ErgoVal textv) {
  cogito_node* n = cogito_node_from_val(nodev);
  ErgoStr* tmp = NULL;
  const char* text = cogito_optional_cstr(textv, &tmp);
  if (text) cogito_node_set_tooltip(n, text);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static void __cogito_pointer_capture(ErgoVal nodev) {
  if (nodev.tag == EVT_NULL) {
    cogito_pointer_release();
    return;
  }
  cogito_node* n = cogito_node_from_val(nodev);
  cogito_pointer_capture(n);
}

static void __cogito_pointer_release(void) {
  cogito_pointer_release();
}

static void __cogito_label_set_wrap(ErgoVal labelv, ErgoVal onv) {
  cogito_node* n = cogito_node_from_val(labelv);
  cogito_label_set_wrap(n, onv.tag == EVT_BOOL ? onv.as.b : false);
}

static void __cogito_label_set_ellipsis(ErgoVal labelv, ErgoVal onv) {
  cogito_node* n = cogito_node_from_val(labelv);
  cogito_label_set_ellipsis(n, onv.tag == EVT_BOOL ? onv.as.b : false);
}

static void __cogito_label_set_align(ErgoVal labelv, ErgoVal alignv) {
  cogito_node* n = cogito_node_from_val(labelv);
  cogito_label_set_align(n, (int)ergo_as_int(alignv));
}

static ErgoVal __cogito_checkbox(ErgoVal textv, ErgoVal groupv) {
  ErgoStr* ttmp = NULL;
  ErgoStr* gtmp = NULL;
  const char* text = cogito_required_cstr(textv, &ttmp);
  const char* group = cogito_optional_cstr(groupv, &gtmp);
  cogito_node* n = cogito_checkbox_new(text, group);
  if (ttmp) ergo_release_val(EV_STR(ttmp));
  if (gtmp) ergo_release_val(EV_STR(gtmp));
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_switch(ErgoVal textv) {
  ErgoStr* tmp = NULL;
  const char* text = cogito_required_cstr(textv, &tmp);
  cogito_node* n = cogito_switch_new(text);
  if (tmp) ergo_release_val(EV_STR(tmp));
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_textfield(ErgoVal textv) {
  ErgoStr* tmp = NULL;
  const char* text = cogito_required_cstr(textv, &tmp);
  cogito_node* n = cogito_textfield_new(text);
  if (tmp) ergo_release_val(EV_STR(tmp));
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_textview(ErgoVal textv) {
  ErgoStr* tmp = NULL;
  const char* text = cogito_required_cstr(textv, &tmp);
  cogito_node* n = cogito_textview_new(text);
  if (tmp) ergo_release_val(EV_STR(tmp));
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_searchfield(ErgoVal textv) {
  ErgoStr* tmp = NULL;
  const char* text = cogito_required_cstr(textv, &tmp);
  cogito_node* n = cogito_searchfield_new(text);
  if (tmp) ergo_release_val(EV_STR(tmp));
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static void __cogito_searchfield_set_text(ErgoVal sfv, ErgoVal textv) {
  cogito_node* sf = cogito_node_from_val(sfv);
  ErgoStr* tmp = NULL;
  const char* text = cogito_required_cstr(textv, &tmp);
  cogito_searchfield_set_text(sf, text);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static ErgoVal __cogito_searchfield_get_text(ErgoVal sfv) {
  cogito_node* sf = cogito_node_from_val(sfv);
  const char* text = cogito_searchfield_get_text(sf);
  return EV_STR(stdr_str_lit(text ? text : ""));
}

static void __cogito_searchfield_on_change(ErgoVal sfv, ErgoVal handler) {
  cogito_node* sf = cogito_node_from_val(sfv);
  CogitoHandle* h = (CogitoHandle*)sfv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_change, handler);
    cogito_searchfield_on_change(sf, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_change, handler);
  cogito_searchfield_on_change(sf, cogito_cb_change, h);
}

static ErgoVal __cogito_dropdown(void) {
  cogito_node* n = cogito_dropdown_new();
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_datepicker(void) {
  cogito_node* n = cogito_datepicker_new();
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static void __cogito_datepicker_on_change(ErgoVal dpv, ErgoVal handler) {
  cogito_node* dp = cogito_node_from_val(dpv);
  CogitoHandle* h = (CogitoHandle*)dpv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_change, handler);
    cogito_datepicker_on_change(dp, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_change, handler);
  cogito_datepicker_on_change(dp, cogito_cb_change, h);
}

static ErgoVal __cogito_stepper(ErgoVal minv, ErgoVal maxv, ErgoVal valuev, ErgoVal stepv) {
  cogito_node* n = cogito_stepper_new(ergo_as_float(minv), ergo_as_float(maxv), ergo_as_float(valuev), ergo_as_float(stepv));
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_slider(ErgoVal minv, ErgoVal maxv, ErgoVal valuev) {
  cogito_node* n = cogito_slider_new(ergo_as_float(minv), ergo_as_float(maxv), ergo_as_float(valuev));
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_tabs(void) {
  cogito_node* n = cogito_tabs_new();
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_nav_rail(void) {
  cogito_node* n = cogito_nav_rail_new();
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_segmented(void) {
  cogito_node* n = cogito_segmented_new();
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_view_switcher(void) {
  cogito_node* n = cogito_view_switcher_new();
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_progress(ErgoVal valuev) {
  cogito_node* n = cogito_progress_new(ergo_as_float(valuev));
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_treeview(void) {
  cogito_node* n = cogito_treeview_new();
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_colorpicker(void) {
  cogito_node* n = cogito_colorpicker_new();
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static void __cogito_colorpicker_on_change(ErgoVal cpv, ErgoVal handler) {
  cogito_node* cp = cogito_node_from_val(cpv);
  CogitoHandle* h = (CogitoHandle*)cpv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_change, handler);
    cogito_colorpicker_on_change(cp, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_change, handler);
  cogito_colorpicker_on_change(cp, cogito_cb_change, h);
}

static ErgoVal __cogito_toasts(void) {
  cogito_node* n = cogito_toasts_new();
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_toast(ErgoVal textv) {
  ErgoStr* tmp = NULL;
  const char* text = cogito_required_cstr(textv, &tmp);
  cogito_node* n = cogito_toast_new(text);
  if (tmp) ergo_release_val(EV_STR(tmp));
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_toolbar(void) {
  cogito_node* n = cogito_bottom_toolbar_new();
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_vstack(void) {
  return cogito_wrap_node(cogito_node_new(COGITO_NODE_VSTACK), COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_hstack(void) {
  return cogito_wrap_node(cogito_node_new(COGITO_NODE_HSTACK), COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_zstack(void) {
  return cogito_wrap_node(cogito_node_new(COGITO_NODE_ZSTACK), COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_fixed(void) {
  return cogito_wrap_node(cogito_node_new(COGITO_NODE_FIXED), COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_scroller(void) {
  return cogito_wrap_node(cogito_node_new(COGITO_NODE_SCROLLER), COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_carousel(void) {
  return cogito_wrap_node(cogito_node_new(COGITO_NODE_CAROUSEL), COGITO_HANDLE_NODE);
}

static void __cogito_carousel_set_active_index(ErgoVal carouselv, ErgoVal idxv) {
  cogito_node* carousel = cogito_node_from_val(carouselv);
  cogito_carousel_set_active_index(carousel, (int)ergo_as_int(idxv));
}

static ErgoVal __cogito_carousel_get_active_index(ErgoVal carouselv) {
  cogito_node* carousel = cogito_node_from_val(carouselv);
  int idx = cogito_carousel_get_active_index(carousel);
  return EV_INT(idx);
}

static ErgoVal __cogito_carousel_item(void) {
  return cogito_wrap_node(cogito_node_new(COGITO_NODE_CAROUSEL_ITEM), COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_list(void) {
  return cogito_wrap_node(cogito_node_new(COGITO_NODE_LIST), COGITO_HANDLE_NODE);
}

static ErgoVal __cogito_grid(ErgoVal cols) {
  return cogito_wrap_node(cogito_grid_new_with_cols((int)ergo_as_int(cols)), COGITO_HANDLE_NODE);
}

static void __cogito_container_add(ErgoVal parentv, ErgoVal childv) {
  cogito_node* parent = cogito_node_from_val(parentv);
  cogito_node* child = cogito_node_from_val(childv);
  cogito_node_add(parent, child);
}

static void __cogito_container_set_margins(ErgoVal nodev, ErgoVal left, ErgoVal top, ErgoVal right, ErgoVal bottom) {
  cogito_node* node = cogito_node_from_val(nodev);
  cogito_node_set_margins(node, (int)ergo_as_int(left), (int)ergo_as_int(top), (int)ergo_as_int(right), (int)ergo_as_int(bottom));
}

static void __cogito_container_set_align(ErgoVal nodev, ErgoVal align) {
  cogito_node* node = cogito_node_from_val(nodev);
  cogito_node_set_align(node, (int)ergo_as_int(align));
}

static void __cogito_container_set_halign(ErgoVal nodev, ErgoVal align) {
  cogito_node* node = cogito_node_from_val(nodev);
  cogito_node_set_halign(node, (int)ergo_as_int(align));
}

static void __cogito_container_set_valign(ErgoVal nodev, ErgoVal align) {
  cogito_node* node = cogito_node_from_val(nodev);
  cogito_node_set_valign(node, (int)ergo_as_int(align));
}

static void __cogito_container_set_hexpand(ErgoVal nodev, ErgoVal expand) {
  cogito_node* node = cogito_node_from_val(nodev);
  cogito_node_set_hexpand(node, ergo_as_bool(expand));
}

static void __cogito_container_set_vexpand(ErgoVal nodev, ErgoVal expand) {
  cogito_node* node = cogito_node_from_val(nodev);
  bool expand_bool = ergo_as_bool(expand);
  cogito_node_set_vexpand(node, expand_bool);
}

static void __cogito_container_set_gap(ErgoVal nodev, ErgoVal gap) {
  cogito_node* node = cogito_node_from_val(nodev);
  cogito_node_set_gap(node, (int)ergo_as_int(gap));
}

static void __cogito_container_set_padding(ErgoVal nodev, ErgoVal left, ErgoVal top, ErgoVal right, ErgoVal bottom) {
  cogito_node* node = cogito_node_from_val(nodev);
  cogito_node_set_padding(node, (int)ergo_as_int(left), (int)ergo_as_int(top), (int)ergo_as_int(right), (int)ergo_as_int(bottom));
}

static void __cogito_fixed_set_pos(ErgoVal fixedv, ErgoVal childv, ErgoVal xv, ErgoVal yv) {
  cogito_node* fixed = cogito_node_from_val(fixedv);
  cogito_node* child = cogito_node_from_val(childv);
  cogito_fixed_set_pos(fixed, child, (int)ergo_as_int(xv), (int)ergo_as_int(yv));
}

static void __cogito_scroller_set_axes(ErgoVal scv, ErgoVal hv, ErgoVal vv) {
  cogito_node* sc = cogito_node_from_val(scv);
  bool h = hv.tag == EVT_BOOL ? hv.as.b : false;
  bool v = vv.tag == EVT_BOOL ? vv.as.b : false;
  cogito_scroller_set_axes(sc, h, v);
}

static void __cogito_grid_set_gap(ErgoVal gridv, ErgoVal xv, ErgoVal yv) {
  cogito_node* grid = cogito_node_from_val(gridv);
  cogito_grid_set_gap(grid, (int)ergo_as_int(xv), (int)ergo_as_int(yv));
}

static void __cogito_grid_set_span(ErgoVal childv, ErgoVal col_span, ErgoVal row_span) {
  cogito_node* child = cogito_node_from_val(childv);
  cogito_grid_set_span(child, (int)ergo_as_int(col_span), (int)ergo_as_int(row_span));
}

static void __cogito_grid_set_align(ErgoVal childv, ErgoVal halign, ErgoVal valign) {
  cogito_node* child = cogito_node_from_val(childv);
  cogito_grid_set_align(child, (int)ergo_as_int(halign), (int)ergo_as_int(valign));
}

static void __cogito_node_set_disabled(ErgoVal nodev, ErgoVal onv) {
  cogito_node* node = cogito_node_from_val(nodev);
  cogito_node_set_disabled(node, onv.tag == EVT_BOOL ? onv.as.b : false);
}

static void __cogito_node_set_editable(ErgoVal nodev, ErgoVal onv) {
  cogito_node* node = cogito_node_from_val(nodev);
  cogito_node_set_editable(node, onv.tag == EVT_BOOL ? onv.as.b : false);
}

static ErgoVal __cogito_node_get_editable(ErgoVal nodev) {
  cogito_node* node = cogito_node_from_val(nodev);
  return EV_BOOL(cogito_node_get_editable(node));
}

static void __cogito_node_set_id(ErgoVal nodev, ErgoVal idv) {
  cogito_node* node = cogito_node_from_val(nodev);
  ErgoStr* tmp = NULL;
  const char* id = cogito_optional_cstr(idv, &tmp);
  if (id) cogito_node_set_id(node, id);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static void __cogito_button_set_text(ErgoVal btnv, ErgoVal textv) {
  cogito_node* btn = cogito_node_from_val(btnv);
  ErgoStr* tmp = NULL;
  const char* text = cogito_required_cstr(textv, &tmp);
  cogito_button_set_text(btn, text);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static void __cogito_button_on_click(ErgoVal btnv, ErgoVal handler) {
  cogito_node* btn = cogito_node_from_val(btnv);
  CogitoHandle* h = (CogitoHandle*)btnv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_click, handler);
    cogito_node_on_click(btn, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_click, handler);
  cogito_node_on_click(btn, cogito_cb_click, h);
}

static void __cogito_button_add_menu(ErgoVal btnv, ErgoVal labelv, ErgoVal handler) {
  cogito_node* btn = cogito_node_from_val(btnv);
  ErgoStr* tmp = NULL;
  const char* label = cogito_required_cstr(labelv, &tmp);
  CogitoMenuHandler* mh = handler.tag == EVT_FN ? cogito_menu_handler_new(handler) : NULL;
  cogito_button_add_menu(btn, label, mh ? cogito_cb_menu : NULL, mh);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static void __cogito_iconbtn_add_menu(ErgoVal btnv, ErgoVal labelv, ErgoVal handler) {
  cogito_node* btn = cogito_node_from_val(btnv);
  ErgoStr* tmp = NULL;
  const char* label = cogito_required_cstr(labelv, &tmp);
  CogitoMenuHandler* mh = handler.tag == EVT_FN ? cogito_menu_handler_new(handler) : NULL;
  cogito_iconbtn_add_menu(btn, label, mh ? cogito_cb_menu : NULL, mh);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static void __cogito_checkbox_set_checked(ErgoVal cbv, ErgoVal checkedv) {
  cogito_node* cb = cogito_node_from_val(cbv);
  cogito_checkbox_set_checked(cb, checkedv.tag == EVT_BOOL ? checkedv.as.b : false);
}

static ErgoVal __cogito_checkbox_get_checked(ErgoVal cbv) {
  cogito_node* cb = cogito_node_from_val(cbv);
  return EV_BOOL(cogito_checkbox_get_checked(cb));
}

static void __cogito_switch_set_checked(ErgoVal swv, ErgoVal checkedv) {
  cogito_node* sw = cogito_node_from_val(swv);
  cogito_switch_set_checked(sw, checkedv.tag == EVT_BOOL ? checkedv.as.b : false);
}

static ErgoVal __cogito_switch_get_checked(ErgoVal swv) {
  cogito_node* sw = cogito_node_from_val(swv);
  return EV_BOOL(cogito_switch_get_checked(sw));
}

static void __cogito_checkbox_on_change(ErgoVal cbv, ErgoVal handler) {
  cogito_node* cb = cogito_node_from_val(cbv);
  CogitoHandle* h = (CogitoHandle*)cbv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_change, handler);
    cogito_checkbox_on_change(cb, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_change, handler);
  cogito_checkbox_on_change(cb, cogito_cb_change, h);
}

static void __cogito_switch_on_change(ErgoVal swv, ErgoVal handler) {
  cogito_node* sw = cogito_node_from_val(swv);
  CogitoHandle* h = (CogitoHandle*)swv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_change, handler);
    cogito_switch_on_change(sw, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_change, handler);
  cogito_switch_on_change(sw, cogito_cb_change, h);
}

static void __cogito_textfield_set_text(ErgoVal tfv, ErgoVal textv) {
  cogito_node* tf = cogito_node_from_val(tfv);
  ErgoStr* tmp = NULL;
  const char* text = cogito_required_cstr(textv, &tmp);
  cogito_textfield_set_text(tf, text);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static ErgoVal __cogito_textfield_get_text(ErgoVal tfv) {
  cogito_node* tf = cogito_node_from_val(tfv);
  const char* text = cogito_textfield_get_text(tf);
  return EV_STR(stdr_str_lit(text ? text : ""));
}

static void __cogito_textfield_on_change(ErgoVal tfv, ErgoVal handler) {
  cogito_node* tf = cogito_node_from_val(tfv);
  CogitoHandle* h = (CogitoHandle*)tfv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_change, handler);
    cogito_textfield_on_change(tf, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_change, handler);
  cogito_textfield_on_change(tf, cogito_cb_change, h);
}

static void __cogito_textview_set_text(ErgoVal tvv, ErgoVal textv) {
  cogito_node* tv = cogito_node_from_val(tvv);
  ErgoStr* tmp = NULL;
  const char* text = cogito_required_cstr(textv, &tmp);
  cogito_textview_set_text(tv, text);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static ErgoVal __cogito_textview_get_text(ErgoVal tvv) {
  cogito_node* tv = cogito_node_from_val(tvv);
  const char* text = cogito_textview_get_text(tv);
  return EV_STR(stdr_str_lit(text ? text : ""));
}

static void __cogito_textview_on_change(ErgoVal tvv, ErgoVal handler) {
  cogito_node* tv = cogito_node_from_val(tvv);
  CogitoHandle* h = (CogitoHandle*)tvv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_change, handler);
    cogito_textview_on_change(tv, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_change, handler);
  cogito_textview_on_change(tv, cogito_cb_change, h);
}

static void __cogito_dropdown_set_items(ErgoVal ddv, ErgoVal itemsv) {
  cogito_node* dd = cogito_node_from_val(ddv);
  if (itemsv.tag != EVT_ARR) ergo_trap("cogito.dropdown_set_items expects array");
  ErgoArr* arr = (ErgoArr*)itemsv.as.p;
  size_t count = arr->len;
  const char** items = (const char**)calloc(count, sizeof(char*));
  ErgoStr** temps = (ErgoStr**)calloc(count, sizeof(ErgoStr*));
  for (size_t i = 0; i < count; i++) {
    items[i] = cogito_required_cstr(arr->items[i], &temps[i]);
  }
  cogito_dropdown_set_items(dd, items, count);
  for (size_t i = 0; i < count; i++) {
    if (temps[i]) ergo_release_val(EV_STR(temps[i]));
  }
  free(temps);
  free(items);
}

static void __cogito_dropdown_set_selected(ErgoVal ddv, ErgoVal idxv) {
  cogito_node* dd = cogito_node_from_val(ddv);
  cogito_dropdown_set_selected(dd, (int)ergo_as_int(idxv));
}

static ErgoVal __cogito_dropdown_get_selected(ErgoVal ddv) {
  cogito_node* dd = cogito_node_from_val(ddv);
  return EV_INT(cogito_dropdown_get_selected(dd));
}

static void __cogito_dropdown_on_change(ErgoVal ddv, ErgoVal handler) {
  cogito_node* dd = cogito_node_from_val(ddv);
  CogitoHandle* h = (CogitoHandle*)ddv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_change, handler);
    cogito_dropdown_on_change(dd, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_change, handler);
  cogito_dropdown_on_change(dd, cogito_cb_change, h);
}

static void __cogito_slider_set_value(ErgoVal slv, ErgoVal valuev) {
  cogito_node* sl = cogito_node_from_val(slv);
  cogito_slider_set_value(sl, ergo_as_float(valuev));
}

static ErgoVal __cogito_slider_get_value(ErgoVal slv) {
  cogito_node* sl = cogito_node_from_val(slv);
  return EV_FLOAT(cogito_slider_get_value(sl));
}

static void __cogito_slider_on_change(ErgoVal slv, ErgoVal handler) {
  cogito_node* sl = cogito_node_from_val(slv);
  CogitoHandle* h = (CogitoHandle*)slv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_change, handler);
    cogito_slider_on_change(sl, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_change, handler);
  cogito_slider_on_change(sl, cogito_cb_change, h);
}

static void __cogito_stepper_set_value(ErgoVal stv, ErgoVal valuev) {
  cogito_node* st = cogito_node_from_val(stv);
  cogito_stepper_set_value(st, ergo_as_float(valuev));
}

static ErgoVal __cogito_stepper_get_value(ErgoVal stv) {
  cogito_node* st = cogito_node_from_val(stv);
  return EV_FLOAT(cogito_stepper_get_value(st));
}

static void __cogito_stepper_on_change(ErgoVal stv, ErgoVal handler) {
  cogito_node* st = cogito_node_from_val(stv);
  CogitoHandle* h = (CogitoHandle*)stv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_change, handler);
    cogito_stepper_on_change(st, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_change, handler);
  cogito_stepper_on_change(st, cogito_cb_change, h);
}

static void __cogito_segmented_on_select(ErgoVal segv, ErgoVal handler) {
  cogito_node* seg = cogito_node_from_val(segv);
  CogitoHandle* h = (CogitoHandle*)segv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_change, handler);
    cogito_segmented_on_select(seg, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_change, handler);
  cogito_segmented_on_select(seg, cogito_cb_change, h);
}

static void __cogito_tabs_set_items(ErgoVal tabsv, ErgoVal itemsv) {
  cogito_node* tabs = cogito_node_from_val(tabsv);
  if (itemsv.tag != EVT_ARR) ergo_trap("cogito.tabs_set_items expects array");
  ErgoArr* arr = (ErgoArr*)itemsv.as.p;
  size_t count = arr->len;
  const char** items = (const char**)calloc(count, sizeof(char*));
  ErgoStr** temps = (ErgoStr**)calloc(count, sizeof(ErgoStr*));
  for (size_t i = 0; i < count; i++) {
    items[i] = cogito_required_cstr(arr->items[i], &temps[i]);
  }
  cogito_tabs_set_items(tabs, items, count);
  for (size_t i = 0; i < count; i++) {
    if (temps[i]) ergo_release_val(EV_STR(temps[i]));
  }
  free(temps);
  free(items);
}

static void __cogito_tabs_set_ids(ErgoVal tabsv, ErgoVal itemsv) {
  cogito_node* tabs = cogito_node_from_val(tabsv);
  if (itemsv.tag != EVT_ARR) ergo_trap("cogito.tabs_set_ids expects array");
  ErgoArr* arr = (ErgoArr*)itemsv.as.p;
  size_t count = arr->len;
  const char** items = (const char**)calloc(count, sizeof(char*));
  ErgoStr** temps = (ErgoStr**)calloc(count, sizeof(ErgoStr*));
  for (size_t i = 0; i < count; i++) {
    items[i] = cogito_required_cstr(arr->items[i], &temps[i]);
  }
  cogito_tabs_set_ids(tabs, items, count);
  for (size_t i = 0; i < count; i++) {
    if (temps[i]) ergo_release_val(EV_STR(temps[i]));
  }
  free(temps);
  free(items);
}

static void __cogito_tabs_set_selected(ErgoVal tabsv, ErgoVal idxv) {
  cogito_node* tabs = cogito_node_from_val(tabsv);
  cogito_tabs_set_selected(tabs, (int)ergo_as_int(idxv));
}

static ErgoVal __cogito_tabs_get_selected(ErgoVal tabsv) {
  cogito_node* tabs = cogito_node_from_val(tabsv);
  return EV_INT(cogito_tabs_get_selected(tabs));
}

static void __cogito_tabs_on_change(ErgoVal tabsv, ErgoVal handler) {
  cogito_node* tabs = cogito_node_from_val(tabsv);
  CogitoHandle* h = (CogitoHandle*)tabsv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_change, handler);
    cogito_tabs_on_change(tabs, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_change, handler);
  cogito_tabs_on_change(tabs, cogito_cb_change, h);
}

static void __cogito_tabs_bind(ErgoVal tabsv, ErgoVal viewv) {
  cogito_node* tabs = cogito_node_from_val(tabsv);
  cogito_node* view = cogito_node_from_val(viewv);
  cogito_tabs_bind(tabs, view);
}

static void __cogito_nav_rail_set_items(ErgoVal railv, ErgoVal labelsv, ErgoVal iconsv) {
  cogito_node* rail = cogito_node_from_val(railv);
  if (labelsv.tag != EVT_ARR) ergo_trap("cogito.nav_rail_set_items expects array of labels");
  ErgoArr* labels = (ErgoArr*)labelsv.as.p;
  size_t count = labels->len;

  const char** label_strs = (const char**)calloc(count, sizeof(char*));
  ErgoStr** label_temps = (ErgoStr**)calloc(count, sizeof(ErgoStr*));
  for (size_t i = 0; i < count; i++) {
    label_strs[i] = cogito_required_cstr(labels->items[i], &label_temps[i]);
  }

  const char** icon_strs = NULL;
  ErgoStr** icon_temps = NULL;
  if (iconsv.tag == EVT_ARR) {
    ErgoArr* icons = (ErgoArr*)iconsv.as.p;
    size_t icon_count = icons->len;
    icon_strs = (const char**)calloc(icon_count, sizeof(char*));
    icon_temps = (ErgoStr**)calloc(icon_count, sizeof(ErgoStr*));
    for (size_t i = 0; i < icon_count; i++) {
      icon_strs[i] = cogito_required_cstr(icons->items[i], &icon_temps[i]);
    }
    cogito_nav_rail_set_items(rail, label_strs, icon_strs, icon_count < count ? icon_count : count);
    for (size_t i = 0; i < icon_count; i++) {
      if (icon_temps[i]) ergo_release_val(EV_STR(icon_temps[i]));
    }
    free(icon_temps);
    free(icon_strs);
  } else {
    cogito_nav_rail_set_items(rail, label_strs, NULL, count);
  }

  for (size_t i = 0; i < count; i++) {
    if (label_temps[i]) ergo_release_val(EV_STR(label_temps[i]));
  }
  free(label_temps);
  free(label_strs);
}

static void __cogito_nav_rail_set_selected(ErgoVal railv, ErgoVal idxv) {
  cogito_node* rail = cogito_node_from_val(railv);
  cogito_nav_rail_set_selected(rail, (int)ergo_as_int(idxv));
}

static ErgoVal __cogito_nav_rail_get_selected(ErgoVal railv) {
  cogito_node* rail = cogito_node_from_val(railv);
  return EV_INT(cogito_nav_rail_get_selected(rail));
}

static ErgoVal __cogito_bottom_nav(void) {
  cogito_node* n = cogito_bottom_nav_new();
  return cogito_wrap_node(n, COGITO_HANDLE_NODE);
}

static void __cogito_nav_rail_on_change(ErgoVal railv, ErgoVal handler) {
  cogito_node* rail = cogito_node_from_val(railv);
  CogitoHandle* h = (CogitoHandle*)railv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_select, handler);
    cogito_nav_rail_on_change(rail, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_select, handler);
  cogito_nav_rail_on_change(rail, cogito_cb_select, h);
}

static void __cogito_bottom_nav_set_items(ErgoVal navv, ErgoVal labelsv, ErgoVal iconsv) {
  cogito_node* nav = cogito_node_from_val(navv);
  if (labelsv.tag != EVT_ARR) ergo_trap("cogito.bottom_nav_set_items expects array of labels");
  ErgoArr* labels = (ErgoArr*)labelsv.as.p;
  size_t count = labels->len;
  const char** label_strs = (const char**)calloc(count, sizeof(char*));
  ErgoStr** label_temps = (ErgoStr**)calloc(count, sizeof(ErgoStr*));
  for (size_t i = 0; i < count; i++) {
    label_strs[i] = cogito_required_cstr(labels->items[i], &label_temps[i]);
  }
  const char** icon_strs = NULL;
  ErgoStr** icon_temps = NULL;
  if (iconsv.tag == EVT_ARR) {
    ErgoArr* icons = (ErgoArr*)iconsv.as.p;
    size_t icon_count = icons->len;
    icon_strs = (const char**)calloc(icon_count, sizeof(char*));
    icon_temps = (ErgoStr**)calloc(icon_count, sizeof(ErgoStr*));
    for (size_t i = 0; i < icon_count; i++) {
      icon_strs[i] = cogito_required_cstr(icons->items[i], &icon_temps[i]);
    }
    cogito_bottom_nav_set_items(nav, label_strs, icon_strs, icon_count < count ? icon_count : count);
    for (size_t i = 0; i < icon_count; i++) {
      if (icon_temps[i]) ergo_release_val(EV_STR(icon_temps[i]));
    }
    free(icon_temps);
    free(icon_strs);
  } else {
    cogito_bottom_nav_set_items(nav, label_strs, NULL, count);
  }
  for (size_t i = 0; i < count; i++) {
    if (label_temps[i]) ergo_release_val(EV_STR(label_temps[i]));
  }
  free(label_temps);
  free(label_strs);
}

static void __cogito_bottom_nav_set_selected(ErgoVal navv, ErgoVal idxv) {
  cogito_node* nav = cogito_node_from_val(navv);
  cogito_bottom_nav_set_selected(nav, (int)ergo_as_int(idxv));
}

static ErgoVal __cogito_bottom_nav_get_selected(ErgoVal navv) {
  cogito_node* nav = cogito_node_from_val(navv);
  return EV_INT(cogito_bottom_nav_get_selected(nav));
}

static void __cogito_bottom_nav_on_change(ErgoVal navv, ErgoVal handler) {
  cogito_node* nav = cogito_node_from_val(navv);
  CogitoHandle* h = (CogitoHandle*)navv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_select, handler);
    cogito_bottom_nav_on_change(nav, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_select, handler);
  cogito_bottom_nav_on_change(nav, cogito_cb_select, h);
}

static void __cogito_view_switcher_set_active(ErgoVal viewv, ErgoVal idv) {
  cogito_node* view = cogito_node_from_val(viewv);
  ErgoStr* tmp = NULL;
  const char* id = cogito_required_cstr(idv, &tmp);
  cogito_view_switcher_set_active(view, id);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static void __cogito_progress_set_value(ErgoVal pv, ErgoVal valuev) {
  cogito_node* p = cogito_node_from_val(pv);
  cogito_progress_set_value(p, ergo_as_float(valuev));
}

static ErgoVal __cogito_progress_get_value(ErgoVal pv) {
  cogito_node* p = cogito_node_from_val(pv);
  return EV_FLOAT(cogito_progress_get_value(p));
}

static void __cogito_toast_set_text(ErgoVal tv, ErgoVal textv) {
  cogito_node* t = cogito_node_from_val(tv);
  ErgoStr* tmp = NULL;
  const char* text = cogito_required_cstr(textv, &tmp);
  cogito_toast_set_text(t, text);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static void __cogito_toast_on_click(ErgoVal tv, ErgoVal handler) {
  cogito_node* t = cogito_node_from_val(tv);
  CogitoHandle* h = (CogitoHandle*)tv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_click, handler);
    cogito_toast_on_click(t, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_click, handler);
  cogito_toast_on_click(t, cogito_cb_click, h);
}

static void __cogito_toast_set_action(ErgoVal tv, ErgoVal textv, ErgoVal handler) {
  cogito_node* t = cogito_node_from_val(tv);
  CogitoHandle* h = (CogitoHandle*)tv.as.p;
  ErgoStr* tmp = NULL;
  const char* text = cogito_required_cstr(textv, &tmp);
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_action, handler);
    cogito_toast_set_action(t, text, NULL, NULL);
    if (tmp) ergo_release_val(EV_STR(tmp));
    return;
  }
  cogito_set_handler(h, &h->on_action, handler);
  cogito_toast_set_action(t, text, cogito_cb_action, h);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static void __cogito_list_on_select(ErgoVal listv, ErgoVal handler) {
  cogito_node* list = cogito_node_from_val(listv);
  CogitoHandle* h = (CogitoHandle*)listv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_select, handler);
    cogito_list_on_select(list, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_select, handler);
  cogito_list_on_select(list, cogito_cb_select, h);
}

static void __cogito_list_on_activate(ErgoVal listv, ErgoVal handler) {
  cogito_node* list = cogito_node_from_val(listv);
  CogitoHandle* h = (CogitoHandle*)listv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_activate, handler);
    cogito_list_on_activate(list, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_activate, handler);
  cogito_list_on_activate(list, cogito_cb_activate, h);
}

static void __cogito_grid_on_select(ErgoVal gridv, ErgoVal handler) {
  cogito_node* grid = cogito_node_from_val(gridv);
  CogitoHandle* h = (CogitoHandle*)gridv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_select, handler);
    cogito_grid_on_select(grid, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_select, handler);
  cogito_grid_on_select(grid, cogito_cb_select, h);
}

static void __cogito_grid_on_activate(ErgoVal gridv, ErgoVal handler) {
  cogito_node* grid = cogito_node_from_val(gridv);
  CogitoHandle* h = (CogitoHandle*)gridv.as.p;
  if (handler.tag != EVT_FN) {
    cogito_set_handler(h, &h->on_activate, handler);
    cogito_grid_on_activate(grid, NULL, NULL);
    return;
  }
  cogito_set_handler(h, &h->on_activate, handler);
  cogito_grid_on_activate(grid, cogito_cb_activate, h);
}

static void __cogito_build(ErgoVal nodev, ErgoVal builder) {
  if (builder.tag != EVT_FN) ergo_trap("cogito.build expects function");
  ErgoVal arg = nodev;
  ergo_retain_val(arg);
  ErgoVal ret = ergo_call(builder, 1, &arg);
  ergo_release_val(arg);
  ergo_release_val(ret);
}

static ErgoVal __cogito_state_new(ErgoVal initial) { return cogito_state_new_val(initial); }
static ErgoVal __cogito_state_get(ErgoVal state) { return cogito_state_get_val(state); }
static void __cogito_state_set(ErgoVal state, ErgoVal value) { cogito_state_set_val(state, value); }

static void __cogito_run(ErgoVal appv, ErgoVal winv) {
  cogito_app* app = cogito_app_from_val(appv);
  cogito_window* win = cogito_window_from_val(winv);
  cogito_app_run(app, win);
}

static void __cogito_load_sum(ErgoVal pathv) {
  ErgoStr* tmp = NULL;
  const char* path = cogito_required_cstr(pathv, &tmp);
  cogito_load_sum_file(path);
  if (tmp) ergo_release_val(EV_STR(tmp));
}

static ErgoVal __cogito_open_url(ErgoVal urlv) {
  ErgoStr* tmp = NULL;
  const char* url = cogito_optional_cstr(urlv, &tmp);
  bool ok = false;
  if (url && url[0]) ok = cogito_open_url(url);
  if (tmp) ergo_release_val(EV_STR(tmp));
  return EV_BOOL(ok);
}

// ---- Codegen aliases ----
#define cogito_app_new __cogito_app
#define cogito_app_set_appid __cogito_app_set_appid
#define cogito_app_set_app_name __cogito_app_set_app_name
#define cogito_app_set_accent_color __cogito_app_set_accent_color
#define cogito_open_url __cogito_open_url
#define cogito_window_new __cogito_window
#define cogito_window_set_resizable __cogito_window_set_resizable
#define cogito_window_set_autosize __cogito_window_set_autosize
#define cogito_window_set_a11y_label __cogito_window_set_a11y_label
#define cogito_window_set_builder __cogito_window_set_builder
#define cogito_button_new __cogito_button
#define cogito_iconbtn_new __cogito_iconbtn
#define cogito_fab_new __cogito_fab
#define cogito_label_new __cogito_label
#define cogito_dialog_new __cogito_dialog
#define cogito_dialog_slot_new __cogito_dialog_slot
#define cogito_image_new __cogito_image
#define cogito_checkbox_new __cogito_checkbox
#define cogito_switch_new __cogito_switch
#define cogito_textfield_new __cogito_textfield
#define cogito_searchfield_new __cogito_searchfield
#define cogito_textview_new __cogito_textview
#define cogito_dropdown_new __cogito_dropdown
#define cogito_datepicker_new __cogito_datepicker
#define cogito_stepper_new __cogito_stepper
#define cogito_slider_new __cogito_slider
#define cogito_tabs_new __cogito_tabs
#define cogito_nav_rail_new __cogito_nav_rail
#define cogito_bottom_nav_new __cogito_bottom_nav
#define cogito_segmented_new __cogito_segmented
#define cogito_view_switcher_new __cogito_view_switcher
#define cogito_progress_new __cogito_progress
#define cogito_treeview_new __cogito_treeview
#define cogito_colorpicker_new __cogito_colorpicker
#define cogito_toasts_new __cogito_toasts
#define cogito_toast_new __cogito_toast
#define cogito_appbar_new __cogito_appbar
#define cogito_toolbar_new __cogito_toolbar
#define cogito_vstack_new __cogito_vstack
#define cogito_hstack_new __cogito_hstack
#define cogito_zstack_new __cogito_zstack
#define cogito_fixed_new __cogito_fixed
#define cogito_scroller_new __cogito_scroller
#define cogito_carousel_new __cogito_carousel
#define cogito_carousel_item_new __cogito_carousel_item
#define cogito_carousel_set_active_index __cogito_carousel_set_active_index
#define cogito_carousel_get_active_index __cogito_carousel_get_active_index
#define cogito_list_new __cogito_list
#define cogito_grid_new __cogito_grid
#define cogito_container_add __cogito_container_add
#define cogito_container_set_margins __cogito_container_set_margins
#define cogito_container_set_align __cogito_container_set_align
#define cogito_container_set_halign __cogito_container_set_halign
#define cogito_container_set_valign __cogito_container_set_valign
#define cogito_container_set_hexpand __cogito_container_set_hexpand
#define cogito_container_set_vexpand __cogito_container_set_vexpand
#define cogito_container_set_gap __cogito_container_set_gap
#define cogito_dialog_slot_show __cogito_dialog_slot_show
#define cogito_dialog_slot_clear __cogito_dialog_slot_clear
#define cogito_container_set_padding __cogito_container_set_padding
#define cogito_fixed_set_pos __cogito_fixed_set_pos
#define cogito_scroller_set_axes __cogito_scroller_set_axes
#define cogito_grid_set_gap __cogito_grid_set_gap
#define cogito_grid_set_span __cogito_grid_set_span
#define cogito_grid_set_align __cogito_grid_set_align
#define cogito_label_set_class __cogito_label_set_class
#define cogito_label_set_text __cogito_label_set_text
#define cogito_label_set_wrap __cogito_label_set_wrap
#define cogito_label_set_ellipsis __cogito_label_set_ellipsis
#define cogito_label_set_align __cogito_label_set_align
#define cogito_node_set_disabled __cogito_node_set_disabled
#define cogito_node_set_editable __cogito_node_set_editable
#define cogito_node_get_editable __cogito_node_get_editable
#define cogito_node_set_id __cogito_node_set_id
#define cogito_node_set_class __cogito_node_set_class
#define cogito_node_set_a11y_label __cogito_node_set_a11y_label
#define cogito_node_set_a11y_role __cogito_node_set_a11y_role
#define cogito_node_set_tooltip_val __cogito_node_set_tooltip
#define cogito_app_set_appid __cogito_app_set_appid
#define cogito_app_set_app_name __cogito_app_set_app_name
#define cogito_app_set_accent_color __cogito_app_set_accent_color
#define cogito_pointer_capture_set __cogito_pointer_capture
#define cogito_pointer_capture_clear __cogito_pointer_release
#define cogito_view_switcher_set_active __cogito_view_switcher_set_active
#define cogito_textfield_set_text __cogito_textfield_set_text
#define cogito_textfield_get_text __cogito_textfield_get_text
#define cogito_searchfield_set_text __cogito_searchfield_set_text
#define cogito_searchfield_get_text __cogito_searchfield_get_text
#define cogito_searchfield_on_change __cogito_searchfield_on_change
#define cogito_textfield_on_change __cogito_textfield_on_change
#define cogito_textview_set_text __cogito_textview_set_text
#define cogito_textview_get_text __cogito_textview_get_text
#define cogito_textview_on_change __cogito_textview_on_change
#define cogito_datepicker_on_change __cogito_datepicker_on_change
#define cogito_dropdown_set_items __cogito_dropdown_set_items
#define cogito_dropdown_set_selected __cogito_dropdown_set_selected
#define cogito_dropdown_get_selected __cogito_dropdown_get_selected
#define cogito_dropdown_on_change __cogito_dropdown_on_change
#define cogito_slider_set_value __cogito_slider_set_value
#define cogito_slider_get_value __cogito_slider_get_value
#define cogito_slider_on_change __cogito_slider_on_change
#define cogito_colorpicker_on_change __cogito_colorpicker_on_change
#define cogito_tabs_set_items __cogito_tabs_set_items
#define cogito_tabs_set_ids __cogito_tabs_set_ids
#define cogito_tabs_set_selected __cogito_tabs_set_selected
#define cogito_tabs_get_selected __cogito_tabs_get_selected
#define cogito_tabs_on_change __cogito_tabs_on_change
#define cogito_tabs_bind __cogito_tabs_bind
#define cogito_nav_rail_set_items __cogito_nav_rail_set_items
#define cogito_nav_rail_set_selected __cogito_nav_rail_set_selected
#define cogito_nav_rail_get_selected __cogito_nav_rail_get_selected
#define cogito_nav_rail_on_change __cogito_nav_rail_on_change
#define cogito_bottom_nav_set_items __cogito_bottom_nav_set_items
#define cogito_bottom_nav_set_selected __cogito_bottom_nav_set_selected
#define cogito_bottom_nav_get_selected __cogito_bottom_nav_get_selected
#define cogito_bottom_nav_on_change __cogito_bottom_nav_on_change
#define cogito_progress_set_value __cogito_progress_set_value
#define cogito_progress_get_value __cogito_progress_get_value
#define cogito_toast_set_text __cogito_toast_set_text
#define cogito_toast_on_click __cogito_toast_on_click
#define cogito_toast_set_action __cogito_toast_set_action
#define cogito_window_set_autosize __cogito_window_set_autosize
#define cogito_window_set_resizable __cogito_window_set_resizable
#define cogito_window_set_dialog __cogito_window_set_dialog
#define cogito_window_clear_dialog __cogito_window_clear_dialog
#define cogito_node_window_val __cogito_node_window
#define cogito_find_parent __cogito_find_parent
#define cogito_find_children __cogito_find_children
#define cogito_build __cogito_build
#define cogito_window_set_builder __cogito_window_set_builder
#define cogito_state_new __cogito_state_new
#define cogito_state_get __cogito_state_get
#define cogito_state_set __cogito_state_set
#define cogito_button_set_text __cogito_button_set_text
#define cogito_image_set_icon __cogito_image_set_icon
#define cogito_checkbox_set_checked __cogito_checkbox_set_checked
#define cogito_checkbox_get_checked __cogito_checkbox_get_checked
#define cogito_switch_set_checked __cogito_switch_set_checked
#define cogito_switch_get_checked __cogito_switch_get_checked
#define cogito_checkbox_on_change __cogito_checkbox_on_change
#define cogito_switch_on_change __cogito_switch_on_change
#define cogito_list_on_select __cogito_list_on_select
#define cogito_list_on_activate __cogito_list_on_activate
#define cogito_grid_on_select __cogito_grid_on_select
#define cogito_grid_on_activate __cogito_grid_on_activate
// Forward declare FFI functions with ErgoVal signature
void __cogito_button_on_click(ErgoVal btn, ErgoVal handler);
#define cogito_button_on_click __cogito_button_on_click
#define cogito_button_add_menu __cogito_button_add_menu
#define cogito_fab_set_extended __cogito_fab_set_extended
#define cogito_fab_on_click __cogito_fab_on_click
#define cogito_chip_new __cogito_chip
#define cogito_chip_set_selected __cogito_chip_set_selected
#define cogito_chip_get_selected __cogito_chip_get_selected
#define cogito_chip_set_closable __cogito_chip_set_closable
#define cogito_chip_on_click __cogito_chip_on_click
#define cogito_chip_on_close __cogito_chip_on_close
#define cogito_appbar_add_button __cogito_appbar_add_button
#define cogito_appbar_set_controls __cogito_appbar_set_controls
#define cogito_appbar_set_title __cogito_appbar_set_title
#define cogito_appbar_set_subtitle __cogito_appbar_set_subtitle
#define cogito_iconbtn_add_menu __cogito_iconbtn_add_menu
#define cogito_run __cogito_run
#define cogito_load_sum __cogito_load_sum
