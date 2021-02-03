/*
* Copyright (C) 2018-2021 Lains
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
    public class Preferences : Hdy.PreferencesWindow {
        public weak MainWindow win { get; construct; }

        public Preferences (MainWindow win) {
            Object (
                title: _("Preferences"),
                type_hint: Gdk.WindowTypeHint.DIALOG,
                transient_for: win,
                win: win,
                destroy_with_parent: true,
                modal: false,
                window_position: Gtk.WindowPosition.CENTER_ON_PARENT
            );
        }

        construct {
            this.title = title;
            weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
            default_theme.add_resource_path ("/com/github/lainsce/quilter");

            var editor_page = get_editor_grid ();
            var interface_page = get_interface_grid ();
            var preview_page = get_preview_grid ();

            this.add (interface_page);
            this.add (editor_page);
            this.add (preview_page);
        }

        private Hdy.PreferencesPage get_editor_grid () {
            var editor_grid = new Hdy.PreferencesPage ();
            editor_grid.set_icon_name ("folder-documents-symbolic");
            editor_grid.set_title (_("Editor"));

            var font_header = new Hdy.PreferencesGroup ();
            font_header.title = (_("Font"));

            var font_type_row = new Hdy.ActionRow ();
            font_type_row.set_title (_("Type"));

            var font_type = new Gtk.ComboBoxText();
            font_type.margin = 6;
            font_type.hexpand = true;
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

            font_type_row.add (font_type);

            font_header.add (font_type_row);
            font_header.show_all ();

            var edit_header = new Hdy.PreferencesGroup ();
            edit_header.title = (_("Editor"));

            var save_row = new Hdy.ExpanderRow ();
            save_row.set_title (_("Autosave Documents"));
            save_row.show_enable_switch = true;
            Quilter.Application.gsettings.bind ("autosave", save_row, "enable_expansion", GLib.SettingsBindFlags.DEFAULT);
            Quilter.Application.gsettings.bind ("autosave", save_row, "expanded", GLib.SettingsBindFlags.DEFAULT);

            var save_time_spinbutton = new Gtk.SpinButton.with_range (5, 60, 5);
            save_time_spinbutton.margin = 6;
            save_time_spinbutton.set_value (Quilter.Application.gsettings.get_int("autosave-delay"));
            Quilter.Application.gsettings.bind ("autosave-delay", save_time_spinbutton, "value", GLib.SettingsBindFlags.DEFAULT);

            var save_r_row = new Hdy.ActionRow ();
            save_r_row.set_title (_("Autosave Delay"));
            save_r_row.subtitle = _("Values below 15s affects the storage medium negatively.");
            save_r_row.add (save_time_spinbutton);

            save_row.add (save_r_row);

            var pos_row = new Hdy.ActionRow ();
            pos_row.set_title (_("Highlight Speech Parts (beta)"));
            pos_row.set_subtitle (_("Only available in English.\nColors words based on type:\n- Nouns are Black\n- Verbs are Blue\n- Adjectives are Yellow\n- Adverbs are Purple\n- Conjunctions are Green"));

            var pos_button = new SettingsSwitch ("pos");

            pos_row.add (pos_button);

            edit_header.add (save_row);
            edit_header.add (pos_row);
            edit_header.show_all ();

            editor_grid.add (edit_header);
            editor_grid.add (font_header);

            return editor_grid;
        }

        private Hdy.PreferencesPage get_interface_grid () {
            var interface_grid = new Hdy.PreferencesPage ();
            interface_grid.set_icon_name ("applications-system-symbolic");
            interface_grid.set_title (_("General"));

            var mode_header = new Hdy.PreferencesGroup ();
            mode_header.title = (_("Appearance"));

            var visual_row = new Hdy.ActionRow ();
            visual_row.set_title (_("Visual Mode"));

            var color_button_light = new Gtk.RadioButton (null);
            color_button_light.halign = Gtk.Align.CENTER;
            color_button_light.height_request = 32;
            color_button_light.width_request = 32;
            color_button_light.tooltip_text = _("Light Mode");

            var color_button_light_context = color_button_light.get_style_context ();
            color_button_light_context.add_class ("circular");
            color_button_light_context.add_class ("color-light");

            var color_button_sepia = new Gtk.RadioButton.from_widget (color_button_light);
            color_button_sepia.halign = Gtk.Align.CENTER;
            color_button_sepia.height_request = 32;
            color_button_sepia.width_request = 32;
            color_button_sepia.tooltip_text = _("Sepia Mode");

            var color_button_sepia_context = color_button_sepia.get_style_context ();
            color_button_sepia_context.add_class ("circular");
            color_button_sepia_context.add_class ("color-sepia");

            var color_button_dark = new Gtk.RadioButton.from_widget (color_button_light);
            color_button_dark.halign = Gtk.Align.CENTER;
            color_button_dark.height_request = 32;
            color_button_dark.width_request = 32;
            color_button_dark.tooltip_text = _("Dark Mode");

            var color_button_dark_context = color_button_dark.get_style_context ();
            color_button_dark_context.add_class ("circular");
            color_button_dark_context.add_class ("color-dark");

            var mode_type = Quilter.Application.gsettings.get_string("visual-mode");

            switch (mode_type) {
                case "sepia":
                    color_button_sepia.set_active (true);
                    break;
                case "dark":
                    color_button_dark.set_active (true);
                    break;
                case "":
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
                Quilter.Application.gsettings.set_string("visual-mode", "light");
            });

            var buttonbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 20);
            buttonbox.halign = Gtk.Align.CENTER;
            buttonbox.add (color_button_light);
            buttonbox.add (color_button_sepia);
            buttonbox.add (color_button_dark);

            visual_row.add (buttonbox);

            var ui_header = new Hdy.PreferencesGroup ();
            ui_header.title = (_("Interface"));

            var fmode_row = new Hdy.ExpanderRow ();
            fmode_row.set_title (_("Focus Mode"));
            fmode_row.show_enable_switch = true;
            Quilter.Application.gsettings.bind ("focus-mode", fmode_row, "enable_expansion", GLib.SettingsBindFlags.DEFAULT);
            Quilter.Application.gsettings.bind ("focus-mode", fmode_row, "expanded", GLib.SettingsBindFlags.DEFAULT);

            var focus_mode_p_size = new Gtk.Image.from_icon_name ("paragraph-focus-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            focus_mode_p_size.tooltip_text = (_("Focus on Paragraph"));
            var focus_mode_s_size = new Gtk.Image.from_icon_name ("sentence-focus-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            focus_mode_s_size.tooltip_text = (_("Focus on Sentence"));
            var focus_mode_type_size = new SettingsSwitch ("focus-mode-type");
            focus_mode_type_size.halign = Gtk.Align.CENTER;

            var focus_mode_type_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            focus_mode_type_box.valign = Gtk.Align.CENTER;
            focus_mode_type_box.pack_start (focus_mode_p_size);
            focus_mode_type_box.pack_start (focus_mode_type_size);
            focus_mode_type_box.pack_start (focus_mode_s_size);

            Quilter.Application.gsettings.bind ("focus-mode-type", focus_mode_type_size, "active", SettingsBindFlags.DEFAULT);

            var typewriterscrolling = new SettingsSwitch ("typewriter-scrolling");

            var fmode_r_row = new Hdy.ActionRow ();
            fmode_r_row.set_title (_("Focus Scope"));
            fmode_r_row.add (focus_mode_type_box);

            var fmode_r2_row = new Hdy.ActionRow ();
            fmode_r2_row.set_title (_("Typewriter Scrolling"));
            fmode_r2_row.add (typewriterscrolling);

            fmode_row.add (fmode_r_row);
            fmode_row.add (fmode_r2_row);

            var tracking_row = new Hdy.ActionRow ();
            tracking_row.set_title (_("Type Counter"));
            var tracking = new SettingsSwitch ("statusbar");

            tracking_row.add (tracking);

            var sidebar_row = new Hdy.ActionRow ();
            sidebar_row.set_title (_("Sidebar"));
            var sidebar = new SettingsSwitch ("sidebar");

            sidebar_row.add (sidebar);

            mode_header.add (visual_row);
            ui_header.add (fmode_row);
            ui_header.add (tracking_row);
            ui_header.add (sidebar_row);

            interface_grid.add (mode_header);
            interface_grid.add (ui_header);

            return interface_grid;
        }

        private Hdy.PreferencesPage get_preview_grid () {
            var preview_grid = new Hdy.PreferencesPage ();
            preview_grid.set_icon_name ("view-dual-symbolic");
            preview_grid.set_title (_("Preview"));

            var preview_header = new Hdy.PreferencesGroup ();
            preview_header.title = (_("Preview"));

            var font_row = new Hdy.ActionRow ();
            font_row.set_title (_("Font Type"));

            var preview_font_type = new Gtk.ComboBoxText();
            preview_font_type.hexpand = true;
            preview_font_type.margin = 6;

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

            font_row.add (preview_font_type);

            var headers_row = new Hdy.ActionRow ();
            headers_row.set_title (_("Header Centering"));
            headers_row.set_subtitle (_("This affects the H1, H2, and H3 type headers."));

            var centering_preview_headers = new SettingsSwitch ("center-headers");

            headers_row.add (centering_preview_headers);

            var ext_header = new Hdy.PreferencesGroup ();
            ext_header.title = (_("Extensions"));

            var highlight_row = new Hdy.ActionRow ();
            highlight_row.set_title (_("Code Highlight"));
            highlight_row.set_subtitle (_("Code blocks will have the contents receive color."));

            var highlight = new SettingsSwitch ("highlight");

            highlight_row.add (highlight);

            var latex_row = new Hdy.ActionRow ();
            latex_row.set_title (_("LaTeX Math"));
            latex_row.set_subtitle (_("LaTeX math blocks will be processed into LaTeX output."));

            var latex = new SettingsSwitch ("latex");

            latex_row.add (latex);

            var mermaid_row = new Hdy.ActionRow ();
            mermaid_row.set_title (_("Mermaid.js Graph"));
            mermaid_row.set_subtitle (_("Mermaid blocks will become graphs."));

            var mermaid = new SettingsSwitch ("mermaid");

            mermaid_row.add (mermaid);

            mermaid.bind_property (
                "active",
                highlight,
                "active",
                GLib.BindingFlags.INVERT_BOOLEAN
            );

            preview_header.add (font_row);
            preview_header.add (headers_row);

            ext_header.add (highlight_row);
            ext_header.add (latex_row);
            ext_header.add (mermaid_row);

            preview_grid.add (preview_header);
            preview_grid.add (ext_header);

            return preview_grid;
        }

        private class SettingsSwitch : Gtk.Switch {
            public SettingsSwitch (string setting) {
                halign = Gtk.Align.START;
                valign = Gtk.Align.START;
                margin = 6;
                Quilter.Application.gsettings.bind (setting, this, "active", GLib.SettingsBindFlags.DEFAULT);
            }
        }
    }
}
