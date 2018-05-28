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
        public Widgets.StatusBar statusbar;

        private Gtk.Button new_button;
        private Gtk.Button open_button;
        private Gtk.Button save_button;
        private Gtk.Button save_as_button;
        private Gtk.MenuButton menu_button;
        private Gtk.Stack stack;
        private Gtk.StackSwitcher view_mode;
        private Gtk.ScrolledWindow edit_view;
        private Gtk.ScrolledWindow preview_view;
        private Gtk.Grid grid;
        private bool timer_scheduled = false;

        /*
         * 100ms equals one keypress per beat. Speedy.
         */
        private const int TIME_TO_REFRESH = 100;

        public SimpleActionGroup actions { get; construct; }

        public const string ACTION_PREFIX = "win.";
        public const string ACTION_CHEATSHEET = "action_cheatsheet";
        public const string ACTION_PREFS = "action_preferences";

        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        private const GLib.ActionEntry[] action_entries = {
            { ACTION_CHEATSHEET, action_cheatsheet },
            { ACTION_PREFS, action_preferences }
        };

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
                } else {
                    unfullscreen ();
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
            focus_mode_toolbar ();

            var settings = AppSettings.get_default ();
            settings.changed.connect (() => {
                focus_mode_toolbar ();
                show_statusbar ();
            });

            edit_view_content.changed.connect (() => {
                schedule_timer ();
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
                            unsaved_indicator (true);
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
                    if (stack.get_visible_child_name () == "preview_view") {
                        stack.set_visible_child (edit_view);
                    } else if (stack.get_visible_child_name () == "edit_view") {
                        stack.set_visible_child (preview_view);
                    }
                    return true;
                }
                return false;
            });
        }

        construct {
            var css_provider = new Gtk.CssProvider();
            string style = """button .color-button {
                border-radius: 8px;
                box-shadow:
                    inset 0 1px 0 0 alpha (@inset_dark_color, 0.7),
                    inset 0 0 0 1px alpha (@inset_dark_color, 0.3),
                    0 1px 0 0 alpha (@bg_highlight_color, 0.3);
                text-shadow: 1px 1px transparent;
            }
            
            button .color-button:focus {
                border-color: @colorAccent;
            }
            
            .color-dark {
                background-color: #151611;
                border: 1px solid #151611;
            }

            .color-dark image {
                color: #C3C3C1;
                -gtk-icon-shadow: 1px 1px transparent;
            }
            
            .color-light {
                background-color: #F9F9F9;
            }

            .color-light image {
                color: #191919;
                -gtk-icon-shadow: 1px 1px transparent;
            }
            
            .color-sepia {
                background-color: #F0E8DD;
            }

            .color-sepia image {
                color: #2D1708;
                -gtk-icon-shadow: 1px 1px transparent;
            }""";


            try {
                css_provider.load_from_data(style, -1);
            } catch (GLib.Error e) {
                warning ("Failed to parse css style : %s", e.message);
            }

            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );

            actions = new SimpleActionGroup ();
            actions.add_action_entries (action_entries, this);
            insert_action_group ("win", actions);

            toolbar = new Gtk.HeaderBar ();
            toolbar.title = title;
            var settings = AppSettings.get_default ();
            string cache = Path.build_filename (Environment.get_user_cache_dir (), "com.github.lainsce.quilter");

            if (settings.last_file != null) {
                toolbar.subtitle = settings.subtitle;
            } else if (settings.last_file == @"$cache/temp") {
                toolbar.subtitle = "New Document";
            }

			var header_context = toolbar.get_style_context ();
            header_context.add_class (Gtk.STYLE_CLASS_FLAT);
            header_context.add_class ("quilter-toolbar");

            new_button = new Gtk.Button ();
            new_button.has_tooltip = true;
            new_button.tooltip_text = (_("New file"));

            new_button.clicked.connect (() => {
                new_file ();
            });

            save_as_button = new Gtk.Button ();
            save_as_button.has_tooltip = true;
            save_as_button.tooltip_text = (_("Save as…"));

            save_as_button.clicked.connect (() => {
                try {
                    Services.FileManager.save_as ();
                    unsaved_indicator (true);
                } catch (Error e) {
                    warning ("Unexpected error during open: " + e.message);
                }
                toolbar.subtitle = settings.subtitle;
            });

            save_button = new Gtk.Button ();
            save_button.has_tooltip = true;
            save_button.tooltip_text = (_("Save file"));

            save_button.clicked.connect (() => {
                try {
                    Services.FileManager.save ();
                    unsaved_indicator (true);
                } catch (Error e) {
                    warning ("Unexpected error during open: " + e.message);
                }
                toolbar.subtitle = settings.subtitle;
            });

            open_button = new Gtk.Button ();
			      open_button.has_tooltip = true;
            open_button.tooltip_text = (_("Open…"));

            open_button.clicked.connect (() => {
                try {
                    Services.FileManager.open ();
                } catch (Error e) {
                    warning ("Unexpected error during open: " + e.message);
                }
                toolbar.subtitle = settings.subtitle;
            });

            var cheatsheet = new Gtk.ModelButton ();
            cheatsheet.text = (_("Markdown Cheatsheet"));
            cheatsheet.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_CHEATSHEET;

            var preferences = new Gtk.ModelButton ();
            preferences.text = (_("Preferences"));
            preferences.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_PREFS;

            var color_button_light = new Gtk.Button ();
            color_button_light.set_image (new Gtk.Image.from_icon_name ("format-justify-fill-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            color_button_light.halign = Gtk.Align.CENTER;
            color_button_light.height_request = 40;
            color_button_light.width_request = 40;
            color_button_light.tooltip_text = _("Light Mode");

            var color_button_light_context = color_button_light.get_style_context ();
            color_button_light_context.add_class ("color-button");
            color_button_light_context.add_class ("color-light");

            var color_button_sepia = new Gtk.Button ();
            color_button_sepia.set_image (new Gtk.Image.from_icon_name ("format-justify-fill-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            color_button_sepia.halign = Gtk.Align.CENTER;
            color_button_sepia.height_request = 40;
            color_button_sepia.width_request = 40;
            color_button_sepia.tooltip_text = _("Sepia Mode");

            var color_button_sepia_context = color_button_sepia.get_style_context ();
            color_button_sepia_context.add_class ("color-button");
            color_button_sepia_context.add_class ("color-sepia");

            var color_button_dark = new Gtk.Button ();
            color_button_dark.set_image (new Gtk.Image.from_icon_name ("format-justify-fill-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            color_button_dark.halign = Gtk.Align.CENTER;
            color_button_dark.height_request = 40;
            color_button_dark.width_request = 40;
            color_button_dark.tooltip_text = _("Dark Mode");

            var color_button_dark_context = color_button_dark.get_style_context ();
            color_button_dark_context.add_class ("color-button");
            color_button_dark_context.add_class ("color-dark");

            color_button_dark.clicked.connect (() => {
                settings.dark_mode = true;
                settings.sepia_mode = false;
            });

            color_button_sepia.clicked.connect (() => {
                settings.sepia_mode = true;
                settings.dark_mode = false;
            });

            color_button_light.clicked.connect (() => {
                settings.dark_mode = false;
                settings.sepia_mode = false;
            });

            var focusmode_button = new Gtk.ToggleButton.with_label ((_("Focus Mode")));
            focusmode_button.set_image (new Gtk.Image.from_icon_name ("zoom-fit-best-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            focusmode_button.set_always_show_image (true);
            focusmode_button.tooltip_text = _("Enter focus mode");

            if (settings.focus_mode == false) {
                focusmode_button.set_active (false);
            } else {
                focusmode_button.set_active (settings.focus_mode);
            }

            focusmode_button.toggled.connect (() => {
    			if (focusmode_button.active) {
    				settings.focus_mode = true;
    			} else {
    				settings.focus_mode = false;
    			}

            });
            
            var buttonbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            buttonbox.pack_start (color_button_light, true, true, 6);
            buttonbox.pack_start (color_button_sepia, true, true, 6);
            buttonbox.pack_start (color_button_dark, true, true, 6);

            var buttonbox2 = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            buttonbox2.pack_start (focusmode_button, true, true, 6);

            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

            var menu_grid = new Gtk.Grid ();
            menu_grid.margin = 6;
            menu_grid.row_spacing = 6;
            menu_grid.column_spacing = 12;
            menu_grid.orientation = Gtk.Orientation.VERTICAL;
            menu_grid.add (buttonbox);
            menu_grid.add (buttonbox2);
            menu_grid.add (separator);
            menu_grid.add (cheatsheet);
            menu_grid.add (preferences);
            menu_grid.show_all ();

            var menu = new Gtk.Popover (null);
            menu.add (menu_grid);

            menu_button = new Gtk.MenuButton ();
            menu_button.has_tooltip = true;
            menu_button.tooltip_text = (_("Settings"));
            menu_button.popover = menu;

            edit_view = new Gtk.ScrolledWindow (null, null);
            edit_view_content = new Widgets.SourceView ();
            edit_view_content.monospace = true;
            edit_view.add (edit_view_content);

            preview_view = new Gtk.ScrolledWindow (null, null);
            preview_view_content = new Widgets.WebView (this);
            preview_view.add (preview_view_content);

            stack = new Gtk.Stack ();
            stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            stack.add_titled (edit_view, "edit_view", _("Edit"));
            stack.add_titled (preview_view, "preview_view", _("Preview"));

            statusbar = new Widgets.StatusBar ();

            grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.add (stack);
            grid.add (statusbar);
            grid.show_all ();
            this.add (grid);

            view_mode = new Gtk.StackSwitcher ();
            view_mode.stack = stack;
            view_mode.valign = Gtk.Align.CENTER;
            view_mode.homogeneous = true;

            toolbar.pack_start (new_button);
            toolbar.pack_start (open_button);
            toolbar.pack_start (save_as_button);

            // This makes the save button show or not, and it's necessary as-is.
            settings.changed.connect (() => {
                if (settings.autosave) {
                    save_button.visible = false;
                    settings.autosave = true;
                } else {
                    toolbar.pack_start (save_button);
                    save_button.visible = true;
                    settings.autosave = false;
                }
            });

            toolbar.pack_end (menu_button);
            toolbar.pack_end (view_mode);

            toolbar.show_close_button = true;
            toolbar.show_all ();

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

        private void schedule_timer () {
            if (!timer_scheduled && edit_view_content.is_modified == true) {
                Timeout.add (TIME_TO_REFRESH, render_func);
                timer_scheduled = true;
            }
        }

        private bool render_func () {
            if (edit_view_content.is_modified) {
                preview_view_content.update_html_view ();
                edit_view_content.is_modified = false;
            } else {
                edit_view_content.is_modified = true;
            }

            timer_scheduled = false;
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

        public void show_statusbar () {
            var settings = AppSettings.get_default ();
            statusbar.reveal_child = settings.statusbar;
        }

        public void unsaved_indicator (bool val) {
            edit_view_content.is_modified = val;

            string unsaved_identifier = "* ";

            if (!val) {
                if (!(unsaved_identifier in toolbar.subtitle)) {
                    toolbar.subtitle = unsaved_identifier + toolbar.subtitle;
                }
            } else {
                toolbar.subtitle = toolbar.subtitle.replace (unsaved_identifier, "");
            }
        }

        public void new_file () {
            debug ("New button pressed.");
            debug ("Buffer was modified. Asking user to save first.");
            var settings = AppSettings.get_default ();
            var dialog = new Services.DialogUtils.Dialog.display_save_confirm (Application.window);
            dialog.response.connect ((response_id) => {
                switch (response_id) {
                    case Gtk.ResponseType.YES:
                        debug ("User saves the file.");

                        try {
                            Services.FileManager.save ();
                            string cache = Path.build_filename (Environment.get_user_cache_dir (), "com.github.lainsce.quilter" + "/temp");
                            file = File.new_for_path (cache);
                            Widgets.SourceView.buffer.text = "";
                            toolbar.subtitle = "New Document";
                            settings.last_file = file.get_path ();
                            settings.subtitle = file.get_basename ();
                        } catch (Error e) {
                            warning ("Unexpected error during save: " + e.message);
                        }
                        break;
                    case Gtk.ResponseType.NO:
                        debug ("User doesn't care about the file, shoot it to space.");

                        string cache = Path.build_filename (Environment.get_user_cache_dir (), "com.github.lainsce.quilter" + "/temp");
                        file = File.new_for_path (cache);
                        Widgets.SourceView.buffer.text = "";
                        toolbar.subtitle = "New Document";
                        settings.last_file = file.get_path ();
                        settings.subtitle = file.get_basename ();
                        break;
                    case Gtk.ResponseType.CANCEL:
                        debug ("User cancelled, don't do anything.");
                        break;
                    case Gtk.ResponseType.DELETE_EVENT:
                        debug ("User cancelled, don't do anything.");
                        break;
                }
                dialog.destroy();
            });

            if (edit_view_content.is_modified) {
                dialog.show ();
                edit_view_content.is_modified = false;
            } else {
                try {
                    Services.FileManager.save ();
                } catch (Error e) {
                    warning ("Unexpected error during save: " + e.message);
                }
                string cache = Path.build_filename (Environment.get_user_cache_dir (), "com.github.lainsce.quilter" + "/temp");
                file = File.new_for_path (cache);
                Widgets.SourceView.buffer.text = "";
                toolbar.subtitle = "New Document";
                settings.last_file = file.get_path ();
                settings.subtitle = file.get_basename ();
            }
        }
    }
}
