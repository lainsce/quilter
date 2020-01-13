/*
* Copyright (C) 2020 Lains
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/
namespace Quilter {
    public class MainWindow : Gtk.ApplicationWindow {
        public Widgets.StatusBar statusbar;
        public Widgets.SideBar sidebar;
        public Widgets.SearchBar searchbar;
        public Widgets.Headerbar toolbar;
        public Gtk.MenuButton set_font_menu;
        public Widgets.EditView edit_view_content;
        public Widgets.Preview preview_view_content;
        public Gtk.Stack main_stack;
        public Gtk.Stack stack;
        public Gtk.StackSwitcher view_mode;
        public Gtk.Paned paned;
        public Gtk.ScrolledWindow edit_view;
        public Gtk.ScrolledWindow preview_view;
        public Gtk.Grid grid;
        public Gtk.Grid main_pane;
        public SimpleActionGroup actions { get; construct; }
        public const string ACTION_PREFIX = "win.";
        public const string ACTION_CHEATSHEET = "action_cheatsheet";
        public const string ACTION_PREFS = "action_preferences";
        public const string ACTION_EXPORT_PDF = "action_export_pdf";
        public const string ACTION_EXPORT_HTML = "action_export_html";
        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();
        
        private const GLib.ActionEntry[] action_entries = {
            { ACTION_CHEATSHEET, action_cheatsheet },
            { ACTION_PREFS, action_preferences },
            { ACTION_EXPORT_PDF, action_export_pdf },
            { ACTION_EXPORT_HTML, action_export_html }
        };
        
        public bool is_fullscreen {
            get {
                return gsettings.get_boolean("fullscreen");
            }
            set {
                gsettings.set_boolean("fullscreen", value);
                if (value) {
                    fullscreen ();
                    gsettings.set_boolean("statusbar", false);
                    gsettings.set_boolean("sidebar", true);
                    var buffer_context = edit_view_content.get_style_context ();
                    buffer_context.add_class ("full-text");
                    buffer_context.remove_class ("small-text");
                } else {
                    unfullscreen ();
                    gsettings.set_boolean("statusbar", true);
                    var buffer_context = edit_view_content.get_style_context ();
                    buffer_context.add_class ("small-text");
                    buffer_context.remove_class ("full-text");
                }
                
                edit_view_content.dynamic_margins ();
            }
        }
        
        public MainWindow (Gtk.Application app) {
            Object (
                application: app,
                resizable: true,
                title: _("Quilter")
            );
            
            // Ensure the folder used in the init is cache and exists
            Services.FileManager.get_cache_path ();
            
            if (gsettings.get_string("current-file") == "") {
                Services.FileManager.get_cache_path ();
                var file = Services.FileManager.get_cache_path ();
                gsettings.set_string("current-file", file);
                sidebar.add_file (file);
                edit_view_content.buffer.text = "";
            }
            
            gsettings.changed.connect (on_gsettings_changed);
            on_gsettings_changed ();
            
            edit_view_content.buffer.changed.connect (() => {
                render_func ();
                update_count ();
                scroll_to ();
                
                if (gsettings.get_string("current-file") != "") {
                    sidebar.store.clear ();
                    sidebar.outline_populate ();
                    sidebar.view.expand_all ();
                } else {
                    Services.FileManager.get_cache_path ();
                    sidebar.add_file (Services.FileManager.get_cache_path ());
                    gsettings.set_string("current-file", Services.FileManager.get_cache_path ());
                    edit_view_content.buffer.text = "";
                }
            });
            
            key_press_event.connect ((e) => {
                uint keycode = e.hardware_keycode;
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.q, keycode)) {
                        this.destroy ();
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.n, keycode)) {
                        on_create_new ();
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.s, keycode)) {
                        on_save ();
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if ((e.state & Gdk.ModifierType.SHIFT_MASK) != 0) {
                        if (match_keycode (Gdk.Key.s, keycode)) {
                            on_save_as ();
                        }
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.o, keycode)) {
                        on_open ();
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.f, keycode)) {
                        if (gsettings.get_boolean("searchbar") == false) {
                            gsettings.set_boolean("searchbar", true);
                            searchbar.search_entry.grab_focus_without_selecting();
                        } else {
                            gsettings.set_boolean("searchbar", false);
                        }
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.h, keycode)) {
                        var cheatsheet_dialog = new Widgets.Cheatsheet (this);
                        cheatsheet_dialog.show_all ();
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.z, keycode)) {
                        edit_view_content.buffer.undo ();
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK + Gdk.ModifierType.SHIFT_MASK) != 0) {
                    if (match_keycode (Gdk.Key.z, keycode)) {
                        edit_view_content.buffer.redo ();
                    }
                }
                if (match_keycode (Gdk.Key.F11, keycode)) {
                    is_fullscreen = !is_fullscreen;
                }
                if (match_keycode (Gdk.Key.F1, keycode)) {
                    debug ("Press to change view...");
                    if (gsettings.get_string("preview-type") == "full") {
                        if (this.stack.get_visible_child_name () == "preview_view") {
                            this.stack.set_visible_child (this.edit_view);
                        } else if (this.stack.get_visible_child_name () == "edit_view") {
                            this.stack.set_visible_child (this.preview_view);
                        }
                    }
                    return true;
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.@1, keycode)) {
                        debug ("Press to change view...");
                        if (gsettings.get_string("preview-type") == "full") {
                            if (this.stack.get_visible_child_name () == "preview_view") {
                                this.stack.set_visible_child (this.edit_view);
                            } else if (this.stack.get_visible_child_name () == "edit_view") {
                                this.stack.set_visible_child (this.preview_view);
                            }
                        }
                        return true;
                    }
                }
                if (match_keycode (Gdk.Key.F2, keycode)) {
                    debug ("Press to change view...");
                    if (gsettings.get_boolean("sidebar")) {
                        gsettings.set_boolean("sidebar", false);
                    } else {
                        gsettings.set_boolean("sidebar", true);
                    }
                    return true;
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.@2, keycode)) {
                        debug ("Press to change view...");
                        if (gsettings.get_boolean("sidebar")) {
                            gsettings.set_boolean("sidebar", false);
                        } else {
                            gsettings.set_boolean("sidebar", true);
                        }
                        return true;
                    }
                }
                return false;
            });
        }
        
        construct {
            
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/com/github/lainsce/quilter/app-main-stylesheet.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            var provider2 = new Gtk.CssProvider ();
            provider2.load_from_resource ("/com/github/lainsce/quilter/app-font-stylesheet.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider2, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            
            toolbar = new Widgets.Headerbar (this);
            toolbar.open.connect (on_open);
            toolbar.save.connect (on_save);
            toolbar.save_as.connect (on_save_as);
            toolbar.create_new.connect (on_create_new);
            toolbar.title = this.title;
            toolbar.has_subtitle = false;
            this.set_titlebar (toolbar);
            
            var set_font_sans = new Gtk.RadioButton.with_label_from_widget (null, _("Use Sans-serif"));
            set_font_sans.toggled.connect (() => {
                gsettings.set_string("preview-font", "sans");
            });
            
            var set_font_serif = new Gtk.RadioButton.with_label_from_widget (set_font_sans, _("Use Serif"));
            set_font_serif.toggled.connect (() => {
                gsettings.set_string("preview-font", "serif");
            });
            set_font_serif.set_active (true);
            
            var set_font_mono = new Gtk.RadioButton.with_label_from_widget (set_font_sans, _("Use Monospace"));
            set_font_mono.toggled.connect (() => {
                gsettings.set_string("preview-font", "mono");
            });
            
            var set_font_menu_grid = new Gtk.Grid ();
            set_font_menu_grid.margin = 12;
            set_font_menu_grid.row_spacing = 12;
            set_font_menu_grid.column_spacing = 12;
            set_font_menu_grid.orientation = Gtk.Orientation.VERTICAL;
            set_font_menu_grid.add (set_font_sans);
            set_font_menu_grid.add (set_font_serif);
            set_font_menu_grid.add (set_font_mono);
            set_font_menu_grid.show_all ();
            
            var set_font_menu_pop = new Gtk.Popover (null);
            set_font_menu_pop.add (set_font_menu_grid);
            
            set_font_menu = new Gtk.MenuButton ();
            set_font_menu.tooltip_text = _("Set Preview Font");
            set_font_menu.popover = set_font_menu_pop;
            
            edit_view = new Gtk.ScrolledWindow (null, null);
            edit_view_content = new Widgets.EditView (this);
            edit_view_content.save.connect (() => on_save ());
            edit_view.add (edit_view_content);
            
            preview_view = new Gtk.ScrolledWindow (null, null);
            preview_view_content = new Widgets.Preview (this, edit_view_content.buffer);
            preview_view.add (preview_view_content);
            ((Gtk.Viewport) preview_view.get_child ()).set_vscroll_policy (Gtk.ScrollablePolicy.NATURAL);
            
            stack = new Gtk.Stack ();
            stack.hexpand = true;
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            
            if (gsettings.get_string("preview-type") == "full") {
                bool v = gsettings.get_boolean("shown-view");
                if (v) {
                    stack.set_visible_child (preview_view);
                } else {
                    stack.set_visible_child (edit_view);
                }
            }
            
            view_mode = new Gtk.StackSwitcher ();
            view_mode.stack = stack;
            view_mode.valign = Gtk.Align.CENTER;
            view_mode.homogeneous = true;
            view_mode.tooltip_markup = Granite.markup_accel_tooltip (
            {"F1"},
            _("Change view")
            );
            
            toolbar.pack_end (set_font_menu);
            toolbar.pack_end (view_mode);
            
            paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            paned.set_position (gsettings.get_int("window-width")/2);
            
            main_stack = new Gtk.Stack ();
            main_stack.hexpand = true;
            main_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
            main_stack.add_named (stack, "stack");
            main_stack.add_named (paned, "paned");
            
            change_layout ();
            
            actions = new SimpleActionGroup ();
            actions.add_action_entries (action_entries, this);
            insert_action_group ("win", actions);
            
            statusbar = new Widgets.StatusBar (edit_view_content.buffer);
            sidebar = new Widgets.SideBar (this);
            sidebar.row_selected.connect (on_sidebar_row_selected);
            sidebar.save_as.connect (() => on_save_as ());
            searchbar = new Widgets.SearchBar (this);
            
            grid = new Gtk.Grid ();
            grid.set_column_homogeneous (false);
            grid.set_row_homogeneous (false);
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.attach (searchbar, 0, 0, 2, 1);
            grid.attach (sidebar, 0, 1, 1, 1);
            grid.attach (main_stack, 1, 1, 1, 1);
            grid.attach (statusbar, 0, 2, 2, 1);
            grid.show_all ();
            this.add (grid);
            
            int x = gsettings.get_int("window-x");
            int y = gsettings.get_int("window-y");
            int w = gsettings.get_int("window-width");
            int h = gsettings.get_int("window-height");
            
            if (x != -1 && y != -1) {
                this.move (x, y);
            }
            if (w != 0 && h != 0) {
                this.resize (w, h);
            }
            
            update_title ();
            if (gsettings.get_string("current-file") != "") {
                on_sidebar_row_selected (sidebar.get_selected_row ());
            }
            
            Gtk.Adjustment eadj = edit_view.get_vadjustment ();
            Gtk.Adjustment padj = preview_view.get_vadjustment ();
            eadj.value_changed.connect (() => {
                scroll_to ();
            });
            padj.value_changed.connect (() => {
                scroll_to_fix ();
            });
            padj.set_lower(1);
            
            if (!Granite.Services.System.history_is_enabled ()) {
                edit_view_content.buffer.text = "";
                Services.FileManager.file = null;
                toolbar.set_subtitle (_("No Documents Open"));
                sidebar.store.clear ();
                sidebar.delete_row ();
                statusbar.readtimecount_label.set_text((_("Reading Time: ")) + "0m");
            }
            
            try {
                this.icon = Gtk.IconTheme.get_default ().load_icon ("com.github.lainsce.quilter", Gtk.IconSize.DIALOG, 0);
            } catch (Error e) {
            }
            
            this.window_position = Gtk.WindowPosition.CENTER;
            this.set_size_request (600, 700);
        }
        
        #if VALA_0_42
        protected bool match_keycode (uint keyval, uint code) {
            #else
            protected bool match_keycode (int keyval, uint code) {
                #endif
                Gdk.KeymapKey [] keys;
                Gdk.Keymap keymap = Gdk.Keymap.get_for_display (Gdk.Display.get_default ());
                if (keymap.get_entries_for_keyval (keyval, out keys)) {
                    foreach (var key in keys) {
                        if (code == key.keycode)
                        return true;
                    }
                }
                
                return false;
            }
            
            public override bool delete_event (Gdk.EventAny event) {
                int x, y, w, h;
                get_position (out x, out y);
                get_size (out w, out h);
                
                
                gsettings.set_int("window-x", x);
                gsettings.set_int("window-y", y);
                gsettings.set_int("window-width", w);
                gsettings.set_int("window-height", h);
                
                string[] files = {};
                foreach (unowned Widgets.SideBarBox row in sidebar.get_rows ()) {
                    if (row.path != _("No Documents Open"))
                    files += row.path;
                }
                
                gsettings.set_strv("last-files", files);
                set_prev_workfile ();
                
                on_save ();
                return false;
            }
            
            public void scroll_to () {
                Gtk.Adjustment eadj = edit_view.get_vadjustment ();
                Gtk.Adjustment padj = preview_view.get_vadjustment ();
                var value = eadj.get_value();
                var psize_edit = eadj.get_page_size();
                var psize_prev = padj.get_page_size();
                var upper_edit = eadj.get_upper();
                var upper_prev = padj.get_upper();
                
                if (value >= (upper_edit - psize_edit)) {
                    padj.set_value(upper_prev - psize_prev);
                } else {
                    padj.set_value(value / upper_edit * upper_prev);
                }
                
                padj.value_changed.connect (() => {
                    scroll_to_fix ();
                });
            }
            
            public void scroll_to_fix () {
                Gtk.Adjustment adj = preview_view.get_vadjustment ();
                var value = adj.get_value();
                if (value == 0) {
                    scroll_to ();
                } else {
                    // pass
                }
            }
            
            private static void widget_unparent (Gtk.Widget widget) {
                unowned Gtk.Container? parent = widget.get_parent ();
                if (parent == null) {
                    return;
                }
                
                parent.remove (widget);
            }
            
            private void update_count () {
                
                if (gsettings.get_string("track-type") == "words") {
                    statusbar.update_wordcount ();
                    gsettings.set_string("track-type", "words");
                } else if (gsettings.get_string("track-type") == "lines") {
                    statusbar.update_linecount ();
                    gsettings.set_string("track-type", "lines");
                } else if (gsettings.get_string("track-type") == "chars") {
                    statusbar.update_charcount ();
                    gsettings.set_string("track-type", "chars");
                }
                statusbar.update_readtimecount ();
            }
            
            private void action_preferences () {
                var dialog = new Widgets.Preferences (this);
                dialog.set_modal (true);
                dialog.transient_for = this;
                dialog.show_all ();
            }
            
            private void action_cheatsheet () {
                var dialog = new Widgets.Cheatsheet (this);
                dialog.set_modal (true);
                dialog.transient_for = this;
                dialog.show_all ();
            }
            
            private void action_export_pdf () {
                Services.ExportUtils.export_pdf ();
            }
            
            private void action_export_html () {
                Services.ExportUtils.export_html ();
            }
            
            private void render_func () {
                preview_view_content.update_html_view ();
                if (edit_view_content.buffer.get_modified () == true) {
                    preview_view_content.update_html_view ();
                    edit_view_content.buffer.set_modified (false);
                }
            }
            
            public void show_sidebar () {
                
                sidebar.show_this = gsettings.get_boolean("sidebar");
                sidebar.reveal_child = gsettings.get_boolean("sidebar");
            }
            
            public void show_statusbar () {
                
                statusbar.reveal_child = gsettings.get_boolean("statusbar");
            }
            
            public void show_searchbar () {
                
                searchbar.reveal_child = gsettings.get_boolean("searchbar");
            }
            
            private void update_title () {
                unowned Widgets.SideBarBox? row = sidebar.get_selected_row ();
                if (row != null) {
                    toolbar.set_subtitle (row.title);
                } else {
                    toolbar.set_subtitle (_("No Documents Open"));
                }
            }
            
            private void set_prev_workfile () {
                unowned Widgets.SideBarBox? row = sidebar.get_selected_row ();
                
                if (row != null && gsettings.get_string("current-file") != _("No Documents Open")) {
                    gsettings.set_string("current-file", row.path);
                }
            }
            
            private void on_gsettings_changed () {
                show_statusbar ();
                show_sidebar ();
                show_searchbar ();
                update_count ();
                edit_view_content.dynamic_margins ();
                change_layout ();
                
                if (!gsettings.get_boolean("focus-mode")) {
                    set_font_menu.image = new Gtk.Image.from_icon_name ("font-select-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
                } else {
                    set_font_menu.image = new Gtk.Image.from_icon_name ("font-select-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
                }
                
                if (gsettings.get_string("current-file") != "" || gsettings.get_string("current-file") != _("No Documents Open")) {
                    // pass
                } else {
                    Services.FileManager.get_cache_path ();
                    sidebar.add_file (Services.FileManager.get_cache_path ());
                    gsettings.set_string("current-file", Services.FileManager.get_cache_path ());
                    edit_view_content.buffer.text = "";
                }
            }
            
            private void change_layout () {
                if (gsettings.get_string("preview-type") == "full") {
                    widget_unparent (edit_view);
                    widget_unparent (preview_view);
                    stack.add_titled (edit_view, "edit_view", _("Edit"));
                    stack.add_titled (preview_view, "preview_view", _("Preview"));
                    main_stack.set_visible_child (stack);
                } else {
                    foreach (Gtk.Widget w in stack.get_children ()) {
                        stack.remove (w);
                    }
                    widget_unparent (edit_view);
                    widget_unparent (preview_view);
                    paned.pack1 (edit_view, false, false);
                    paned.pack2 (preview_view, false, false);
                    main_stack.set_visible_child (paned);
                }
            }
            
            private void on_create_new () {
                var dialog = new Services.DialogUtils.Dialog ();
                dialog.transient_for = this;
                
                dialog.response.connect ((response_id) => {
                    switch (response_id) {
                        case Gtk.ResponseType.OK:
                        debug ("User saves the file.");
                        unowned Widgets.SideBarBox? row = sidebar.get_selected_row ();
                        if (row != null && row.path != null) {
                            on_save ();
                        } else {
                            on_save_as ();
                        }
                        
                        edit_view_content.modified = false;
                        dialog.close ();
                        break;
                        case Gtk.ResponseType.NO:
                        edit_view_content.modified = false;
                        dialog.close ();
                        break;
                        case Gtk.ResponseType.CANCEL:
                        case Gtk.ResponseType.CLOSE:
                        case Gtk.ResponseType.DELETE_EVENT:
                        dialog.close ();
                        return;
                        default:
                        assert_not_reached ();
                    }
                });
                
                
                if (edit_view_content.modified) {
                    dialog.run ();
                }
                
                debug ("Creating new document");
                on_save ();
                sidebar.add_file (Services.FileManager.get_cache_path ());
                edit_view_content.text = "";
                edit_view_content.modified = true;
                on_save ();
            }
            
            private void on_open () {
                string contents;
                string path = Services.FileManager.open (out contents);
                
                edit_view_content.text = contents;
                
                
                if (gsettings.get_strv("last-files") != null && path != _("No Documents Open")) {
                    sidebar.add_file (path);
                } else {
                    sidebar.delete_row ();
                    sidebar.add_file (path);
                }
            }
            
            private void on_save () {
                unowned Widgets.SideBarBox? row = sidebar.get_selected_row ();
                if (row != null) {
                    try {
                        Services.FileManager.save_file (row.path ?? Services.FileManager.get_cache_path (), edit_view_content.text);
                        edit_view_content.modified = false;
                    } catch (Error e) {
                        warning ("Unexpected error during save: " + e.message);
                    }
                }
            }
            
            private void on_save_as () {
                unowned Widgets.SideBarBox? row = sidebar.get_selected_row ();
                if (row != null) {
                    try {
                        
                        string path;
                        Services.FileManager.save_as (edit_view_content.text, out path);
                        edit_view_content.modified = false;
                        if (gsettings.get_strv("last-files") != null) {
                            sidebar.delete_row_with_name ();
                            sidebar.add_file (path);
                        } else {
                            sidebar.delete_row ();
                            sidebar.add_file (path);
                        }
                    } catch (Error e) {
                        warning ("Unexpected error during save: " + e.message);
                    }
                }
            }
            
            private void on_sidebar_row_selected (Widgets.SideBarBox? box) {
                if (box != null) {
                    try {
                        string file_path = box.path;
                        gsettings.set_string("current-file", file_path);
                        
                        string text;
                        GLib.FileUtils.get_contents (file_path, out text);
                        
                        if (gsettings.get_string("current-file") != file_path) {
                            if (gsettings.get_boolean("auto-save") == true) {
                                on_save ();
                            }
                        } else if (gsettings.get_string("current-file") == _("No Documents Open")) {
                            return;
                        }
                        
                        if (edit_view_content.modified) {
                            Services.FileManager.save_file (file_path, text);
                        }
                        
                        edit_view_content.text = text;
                        edit_view_content.modified = false;
                    } catch (Error e) {
                        warning ("Unexpected error during selection: " + e.message);
                    }
                }
                
                update_title ();
            }
        }
    }