/*
* Copyright (c) 2017-2020 Lains
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
    public class MainWindow : Hdy.ApplicationWindow {
        delegate void HookFunc ();
        public Gtk.Adjustment eadj;
        public Gtk.Box box;
        public Gtk.Box main_leaf;
        public Gtk.Overlay overlay_editor;
        public Gtk.Button focus_overlay_button;
        public Hdy.Leaflet grid;
        public Hdy.Leaflet header;
        public Hdy.TitleBar window_header;
        public Gtk.Grid main_pane;
        public Gtk.Grid normal_view;
        public Gtk.MenuButton set_font_menu;
        public Gtk.Paned paned;
        public Gtk.Revealer overlay_button_revealer;
        public Gtk.ScrolledWindow edit_view;
        public Gtk.Stack main_stack;
        public Gtk.Stack stack;
        public Gtk.Separator separator;
        public Gtk.Separator separator2;
        public SimpleActionGroup actions { get; construct; }
        public Widgets.EditView edit_view_content;
        public Widgets.Headerbar toolbar;
        public Widgets.Preview preview_view_content;
        public Widgets.SearchBar searchbar;
        public Widgets.SideBar sidebar;
        public Widgets.StatusBar statusbar;
        public const string ACTION_CHEATSHEET = "action_cheatsheet";
        public const string ACTION_EXPORT_HTML = "action_export_html";
        public const string ACTION_EXPORT_PDF = "action_export_pdf";
        public const string ACTION_FOCUS = "action_focus";
        public const string ACTION_TOGGLE_VIEW = "action_toggle_view";
        public const string ACTION_PREFIX = "win.";
        public const string ACTION_PREFS = "action_preferences";
        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();
        public weak Quilter.Application app { get; construct; }

        private const GLib.ActionEntry[] ACTION_ENTRIES = {
            { ACTION_CHEATSHEET, action_cheatsheet },
            { ACTION_PREFS, action_preferences },
            { ACTION_FOCUS, action_focus },
            { ACTION_TOGGLE_VIEW, action_toggle_view },
            { ACTION_EXPORT_PDF, action_export_pdf },
            { ACTION_EXPORT_HTML, action_export_html }
        };

        private GtkSpell.Checker spell = null;
        public bool spellcheck {
            set {
                if (value) {
                    try {
                        var last_language = Quilter.Application.gsettings.get_string ("spellcheck-language");
                        var language_list = GtkSpell.Checker.get_language_list ();

                        bool language_set = false;
                        foreach (var element in language_list) {
                            if (last_language == element) {
                                spell.set_language (last_language);
                                language_set = true;
                                break;
                            }
                        }

                        if (language_list.length () == 0) {
                            spell.set_language (null);
                        } else if (!language_set) {
                            last_language = language_list.first ().data;
                            spell.set_language (last_language);
                        }
                        spell.attach (edit_view_content);
                    } catch (Error e) {
                        warning (e.message);
                    }
                } else {
                    spell.detach ();
                }
            }
        }

        public bool is_fullscreen {
            get {
                return Quilter.Application.gsettings.get_boolean("fullscreen");
            }
            set {
                Quilter.Application.gsettings.set_boolean("fullscreen", value);
                if (value) {
                    fullscreen ();
                    if (Quilter.Application.gsettings.get_string("preview-type") != "full") {
                        Quilter.Application.gsettings.set_string("preview-type", "full");
                    }
                    var buffer_context = edit_view_content.get_style_context ();
                    buffer_context.add_class ("full-text");
                    buffer_context.remove_class ("small-text");
                    var sb_context = statusbar.actionbar.get_style_context ();
                    sb_context.add_class ("full-bar");
                    sb_context.remove_class ("statusbar");
                    sidebar.reveal_child = false;
                } else {
                    unfullscreen ();
                    var buffer_context = edit_view_content.get_style_context ();
                    buffer_context.add_class ("small-text");
                    buffer_context.remove_class ("full-text");
                    var sb_context = statusbar.actionbar.get_style_context ();
                    sb_context.remove_class ("full-bar");
                    sb_context.add_class ("statusbar");
                    sidebar.reveal_child = true;
                }

                edit_view_content.dynamic_margins ();
            }
        }

        public MainWindow (Quilter.Application application) {
            Object (
                application: application,
                app: application
            );

            weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
            default_theme.add_resource_path ("/com/github/lainsce/quilter");

            // Ensure use of elementary theme and icons, accent color doesn't matter
            Gtk.Settings.get_default().set_property("gtk-theme-name", "io.elementary.stylesheet.blueberry");
            Gtk.Settings.get_default().set_property("gtk-icon-theme-name", "elementary");

            // Ensure the file used in the init is cache and exists
            Services.FileManager.get_cache_path ();

            on_settings_changed ();

            Quilter.Application.gsettings.changed.connect (() => {
                on_settings_changed ();
            });

            spell = new GtkSpell.Checker ();
            spell.decode_language_codes = true;

            spellcheck = Quilter.Application.gsettings.get_boolean ("spellcheck");

            spell.language_changed.connect (() => {
                Quilter.Application.gsettings.set_string ("spellcheck-language", spell.get_language ());
            });


            eadj = edit_view.get_vadjustment ();
            eadj.notify["value"].connect (() => {
                scroll_to ();
            });

            edit_view_content.buffer.changed.connect (() => {
                render_func ();
                update_count ();
                scroll_to ();
                sidebar.store.clear ();
                sidebar.outline_populate ();
                sidebar.view.expand_all ();
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
                        if (Quilter.Application.gsettings.get_boolean("searchbar") == false) {
                            Quilter.Application.gsettings.set_boolean("searchbar", true);
                            searchbar.search_entry.grab_focus_without_selecting();
                        } else {
                            Quilter.Application.gsettings.set_boolean("searchbar", false);
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
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.g, keycode)) {
                        action_export_html ();
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.p, keycode)) {
                        action_export_pdf ();
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
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.@1, keycode)) {
                        debug ("Press to change view...");
                        if (Quilter.Application.gsettings.get_boolean ("full-width-changed")) {
                            if (this.stack.get_visible_child_name () == "preview_view") {
                                this.stack.set_visible_child (this.edit_view);
                            } else if (this.stack.get_visible_child_name () == "edit_view") {
                                this.stack.set_visible_child (this.preview_view_content);
                            }
                        }
                        return true;
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.@2, keycode)) {
                        debug ("Press to change view...");
                        if (Quilter.Application.gsettings.get_boolean("sidebar")) {
                            Quilter.Application.gsettings.set_boolean("sidebar", false);
                        } else {
                            Quilter.Application.gsettings.set_boolean("sidebar", true);
                        }
                        return true;
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.@3, keycode)) {
                        debug ("Press to change view...");
                        if (Quilter.Application.gsettings.get_boolean("focus-mode")) {
                            Quilter.Application.gsettings.set_boolean("focus-mode", false);
                        } else {
                            Quilter.Application.gsettings.set_boolean("focus-mode", true);
                        }
                        return true;
                    }
                }
                return false;
            });

            overlay_button_revealer.visible = false;
        }

        static construct {
            action_accelerators.set (ACTION_CHEATSHEET, "<Control>h");
            action_accelerators.set (ACTION_EXPORT_HTML, "<Control>g");
            action_accelerators.set (ACTION_EXPORT_PDF, "<Control>p");
            action_accelerators.set (ACTION_TOGGLE_VIEW, "<Control>1");
            action_accelerators.set (ACTION_FOCUS, "<Control>3");
        }

        construct {
            int window_x, window_y, width, height;
            Quilter.Application.gsettings.get ("window-position", "(ii)", out window_x, out window_y);
            Quilter.Application.gsettings.get ("window-size", "(ii)", out width, out height);
            if (window_x != -1 || window_y != -1) {
                this.move (window_x, window_y);
            }
            this.resize (width, height);

            try {
                this.icon = Gtk.IconTheme.get_default ().load_icon ("com.github.lainsce.quilter", Gtk.IconSize.DIALOG, 0);
            } catch (Error e) {
            }

            actions = new SimpleActionGroup ();
            actions.add_action_entries (ACTION_ENTRIES, this);
            insert_action_group ("win", actions);

            foreach (var action in action_accelerators.get_keys ()) {
                var accels_array = action_accelerators[action].to_array ();
                accels_array += null;

                app.set_accels_for_action (ACTION_PREFIX + action, accels_array);
            }

            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/com/github/lainsce/quilter/app-main-stylesheet.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            var provider2 = new Gtk.CssProvider ();
            provider2.load_from_resource ("/com/github/lainsce/quilter/app-font-stylesheet.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider2, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            var provider3 = new Gtk.CssProvider ();

            toolbar = new Widgets.Headerbar (this);
            toolbar.set_title ("Quilter");
            toolbar.has_subtitle = false;
            toolbar.hexpand = true;
            toolbar.open.connect (on_open);
            toolbar.save_as.connect (on_save_as);
            toolbar.create_new.connect (on_create_new);

            edit_view = new Gtk.ScrolledWindow (null, null);
            edit_view_content = new Widgets.EditView (this);
            edit_view.vexpand = true;
            edit_view_content.save.connect (on_save);
            edit_view.add (edit_view_content);

            preview_view_content = new Widgets.Preview (this, edit_view_content);
            preview_view_content.vexpand = true;

            stack = new Gtk.Stack ();

            box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            box.homogeneous = true;

            statusbar = new Widgets.StatusBar (edit_view_content.buffer);
            statusbar.valign = Gtk.Align.END;

            overlay_editor = new Gtk.Overlay ();
            overlay_editor.add (edit_view);
            overlay_editor.add_overlay (statusbar);

            main_stack = new Gtk.Stack ();
            main_stack.add_named (stack, "stack");
            main_stack.add_named (box, "paned");

            var normal_icon = new Gtk.Image.from_icon_name ("document-new-symbolic", Gtk.IconSize.DND);
            var normal_label = new Gtk.Label (_("Start by creating a new story…"));
            normal_label.halign = Gtk.Align.START;
            var normal_label_context = normal_label.get_style_context ();
            normal_label_context.add_class (Granite.STYLE_CLASS_H2_LABEL);
            normal_label_context.add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            var onormal_icon = new Gtk.Image.from_icon_name ("document-open-symbolic", Gtk.IconSize.DND);
            var onormal_label = new Gtk.Label (_("Or open a saved story…"));
            onormal_label.halign = Gtk.Align.START;
            var onormal_label_context = onormal_label.get_style_context ();
            onormal_label_context.add_class (Granite.STYLE_CLASS_H2_LABEL);
            onormal_label_context.add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            normal_view = new Gtk.Grid ();
            normal_view.orientation = Gtk.Orientation.VERTICAL;
            normal_view.column_spacing = 12;
            normal_view.row_spacing = 24;
            normal_view.margin = 24;
            normal_view.expand = true;
            normal_view.halign = normal_view.valign = Gtk.Align.CENTER;
            normal_view.attach (normal_icon,0,0);
            normal_view.attach (normal_label,1,0);
            normal_view.attach (onormal_icon,0,1);
            normal_view.attach (onormal_label,1,1);

            change_layout ();

            sidebar = new Widgets.SideBar (this, edit_view_content);
            sidebar.save_as.connect (() => on_save_as ());

            var win_stack  = new Gtk.Stack ();
            win_stack.add_named (normal_view, "welcome");
            win_stack.add_named (main_stack, "doc");

            if (sidebar.column.get_children () == null) {
                normal_view.visible = true;
                main_stack.visible = false;
            } else {
                normal_view.visible = false;
                main_stack.visible = true;
            }

            searchbar = new Widgets.SearchBar (this);

            overlay_button_revealer = new Gtk.Revealer ();
            overlay_button_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
            overlay_button_revealer.halign = Gtk.Align.END;
            overlay_button_revealer.valign = Gtk.Align.START;

            focus_overlay_button = new Gtk.Button ();
            focus_overlay_button.set_image (new Gtk.Image.from_icon_name ("zoom-fit-best-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            focus_overlay_button.set_always_show_image (true);
            focus_overlay_button.tooltip_text = _("Exit focus mode");
            focus_overlay_button.halign = Gtk.Align.END;
            focus_overlay_button.valign = Gtk.Align.START;
            focus_overlay_button.margin = 6;
            var focus_overlay_button_context = focus_overlay_button.get_style_context ();
            focus_overlay_button_context.add_class ("quilter-focus-button");
            focus_overlay_button_context.add_class ("osd");

            focus_overlay_button.clicked.connect (() => {
                Quilter.Application.gsettings.set_boolean("focus-mode", false);
            });

            overlay_button_revealer.add (focus_overlay_button);

            main_leaf = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            main_leaf.add (toolbar);
            main_leaf.add (searchbar);
            main_leaf.add (win_stack);

            update ();

            grid = new Hdy.Leaflet ();
            grid.add (sidebar);
            grid.add (main_leaf);
            grid.transition_type = Hdy.LeafletTransitionType.UNDER;
            grid.show_all ();
            grid.can_swipe_back = true;
            grid.set_visible_child (main_leaf);

            grid.notify["folded"].connect (() => {
                update ();
            });

            var main_overlay = new Gtk.Overlay ();
            main_overlay.add_overlay (overlay_button_revealer);
            main_overlay.add (grid);

            var window_grid = new Gtk.Grid ();
            window_grid.orientation = Gtk.Orientation.VERTICAL;
            window_grid.add (main_overlay);

            add (window_grid);

            if (!Granite.Services.System.history_is_enabled ()) {
                edit_view_content.buffer.text = "";
                Services.FileManager.file = null;
                sidebar.store.clear ();
                sidebar.delete_rows ();
            }

            this.set_size_request (360, 435);
            this.show_all ();
        }

        private void update () {
            if (grid != null && grid.get_folded ()) {
                toolbar.pmenu_button.visible = false;
                toolbar.pmenu_button.no_show_all = true;
                toolbar.back_button.visible = true;
                toolbar.back_button.no_show_all = false;
                toolbar.focusmode_button.visible = false;
                toolbar.focusmode_button.no_show_all = true;
                Quilter.Application.gsettings.set_boolean("sidebar", true);
                Quilter.Application.gsettings.set_boolean("header", false);
                Quilter.Application.gsettings.set_boolean("focus-mode", false);
            } else {
                toolbar.pmenu_button.visible = true;
                toolbar.pmenu_button.no_show_all = false;
                toolbar.back_button.visible = false;
                toolbar.back_button.no_show_all = true;
                toolbar.focusmode_button.visible = true;
                toolbar.focusmode_button.no_show_all = false;
                Quilter.Application.gsettings.set_boolean("header", true);
                if (Quilter.Application.gsettings.get_boolean("focus-mode")) {
                    Quilter.Application.gsettings.set_boolean("focus-mode", true);
                }
                if (!Quilter.Application.gsettings.get_boolean("sidebar")) {
                    Quilter.Application.gsettings.set_boolean("sidebar", false);
                }
            }

            if (!Quilter.Application.gsettings.get_boolean("header")) {
                // On Mobile size, so.... have to have no buttons anywhere.
                sidebar.header.set_decoration_layout (":");
                toolbar.set_decoration_layout (":");
            } else {
                // Else you're on Desktop size, so business as usual.
                sidebar.header.set_decoration_layout ("close:");
                toolbar.set_decoration_layout (":maximize");
            }
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
            int w, h;
            get_size (out w, out h);
            Quilter.Application.gsettings.set ("window-size", "(ii)", w, h);
            int root_x, root_y;
            this.get_position (out root_x, out root_y);
            Quilter.Application.gsettings.set ("window-position", "(ii)", root_x, root_y);

            save_last_files ();
            if (sidebar.column.get_children () == null) {
                Quilter.Application.gsettings.set_string("current-file", "");
            }

            set_prev_workfile ();
            if (edit_view_content.modified) {
                on_save ();
            }

            return false;
        }

        public void scroll_to () {
            Gtk.Adjustment vap = edit_view.get_vadjustment ();
            var upper = vap.get_upper();
            var value = vap.get_value();
            preview_view_content.scroll_value = value/upper;
        }

        private static void widget_unparent (Gtk.Widget widget) {
            unowned Gtk.Container parent = widget.get_parent ();
            if (parent == null) {
                return;
            } else {
                parent.remove (widget);
                widget.unparent ();
            }
        }

        private void update_count () {
            if (Quilter.Application.gsettings.get_string("track-type") == "words") {
                statusbar.update_wordcount ();
            } else if (Quilter.Application.gsettings.get_string("track-type") == "lines") {
                statusbar.update_linecount ();
            } else if (Quilter.Application.gsettings.get_string("track-type") == "chars") {
                statusbar.update_charcount ();
            } else if (Quilter.Application.gsettings.get_string("track-type") == "rtc") {
                statusbar.update_readtimecount ();
            }
        }

        private void action_preferences () {
            var prefs = new Widgets.Preferences (this);
            prefs.show_all ();
        }
        private void action_cheatsheet () {
            var ch = new Widgets.Cheatsheet (this);
            ch.show_all ();
        }
        private void action_toggle_view () {
            if (Quilter.Application.gsettings.get_boolean ("full-width-changed") == false) {
                stack.set_visible_child (preview_view_content);
                Quilter.Application.gsettings.set_boolean ("full-width-changed", true);
            } else if (Quilter.Application.gsettings.get_boolean ("full-width-changed") == true) {
                stack.set_visible_child (overlay_editor);
                Quilter.Application.gsettings.set_boolean ("full-width-changed", false);
            }
        }
        private void action_focus () {
            Quilter.Application.gsettings.set_boolean("focus-mode", true);
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

        public void show_searchbar () {
            searchbar.set_search_mode (Quilter.Application.gsettings.get_boolean("searchbar"));
        }

        public void show_sidebar () {
            sidebar.reveal_child = Quilter.Application.gsettings.get_boolean("sidebar");
            separator.visible = Quilter.Application.gsettings.get_boolean("sidebar");
            separator2.visible = Quilter.Application.gsettings.get_boolean("sidebar");
        }

        public void show_statusbar () {
            statusbar.reveal_child = Quilter.Application.gsettings.get_boolean("statusbar");
        }

        private void set_prev_workfile () {
            if (((Widgets.SideBarBox)sidebar.column.get_selected_row ()) != null) {
                Quilter.Application.gsettings.set_string("current-file", ((Widgets.SideBarBox)sidebar.column.get_selected_row ()).path);
            }
        }

        private void on_settings_changed () {
            show_searchbar ();
            show_statusbar ();
            show_sidebar ();
            update_count ();
            edit_view_content.dynamic_margins ();
            change_layout ();

            if (Quilter.Application.gsettings.get_boolean("focus-mode")) {
                overlay_button_revealer.no_show_all = false;
                overlay_button_revealer.reveal_child = true;
                overlay_button_revealer.visible = true;
                sidebar.reveal_child = false;
                sidebar.visible = false;
                toolbar.visible = false;
                separator.visible = false;
                separator2.visible = false;
                focus_overlay_button.button_press_event.connect ((e) => {
                    if (e.button == Gdk.BUTTON_SECONDARY) {
                        begin_move_drag ((int) e.button, (int) e.x_root, (int) e.y_root, e.time);
                        return true;
                    }
                    return false;
                });
            } else {
                overlay_button_revealer.no_show_all = true;
                overlay_button_revealer.reveal_child = false;
                overlay_button_revealer.visible = false;
                toolbar.visible = true;
                if (Quilter.Application.gsettings.get_boolean("sidebar")) {
                    sidebar.reveal_child = true;
                    sidebar.visible = true;
                }
            }

            if (Quilter.Application.gsettings.get_boolean ("full-width-changed") == false) {
                stack.set_visible_child (preview_view_content);
            } else if (Quilter.Application.gsettings.get_boolean ("full-width-changed") == true) {
                stack.set_visible_child (overlay_editor);
            }

            if (Quilter.Application.gsettings.get_boolean ("sidebar") == false) {
                toolbar.set_decoration_layout ("close:maximize");
            } else {
                if (!Quilter.Application.gsettings.get_boolean("header")) {
                    // On Mobile size, so.... have to have no buttons anywhere.
                    toolbar.set_decoration_layout (":");
                } else {
                    // Else you're on Desktop size, so business as usual.
                    toolbar.set_decoration_layout (":maximize");
                }
            }

            var edit_view_context = edit_view.get_style_context ();
            if (Quilter.Application.gsettings.get_string("preview-type") == "half") {
                edit_view_context.add_class ("edit-view-paned");
            } else {
                edit_view_context.remove_class ("edit-view-paned");
            }

            render_func ();
        }

        private void change_layout () {
            if (Quilter.Application.gsettings.get_string("preview-type") == "full") {
                widget_unparent (overlay_editor);
                widget_unparent (preview_view_content);

                stack.add_titled (overlay_editor, "overlay_editor", _("Edit"));
                stack.child_set_property (overlay_editor, "icon-name", "text-x-generic-symbolic");
                stack.add_titled (preview_view_content, "preview_view", _("Preview"));
                stack.child_set_property (preview_view_content, "icon-name", "view-reveal-symbolic");
                main_stack.set_visible_child (stack);
            } else {
                widget_unparent (overlay_editor);
                widget_unparent (preview_view_content);

                box.add (overlay_editor);
                box.add (preview_view_content);
                main_stack.set_visible_child (box);
            }
        }

        public void save_last_files () {
          string[] rows = {};
          foreach (var child in sidebar.column.get_children ()) {
            rows += ((Widgets.SideBarBox)child).path;
          }
          Quilter.Application.gsettings.set_strv ("last-files", rows);
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
            sidebar.add_file (Services.FileManager.get_temp_document_path ());
            sidebar.is_modified = true;
            save_last_files ();
            edit_view_content.text = "";
            edit_view_content.modified = true;
            sidebar.store.clear ();
            sidebar.outline_populate ();
            sidebar.view.expand_all ();
            on_save ();
            normal_view.visible = false;
            main_stack.visible = true;
        }

        private void on_open () {
            string contents;
            string path = Services.FileManager.open (out contents);

            if (sidebar.column.get_children () != null) {
                foreach (var child in sidebar.column.get_children ()) {
                    if (((Widgets.SideBarBox)child).path == path) {
                        sidebar.column.select_row (((Widgets.SideBarBox)child));
                        break;
                    } else {
                        sidebar.add_file (path);
                        sidebar.is_modified = true;
                        normal_view.visible = false;
                        main_stack.visible = true;
                        break;
                    }
                }
            } else {
                sidebar.add_file (path);
                sidebar.is_modified = true;
                normal_view.visible = false;
                main_stack.visible = true;
            }
            edit_view_content.text = contents;
            save_last_files ();
            sidebar.store.clear ();
            sidebar.outline_populate ();
            sidebar.view.expand_all ();
        }

        public void on_save () {
            unowned Widgets.SideBarBox? row = sidebar.get_selected_row ();
            if (row != null) {
                try {
                    Services.FileManager.save_file (row.path, edit_view_content.text);
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
                    sidebar.store.clear ();
                    sidebar.outline_populate ();
                    sidebar.view.expand_all ();

                    foreach (var child in sidebar.column.get_children ()) {
                        if (((Widgets.SideBarBox)child).path == Services.FileManager.get_temp_document_path ()) {
                            ((Widgets.SideBarBox)child).path = path;
                            break;
                        }
                    }
                } catch (Error e) {
                    warning ("Unexpected error during save: " + e.message);
                }
            }
        }
    }
}
