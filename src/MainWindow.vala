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

namespace Quilter {
    public class MainWindow : Gtk.Window {
        public Widgets.StatusBar statusbar;
        public Widgets.Headerbar toolbar;
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
        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        // Margin Constants
        public const int NARROW_MARGIN = 10;
        public const int MEDIUM_MARGIN = 15;
        public const int WIDE_MARGIN = 25;

        private const GLib.ActionEntry[] action_entries = {
            { ACTION_CHEATSHEET, action_cheatsheet },
            { ACTION_PREFS, action_preferences },
            { ACTION_EXPORT_PDF, action_export_pdf },
            { ACTION_EXPORT_HTML, action_export_html }
        };

        public void dynamic_margins() {
            var settings = AppSettings.get_default ();
            int w, h, m;
            get_size (out w, out h);

            var margins = settings.margins;
            switch (margins) {
                case NARROW_MARGIN:
                    m = (int)(w * 0.1);
                    break;
                case WIDE_MARGIN:
                    m = (int)(w * 0.25);
                    break;
                default:
                case MEDIUM_MARGIN:
                    m = (int)(w * 0.15);
                    break;
            }
            edit_view_content.left_margin = m;
            edit_view_content.right_margin = m;

            if (settings.last_file != "")
            {
                this.title = "Quilter: " + settings.last_file;
            }
            else
            {
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

                    dynamic_margins();
                } else {
                    unfullscreen ();
                    settings.statusbar = true;
                    var buffer_context = edit_view_content.get_style_context ();
                    buffer_context.add_class ("small-text");
                    buffer_context.remove_class ("full-text");

                    dynamic_margins();
                }
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
            settings.changed.connect (() => {
                show_statusbar ();
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

            if (x != -1 && y != -1) {
                this.move (x, y);
            }
            if (w != 0 && h != 0) {
                this.resize (w, h);
            }

            // Dynamic resizing
            configure_event.connect ((event) => {
                dynamic_margins();
            });

            // Attempt to set taskbar icon
            try {
                this.icon = IconTheme.get_default ().load_icon ("com.github.lainsce.quilter", 48, 0);
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

            var settings = AppSettings.get_default ();
            settings.window_x = x;
            settings.window_y = y;
            settings.window_width = w;
            settings.window_height = h;

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
    }
}
