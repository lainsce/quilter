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
    public class Preferences : Gtk.Dialog {
        public Preferences (Gtk.Window? parent) {
            Object (
                border_width: 6,
                deletable: false,
                resizable: false,
                title: _("Preferences"),
                transient_for: parent,
                destroy_with_parent: true,
                window_position: Gtk.WindowPosition.CENTER_ON_PARENT
            );
        }

        construct {
            var main_stack = new Gtk.Stack ();
            main_stack.margin = 12;
            main_stack.margin_top = 0;

            var main_stackswitcher = new Gtk.StackSwitcher ();
            main_stackswitcher.stack = main_stack;
            main_stackswitcher.halign = Gtk.Align.CENTER;
            main_stackswitcher.homogeneous = true;
            main_stackswitcher.margin = 12;
            main_stackswitcher.margin_top = 0;

            main_stack.add_titled (get_editor_grid (), "editor", _("Editor"));
            main_stack.add_titled (get_interface_grid (), "interface", _("Interface"));
            main_stack.add_titled (get_ext_grid (), "ext", _("Extensions"));

            var close_button = add_button (_("Close"), Gtk.ResponseType.CLOSE);
            ((Gtk.Button) close_button).clicked.connect (() => destroy ());

            var main_grid = new Gtk.Grid ();
            main_grid.margin_top = 0;
            main_grid.attach (main_stackswitcher, 0, 0, 1, 1);
            main_grid.attach (main_stack, 0, 1, 1, 1);

            ((Gtk.Container) get_content_area ()).add (main_grid);
        }

        private Gtk.Widget get_editor_grid () {
            var main_settings = AppSettings.get_default ();
            var editor_grid = new Gtk.Grid ();
            editor_grid.orientation = Gtk.Orientation.VERTICAL;
            editor_grid.row_spacing = 6;
            editor_grid.column_spacing = 12;

            var editor_header = new Granite.HeaderLabel (_("Editor"));
            var spellcheck_label = new SettingsLabel (_("Enable Spellchecking:"));
            spellcheck_label.set_halign (Gtk.Align.END);
            var spellcheck = new SettingsSwitch ("spellcheck");

            var geo_header = new Granite.HeaderLabel (_("Geometry"));
            var spacing_label = new SettingsLabel (_("Spacing of Text:"));
            var spacing_size = new Granite.Widgets.ModeButton ();
            spacing_size.append_text (_("Small"));
            spacing_size.append_text (_("Normal"));
            spacing_size.append_text (_("Large"));

            var spacing = main_settings.spacing;

            switch (spacing) {
                case 2:
                    spacing_size.selected = 0;
                    break;
                case 4:
                    spacing_size.selected = 1;
                    break;
                case 6:
                    spacing_size.selected = 2;
                    break;
                default:
                    spacing_size.selected = 1;
                    break;
            }

            spacing_size.mode_changed.connect (() => {
                switch (spacing_size.selected) {
                    case 0:
                        main_settings.spacing = 2;
                        break;
                    case 1:
                        main_settings.spacing = 4;
                        break;
                    case 2:
                        main_settings.spacing = 6;
                        break;
                    case 3:
                        main_settings.spacing = spacing;
                        break;
                }
            });

            var margins_label = new SettingsLabel (_("Margins of Text:"));
            var margins_size = new Granite.Widgets.ModeButton ();
            margins_size.append_text (_("Small"));
            margins_size.append_text (_("Normal"));
            margins_size.append_text (_("Large"));

            var margins = main_settings.margins;

            switch (margins) {
                case 40:
                    margins_size.selected = 0;
                    break;
                case 80:
                    margins_size.selected = 1;
                    break;
                case 120:
                    margins_size.selected = 2;
                    break;
                default:
                    margins_size.selected = 1;
                    break;
            }

            margins_size.mode_changed.connect (() => {
                switch (margins_size.selected) {
                    case 0:
                        main_settings.margins = 40;
                        break;
                    case 1:
                        main_settings.margins = 80;
                        break;
                    case 2:
                        main_settings.margins = 120;
                        break;
                    case 3:
                        main_settings.margins = margins;
                        break;
                }
            });

            var save_button_label = new SettingsLabel (_("Save files when changed:"));
            var save_button = new SettingsSwitch ("autosave");

            editor_grid.attach (editor_header, 0, 1, 3, 1);
            editor_grid.attach (spellcheck_label,  0, 2, 1, 1);
            editor_grid.attach (spellcheck, 1, 2, 1, 1);
            editor_grid.attach (save_button_label,  0, 3, 1, 1);
            editor_grid.attach (save_button, 1, 3, 1, 1);

            editor_grid.attach (geo_header, 0, 4, 3, 1);
            editor_grid.attach (spacing_label, 0, 5, 1, 1);
            editor_grid.attach (spacing_size, 1, 5, 1, 1);
            editor_grid.attach (margins_label, 0, 6, 1, 1);
            editor_grid.attach (margins_size, 1, 6, 1, 1);

            return editor_grid;
        }

        private Gtk.Widget get_interface_grid () {
            var main_settings = AppSettings.get_default ();
            var interface_grid = new Gtk.Grid ();
            interface_grid.row_spacing = 6;
            interface_grid.column_spacing = 12;
            interface_grid.orientation = Gtk.Orientation.VERTICAL;
            interface_grid.set_column_homogeneous (false);

            var mode_header = new Granite.HeaderLabel (_("Modes"));
            var color_button_light = new Gtk.Button ();
            var color_button_light_icon = new Gtk.Image ();
            color_button_light_icon.gicon = new ThemedIcon ("mode-change-symbolic");
            color_button_light_icon.pixel_size = 48;
            color_button_light.set_image (color_button_light_icon);
            color_button_light.halign = Gtk.Align.CENTER;
            color_button_light.height_request = 64;
            color_button_light.width_request = 64;

            var color_button_light_context = color_button_light.get_style_context ();
            color_button_light_context.add_class ("color-button");
            color_button_light_context.add_class ("color-light");

            var color_button_light_text = new Gtk.Label (_("Light Mode"));

            var color_button_sepia = new Gtk.Button ();
            var color_button_sepia_icon = new Gtk.Image ();
            color_button_sepia_icon.gicon = new ThemedIcon ("mode-change-symbolic");
            color_button_sepia_icon.pixel_size = 48;
            color_button_sepia.set_image (color_button_sepia_icon);
            color_button_sepia.halign = Gtk.Align.CENTER;
            color_button_sepia.height_request = 64;
            color_button_sepia.width_request = 64;

            var color_button_sepia_context = color_button_sepia.get_style_context ();
            color_button_sepia_context.add_class ("color-button");
            color_button_sepia_context.add_class ("color-sepia");

            var color_button_sepia_text = new Gtk.Label (_("Sepia Mode"));

            var color_button_dark = new Gtk.Button ();
            var color_button_dark_icon = new Gtk.Image ();
            color_button_dark_icon.gicon = new ThemedIcon ("mode-change-symbolic");
            color_button_dark_icon.pixel_size = 48;
            color_button_dark.set_image (color_button_dark_icon);
            color_button_dark.halign = Gtk.Align.CENTER;
            color_button_dark.height_request = 64;
            color_button_dark.width_request = 64;

            var color_button_dark_context = color_button_dark.get_style_context ();
            color_button_dark_context.add_class ("color-button");
            color_button_dark_context.add_class ("color-dark");

            var color_button_dark_text = new Gtk.Label (_("Dark Mode"));

            color_button_dark.clicked.connect (() => {
                main_settings.dark_mode = true;
                main_settings.sepia_mode = false;
            });

            color_button_sepia.clicked.connect (() => {
                main_settings.sepia_mode = true;
                main_settings.dark_mode = false;
            });

            color_button_light.clicked.connect (() => {
                main_settings.dark_mode = false;
                main_settings.sepia_mode = false;
            });

            var focus_mode_label = new SettingsLabel (_("Enable Focus Mode:"));
            var focus_mode = new SettingsSwitch ("focus-mode");

            var focus_mode_type_label = new SettingsLabel (_("Type of Focus Mode:"));
            var focus_mode_type_size = new Granite.Widgets.ModeButton ();
            focus_mode_type_size.append_text (_("Paragraph"));
            focus_mode_type_size.append_text (_("Sentence"));

            var focus_mode_type = main_settings.focus_mode_type;

            switch (focus_mode_type) {
                case 0:
                    focus_mode_type_size.selected = 0;
                    break;
                case 1:
                    focus_mode_type_size.selected = 1;
                    break;
                default:
                    focus_mode_type_size.selected = 0;
                    break;
            }

            focus_mode_type_size.mode_changed.connect (() => {
                switch (focus_mode_type_size.selected) {
                    case 0:
                        main_settings.focus_mode_type = 0;
                        break;
                    case 1:
                        main_settings.focus_mode_type = 1;
                        break;
                    case 2:
                        main_settings.focus_mode_type = focus_mode_type;
                        break;
                }
            });

            var statusbar_header = new Granite.HeaderLabel (_("Statusbar"));
            var statusbar_label = new SettingsLabel (_("Show Statusbar:"));
            statusbar_label.set_halign (Gtk.Align.END);
            var statusbar = new SettingsSwitch ("statusbar");

            var buttonbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            buttonbox.halign = Gtk.Align.FILL;
            buttonbox.hexpand = true;
            buttonbox.set_homogeneous (true);
            buttonbox.pack_start (color_button_light, true, true, 6);
            buttonbox.pack_start (color_button_sepia, true, true, 6);
            buttonbox.pack_start (color_button_dark, true, true, 6);

            var textbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            textbox.halign = Gtk.Align.FILL;
            textbox.hexpand = true;
            textbox.set_homogeneous (true);
            textbox.pack_start (color_button_light_text, true, true, 6);
            textbox.pack_start (color_button_sepia_text, true, true, 6);
            textbox.pack_start (color_button_dark_text, true, true, 6);

            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            separator.hexpand = true;
            separator.margin_top = 6;
            separator.margin_bottom = 6;

            interface_grid.attach (mode_header, 0, 1, 3, 1);
            interface_grid.attach (buttonbox, 0, 2, 3, 1);
            interface_grid.attach (textbox, 0, 3, 3, 1);
            interface_grid.attach (separator, 0, 4, 3, 1);

            interface_grid.attach (focus_mode_label, 0, 5, 1, 1);
            interface_grid.attach (focus_mode, 1, 5, 1, 1);
            interface_grid.attach (focus_mode_type_label, 0, 6, 1, 1);
            interface_grid.attach (focus_mode_type_size, 1, 6, 1, 1);

            interface_grid.attach (statusbar_header,  0, 7, 1, 1);
            interface_grid.attach (statusbar_label,  0, 8, 1, 1);
            interface_grid.attach (statusbar, 1, 8, 1, 1);

            return interface_grid;
        }

        private Gtk.Widget get_ext_grid () {
            var ext_grid = new Gtk.Grid ();
            ext_grid.orientation = Gtk.Orientation.VERTICAL;
            ext_grid.row_spacing = 6;
            ext_grid.column_spacing = 12;

            var ext_header = new Granite.HeaderLabel (_("Extensions"));
            var latex_label = new SettingsLabel (_("Enable LaTeX:"));
            latex_label.set_halign (Gtk.Align.END);
            var latex = new SettingsSwitch ("latex");
            var highlight_label = new SettingsLabel (_("Enable code highlight:"));
            highlight_label.set_halign (Gtk.Align.END);
            var highlight = new SettingsSwitch ("highlight");

            ext_grid.attach (ext_header,  0, 1, 1, 1);
            ext_grid.attach (latex_label,  0, 2, 1, 1);
            ext_grid.attach (latex, 1, 2, 1, 1);
            ext_grid.attach (highlight_label,  0, 3, 1, 1);
            ext_grid.attach (highlight, 1, 3, 1, 1);

            return ext_grid;
        }

        private class SettingsLabel : Gtk.Label {
            public SettingsLabel (string text) {
                label = text;
                halign = Gtk.Align.END;
                margin_start = 12;
            }
        }

        private class SettingsSwitch : Gtk.Switch {
            public SettingsSwitch (string setting) {
                var main_settings = AppSettings.get_default ();
                halign = Gtk.Align.START;
                main_settings.schema.bind (setting, this, "active", SettingsBindFlags.DEFAULT);
            }
        }
    }
}
