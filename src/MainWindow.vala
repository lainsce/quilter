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
        public Gtk.HeaderBar toolbar;
        public File file;
        public Widgets.SourceView edit_view_content;
        public Widgets.WebView preview_view_content;

        private Gtk.Menu menu;
        private Gtk.Button new_button;
        private Gtk.Button open_button;
        private Gtk.Button save_button;
        private Gtk.Button save_as_button;
        private Gtk.MenuButton menu_button;
        private Gtk.Stack stack;
        private Granite.Widgets.ModeButton view_mode;
        private Gtk.Revealer view_mode_revealer;
        private Widgets.Preferences preferences_dialog;
        private Widgets.Cheatsheet cheatsheet_dialog;
        private Gtk.ScrolledWindow edit_view;
        private Gtk.ScrolledWindow preview_view;
        private int edit_view_id;
        private int preview_view_id;

        private bool _is_fullscreen;
    	public bool is_fullscreen {
    		get { return _is_fullscreen; }
            set {
                _is_fullscreen = value;

                if (_is_fullscreen)
                    fullscreen ();
                else
                    unfullscreen ();
            }
    	}

        public MainWindow (Gtk.Application application) {
            Object (application: application,
                    resizable: true,
                    title: _("Quilter"),
                    height_request: 800,
                    width_request: 920);
            
            view_mode.notify["selected"].connect (on_view_mode_changed);
        }

        construct {
            var context = this.get_style_context ();
            context.add_class ("quilter-window");
            toolbar = new Gtk.HeaderBar ();
            var settings = AppSettings.get_default ();
            toolbar.subtitle = settings.last_file;

			var header_context = toolbar.get_style_context ();
            header_context.add_class ("quilter-toolbar");

            new_button = new Gtk.Button ();
            new_button.has_tooltip = true;
            new_button.tooltip_text = (_("New file"));

            new_button.clicked.connect (() => {
                new_button_pressed ();
            });

            save_as_button = new Gtk.Button ();
            save_as_button.has_tooltip = true;
            save_as_button.tooltip_text = (_("Save as…"));

            save_as_button.clicked.connect (() => {
                save_as_button_pressed ();
            });

            save_button = new Gtk.Button ();
            save_button.has_tooltip = true;
            save_button.tooltip_text = (_("Save file"));

            save_button.clicked.connect (() => {
                save_button_pressed ();
            });

            open_button = new Gtk.Button ();
			      open_button.has_tooltip = true;
            open_button.tooltip_text = (_("Open…"));

            open_button.clicked.connect (() => {
                open_button_pressed ();
            });

            menu_button = new Gtk.MenuButton ();
            menu_button.has_tooltip = true;
            menu_button.tooltip_text = (_("Settings"));

            menu = new Gtk.Menu ();

            var cheatsheet = new Gtk.MenuItem.with_label (_("Markdown Cheatsheet"));
            cheatsheet.activate.connect (() => {
                debug ("Cheatsheet button pressed.");
                cheatsheet_dialog = new Widgets.Cheatsheet ();
                cheatsheet_dialog.show_all ();
            });

            var preferences = new Gtk.MenuItem.with_label (_("Preferences"));
            preferences.activate.connect (() => {
                debug ("Prefs button pressed.");
                preferences_dialog = new Widgets.Preferences ();
                preferences_dialog.show_all ();
            });

            var separator = new Gtk.SeparatorMenuItem ();

            menu.add (cheatsheet);
            menu.add (separator);
            menu.add (preferences);
            menu.show_all ();

            menu_button.popup = menu;

            view_mode = new Granite.Widgets.ModeButton ();
            view_mode.margin = 1;
            edit_view_id = view_mode.append_text (_("Edit"));
            preview_view_id = view_mode.append_text (_("Preview"));
    
            view_mode_revealer = new Gtk.Revealer ();
            view_mode_revealer.reveal_child = true;
            view_mode_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
            view_mode_revealer.add (view_mode);

            toolbar.pack_start (new_button);
            toolbar.pack_start (open_button);
            toolbar.pack_start (save_as_button);
            toolbar.pack_end (menu_button);
            toolbar.pack_end (view_mode_revealer);

            toolbar.show_close_button = true;
            toolbar.show_all ();

            focus_mode_toolbar ();

            settings.changed.connect (() => {
                show_save_button ();
                focus_mode_toolbar ();
            });

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

            this.window_position = Gtk.WindowPosition.CENTER;
            this.set_titlebar (toolbar);

            edit_view = new Gtk.ScrolledWindow (null, null);
            var edit_view_content = new Widgets.SourceView ();
            edit_view_content.monospace = true;
            edit_view.add (edit_view_content);

            preview_view = new Gtk.ScrolledWindow (null, null);
            var preview_view_content = new Widgets.WebView ();
            preview_view.add (preview_view_content);

            stack = new Gtk.Stack ();
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            stack.add (edit_view);
            stack.add (preview_view);

            this.add (stack);

            view_mode.selected = edit_view_id;
            stack.visible_child = edit_view;

            if (settings.last_file != null) {
                Services.FileUtils.load_work_file ();
            } else {
                var home = GLib.Environment.get_home_dir ();
                settings.last_file = @"$home/.cache/com.github.lainsce.quilter/temp";
                Services.FileUtils.load_tmp_file ();
            }

            this.key_press_event.connect ((e) => {
                uint keycode = e.hardware_keycode;
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.q, keycode)) {
                        this.destroy ();
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.s, keycode)) {
                        save_button_pressed ();
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.o, keycode)) {
                        open_button_pressed ();
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.h, keycode)) {
                        var cheatsheet_dialog = new Widgets.Cheatsheet ();
                        cheatsheet_dialog.show_all ();
                    }
                }
                if (match_keycode (Gdk.Key.F11, keycode)) {
                    is_fullscreen = !is_fullscreen;
                }
                return false;
            });
        }

        protected bool match_keycode (int keyval, uint code) {
            Gdk.KeymapKey [] keys;
            Gdk.Keymap keymap = Gdk.Keymap.get_default ();
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
                Services.FileUtils.save_work_file ();
            } else {
                string cache = Path.build_filename (Environment.get_user_cache_dir (), "com.github.lainsce.quilter");
                settings.last_file = @"$cache/temp";
                Services.FileUtils.save_tmp_file ();
            }

            return false;
        }

        public void focus_mode_toolbar () {
            var settings = AppSettings.get_default ();
            if (!settings.focus_mode) {
                new_button.set_image (new Gtk.Image.from_icon_name ("document-new", Gtk.IconSize.LARGE_TOOLBAR));
                save_button.set_image (new Gtk.Image.from_icon_name ("document-save", Gtk.IconSize.LARGE_TOOLBAR));
                save_as_button.set_image (new Gtk.Image.from_icon_name ("document-save-as", Gtk.IconSize.LARGE_TOOLBAR));
                open_button.set_image (new Gtk.Image.from_icon_name ("document-open", Gtk.IconSize.LARGE_TOOLBAR));
                menu_button.set_image (new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR));
            } else {
                new_button.set_image (new Gtk.Image.from_icon_name ("document-new-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
                save_button.set_image (new Gtk.Image.from_icon_name ("document-save-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
                save_as_button.set_image (new Gtk.Image.from_icon_name ("document-save-as-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
                open_button.set_image (new Gtk.Image.from_icon_name ("document-open-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
                menu_button.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            }
        }

        public void show_save_button () {
            var settings = AppSettings.get_default ();
            toolbar.pack_start (save_button);
            save_button.visible = settings.show_save_button;
        }

        public void new_button_pressed () {
            debug ("New button pressed.");
            var settings = AppSettings.get_default ();

            if (Widgets.SourceView.is_modified = true) {
                try {
                    debug ("Making new file...");
                    Services.FileUtils.new_document ();
                    toolbar.subtitle = "New Document";
                    var home = GLib.Environment.get_home_dir ();
                    settings.last_file = @"$home/.cache/com.github.lainsce.quilter/temp";
                } catch (Error e) {
                    warning ("Unexpected error: " + e.message);
                }
            }

            file = null;
            Widgets.SourceView.is_modified = false;
        }

        public void open_button_pressed () {
            debug ("Open button pressed.");
            var settings = AppSettings.get_default ();

            if (Widgets.SourceView.is_modified = true) {
                try {
                    debug ("Opening file...");
                    Services.FileUtils.save_work_file ();
                    Services.FileUtils.open_document ();
                    toolbar.subtitle = settings.last_file;
                } catch (Error e) {
                    warning ("Unexpected error during open: " + e.message);
                }
            }

            file = null;
            Widgets.SourceView.is_modified = false;
        }

        public void save_button_pressed () {
            debug ("Save button pressed.");
            var settings = AppSettings.get_default ();
            var file = File.new_for_path (settings.last_file);

            if (file.query_exists ()) {
                try {
                    file.delete ();
                } catch (Error e) {
                    warning ("Error: " + e.message);
                }
            }

            Gtk.TextIter start, end;
            Widgets.SourceView.buffer.get_bounds (out start, out end);
            string buffer = Widgets.SourceView.buffer.get_text (start, end, true);
            uint8[] binbuffer = buffer.data;

            try {
                Services.FileUtils.save_file (file, binbuffer);
                toolbar.subtitle = settings.last_file;
            } catch (Error e) {
                warning ("Unexpected error during save: " + e.message);
            }

            file = null;
            Widgets.SourceView.is_modified = false;
        }

        public void save_as_button_pressed () {
            debug ("Save as button pressed.");
            var settings = AppSettings.get_default ();

            if (Widgets.SourceView.is_modified = true) {
                try {
                    debug ("Saving file...");
                    Services.FileUtils.save_document ();
                    toolbar.subtitle = settings.last_file;
                } catch (Error e) {
                    warning ("Unexpected error during save: " + e.message);
                }
            }

            file = null;
            Widgets.SourceView.is_modified = false;
        }

        private void on_view_mode_changed () {
            if (view_mode.selected == edit_view_id) {
                stack.visible_child = edit_view;
            } else if (view_mode.selected == preview_view_id) {
                stack.visible_child = preview_view;
            }
        }
    }
}
