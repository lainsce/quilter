/*
* Copyright (c) 2017 Lains
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
using Gtk;
using Granite;
using Granite.Services;

namespace Quilter {
    public class MainWindow : Gtk.Window {
        public Widgets.StatusBar statusbar;
        public Widgets.Headerbar toolbar;
        public Gtk.MenuButton set_font_menu;
        public Widgets.SourceView edit_view_content;
        public Widgets.Preview preview_view_content;
        public Gtk.Stack stack;
        public Gtk.ScrolledWindow edit_view;
        public Gtk.ScrolledWindow preview_view;
        public Gtk.Grid grid;
        public SimpleActionGroup actions { get; construct; }
        public const string ACTION_PREFIX = "win.";
        public const string ACTION_CHEATSHEET = "action_cheatsheet";
        public const string ACTION_PREFS = "action_preferences";
        public const string ACTION_EXPORT_PDF = "action_export_pdf";
        public const string ACTION_EXPORT_HTML = "action_export_html";
        public const string ACTION_FONT_SERIF = "action_font_serif";
        public const string ACTION_FONT_SANS = "action_font_sans";
        public const string ACTION_FONT_MONO = "action_font_mono";
        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        private const GLib.ActionEntry[] action_entries = {
            { ACTION_CHEATSHEET, action_cheatsheet },
            { ACTION_PREFS, action_preferences },
            { ACTION_EXPORT_PDF, action_export_pdf },
            { ACTION_EXPORT_HTML, action_export_html },
            { ACTION_FONT_SERIF, action_font_serif },
            { ACTION_FONT_SANS, action_font_sans },
            { ACTION_FONT_MONO, action_font_mono }
        };

        public void dynamic_margins() {
            var settings = AppSettings.get_default ();
            int w, h, m, p;
            get_size (out w, out h);

            // If Quilter is Full Screen, add additional padding
            p = (is_fullscreen) ? 5 : 0;

            var margins = settings.margins;
            switch (margins) {
                case Constants.NARROW_MARGIN:
                    m = (int)(w * ((Constants.NARROW_MARGIN + p) / 100.0));
                    break;
                case Constants.WIDE_MARGIN:
                    m = (int)(w * ((Constants.WIDE_MARGIN + p) / 100.0));
                    break;
                default:
                case Constants.MEDIUM_MARGIN:
                    m = (int)(w * ((Constants.MEDIUM_MARGIN + p) / 100.0));
                    break;
            }

            // Update margins
            edit_view_content.left_margin = m;
            edit_view_content.right_margin = m;

            // Update margins for typewriter scrolling
            if (settings.typewriter_scrolling && settings.focus_mode) {
                edit_view_content.bottom_margin = (int)(h * (1 - Constants.TYPEWRITER_POSITION));
            } else {
                edit_view_content.bottom_margin = 40;
            }

            // Update file name
            if (settings.last_file != "" && settings.show_filename) {

                // Trim off user's home directory if present
                if (settings.last_file.has_prefix(Environment.get_home_dir())) {
                    this.title = "Quilter: " + settings.last_file.replace(Environment.get_home_dir(), "~");
                } else {
                    this.title = "Quilter: " + settings.last_file;
                }
            } else {
                this.title = "Quilter";
            }
        }

        public bool is_fullscreen {
            get {
                var settings = AppSettings.get_default ();
                return settings.fullscreen;
            }
            set {
                var settings = AppSettings.get_default ();
                settings.fullscreen = value;

                if (settings.fullscreen) {
                    fullscreen ();
                    settings.statusbar = false;
                    var buffer_context = edit_view_content.get_style_context ();
                    buffer_context.add_class ("full-text");
                    buffer_context.remove_class ("small-text");
                } else {
                    unfullscreen ();
                    settings.statusbar = true;
                    var buffer_context = edit_view_content.get_style_context ();
                    buffer_context.add_class ("small-text");
                    buffer_context.remove_class ("full-text");
                }

                // Update margins
                dynamic_margins();
            }
        }

        public MainWindow (Gtk.Application application) {
            Object (application: application,
                    resizable: true,
                    title: _("Quilter"),
                    height_request: 600,
                    width_request: 700);

            statusbar.update_wordcount ();
            statusbar.update_linecount ();
            statusbar.update_readtimecount ();
            show_statusbar ();

            var settings = AppSettings.get_default ();
            if (!settings.focus_mode) {
                set_font_menu.image = new Gtk.Image.from_icon_name ("set-font", Gtk.IconSize.LARGE_TOOLBAR);
            } else {
                set_font_menu.image = new Gtk.Image.from_icon_name ("font-select-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            }

            settings.changed.connect (() => {
                show_statusbar ();

                if (!settings.focus_mode) {
                    set_font_menu.image = new Gtk.Image.from_icon_name ("set-font", Gtk.IconSize.LARGE_TOOLBAR);
                } else {
                    set_font_menu.image = new Gtk.Image.from_icon_name ("font-select-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
                }
            });

            edit_view_content.changed.connect (() => {
                render_func ();
                statusbar.update_wordcount ();
                statusbar.update_linecount ();
                statusbar.update_readtimecount ();
            });

            key_press_event.connect ((e) => {
                uint keycode = e.hardware_keycode;
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.q, keycode)) {
                        this.destroy ();
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.s, keycode)) {
                        try {
                            Services.FileManager.save ();
                        } catch (Error e) {
                            warning ("Unexpected error during open: " + e.message);
                        }
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.o, keycode)) {
                        try {
                            Services.FileManager.open ();
                        } catch (Error e) {
                            warning ("Unexpected error during open: " + e.message);
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
                        Widgets.SourceView.buffer.undo ();
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK + Gdk.ModifierType.SHIFT_MASK) != 0) {
                    if (match_keycode (Gdk.Key.z, keycode)) {
                        Widgets.SourceView.buffer.redo ();
                    }
                }
                if (match_keycode (Gdk.Key.F11, keycode)) {
                    is_fullscreen = !is_fullscreen;
                }
                if (match_keycode (Gdk.Key.F1, keycode)) {
                    debug ("Press to change view...");
                    if (this.stack.get_visible_child_name () == "preview_view") {
                        this.stack.set_visible_child (this.edit_view);
                    } else if (this.stack.get_visible_child_name () == "edit_view") {
                        this.stack.set_visible_child (this.preview_view);
                    }
                    return true;
                }
                return false;
            });
        }

        construct {
            var settings = AppSettings.get_default ();
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/com/github/lainsce/quilter/app-main-stylesheet.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            var toolbar = new Widgets.Headerbar ();
            toolbar.title = this.title;
            toolbar.has_subtitle = false;
            this.set_titlebar (toolbar);

            var set_font_sans = new Gtk.ModelButton ();
            set_font_sans.text = (_("Sans-serif"));
            set_font_sans.action_name = ACTION_PREFIX + ACTION_FONT_SANS;

            var set_font_serif = new Gtk.ModelButton ();
            set_font_serif.text = (_("Serif"));
            set_font_serif.action_name = ACTION_PREFIX + ACTION_FONT_SERIF;

            var set_font_mono = new Gtk.ModelButton ();
            set_font_mono.text = (_("Monospace"));
            set_font_mono.action_name = ACTION_PREFIX + ACTION_FONT_MONO;

            var set_font_menu_grid = new Gtk.Grid ();
            set_font_menu_grid.margin = 6;
            set_font_menu_grid.row_spacing = 6;
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
            edit_view_content = new Widgets.SourceView ();
            edit_view_content.monospace = true;
            edit_view.add (edit_view_content);

            preview_view = new Gtk.ScrolledWindow (null, null);
            preview_view_content = new Widgets.Preview ();
            preview_view.add (preview_view_content);

            stack = new Gtk.Stack ();
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            stack.add_titled (edit_view, "edit_view", _("Edit"));
            stack.add_titled (preview_view, "preview_view", _("Preview"));

            var view_mode = new Gtk.StackSwitcher ();
            view_mode.stack = stack;
            view_mode.valign = Gtk.Align.CENTER;
            view_mode.homogeneous = true;

            ((Gtk.RadioButton)(view_mode.get_children().first().data)).toggled.connect(() => {
                show_font_button (false);
            });
            ((Gtk.RadioButton)(view_mode.get_children().last().data)).toggled.connect(() => {
                toolbar.pack_end (set_font_menu);
                show_font_button (true);
            });

            toolbar.pack_end (view_mode);

            actions = new SimpleActionGroup ();
            actions.add_action_entries (action_entries, this);
            insert_action_group ("win", actions);

            statusbar = new Widgets.StatusBar ();

            grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.add (stack);
            grid.add (statusbar);
            grid.show_all ();
            this.add (grid);

            int x = settings.window_x;
            int y = settings.window_y;
            int h = settings.window_height;
            int w = settings.window_width;

            bool v = settings.shown_view;
            set_font_menu.set_visible (v);

            if (x != -1 && y != -1) {
                this.move (x, y);
            }
            if (w != 0 && h != 0) {
                this.resize (w, h);
            }

            // Register for redrawing of window for handling margins and other
            // redrawing
            configure_event.connect ((event) => {
                dynamic_margins();
            });

            // Attempt to set taskbar icon
            try {
                this.icon = IconTheme.get_default ().load_icon ("com.github.lainsce.quilter", Gtk.IconSize.DIALOG, 0);
            } catch (Error e) {
            }

            this.window_position = Gtk.WindowPosition.CENTER;
            this.show_all ();
        }

        protected bool match_keycode (int keyval, uint code) {
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
            bool v = set_font_menu.get_visible ();

            var settings = AppSettings.get_default ();
            settings.window_x = x;
            settings.window_y = y;
            settings.window_width = w;
            settings.window_height = h;
            settings.shown_view = v;

            if (settings.last_file != null) {
                debug ("Saving working file...");
                Services.FileManager.save_work_file ();
            } else if (settings.last_file == "New Document") {
                debug ("Saving cache...");
                Services.FileManager.save_tmp_file ();
            }
            return false;
        }

        private void action_preferences () {
            var dialog = new Widgets.Preferences (this);
            dialog.set_modal (true);
            dialog.show_all ();
        }

        private void action_cheatsheet () {
            var dialog = new Widgets.Cheatsheet (this);
            dialog.set_modal (true);
            dialog.show_all ();
        }

        private void action_export_pdf () {
            Services.ExportUtils.export_pdf ();
        }

        private void action_export_html () {
            Services.ExportUtils.export_html ();
        }

        private void action_font_serif () {
            var settings = AppSettings.get_default ();
            settings.preview_font = "serif";
        }

        private void action_font_sans () {
            var settings = AppSettings.get_default ();
            settings.preview_font = "sans";
        }

        private void action_font_mono () {
            var settings = AppSettings.get_default ();
            settings.preview_font = "mono";
        }

        private void render_func () {
            if (edit_view_content.is_modified == true) {
                preview_view_content.update_html_view ();
                edit_view_content.is_modified = false;
            }
        }

        public void show_statusbar () {
            var settings = AppSettings.get_default ();
            statusbar.reveal_child = settings.statusbar;
        }

        public void show_font_button (bool v) {
            set_font_menu.set_visible (v);
        }
    }
}
