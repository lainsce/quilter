/*
* Copyright (C) 2018-2020 Lains
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
        private Gtk.Grid editor_grid;
        private Gtk.Grid interface_grid;
        private Gtk.Grid preview_grid;
        private Gtk.Stack main_stack;
        public weak MainWindow win { get; construct; }

        public Preferences (MainWindow win) {
            Object (
                title: _("Preferences"),
                type_hint: Gdk.WindowTypeHint.DIALOG,
                transient_for: win,
                win: win,
                destroy_with_parent: true,
                window_position: Gtk.WindowPosition.CENTER_ON_PARENT
            );
        }

        construct {
            this.title = title;
            weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
            default_theme.add_resource_path ("/com/github/lainsce/quilter");

            main_stack = new Gtk.Stack ();
            main_stack.margin = 12;
            main_stack.margin_top = 6;
            main_stack.vexpand = true;

            // Let's make a new Dialog design for preferences, follow elementary OS UI cues.
            get_editor_grid ();
            get_interface_grid ();
            get_preview_grid ();

            main_stack.add_titled (interface_grid, "interface", _("INTERFACE"));
            main_stack.add_titled (editor_grid, "editor", _("EDITOR"));
            main_stack.add_titled (preview_grid, "preview", _("PREVIEW"));

            var window_title_vs = new Gtk.StackSwitcher ();
            window_title_vs.get_style_context ().add_class ("quilter-prefs-vs");
            window_title_vs.hexpand = true;
            window_title_vs.homogeneous = true;
            window_title_vs.margin_start = window_title_vs.margin_end = 12;
            window_title_vs.set_stack (main_stack);

            var grid = new Gtk.Grid ();
            grid.attach (window_title_vs, 0, 0, 3, 1);
            grid.attach (main_stack, 0, 1);

            var content = this.get_content_area () as Gtk.Box;
            content.add (grid);

            var context = this.get_style_context ();
            context.add_class ("quilter-dialog-hb");
        }

        private void get_editor_grid () {
            editor_grid = new Gtk.Grid ();
            editor_grid.row_spacing = 12;
            editor_grid.column_spacing = 6;

            var geo_header = new Granite.HeaderLabel (_("Geometry"));
            var spacing_label = new SettingsLabel (_("Text Spacing:"));
            var spacing_size = new Granite.Widgets.ModeButton ();
            spacing_size.append_icon ("small-spacing-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            spacing_size.append_icon ("normal-spacing-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            spacing_size.append_icon ("large-spacing-symbolic", Gtk.IconSize.LARGE_TOOLBAR);

            var spacing = Quilter.Application.gsettings.get_int("spacing");

            switch (spacing) {
                case Constants.NARROW_SPACING:
                    spacing_size.selected = 0;
                    break;
                case Constants.MEDIUM_SPACING:
                    spacing_size.selected = 1;
                    break;
                case Constants.WIDE_SPACING:
                    spacing_size.selected = 2;
                    break;
                default:
                    spacing_size.selected = 1;
                    break;
            }

            spacing_size.mode_changed.connect (() => {
                switch (spacing_size.selected) {
                    case 0:
                        Quilter.Application.gsettings.set_int("spacing", Constants.NARROW_SPACING);
                        break;
                    case 1:
                        Quilter.Application.gsettings.set_int("spacing", Constants.MEDIUM_SPACING);
                        break;
                    case 2:
                        Quilter.Application.gsettings.set_int("spacing", Constants.WIDE_SPACING);
                        break;
                    case 3:
                        Quilter.Application.gsettings.set_int("spacing", spacing);
                        break;
                }
            });

            var margins_label = new SettingsLabel (_("Text Margins:"));
            var margins_size = new Granite.Widgets.ModeButton ();
            margins_size.append_icon ("small-margin-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            margins_size.append_icon ("normal-margin-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            margins_size.append_icon ("large-margin-symbolic", Gtk.IconSize.LARGE_TOOLBAR);

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
            font_size.hexpand = true;
            font_size.append_icon ("small-font-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            font_size.append_icon ("normal-font-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            font_size.append_icon ("large-font-symbolic", Gtk.IconSize.LARGE_TOOLBAR);

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

            var save_button_label = new SettingsLabel (_("Autosave opened document:"));
            var save_button = new SettingsSwitch ("autosave");
            var save_revealer = new Gtk.Revealer ();
            var save_time_label = new SettingsLabel (_("Autosave every:"));

            var save_time_spinbutton = new Gtk.SpinButton.with_range (5, 60, 5);
            save_time_spinbutton.set_value (Quilter.Application.gsettings.get_int("autosave-delay"));
            Quilter.Application.gsettings.bind ("autosave-delay", save_time_spinbutton, "value", SettingsBindFlags.DEFAULT);

            var save_time_unit = new SettingsLabel (_("seconds."));

            var custom_help1 = new Gtk.Image.from_icon_name ("dialog-information-symbolic", Gtk.IconSize.BUTTON);
            custom_help1.halign = Gtk.Align.START;
            custom_help1.margin_start = 6;
            custom_help1.tooltip_text = _("Warning: Values below 15 seconds may affect your storage medium negatively.");

            var save_grid = new Gtk.Grid ();
            save_grid.row_homogeneous = false;
            save_grid.column_spacing = 6;
            save_grid.halign = Gtk.Align.CENTER;
            save_grid.attach (save_time_label, 0, 0);
            save_grid.attach (save_time_spinbutton, 1, 0);
            save_grid.attach (save_time_unit, 2, 0);
            save_grid.attach (custom_help1, 3, 0);

            save_revealer.add (save_grid);

            if (save_button.active) {
                save_revealer.reveal_child = true;
            } else {
                save_revealer.reveal_child = false;
            }

            save_button.bind_property (
                "active",
                save_revealer,
                "reveal-child",
                GLib.BindingFlags.SYNC_CREATE
            );

            var pos_button_label = new SettingsLabel (_("Highlight Speech Parts<sup>𝜷</sup>:"));
            var pos_button = new SettingsSwitch ("pos");
            var custom_help2 = new Gtk.Image.from_icon_name ("dialog-information-symbolic", Gtk.IconSize.BUTTON);
            custom_help2.halign = Gtk.Align.START;
            custom_help2.margin_start = 6;
            // Please mind the line breaks (\n).
            custom_help2.tooltip_text = _("Only available in English.\n\nColors words based on type:\n- Nouns are Black\n- Verbs are Blue\n- Adjectives are Yellow\n- Adverbs are Purple\n- Conjunctions are Green");

            var pos_switch_grid = new Gtk.Grid ();
            pos_switch_grid.add (pos_button);
            pos_switch_grid.add (custom_help2);

            editor_grid.attach (edit_header,  0, 0, 3, 1);
            editor_grid.attach (save_button_label,  0, 1, 1, 1);
            editor_grid.attach (save_button, 1, 1, 1, 1);
            editor_grid.attach (save_revealer, 0, 2, 3, 1);
            editor_grid.attach (pos_button_label,  0, 3, 1, 1);
            editor_grid.attach (pos_switch_grid, 1, 3, 1, 1);

            editor_grid.attach (geo_header, 0, 5, 3, 1);
            editor_grid.attach (spacing_label, 0, 6, 1, 1);
            editor_grid.attach (spacing_size, 1, 6, 1, 1);
            editor_grid.attach (margins_label, 0, 7, 1, 1);
            editor_grid.attach (margins_size, 1, 7, 1, 1);

            editor_grid.attach (font_header, 0, 8, 3, 1);
            editor_grid.attach (font_type_label, 0, 9, 1, 1);
            editor_grid.attach (font_type, 1, 9, 1, 1);
            editor_grid.attach (font_label, 0, 10, 1, 1);
            editor_grid.attach (font_size, 1, 10, 1, 1);
        }

        private void get_interface_grid () {
            interface_grid = new Gtk.Grid ();
            interface_grid.row_spacing = 12;
            interface_grid.column_spacing = 6;

            var mode_header = new Granite.HeaderLabel (_("Modes"));
            var color_button_light = new Gtk.RadioButton (null);
            color_button_light.halign = Gtk.Align.CENTER;
            color_button_light.height_request = 32;
            color_button_light.width_request = 32;
            color_button_light.tooltip_text = _("Light Mode");

            var color_button_light_context = color_button_light.get_style_context ();
            color_button_light_context.add_class ("color-button");
            color_button_light_context.add_class ("color-light");

            var color_button_sepia = new Gtk.RadioButton.from_widget (color_button_light);
            color_button_sepia.halign = Gtk.Align.CENTER;
            color_button_sepia.height_request = 32;
            color_button_sepia.width_request = 32;
            color_button_sepia.tooltip_text = _("Sepia Mode");

            var color_button_sepia_context = color_button_sepia.get_style_context ();
            color_button_sepia_context.add_class ("color-button");
            color_button_sepia_context.add_class ("color-sepia");

            var color_button_dark = new Gtk.RadioButton.from_widget (color_button_light);
            color_button_dark.halign = Gtk.Align.CENTER;
            color_button_dark.height_request = 32;
            color_button_dark.width_request = 32;
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

            var color_button_light_text = new Gtk.Label (_("Light Mode"));

            var color_button_sepia_text = new Gtk.Label (_("Sepia Mode"));

            var color_button_dark_text = new Gtk.Label (_("Dark Mode"));

            var focus_mode_label = new SettingsLabel (_("Focus Mode:"));
            var focus_mode = new SettingsSwitch ("focus-mode");

            var focus_revealer = new Gtk.Revealer ();

            var focus_mode_type_label = new SettingsLabel (_("Focus Scope:"));

            var focus_mode_p_size = new Gtk.Image.from_icon_name ("paragraph-focus-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            focus_mode_p_size.tooltip_text = (_("Focus on Paragraph"));
            var focus_mode_s_size = new Gtk.Image.from_icon_name ("sentence-focus-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            focus_mode_s_size.tooltip_text = (_("Focus on Sentence"));
            var focus_mode_type_size = new SettingsSwitch ("focus-mode-type");
            focus_mode_type_size.halign = Gtk.Align.CENTER;

            var focus_mode_type_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            focus_mode_type_box.pack_start (focus_mode_p_size);
            focus_mode_type_box.pack_start (focus_mode_type_size);
            focus_mode_type_box.pack_start (focus_mode_s_size);

            Quilter.Application.gsettings.bind ("focus-mode-type", focus_mode_type_size, "active", SettingsBindFlags.DEFAULT);

            var typewriterscrolling_label = new SettingsLabel (_("Typewriter Scrolling:"));
            var typewriterscrolling = new SettingsSwitch ("typewriter-scrolling");

            var focus_grid = new Gtk.Grid ();
            focus_grid.row_homogeneous = false;
            focus_grid.column_spacing = 6;
            focus_grid.row_spacing = 6;
            focus_grid.margin_end = 32;
            focus_grid.halign = Gtk.Align.CENTER;
            focus_grid.attach (focus_mode_type_label, 0, 0);
            focus_grid.attach (focus_mode_type_box, 1, 0);
            focus_grid.attach (typewriterscrolling_label, 0, 1);
            focus_grid.attach (typewriterscrolling, 1, 1);

            focus_revealer.add (focus_grid);

            if (focus_mode.active) {
                focus_revealer.reveal_child = true;
            } else {
                focus_revealer.reveal_child = false;
            }

            focus_mode.bind_property (
                "active",
                focus_revealer,
                "reveal-child",
                GLib.BindingFlags.SYNC_CREATE
            );

            var tracking_label = new SettingsLabel (_("Type Counter:"));
            tracking_label.set_halign (Gtk.Align.END);
            var tracking = new SettingsSwitch ("statusbar");

            var sidebar_label = new SettingsLabel (_("Sidebar:"));
            sidebar_label.set_halign (Gtk.Align.END);
            var sidebar = new SettingsSwitch ("sidebar");

            var prefer_label_button_prefs = new Gtk.Button ();
            // Please take note of the \n, keep it where you'd want a line break because the space is small
            prefer_label_button_prefs.label = _("Changing modes is disabled due\nto the system dark style preference.");
            var prefer_label_button_prefs_context = prefer_label_button_prefs.get_style_context ();
            prefer_label_button_prefs_context.add_class ("flat");
            prefer_label_button_prefs.margin_start = prefer_label_button_prefs.margin_end = 3;

            prefer_label_button_prefs.clicked.connect (() => {
                try {
                    AppInfo.launch_default_for_uri ("settings://desktop/appearance", null);
                } catch (Error e) {
                    warning ("Failed to open system settings: %s", e.message);
                }
            });

            var ui_header = new Granite.HeaderLabel (_("User Interface"));
            var buttonbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            buttonbox.set_homogeneous (true);
            buttonbox.hexpand = true;
            buttonbox.add (color_button_light);
            buttonbox.add (color_button_sepia);
            buttonbox.add (color_button_dark);

            var textbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            textbox.set_homogeneous (true);
            textbox.add (color_button_light_text);
            textbox.add (color_button_sepia_text);
            textbox.add (color_button_dark_text);

            var modesbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            modesbox.set_homogeneous (true);
            modesbox.add (buttonbox);
            modesbox.add (textbox);

            interface_grid.attach (mode_header, 0, 0, 3, 1);
            interface_grid.attach (modesbox, 0, 1, 3, 1);
            interface_grid.attach (ui_header,  0, 2, 3, 1);
            interface_grid.attach (focus_mode_label, 0, 4, 1, 1);
            interface_grid.attach (focus_mode, 1, 4, 1, 1);
            interface_grid.attach (focus_revealer, 0, 5, 3, 1);
            interface_grid.attach (tracking_label, 0, 6, 1, 1);
            interface_grid.attach (tracking, 1, 6, 1, 1);
            interface_grid.attach (sidebar_label, 0, 7, 1, 1);
            interface_grid.attach (sidebar, 1, 7, 1, 1);
        
            if (Quilter.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK) {
                modesbox.sensitive = false;
                interface_grid.attach (prefer_label_button_prefs, 0, 3, 3, 1);
                prefer_label_button_prefs.visible = true;
                color_button_dark.set_active (true);
            } else if (Quilter.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.NO_PREFERENCE) {
                modesbox.sensitive = true;
                interface_grid.remove (prefer_label_button_prefs);
                prefer_label_button_prefs.visible = false;
            } else {
                modesbox.sensitive = true;
                interface_grid.remove (prefer_label_button_prefs);
                prefer_label_button_prefs.visible = false;
            }

            Quilter.Application.grsettings.notify["prefers-color-scheme"].connect (() => {
                if (Quilter.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK) {
                    modesbox.sensitive = false;
                    interface_grid.attach (prefer_label_button_prefs, 0, 3, 3, 1);
                    prefer_label_button_prefs.visible = true;
                    color_button_dark.set_active (true);
                } else if (Quilter.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.NO_PREFERENCE) {
                    modesbox.sensitive = true;
                    interface_grid.remove (prefer_label_button_prefs);
                    prefer_label_button_prefs.visible = false;
                } else {
                    modesbox.sensitive = true;
                    interface_grid.remove (prefer_label_button_prefs);
                    prefer_label_button_prefs.visible = false;
                }
            });
        }

        private void get_preview_grid () {
            preview_grid = new Gtk.Grid ();
            preview_grid.row_spacing = 12;
            preview_grid.column_spacing = 6;

            var preview_header = new Granite.HeaderLabel (_("Preview"));
            var preview_font_label = new SettingsLabel (_("Font Type:"));

            var preview_font_type = new Gtk.ComboBoxText();

            preview_font_type.append_text(_("Serif"));
            preview_font_type.append_text(_("Sans-serif"));
            preview_font_type.append_text(_("Monospace"));

            switch (Quilter.Application.gsettings.get_string("preview-font")) {
                case "serif":
                    preview_font_type.set_active(0);
                    break;
                case "sans":
                    preview_font_type.set_active(1);
                    break;
                case "mono":
                    preview_font_type.set_active(2);
                    break;
                default:
                    preview_font_type.set_active(0);
                    break;
            }

            preview_font_type.changed.connect (() => {
                switch (preview_font_type.get_active ()) {
                    case 0:
                        Quilter.Application.gsettings.set_string("preview-font", "serif");
                        break;
                    case 1:
                        Quilter.Application.gsettings.set_string("preview-font", "sans");
                        break;
                    case 2:
                        Quilter.Application.gsettings.set_string("preview-font", "mono");
                        break;
                    default:
                        Quilter.Application.gsettings.set_string("preview-font", "serif");
                        break;
                }
            });

            var centering_preview_headers_label = new SettingsLabel (_("Center Headers:"));
            var centering_preview_headers = new SettingsSwitch ("center-headers");
            centering_preview_headers.hexpand = true;

            var ext_header = new Granite.HeaderLabel (_("Extensions"));

            var highlight_label = new SettingsLabel (_("Code Highlighting:"));
            var highlight = new SettingsSwitch ("highlight");
            highlight.hexpand = true;

            var latex_label = new SettingsLabel (_("LaTeX Processing:"));
            var latex = new SettingsSwitch ("latex");
            latex.hexpand = true;

            var mermaid_label = new SettingsLabel (_("Mermaid.js Graphing:"));
            var mermaid = new SettingsSwitch ("mermaid");

            mermaid.bind_property (
                "active",
                highlight,
                "active",
                GLib.BindingFlags.INVERT_BOOLEAN
            );

            preview_grid.attach (preview_header,  0, 0, 3, 1);
            preview_grid.attach (preview_font_label, 0, 1, 1, 1);
            preview_grid.attach (preview_font_type, 1, 1, 1, 1);
            preview_grid.attach (centering_preview_headers_label, 0, 2, 1, 1);
            preview_grid.attach (centering_preview_headers, 1, 2, 1, 1);

            preview_grid.attach (ext_header,  0, 3, 3, 1);
            preview_grid.attach (highlight_label, 0, 4, 1, 1);
            preview_grid.attach (highlight, 1, 4, 1, 1);
            preview_grid.attach (latex_label, 0, 5, 1, 1);
            preview_grid.attach (latex, 1, 5, 1, 1);
            preview_grid.attach (mermaid_label, 0, 6, 1, 1);
            preview_grid.attach (mermaid, 1, 6, 1, 1);
        }

        private class SettingsLabel : Gtk.Label {
            public SettingsLabel (string text) {
                label = text;
                halign = Gtk.Align.END;
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
                Quilter.Application.gsettings.bind (setting, this, "active", GLib.SettingsBindFlags.DEFAULT);
            }
        }
    }
}
