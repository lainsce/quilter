// Cogito C API (opaque handles, synchronous callbacks)
#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CogitoApp cogito_app;
typedef struct CogitoNode cogito_node;
typedef struct CogitoNode cogito_window;

typedef void (*cogito_node_fn)(cogito_node* node, void* user);
typedef void (*cogito_index_fn)(cogito_node* node, int index, void* user);
typedef enum {
  COGITO_WINDOW_HITTEST_NORMAL = 0,
  COGITO_WINDOW_HITTEST_DRAGGABLE,
  COGITO_WINDOW_HITTEST_RESIZE_TOPLEFT,
  COGITO_WINDOW_HITTEST_RESIZE_TOP,
  COGITO_WINDOW_HITTEST_RESIZE_TOPRIGHT,
  COGITO_WINDOW_HITTEST_RESIZE_RIGHT,
  COGITO_WINDOW_HITTEST_RESIZE_BOTTOMRIGHT,
  COGITO_WINDOW_HITTEST_RESIZE_BOTTOM,
  COGITO_WINDOW_HITTEST_RESIZE_BOTTOMLEFT,
  COGITO_WINDOW_HITTEST_RESIZE_LEFT,
  COGITO_WINDOW_HITTEST_BUTTON_CLOSE,
  COGITO_WINDOW_HITTEST_BUTTON_MIN,
  COGITO_WINDOW_HITTEST_BUTTON_MAX,
} cogito_hit_test_result;
typedef cogito_hit_test_result (*cogito_hit_test_fn)(cogito_window* window, int x, int y, void* user);

typedef enum {
  COGITO_NODE_WINDOW = 1,
  COGITO_NODE_APPBAR,
  COGITO_NODE_VSTACK,
  COGITO_NODE_HSTACK,
  COGITO_NODE_ZSTACK,
  COGITO_NODE_FIXED,
  COGITO_NODE_SCROLLER,
  COGITO_NODE_LIST,
  COGITO_NODE_GRID,
  COGITO_NODE_LABEL,
  COGITO_NODE_BUTTON,
  COGITO_NODE_ICONBTN,
  COGITO_NODE_CHECKBOX,
  COGITO_NODE_SWITCH,
  COGITO_NODE_TEXTFIELD,
  COGITO_NODE_TEXTVIEW,
  COGITO_NODE_SEARCHFIELD,
  COGITO_NODE_DROPDOWN,
  COGITO_NODE_SLIDER,
  COGITO_NODE_TABS,
  COGITO_NODE_VIEW_SWITCHER,
  COGITO_NODE_PROGRESS,
  COGITO_NODE_DATEPICKER,
  COGITO_NODE_COLORPICKER,
  COGITO_NODE_STEPPER,
  COGITO_NODE_SEGMENTED,
  COGITO_NODE_TREEVIEW,
  COGITO_NODE_TOASTS,
  COGITO_NODE_TOAST,
  COGITO_NODE_BOTTOM_TOOLBAR,
  COGITO_NODE_CAROUSEL,
  COGITO_NODE_CAROUSEL_ITEM,
  COGITO_NODE_DIALOG,
  COGITO_NODE_DIALOG_SLOT,
  COGITO_NODE_TOOLTIP,
  COGITO_NODE_IMAGE,
  COGITO_NODE_CHIP,
  COGITO_NODE_FAB,
  COGITO_NODE_NAV_RAIL,
  COGITO_NODE_BOTTOM_NAV,
} cogito_node_kind;

// App / window lifecycle
cogito_app* cogito_app_new(void);
void cogito_app_free(cogito_app* app);
void cogito_app_run(cogito_app* app, cogito_window* window);

void cogito_app_set_appid(cogito_app* app, const char* rdnn);
void cogito_app_set_app_name(cogito_app* app, const char* name);
void cogito_app_set_accent_color(cogito_app* app, const char* hex, bool follow_system);
bool cogito_open_url(const char* url);

cogito_window* cogito_window_new(const char* title, int w, int h);
void cogito_window_free(cogito_window* window);
void cogito_window_set_resizable(cogito_window* window, bool on);
void cogito_window_set_autosize(cogito_window* window, bool on);
void cogito_window_set_a11y_label(cogito_window* window, const char* label);
void cogito_window_set_builder(cogito_window* window, cogito_node_fn builder, void* user);
void* cogito_window_get_native_handle(cogito_window* window);
bool cogito_window_has_native_handle(cogito_window* window);
void cogito_window_set_hit_test(cogito_window* window, cogito_hit_test_fn callback, void* user);
void cogito_hit_test_cleanup(void);
void cogito_window_set_debug_overlay(cogito_window* window, bool enable);
void cogito_rebuild_active_window(void);

// Node creation
cogito_node* cogito_node_new(cogito_node_kind kind);
cogito_node* cogito_grid_new_with_cols(int cols);
cogito_node* cogito_label_new(const char* text);
cogito_node* cogito_button_new(const char* text);
cogito_node* cogito_carousel_new(void);
cogito_node* cogito_carousel_item_new(void);
int cogito_carousel_get_active_index(cogito_node* node);
void cogito_carousel_set_active_index(cogito_node* node, int index);
cogito_node* cogito_iconbtn_new(const char* text);
cogito_node* cogito_checkbox_new(const char* text, const char* group);
cogito_node* cogito_chip_new(const char* text);
cogito_node* cogito_fab_new(const char* icon);
cogito_node* cogito_nav_rail_new(void);
cogito_node* cogito_bottom_nav_new(void);
cogito_node* cogito_switch_new(const char* text);
cogito_node* cogito_textfield_new(const char* text);
cogito_node* cogito_textview_new(const char* text);
cogito_node* cogito_searchfield_new(const char* text);
cogito_node* cogito_dropdown_new(void);
cogito_node* cogito_slider_new(double min, double max, double value);
cogito_node* cogito_tabs_new(void);
cogito_node* cogito_view_switcher_new(void);
cogito_node* cogito_progress_new(double value);
cogito_node* cogito_divider_new(const char* orientation, bool is_inset);
cogito_node* cogito_datepicker_new(void);
cogito_node* cogito_colorpicker_new(void);
cogito_node* cogito_stepper_new(double min, double max, double value, double step);
cogito_node* cogito_segmented_new(void);
cogito_node* cogito_treeview_new(void);
cogito_node* cogito_toasts_new(void);
cogito_node* cogito_toast_new(const char* text);
cogito_node* cogito_bottom_toolbar_new(void);
cogito_node* cogito_dialog_new(const char* title);
cogito_node* cogito_dialog_slot_new(void);
cogito_node* cogito_appbar_new(const char* title, const char* subtitle);
void cogito_appbar_set_title(cogito_node* appbar, const char* title);
void cogito_appbar_set_subtitle(cogito_node* appbar, const char* subtitle);
cogito_node* cogito_image_new(const char* icon);

// Tree / layout
void cogito_node_add(cogito_node* parent, cogito_node* child);
void cogito_node_remove(cogito_node* parent, cogito_node* child);
void cogito_node_free(cogito_node* node);

void cogito_node_set_margins(cogito_node* node, int left, int top, int right, int bottom);
void cogito_node_set_padding(cogito_node* node, int left, int top, int right, int bottom);
void cogito_node_set_align(cogito_node* node, int align);
void cogito_node_set_halign(cogito_node* node, int align);
void cogito_node_set_valign(cogito_node* node, int align);
void cogito_node_set_hexpand(cogito_node* node, bool expand);
void cogito_node_set_vexpand(cogito_node* node, bool expand);
void cogito_node_set_gap(cogito_node* node, int gap);
void cogito_node_set_id(cogito_node* node, const char* id);

// Common props
void cogito_node_set_text(cogito_node* node, const char* text);
const char* cogito_node_get_text(cogito_node* node);
void cogito_node_set_disabled(cogito_node* node, bool on);
void cogito_node_set_editable(cogito_node* node, bool on);
bool cogito_node_get_editable(cogito_node* node);
void cogito_node_set_class(cogito_node* node, const char* cls);
void cogito_node_set_a11y_label(cogito_node* node, const char* label);
void cogito_node_set_a11y_role(cogito_node* node, const char* role);
void cogito_node_set_tooltip(cogito_node* node, const char* text);
void cogito_node_build(cogito_node* node, cogito_node_fn builder, void* user);
void cogito_pointer_capture(cogito_node* node);
void cogito_pointer_release(void);

// Callbacks
void cogito_node_on_click(cogito_node* node, cogito_node_fn fn, void* user);
void cogito_node_on_change(cogito_node* node, cogito_node_fn fn, void* user);
void cogito_node_on_select(cogito_node* node, cogito_index_fn fn, void* user);
void cogito_node_on_activate(cogito_node* node, cogito_index_fn fn, void* user);

// Widget-specific helpers
void cogito_dropdown_set_items(cogito_node* dropdown, const char** items, size_t count);
int cogito_dropdown_get_selected(cogito_node* dropdown);
void cogito_dropdown_set_selected(cogito_node* dropdown, int idx);

void cogito_tabs_set_items(cogito_node* tabs, const char** items, size_t count);
void cogito_tabs_set_ids(cogito_node* tabs, const char** ids, size_t count);
int cogito_tabs_get_selected(cogito_node* tabs);
void cogito_tabs_set_selected(cogito_node* tabs, int idx);
void cogito_tabs_bind(cogito_node* tabs, cogito_node* view_switcher);

void cogito_nav_rail_set_items(cogito_node* rail, const char** labels, const char** icons, size_t count);
int cogito_nav_rail_get_selected(cogito_node* rail);
void cogito_nav_rail_set_selected(cogito_node* rail, int idx);
void cogito_nav_rail_on_change(cogito_node* rail, cogito_index_fn fn, void* user);

void cogito_bottom_nav_set_items(cogito_node* nav, const char** labels, const char** icons, size_t count);
int cogito_bottom_nav_get_selected(cogito_node* nav);
void cogito_bottom_nav_set_selected(cogito_node* nav, int idx);
void cogito_bottom_nav_on_change(cogito_node* nav, cogito_index_fn fn, void* user);

double cogito_slider_get_value(cogito_node* slider);
void cogito_slider_set_value(cogito_node* slider, double value);

bool cogito_checkbox_get_checked(cogito_node* cb);
void cogito_checkbox_set_checked(cogito_node* cb, bool checked);

bool cogito_chip_get_selected(cogito_node* chip);
void cogito_chip_set_selected(cogito_node* chip, bool selected);
void cogito_chip_set_closable(cogito_node* chip, bool closable);

bool cogito_switch_get_checked(cogito_node* sw);
void cogito_switch_set_checked(cogito_node* sw, bool checked);

void cogito_textfield_set_text(cogito_node* tf, const char* text);
const char* cogito_textfield_get_text(cogito_node* tf);
void cogito_textview_set_text(cogito_node* tv, const char* text);
const char* cogito_textview_get_text(cogito_node* tv);
void cogito_searchfield_set_text(cogito_node* sf, const char* text);
const char* cogito_searchfield_get_text(cogito_node* sf);

void cogito_progress_set_value(cogito_node* prog, double value);
double cogito_progress_get_value(cogito_node* prog);

void cogito_stepper_set_value(cogito_node* stepper, double value);
double cogito_stepper_get_value(cogito_node* stepper);
void cogito_stepper_on_change(cogito_node* stepper, cogito_node_fn fn, void* user);
void cogito_segmented_on_select(cogito_node* seg, cogito_node_fn fn, void* user);

// Theming
void cogito_load_sum_file(const char* path);
void cogito_load_sum_inline(const char* src);
bool cogito_debug_style(void);
void cogito_style_dump(cogito_node* node);
void cogito_style_dump_tree(cogito_node* root, int depth);
void cogito_style_dump_button_demo(void);

#ifdef __cplusplus
}
#endif
// Label helpers
void cogito_label_set_text(cogito_node* label, const char* text);
void cogito_label_set_wrap(cogito_node* label, bool on);
void cogito_label_set_ellipsis(cogito_node* label, bool on);
void cogito_label_set_align(cogito_node* label, int align);

// Image helpers
void cogito_image_set_icon(cogito_node* image, const char* icon);

// Appbar helpers
cogito_node* cogito_appbar_add_button(cogito_node* appbar, const char* icon, cogito_node_fn fn, void* user);
void cogito_appbar_set_controls(cogito_node* appbar, const char* layout);

// Dialog helpers
void cogito_dialog_slot_show(cogito_node* slot, cogito_node* dialog);
void cogito_dialog_slot_clear(cogito_node* slot);
void cogito_dialog_close(cogito_node* dialog);
void cogito_dialog_remove(cogito_node* dialog);
void cogito_window_set_dialog(cogito_window* window, cogito_node* dialog);
void cogito_window_clear_dialog(cogito_window* window);

// Containers and layout helpers
void cogito_fixed_set_pos(cogito_node* fixed, cogito_node* child, int x, int y);
void cogito_scroller_set_axes(cogito_node* scroller, bool h, bool v);
void cogito_carousel_set_active_index(cogito_node* carousel, int idx);
int cogito_carousel_get_active_index(cogito_node* carousel);
void cogito_grid_set_gap(cogito_node* grid, int x, int y);
void cogito_grid_set_span(cogito_node* child, int col_span, int row_span);
void cogito_grid_set_align(cogito_node* child, int halign, int valign);

// Widget event helpers
void cogito_button_set_text(cogito_node* button, const char* text);
void cogito_button_add_menu(cogito_node* button, const char* label, cogito_node_fn fn, void* user);
void cogito_iconbtn_add_menu(cogito_node* button, const char* label, cogito_node_fn fn, void* user);

void cogito_checkbox_on_change(cogito_node* cb, cogito_node_fn fn, void* user);
void cogito_chip_on_click(cogito_node* chip, cogito_node_fn fn, void* user);
void cogito_chip_on_close(cogito_node* chip, cogito_node_fn fn, void* user);
void cogito_fab_set_extended(cogito_node* fab, bool extended, const char* label);
void cogito_fab_on_click(cogito_node* fab, cogito_node_fn fn, void* user);
void cogito_switch_on_change(cogito_node* sw, cogito_node_fn fn, void* user);

void cogito_textfield_on_change(cogito_node* tf, cogito_node_fn fn, void* user);
void cogito_textview_on_change(cogito_node* tv, cogito_node_fn fn, void* user);
void cogito_searchfield_on_change(cogito_node* sf, cogito_node_fn fn, void* user);

void cogito_dropdown_on_change(cogito_node* dropdown, cogito_node_fn fn, void* user);
void cogito_slider_on_change(cogito_node* slider, cogito_node_fn fn, void* user);
void cogito_tabs_on_change(cogito_node* tabs, cogito_node_fn fn, void* user);
void cogito_datepicker_on_change(cogito_node* datepicker, cogito_node_fn fn, void* user);
void cogito_colorpicker_on_change(cogito_node* colorpicker, cogito_node_fn fn, void* user);

void cogito_list_on_select(cogito_node* list, cogito_index_fn fn, void* user);
void cogito_list_on_activate(cogito_node* list, cogito_index_fn fn, void* user);
void cogito_grid_on_select(cogito_node* grid, cogito_index_fn fn, void* user);
void cogito_grid_on_activate(cogito_node* grid, cogito_index_fn fn, void* user);

void cogito_view_switcher_set_active(cogito_node* view_switcher, const char* id);

void cogito_toast_set_text(cogito_node* toast, const char* text);
void cogito_toast_on_click(cogito_node* toast, cogito_node_fn fn, void* user);
void cogito_toast_set_action(cogito_node* toast, const char* action_text, cogito_node_fn fn, void* user);

// Node/window helpers
cogito_window* cogito_node_window(cogito_node* node);
cogito_node* cogito_node_get_parent(cogito_node* node);
cogito_node* cogito_node_parent(cogito_node* node);
size_t cogito_node_get_child_count(cogito_node* node);
cogito_node* cogito_node_get_child(cogito_node* node, size_t index);
