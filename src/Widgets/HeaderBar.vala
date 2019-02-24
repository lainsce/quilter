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
namespace Quilter.Widgets {
    public class Headerbar : Gtk.HeaderBar {
        public EditView sourceview;
        public Preview preview;
        public MainWindow win;

        public signal void open ();
        public signal void save_as ();
        public signal void save ();
        public signal void create_new ();

        private Gtk.Button new_button;
        private Gtk.Button open_button;
        private Gtk.Button save_button;
        private Gtk.Button save_as_button;
        public Gtk.ToggleButton search_button;
        private Gtk.MenuButton menu_button;
        private Gtk.MenuButton share_app_menu;

        public Headerbar (MainWindow win) {
            this.win = win;
            var header_context = this.get_style_context ();
            header_context.add_class (Gtk.STYLE_CLASS_FLAT);
            header_context.add_class ("quilter-toolbar");

            build_ui ();

            focus_mode_toolbar ();

            var settings = AppSettings.get_default ();
            settings.changed.connect (() => {
                focus_mode_toolbar ();
            });
        }

        private void build_ui () {
            set_title (null);
            var settings = AppSettings.get_default ();
            string cache = Services.FileManager.get_cache_path ();
            if (this.subtitle != cache) {
                set_subtitle (settings.current_file);
            } else if (this.subtitle != cache) {
                set_subtitle ("No Documents Open");
            } else if (settings.current_file == null) {
                set_subtitle ("No Documents Open");
            }
            new_button = new Gtk.Button ();
            new_button.has_tooltip = true;
            new_button.tooltip_text = (_("New file"));

            new_button.clicked.connect (() => create_new ());

            save_as_button = new Gtk.Button ();
            save_as_button.has_tooltip = true;
            save_as_button.tooltip_text = (_("Save as…"));

            save_as_button.clicked.connect (() => save_as ());

            save_button = new Gtk.Button ();
            save_button.has_tooltip = true;
            save_button.tooltip_text = (_("Save file"));

            save_button.clicked.connect (() => save ());

            open_button = new Gtk.Button ();
			open_button.has_tooltip = true;
            open_button.tooltip_text = (_("Open…"));

            open_button.clicked.connect (() => open ());
            search_button = new Gtk.ToggleButton ();
            search_button.has_tooltip = true;
            search_button.tooltip_text = _("Start search");

            if (settings.searchbar == false) {
                search_button.set_active (false);
            } else {
                search_button.set_active (settings.searchbar);
            }

            search_button.toggled.connect (() => {
    			if (search_button.active) {
    				settings.searchbar = true;
    			} else {
    				settings.searchbar = false;
    			}

            });

            var export_pdf = new Gtk.ModelButton ();
            export_pdf.text = (_("Export to PDF…"));
            export_pdf.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_EXPORT_PDF;

            var export_html = new Gtk.ModelButton ();
            export_html.text = (_("Export to HTML…"));
            export_html.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_EXPORT_HTML;

            var share_menu_grid = new Gtk.Grid ();
            share_menu_grid.margin = 6;
            share_menu_grid.row_spacing = 6;
            share_menu_grid.column_spacing = 12;
            share_menu_grid.orientation = Gtk.Orientation.VERTICAL;
            share_menu_grid.add (export_pdf);
            share_menu_grid.add (export_html);
            share_menu_grid.show_all ();

            var share_menu = new Gtk.Popover (null);
            share_menu.add (share_menu_grid);

            share_app_menu = new Gtk.MenuButton ();
            share_app_menu.tooltip_text = _("Export");
            share_app_menu.popover = share_menu;

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

            var color_button_moon = new Gtk.Button ();
            color_button_moon.set_image (new Gtk.Image.from_icon_name ("format-justify-fill-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            color_button_moon.halign = Gtk.Align.CENTER;
            color_button_moon.height_request = 40;
            color_button_moon.width_request = 40;
            color_button_moon.tooltip_text = _("Moon Mode");

            var color_button_moon_context = color_button_moon.get_style_context ();
            color_button_moon_context.add_class ("color-button");
            color_button_moon_context.add_class ("color-moon");

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
                settings.moon_mode = false;
            });

            color_button_sepia.clicked.connect (() => {
                settings.sepia_mode = true;
                settings.dark_mode = false;
                settings.moon_mode = false;
            });

            color_button_moon.clicked.connect (() => {
                settings.moon_mode = true;
                settings.sepia_mode = false;
                settings.dark_mode = false;
            });

            color_button_light.clicked.connect (() => {
                settings.dark_mode = false;
                settings.sepia_mode = false;
                settings.moon_mode = false;
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

            var colorbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            colorbox.pack_start (color_button_light, true, true, 0);
            colorbox.pack_start (color_button_sepia, true, true, 0);
            colorbox.pack_start (color_button_moon, true, true, 0);
            colorbox.pack_start (color_button_dark, true, true, 0);

            var modebox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            modebox.pack_start (focusmode_button, true, true, 6);

            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

            var menu_grid = new Gtk.Grid ();
            menu_grid.margin = 6;
            menu_grid.row_spacing = 6;
            menu_grid.column_spacing = 12;
            menu_grid.orientation = Gtk.Orientation.VERTICAL;
            menu_grid.add (colorbox);
            menu_grid.add (modebox);
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

            pack_start (new_button);
            pack_start (open_button);
            pack_start (save_as_button);

            // This makes the save button show or not, and it's necessary as-is.
            settings.changed.connect (() => {
                if (settings.autosave) {
                    save_button.visible = false;
                    settings.autosave = true;
                } else {
                    pack_start (save_button);
                    save_button.visible = true;
                    settings.autosave = false;
                }
            });

            pack_end (menu_button);
            pack_end (share_app_menu);
            pack_end (search_button);

            set_show_close_button (true);
            this.show_all ();
        }

        public void focus_mode_toolbar () {
            var settings = AppSettings.get_default ();
            if (!settings.focus_mode) {
                new_button.set_image (new Gtk.Image.from_icon_name ("document-new", Gtk.IconSize.LARGE_TOOLBAR));
                save_button.set_image (new Gtk.Image.from_icon_name ("document-save", Gtk.IconSize.LARGE_TOOLBAR));
                save_as_button.set_image (new Gtk.Image.from_icon_name ("document-save-as", Gtk.IconSize.LARGE_TOOLBAR));
                open_button.set_image (new Gtk.Image.from_icon_name ("document-open", Gtk.IconSize.LARGE_TOOLBAR));
                menu_button.set_image (new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR));
                share_app_menu.image = new Gtk.Image.from_icon_name ("document-export", Gtk.IconSize.LARGE_TOOLBAR);
                search_button.set_image (new Gtk.Image.from_icon_name ("edit-find", Gtk.IconSize.LARGE_TOOLBAR));
            } else {
                new_button.set_image (new Gtk.Image.from_icon_name ("document-new-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
                save_button.set_image (new Gtk.Image.from_icon_name ("document-save-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
                save_as_button.set_image (new Gtk.Image.from_icon_name ("document-save-as-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
                open_button.set_image (new Gtk.Image.from_icon_name ("document-open-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
                menu_button.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
                share_app_menu.image = new Gtk.Image.from_icon_name ("document-export-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
                search_button.set_image (new Gtk.Image.from_icon_name ("edit-find-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            }
        }
    }
}
