/*
* Copyright (C) 2018 Lains
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
            main_stack.margin = 6;
            main_stack.margin_top = 0;

            var main_stackswitcher = new Gtk.StackSwitcher ();
            main_stackswitcher.stack = main_stack;
            main_stackswitcher.halign = Gtk.Align.CENTER;
            main_stackswitcher.homogeneous = true;
            main_stackswitcher.margin = 6;
            main_stackswitcher.margin_top = 0;

            main_stack.add_titled (get_interface_grid (), "interface", _("Interface"));
            main_stack.add_titled (get_editor_grid (), "editor", _("Editor"));
            main_stack.add_titled (get_preview_grid (), "preview", _("Preview"));

            var close_button = add_button (_("Close"), Gtk.ResponseType.CLOSE);
            ((Gtk.Button) close_button).clicked.connect (() => destroy ());

            var main_grid = new Gtk.Grid ();
            main_grid.margin_top = 0;
            main_grid.attach (main_stackswitcher, 0, 0, 1, 1);
            main_grid.attach (main_stack, 0, 1, 1, 1);

            ((Gtk.Container) get_content_area ()).add (main_grid);
        }

        private Gtk.Widget get_editor_grid () {
            var editor_grid = new Gtk.Grid ();
            editor_grid.orientation = Gtk.Orientation.VERTICAL;
            editor_grid.row_spacing = 6;
            editor_grid.column_spacing = 12;

            var geo_header = new Granite.HeaderLabel (_("Geometry"));
            var spacing_label = new SettingsLabel (_("Spacing of Text:"));
            var spacing_size = new Granite.Widgets.ModeButton ();
            spacing_size.append_text (_("Small"));
            spacing_size.append_text (_("Normal"));
            spacing_size.append_text (_("Large"));

            var spacing = Quilter.Application.gsettings.get_int("spacing");

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
                        Quilter.Application.gsettings.set_int("spacing", 2);
                        break;
                    case 1:
                        Quilter.Application.gsettings.set_int("spacing", 4);
                        break;
                    case 2:
                        Quilter.Application.gsettings.set_int("spacing", 6);
                        break;
                    case 3:
                        Quilter.Application.gsettings.set_int("spacing", spacing);
                        break;
                }
            });

            var margins_label = new SettingsLabel (_("Margins of Text:"));
            var margins_size = new Granite.Widgets.ModeButton ();
            margins_size.append_text (_("Small"));
            margins_size.append_text (_("Normal"));
            margins_size.append_text (_("Large"));

            var margins = Quilter.Application.gsettings.get_int("margins");

            switch (margins) {
                case Constants.NARROW_MARGIN:
                    margins_size.selected = 0;
                    break;
                case Constants.MEDIUM_MARGIN:
                    margins_size.selected = 1;
                    break;
                case Constants.WIDE_MARGIN:
                    margins_size.selected = 2;
                    break;
                default:
                    margins_size.selected = 1;
                    break;
            }

            margins_size.mode_changed.connect (() => {
                switch (margins_size.selected) {
                    case 0:
                        Quilter.Application.gsettings.set_int("margins", Constants.NARROW_MARGIN);
                        break;
                    case 1:
                        Quilter.Application.gsettings.set_int("margins", Constants.MEDIUM_MARGIN);
                        break;
                    case 2:
                        Quilter.Application.gsettings.set_int("margins", Constants.WIDE_MARGIN);
                        break;
                    case 3:
                        Quilter.Application.gsettings.set_int("margins", margins);
                        break;
                }
            });

            var font_header = new Granite.HeaderLabel (_("Fonts & Type"));
            var font_type_label = new SettingsLabel (_("Editor Font Type:"));
            var font_type = new Gtk.ComboBoxText();
            font_type.append_text(_("Quilt Mono"));
            font_type.append_text(_("Quilt Zwei"));
            font_type.append_text(_("Quilt Vier"));

            switch (Quilter.Application.gsettings.get_string("edit-font-type")) {
                case "mono":
                    font_type.set_active(0);
                    break;
                case "zwei":
                    font_type.set_active(1);
                    break;
                case "vier":
                    font_type.set_active(2);
                    break;
                default:
                    font_type.set_active(0);
                    break;
            }

            font_type.changed.connect (() => {
                switch (font_type.get_active ()) {
                    case 0:
                        Quilter.Application.gsettings.set_string("edit-font-type", "mono");
                        break;
                    case 1:
                        Quilter.Application.gsettings.set_string("edit-font-type", "zwei");
                        break;
                    case 2:
                        Quilter.Application.gsettings.set_string("edit-font-type", "vier");
                        break;
                    default:
                        Quilter.Application.gsettings.set_string("edit-font-type", "mono");
                        break;
                }
            });

            var font_label = new SettingsLabel (_("Editor Font Size:"));
            var font_size = new Granite.Widgets.ModeButton ();
            font_size.append_text (_("Small"));
            font_size.append_text (_("Normal"));
            font_size.append_text (_("Large"));

            var font_sizing = Quilter.Application.gsettings.get_int("font-sizing");

            switch (font_sizing) {
                case Constants.SMALL_FONT:
                    font_size.selected = 0;
                    break;
                case Constants.MEDIUM_FONT:
                    font_size.selected = 1;
                    break;
                case Constants.BIG_FONT:
                    font_size.selected = 2;
                    break;
                default:
                    font_size.selected = 1;
                    break;
            }

            font_size.mode_changed.connect (() => {
                switch (font_size.selected) {
                    case 0:
                        Quilter.Application.gsettings.set_int("font-sizing", Constants.SMALL_FONT);
                        Widgets.EditView.get_instance ().get_style_context ().add_class ("small-text");
                        Widgets.EditView.get_instance ().get_style_context ().remove_class ("medium-text");
                        Widgets.EditView.get_instance ().get_style_context ().remove_class ("big-text");
                        break;
                    case 1:
                        Quilter.Application.gsettings.set_int("font-sizing", Constants.MEDIUM_FONT);
                        Widgets.EditView.get_instance ().get_style_context ().remove_class ("small-text");
                        Widgets.EditView.get_instance ().get_style_context ().add_class ("medium-text");
                        Widgets.EditView.get_instance ().get_style_context ().remove_class ("big-text");
                        break;
                    case 2:
                        Quilter.Application.gsettings.set_int("font-sizing", Constants.BIG_FONT);
                        Widgets.EditView.get_instance ().get_style_context ().remove_class ("small-text");
                        Widgets.EditView.get_instance ().get_style_context ().remove_class ("medium-text");
                        Widgets.EditView.get_instance ().get_style_context ().add_class ("big-text");
                        break;
                    case 3:
                        Quilter.Application.gsettings.set_int("font-sizing", font_sizing);
                        Widgets.EditView.get_instance ().get_style_context ().remove_class ("small-text");
                        Widgets.EditView.get_instance ().get_style_context ().add_class ("medium-text");
                        Widgets.EditView.get_instance ().get_style_context ().remove_class ("big-text");
                        break;
                }
            });

            var edit_header = new Granite.HeaderLabel (_("Editor"));
            var save_button_label = new SettingsLabel (_("Save files when changed:"));
            var save_button = new SettingsSwitch ("autosave");
            var pos_button_label = new SettingsLabel (_("Highlight Parts of Speech<sup>BETA</sup> :"));
            var pos_button = new SettingsSwitch ("pos");
            var custom_help = new Gtk.Image.from_icon_name ("help-info-symbolic", Gtk.IconSize.BUTTON);
            custom_help.halign = Gtk.Align.START;
            custom_help.margin_start = 6;
            custom_help.tooltip_text = _("Only available in English.\n\nColors words based on type:\n- Nouns are Black\n- Verbs are Blue\n- Adjectives are Yellow\n- Adverbs are Purple\n- Conjunctions are Green");

            var pos_switch_grid = new Gtk.Grid ();
            pos_switch_grid.add (pos_button);
            pos_switch_grid.add (custom_help);

            editor_grid.attach (edit_header,  0, 0, 1, 1);
            editor_grid.attach (save_button_label,  0, 1, 1, 1);
            editor_grid.attach (save_button, 1, 1, 1, 1);
            editor_grid.attach (pos_button_label,  0, 2, 1, 1);
            editor_grid.attach (pos_switch_grid, 1, 2, 1, 1);

            editor_grid.attach (geo_header, 0, 3, 3, 1);
            editor_grid.attach (spacing_label, 0, 4, 1, 1);
            editor_grid.attach (spacing_size, 1, 4, 1, 1);
            editor_grid.attach (margins_label, 0, 5, 1, 1);
            editor_grid.attach (margins_size, 1, 5, 1, 1);

            editor_grid.attach (font_header, 0, 7, 3, 1);
            editor_grid.attach (font_type_label, 0, 8, 1, 1);
            editor_grid.attach (font_type, 1, 8, 1, 1);
            editor_grid.attach (font_label, 0, 9, 1, 1);
            editor_grid.attach (font_size, 1, 9, 1, 1);

            return editor_grid;
        }

        private Gtk.Widget get_interface_grid () {
            weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
            default_theme.add_resource_path ("/com/github/lainsce/quilter");


            var interface_grid = new Gtk.Grid ();
            interface_grid.row_spacing = 6;
            interface_grid.column_spacing = 12;
            interface_grid.orientation = Gtk.Orientation.VERTICAL;
            interface_grid.set_column_homogeneous (false);

            var mode_header = new Granite.HeaderLabel (_("Modes"));
            var color_button_light = new Gtk.Button ();
            var color_button_light_icon = new Gtk.Image.from_icon_name ("mode-change-symbolic", Gtk.IconSize.DIALOG);
            color_button_light.set_image (color_button_light_icon);
            color_button_light.halign = Gtk.Align.CENTER;
            color_button_light.height_request = 64;
            color_button_light.width_request = 64;

            var color_button_light_context = color_button_light.get_style_context ();
            color_button_light_context.add_class ("color-button");
            color_button_light_context.add_class ("color-light");

            var color_button_light_text = new Gtk.Label (_("Light Mode"));

            var color_button_sepia = new Gtk.Button ();
            var color_button_sepia_icon = new Gtk.Image.from_icon_name ("mode-change-symbolic", Gtk.IconSize.DIALOG);
            color_button_sepia.set_image (color_button_sepia_icon);
            color_button_sepia.halign = Gtk.Align.CENTER;
            color_button_sepia.height_request = 64;
            color_button_sepia.width_request = 64;

            var color_button_sepia_context = color_button_sepia.get_style_context ();
            color_button_sepia_context.add_class ("color-button");
            color_button_sepia_context.add_class ("color-sepia");

            var color_button_sepia_text = new Gtk.Label (_("Sepia Mode"));

            var color_button_dark = new Gtk.Button ();
            var color_button_dark_icon = new Gtk.Image.from_icon_name ("mode-change-symbolic", Gtk.IconSize.DIALOG);
            color_button_dark.set_image (color_button_dark_icon);
            color_button_dark.halign = Gtk.Align.CENTER;
            color_button_dark.height_request = 64;
            color_button_dark.width_request = 64;

            var color_button_dark_context = color_button_dark.get_style_context ();
            color_button_dark_context.add_class ("color-button");
            color_button_dark_context.add_class ("color-dark");

            var color_button_dark_text = new Gtk.Label (_("Dark Mode"));

            color_button_dark.clicked.connect (() => {
                Quilter.Application.gsettings.set_string("visual-mode", "dark");
            });

            color_button_sepia.clicked.connect (() => {
                Quilter.Application.gsettings.set_string("visual-mode", "sepia");
            });

            color_button_light.clicked.connect (() => {
                Quilter.Application.gsettings.set_string("visual-mode", "");
            });

            color_button_light.sensitive = false;
            color_button_sepia.sensitive = false;
            color_button_dark.sensitive = false;

            var focus_mode_label = new SettingsLabel (_("Enable Focus Mode:"));
            var focus_mode = new SettingsSwitch ("focus-mode");

            var focus_mode_type_label = new SettingsLabel (_("Type of Focus Mode:"));
            var focus_mode_type_size = new Granite.Widgets.ModeButton ();
            focus_mode_type_size.append_text (_("Paragraph"));
            focus_mode_type_size.append_text (_("Sentence"));

            var focus_mode_type = Quilter.Application.gsettings.get_int("focus-mode-type");

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
                       Quilter.Application.gsettings.set_int("focus-mode-type", 0);
                        break;
                    case 1:
                       Quilter.Application.gsettings.set_int("focus-mode-type", 1);
                        break;
                    case 2:
                       Quilter.Application.gsettings.set_int("focus-mode-type", focus_mode_type);
                        break;
                }
            });

            var typewriterscrolling_label = new SettingsLabel (_("Typewriter Scrolling:"));
            typewriterscrolling_label.set_halign (Gtk.Align.END);
            var typewriterscrolling = new SettingsSwitch ("typewriter-scrolling");

            var ui_header = new Granite.HeaderLabel (_("User Interface"));
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
            var separator_cx = separator.get_style_context ();
            separator_cx.add_class ("sep");

            interface_grid.attach (mode_header, 0, 1, 3, 1);
            interface_grid.attach (buttonbox, 0, 2, 3, 1);
            interface_grid.attach (textbox, 0, 3, 3, 1);
            interface_grid.attach (separator, 0, 5, 3, 1);

            interface_grid.attach (ui_header,  0, 6, 1, 1);
            interface_grid.attach (focus_mode_label, 0, 7, 1, 1);
            interface_grid.attach (focus_mode, 1, 7, 1, 1);
            interface_grid.attach (focus_mode_type_label, 0, 8, 1, 1);
            interface_grid.attach (focus_mode_type_size, 1, 8, 1, 1);
            interface_grid.attach (typewriterscrolling_label, 0, 9, 1, 1);
            interface_grid.attach (typewriterscrolling, 1, 9, 1, 1);

            Quilter.Application.grsettings.notify["prefers-color-scheme"].connect (() => {
                if (Quilter.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK) {
                    color_button_light.sensitive = false;
                    color_button_sepia.sensitive = false;
                    color_button_dark.sensitive = false;
                    color_button_light_text.sensitive = false;
                    color_button_sepia_text.sensitive = false;
                    color_button_dark_text.sensitive = false;
                } else if (Quilter.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.NO_PREFERENCE) {
                    color_button_light.sensitive = true;
                    color_button_sepia.sensitive = true;
                    color_button_dark.sensitive = true;
                    color_button_light_text.sensitive = true;
                    color_button_sepia_text.sensitive = true;
                    color_button_dark_text.sensitive = true;
                }
            });

            return interface_grid;
        }

        private Gtk.Widget get_preview_grid () {
            var ext_grid = new Gtk.Grid ();
            ext_grid.row_spacing = 6;
            ext_grid.column_spacing = 12;
            ext_grid.orientation = Gtk.Orientation.VERTICAL;
            ext_grid.set_column_homogeneous (false);

            var preview_header = new Granite.HeaderLabel (_("Preview"));
            var preview_font_label = new SettingsLabel (_("Preview Font Type:"));
            var preview_font_size = new Granite.Widgets.ModeButton ();
            preview_font_size.append_text (_("Serif"));
            preview_font_size.append_text (_("Sans"));
            preview_font_size.append_text (_("Mono"));

            var preview_font = Quilter.Application.gsettings.get_string("preview-font");

            switch (preview_font) {
                case "serif":
                    preview_font_size.selected = 0;
                    break;
                case "sans":
                    preview_font_size.selected = 1;
                    break;
                case "mono":
                    preview_font_size.selected = 2;
                    break;
                default:
                    preview_font_size.selected = 1;
                    break;
            }

            preview_font_size.mode_changed.connect (() => {
                switch (preview_font_size.selected) {
                    case 0:
                        Quilter.Application.gsettings.set_string("preview-font", "serif");
                        break;
                    case 1:
                        Quilter.Application.gsettings.set_string("preview-font", "sans");
                        break;
                    case 2:
                        Quilter.Application.gsettings.set_string("preview-font", "mono");
                        break;
                    case 3:
                        Quilter.Application.gsettings.set_string("preview-font", preview_font);
                        break;
                }
            });

            var centering_preview_headers_label = new SettingsLabel (_("Center Preview Headers:"));
            var centering_preview_headers = new SettingsSwitch ("center-headers");
            centering_preview_headers.hexpand = true;

            var ext_header = new Granite.HeaderLabel (_("Extensions"));

            var highlight_label = new SettingsLabel (_("Enable Code Highlighting:"));
            var highlight = new SettingsSwitch ("highlight");
            highlight.hexpand = true;

            var latex_label = new SettingsLabel (_("Enable LaTeX Processing:"));
            var latex = new SettingsSwitch ("latex");
            latex.hexpand = true;

            var mermaid_label = new SettingsLabel (_("Enable Mermaid.js Graphing:"));
            var mermaid = new SettingsSwitch ("mermaid");
            var custom_help = new Gtk.Image.from_icon_name ("help-info-symbolic", Gtk.IconSize.BUTTON);
            custom_help.halign = Gtk.Align.START;
            custom_help.margin_start = 6;
            custom_help.tooltip_text = _("Disable Code Highlighting for optimal use of Mermaid.js");

            var mermaid_switch_grid = new Gtk.Grid ();
            mermaid_switch_grid.add (mermaid);
            mermaid_switch_grid.add (custom_help);

            var spellcheck_label = new SettingsLabel (_("Enable Spellchecking:"));
            var spellcheck = new SettingsSwitch ("spellcheck");

            ext_grid.attach (preview_header,  0, 0, 1, 1);
            ext_grid.attach (preview_font_label, 0, 1, 1, 1);
            ext_grid.attach (preview_font_size, 1, 1, 1, 1);
            ext_grid.attach (centering_preview_headers_label, 0, 2, 1, 1);
            ext_grid.attach (centering_preview_headers, 1, 2, 1, 1);
            ext_grid.attach (ext_header,  0, 3, 1, 1);
            ext_grid.attach (highlight_label, 0, 4, 1, 1);
            ext_grid.attach (highlight, 1, 4, 1, 1);
            ext_grid.attach (latex_label, 0, 5, 1, 1);
            ext_grid.attach (latex, 1, 5, 1, 1);
            ext_grid.attach (mermaid_label, 0, 6, 1, 1);
            ext_grid.attach (mermaid_switch_grid, 1, 6, 1, 1);
            ext_grid.attach (spellcheck_label, 0, 7, 1, 1);
            ext_grid.attach (spellcheck, 1, 7, 1, 1);

            return ext_grid;
        }

        private class SettingsLabel : Gtk.Label {
            public SettingsLabel (string text) {
                label = text;
                halign = Gtk.Align.END;
                margin_start = 12;
                use_markup = true;
            }
        }

        private class Text : Gtk.Label {
            public Text (string text) {
                label = text;
                halign = Gtk.Align.END;
                use_markup = true;
            }
        }

        private class SettingsSwitch : Gtk.Switch {
            public SettingsSwitch (string setting) {
                halign = Gtk.Align.START;
                Quilter.Application.gsettings.bind (setting, this, "active", SettingsBindFlags.DEFAULT);
            }
        }
    }
}
