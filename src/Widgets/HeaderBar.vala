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
namespace Quilter.Widgets {
    public class Headerbar : Hdy.HeaderBar {
        public Gtk.Button back_button;
        private Gtk.Button open_button;
        private Gtk.Button save_as_button;
        private Gtk.Grid menu_grid;
        private Gtk.Grid top_grid;
        private Gtk.MenuButton menu_button;
        public Gtk.MenuButton pmenu_button;
        public EditView sourceview;
        public Gtk.ToggleButton search_button;
        public Gtk.ToggleButton view_mode;
        public Gtk.ModelButton focusmode_button;
        public MainWindow win;
        public Preview preview;
        private Gtk.Button new_button;
        public signal void create_new ();
        public signal void open ();
        public signal void save_as ();

        public Headerbar (MainWindow win) {
            this.win = win;
            show_close_button = true;

            var header_context = this.get_style_context ();
            header_context.add_class (Gtk.STYLE_CLASS_FLAT);
            header_context.add_class ("quilter-toolbar");
            header_context.add_class ("quilter-toolbar-main");

            build_ui ();
            icons_toolbar ();
        }

        private void build_ui () {
            set_title (null);

            back_button = new Gtk.Button ();
            back_button.has_tooltip = true;
            back_button.tooltip_markup = Granite.markup_accel_tooltip (
                {""},
                _("Go back")
            );
            pack_start (back_button);

            back_button.clicked.connect (() => {
                win.header.set_visible_child (win.side_toolbar);
                win.grid.set_visible_child (win.sidebar);
            });

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

            var color_button_light = new Gtk.RadioButton (null);
            color_button_light.halign = Gtk.Align.CENTER;
            color_button_light.height_request = 40;
            color_button_light.width_request = 40;
            color_button_light.tooltip_text = _("Light Mode");

            var color_button_light_context = color_button_light.get_style_context ();
            color_button_light_context.add_class ("color-button");
            color_button_light_context.add_class ("color-light");

            var color_button_sepia = new Gtk.RadioButton.from_widget (color_button_light);
            color_button_sepia.halign = Gtk.Align.CENTER;
            color_button_sepia.height_request = 40;
            color_button_sepia.width_request = 40;
            color_button_sepia.tooltip_text = _("Sepia Mode");

            var color_button_sepia_context = color_button_sepia.get_style_context ();
            color_button_sepia_context.add_class ("color-button");
            color_button_sepia_context.add_class ("color-sepia");

            var color_button_dark = new Gtk.RadioButton.from_widget (color_button_light);
            color_button_dark.halign = Gtk.Align.CENTER;
            color_button_dark.height_request = 40;
            color_button_dark.width_request = 40;
            color_button_dark.tooltip_text = _("Dark Mode");

            var color_button_dark_context = color_button_dark.get_style_context ();
            color_button_dark_context.add_class ("color-button");
            color_button_dark_context.add_class ("color-dark");

            var mode_type = Quilter.Application.gsettings.get_string("visual-mode");

            switch (mode_type) {
                case "":
                    color_button_light.set_active (true);
                    break;
                case "sepia":
                    color_button_sepia.set_active (true);
                    break;
                case "dark":
                    color_button_dark.set_active (true);
                    break;
                default:
                    color_button_light.set_active (true);
                    break;
            }

            color_button_dark.clicked.connect (() => {
                Quilter.Application.gsettings.set_string("visual-mode", "dark");
            });

            color_button_sepia.clicked.connect (() => {
                Quilter.Application.gsettings.set_string("visual-mode", "sepia");
            });

            color_button_light.clicked.connect (() => {
                Quilter.Application.gsettings.set_string("visual-mode", "");
            });

            focusmode_button = new Gtk.ModelButton ();
            focusmode_button.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_FOCUS;
            focusmode_button.get_child ().destroy ();
            var focusmode_button_accellabel = new Granite.AccelLabel.from_action_name (
                _("Focus Mode…"),
                MainWindow.ACTION_PREFIX + MainWindow.ACTION_FOCUS
            );
            focusmode_button.add (focusmode_button_accellabel);

            focusmode_button.clicked.connect (() => {
                Quilter.Application.gsettings.set_boolean("focus-mode", true);
            });

            var view_mode = new Gtk.ModelButton ();
            view_mode.role = Gtk.ButtonRole.CHECK;
            view_mode.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_TOGGLE_VIEW;
            view_mode.get_child ().destroy ();
            var view_mode_accellabel = new Granite.AccelLabel.from_action_name (
                _("Toggle View…"),
                MainWindow.ACTION_PREFIX + MainWindow.ACTION_TOGGLE_VIEW
            );
            view_mode.add (view_mode_accellabel);

            var view_mode_context = view_mode.get_style_context ();
            view_mode_context.add_class ("flat");

            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            var separator_cx = separator.get_style_context ();
            separator_cx.add_class ("sep");

            var separator2 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            var separator2_cx = separator2.get_style_context ();
            separator2_cx.add_class ("sep");


            //_("Full-Width\nFull Editor, change with switcher")
            var preview_full_label_title = new Gtk.Label (_("Full-Width"));
            preview_full_label_title.halign = Gtk.Align.START;
            var preview_full_label_title_context = preview_full_label_title.get_style_context ();
            preview_full_label_title_context.add_class ("bold");
            var preview_full_label_subtitle = new Gtk.Label (_("Editor or Preview, change on the menu."));
            preview_full_label_subtitle.halign = Gtk.Align.START;
            preview_full_label_subtitle.sensitive = false;
            var preview_full_icon = new Gtk.Image.from_icon_name ("full-width-symbolic", Gtk.IconSize.BUTTON);

            var preview_full_box = new Gtk.Grid ();
            preview_full_box.column_spacing = 12;
            preview_full_box.row_spacing = 6;
            preview_full_box.row_homogeneous = true;
            preview_full_box.attach (preview_full_icon, 0, 0, 1, 2);
            preview_full_box.attach (preview_full_label_title, 1, 0, 1, 1);
            preview_full_box.attach (preview_full_label_subtitle, 1, 1, 1, 1);

            var preview_full_row = new Gtk.ListBoxRow ();
            var preview_full_row_context = preview_full_row.get_style_context ();
            preview_full_row_context.add_class ("preview-row");
            preview_full_row.margin = 6;
            preview_full_row.add (preview_full_box);

            var preview_half_label_title = new Gtk.Label (_("Half-Width"));
            preview_half_label_title.halign = Gtk.Align.START;
            var preview_half_label_title_context = preview_half_label_title.get_style_context ();
            preview_half_label_title_context.add_class ("bold");
            var preview_half_label_subtitle = new Gtk.Label (_("Editor & Preview, divided equally."));
            preview_half_label_subtitle.halign = Gtk.Align.START;
            preview_half_label_subtitle.sensitive = false;
            var preview_half_icon = new Gtk.Image.from_icon_name ("half-width-symbolic", Gtk.IconSize.BUTTON);

            var prev_type = Quilter.Application.gsettings.get_string("preview-type");

            var preview_half_box = new Gtk.Grid ();
            preview_half_box.column_spacing = 12;
            preview_half_box.row_spacing = 6;
            preview_half_box.row_homogeneous = true;
            preview_half_box.attach (preview_half_icon, 0, 0, 1, 2);
            preview_half_box.attach (preview_half_label_title, 1, 0, 1, 1);
            preview_half_box.attach (preview_half_label_subtitle, 1, 1, 1, 1);

            var preview_half_row = new Gtk.ListBoxRow ();
            var preview_half_row_context = preview_half_row.get_style_context ();
            preview_half_row_context.add_class ("preview-row");
            preview_half_row.margin = 6;
            preview_half_row.add (preview_half_box);

            var preview_grid = new Gtk.ListBox ();
            preview_grid.activate_on_single_click = true;
            preview_grid.selection_mode = Gtk.SelectionMode.SINGLE;
            preview_grid.hexpand = true;
            preview_grid.margin = 6;
            preview_grid.add (preview_full_row);
            preview_grid.add (preview_half_row);
            preview_grid.show_all ();

            switch (prev_type) {
                case "half":
                    preview_grid.select_row (preview_half_row);
                    break;
                case "full":
                    preview_grid.select_row (preview_full_row);
                    break;
                default:
                    preview_grid.select_row (preview_half_row);
                    break;
            }

            preview_grid.row_selected.connect ((selected_row) => {
                if (selected_row == preview_half_row) {
                    Quilter.Application.gsettings.set_string("preview-type", "half");
                } else if (selected_row == preview_full_row) {
                    Quilter.Application.gsettings.set_string("preview-type", "full");
                }
            });

            var pmenu = new Gtk.Popover (null);
            pmenu.add (preview_grid);

            pmenu_button = new Gtk.MenuButton ();
            pmenu_button.has_tooltip = true;
            pmenu_button.tooltip_markup = Granite.markup_accel_tooltip (
                {"<Ctrl>1"},
                _("Interface Modes")
            );
            pmenu_button.popover = pmenu;

            top_grid = new Gtk.Grid ();
            top_grid.column_homogeneous = true;
            top_grid.hexpand = true;
            top_grid.row_spacing = 6;
            top_grid.attach (color_button_light, 0, 0, 1, 1);
            top_grid.attach (color_button_sepia, 1, 0, 1, 1);
            top_grid.attach (color_button_dark, 2, 0, 1, 1);
            top_grid.attach (focusmode_button, 0, 2, 3, 1);

            menu_grid = new Gtk.Grid ();
            menu_grid.margin_top = 12;
            menu_grid.margin_bottom = 6;
            menu_grid.column_homogeneous = true;
            menu_grid.row_spacing = 6;
            menu_grid.attach (top_grid, 0, 0);
            menu_grid.attach (separator, 0, 2);
            menu_grid.attach (export_pdf, 0, 3);
            menu_grid.attach (export_html, 0, 4);
            menu_grid.attach (separator2, 0, 5);
            menu_grid.attach (cheatsheet, 0, 6);
            menu_grid.attach (preferences, 0, 7);
            menu_grid.show_all ();

            var menu = new Gtk.Popover (null);
            menu.add (menu_grid);

            menu_button = new Gtk.MenuButton ();
            menu_button.has_tooltip = true;
            menu_button.tooltip_text = (_("Settings"));
            menu_button.popover = menu;

            pack_end (menu_button);
            pack_end (pmenu_button);
            pack_end (search_button);

            pack_start (new_button);
            pack_start (open_button);
            pack_start (save_as_button);

            var prefer_label_button = new Gtk.Button ();
            // Please take note of the \n, keep it where you'd want a line break because the space is small
            prefer_label_button.label = _("Changing modes is disabled due\nto the system dark style preference.");
            var prefer_label_button_context = prefer_label_button.get_style_context ();
            prefer_label_button_context.add_class ("flat");
            prefer_label_button.margin_start = prefer_label_button.margin_end = 3;

            prefer_label_button.clicked.connect (() => {
                try {
                    AppInfo.launch_default_for_uri ("settings://desktop/appearance", null);
                } catch (Error e) {
                    warning ("Failed to open system settings: %s", e.message);
                }
            });

            Quilter.Application.grsettings.notify["prefers-color-scheme"].connect (() => {
                if (Quilter.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK) {
                    color_button_light.sensitive = false;
                    color_button_sepia.sensitive = false;
                    color_button_dark.sensitive = false;

                    top_grid.attach (prefer_label_button, 0, 1, 3, 1);
                    prefer_label_button.visible = true;
                } else if (Quilter.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.NO_PREFERENCE) {
                    color_button_light.sensitive = true;
                    color_button_sepia.sensitive = true;
                    color_button_dark.sensitive = true;

                    top_grid.remove (prefer_label_button);
                    prefer_label_button.visible = false;
                }
            });

            if (Quilter.Application.gsettings.get_string("preview-type") == "full") {
                top_grid.attach (view_mode, 0, 3, 3, 1);
                view_mode.visible = true;
            } else {
                top_grid.remove (view_mode);
                view_mode.visible = true;
            }

            Quilter.Application.gsettings.changed.connect (() => {
                if (Quilter.Application.gsettings.get_string("preview-type") == "full") {
                    top_grid.attach (view_mode, 0, 3, 3, 1);
                    view_mode.visible = true;
                } else {
                    top_grid.remove (view_mode);
                    view_mode.visible = true;
                }
            });

            this.set_size_request (-1,54);
        }

        public void icons_toolbar () {
            menu_button.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.BUTTON));
            pmenu_button.set_image (new Gtk.Image.from_icon_name ("view-dual-symbolic", Gtk.IconSize.BUTTON));
            search_button.set_image (new Gtk.Image.from_icon_name ("edit-find-symbolic", Gtk.IconSize.BUTTON));
            save_as_button.set_image (new Gtk.Image.from_icon_name ("document-save-as-symbolic", Gtk.IconSize.BUTTON));
            open_button.set_image (new Gtk.Image.from_icon_name ("document-open-symbolic", Gtk.IconSize.BUTTON));
            new_button.set_image (new Gtk.Image.from_icon_name ("document-new-symbolic", Gtk.IconSize.BUTTON));
            back_button.set_image (new Gtk.Image.from_icon_name ("go-previous-symbolic", Gtk.IconSize.BUTTON));
        }
    }
}
