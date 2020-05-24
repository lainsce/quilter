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
        private Gtk.Grid menu_grid;
        private Gtk.Grid top_grid;

        public Headerbar (MainWindow win) {
            this.win = win;
            var header_context = this.get_style_context ();
            header_context.add_class (Gtk.STYLE_CLASS_FLAT);
            header_context.add_class ("quilter-toolbar");

            build_ui ();
            icons_toolbar ();
        }

        private void build_ui () {
            set_title (null);
            string cache = Services.FileManager.get_cache_path ();
            if (this.subtitle != cache) {
                set_subtitle (Quilter.Application.gsettings.get_string("current-file"));
            } else if (this.subtitle == cache) {
                set_subtitle (_("No Documents Open"));
            } else if (Quilter.Application.gsettings.get_string("current-file") == null) {
                set_subtitle (_("No Documents Open"));
            } else if (this.subtitle == Services.FileManager.get_temp_document_path ()) {
                set_subtitle (_("No Documents Open"));
            }
            new_button = new Gtk.Button ();
            new_button.has_tooltip = true;
            new_button.tooltip_markup = Granite.markup_accel_tooltip (
                {"<Ctrl>n"},
                _("New file")
            );

            new_button.clicked.connect (() => create_new ());

            save_as_button = new Gtk.Button ();
            save_as_button.has_tooltip = true;
            save_as_button.tooltip_markup = Granite.markup_accel_tooltip (
                {"<Ctrl><Shift>s"},
                _("Save as…")
            );

            save_as_button.clicked.connect (() => save_as ());

            save_button = new Gtk.Button ();
            save_button.has_tooltip = true;
            save_button.tooltip_markup = Granite.markup_accel_tooltip (
                {"<Ctrl>s"},
                _("Save file")
            );

            save_button.clicked.connect (() => save ());

            open_button = new Gtk.Button ();
			open_button.has_tooltip = true;
            open_button.tooltip_markup = Granite.markup_accel_tooltip (
                {"<Ctrl>o"},
                _("Open…")
            );

            open_button.clicked.connect (() => open ());

            search_button = new Gtk.ToggleButton ();
            search_button.has_tooltip = true;
            search_button.tooltip_markup = Granite.markup_accel_tooltip (
                {"<Ctrl>f"},
                _("Find…")
            );

            if (Quilter.Application.gsettings.get_boolean("searchbar") == false) {
                search_button.set_active (false);
            } else {
                search_button.set_active (Quilter.Application.gsettings.get_boolean("searchbar"));
            }

            search_button.toggled.connect (() => {
    			if (search_button.active) {
    				Quilter.Application.gsettings.set_boolean("searchbar", true);
    			} else {
    				Quilter.Application.gsettings.set_boolean("searchbar", false);
    			}

            });

            var export_pdf = new Gtk.ModelButton ();
            export_pdf.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_EXPORT_PDF;
            export_pdf.get_child ().destroy ();
            var export_pdf_accellabel = new Granite.AccelLabel.from_action_name (
                _("Export to PDF…"),
                MainWindow.ACTION_PREFIX + MainWindow.ACTION_EXPORT_PDF
            );
            export_pdf.add (export_pdf_accellabel);

            var export_html = new Gtk.ModelButton ();
            export_html.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_EXPORT_HTML;
            export_html.get_child ().destroy ();
            var export_html_accellabel = new Granite.AccelLabel.from_action_name (
                _("Export to HTML…"),
                MainWindow.ACTION_PREFIX + MainWindow.ACTION_EXPORT_HTML
            );
            export_html.add (export_html_accellabel);

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
            cheatsheet.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_CHEATSHEET;
            cheatsheet.get_child ().destroy ();
            var cheatsheet_accellabel = new Granite.AccelLabel.from_action_name (
                _("Markdown Cheatsheet"),
                MainWindow.ACTION_PREFIX + MainWindow.ACTION_CHEATSHEET
            );
            cheatsheet.add (cheatsheet_accellabel);

            var preferences = new Gtk.ModelButton ();
            preferences.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_PREFS;
            preferences.text = _("Preferences");

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
                Quilter.Application.gsettings.set_string("visual-mode", "dark");
            });

            color_button_sepia.clicked.connect (() => {
                Quilter.Application.gsettings.set_string("visual-mode", "sepia");
            });

            color_button_light.clicked.connect (() => {
                Quilter.Application.gsettings.set_string("visual-mode", "");
            });

            var focusmode_button = new Gtk.Button.with_label ((_("Focus Mode")));
            focusmode_button.set_image (new Gtk.Image.from_icon_name ("zoom-fit-best-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            focusmode_button.set_always_show_image (true);
            focusmode_button.tooltip_text = _("Enter focus mode");
            focusmode_button.margin_start = 15;
            focusmode_button.margin_end = 15;

            focusmode_button.clicked.connect (() => {
    			Quilter.Application.gsettings.set_boolean("focus-mode", true);
            });

            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

            top_grid = new Gtk.Grid ();
            top_grid.column_homogeneous = true;
            top_grid.hexpand = true;
            top_grid.row_spacing = 12;
            top_grid.margin_top = 6;
            top_grid.attach (color_button_light, 0, 0, 1, 1);
            top_grid.attach (color_button_sepia, 1, 0, 1, 1);
            top_grid.attach (color_button_dark, 2, 0, 1, 1);
            top_grid.attach (focusmode_button, 0, 2, 3, 1);

            menu_grid = new Gtk.Grid ();
            menu_grid.margin = 6;
            menu_grid.column_homogeneous = true;
            menu_grid.row_spacing = 6;
            menu_grid.attach (top_grid, 0, 0);
            menu_grid.attach (separator, 0, 2);
            menu_grid.attach (cheatsheet, 0, 3);
            menu_grid.attach (preferences, 0, 4);
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
            if (Quilter.Application.gsettings.get_boolean("autosave")) {
                save_button.visible = false;
                Quilter.Application.gsettings.set_boolean("autosave", true);
            } else {
                pack_start (save_button);
                save_button.visible = true;
                Quilter.Application.gsettings.set_boolean("autosave", false);
            }

            pack_end (menu_button);
            pack_end (share_app_menu);
            pack_end (search_button);

            // Please take note of the \n, keep it where you'd want a line break because the space is small
            var prefer_label = new Gtk.Label (_("Changing modes is disabled due\nto global dark mode."));
            prefer_label.visible = false;
            var prefer_label_context = prefer_label.get_style_context ();
            prefer_label_context.add_class ("h6");

            Quilter.Application.grsettings.notify["prefers-color-scheme"].connect (() => {
                if (Quilter.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK) {
                    color_button_light.sensitive = false;
                    color_button_sepia.sensitive = false;
                    color_button_dark.sensitive = false;

                    top_grid.attach (prefer_label, 0, 1, 3, 1);
                    prefer_label.visible = true;
                } else if (Quilter.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.NO_PREFERENCE) {
                    color_button_light.sensitive = true;
                    color_button_sepia.sensitive = true;
                    color_button_dark.sensitive = true;

                    top_grid.remove (prefer_label);
                    prefer_label.visible = false;
                }
            });

            set_show_close_button (true);
            this.show_all ();
        }

        public void icons_toolbar () {
            new_button.set_image (new Gtk.Image.from_icon_name ("document-new-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
            save_button.set_image (new Gtk.Image.from_icon_name ("document-save-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
            save_as_button.set_image (new Gtk.Image.from_icon_name ("document-save-as-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
            open_button.set_image (new Gtk.Image.from_icon_name ("document-open-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
            menu_button.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
            share_app_menu.image = new Gtk.Image.from_icon_name ("document-export-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            search_button.set_image (new Gtk.Image.from_icon_name ("edit-find-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
        }
    }
}
