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
        Gtk.Switch focus_mode;
        Gtk.Switch dark_mode;
        Gtk.Switch use_custom_font;
        Gtk.Switch spellcheck;
        Gtk.Switch statusbar;
        Gtk.Switch save_button;
        Gtk.FontButton select_font;

        public Preferences (Gtk.Window? parent) {
            Object (
                border_width: 0,
                deletable: false,
                resizable: false,
                title: _("Preferences"),
                transient_for: parent,
                destroy_with_parent: true,
                window_position: Gtk.WindowPosition.CENTER_ON_PARENT
            );
        }

        construct {
            var main_settings = AppSettings.get_default ();
            var main_grid = new Gtk.Grid ();
            main_grid.row_spacing = 6;
            main_grid.column_spacing = 12;
            main_grid.margin = 12;
            main_grid.margin_top = 0;

            var editor_header = new SettingsHeader (_("Editor"));
            var focus_mode_label = new SettingsLabel (_("Enable Focus Mode:"));
            focus_mode = new SettingsSwitch ("focus-mode");
            var dark_mode_label = new SettingsLabel (_("Enable Dark Mode:"));
            dark_mode = new SettingsSwitch ("dark-mode");

            var save_button_label = new SettingsLabel (_("Show the Save Button:"));
            save_button = new SettingsSwitch ("show-save-button");

            var font_header = new SettingsHeader (_("Font"));
            var use_custom_font_label = new SettingsLabel (_("Custom font:"));
            use_custom_font = new Gtk.Switch ();
            use_custom_font.halign = Gtk.Align.START;
            main_settings.schema.bind ("use-system-font", use_custom_font, "active", SettingsBindFlags.INVERT_BOOLEAN);
            select_font = new Gtk.FontButton ();
            select_font.use_font = true;
            select_font.hexpand = true;
            main_settings.schema.bind ("font", select_font, "font-name", SettingsBindFlags.DEFAULT);
            main_settings.schema.bind ("use-system-font", select_font, "sensitive", SettingsBindFlags.INVERT_BOOLEAN);

            var spellcheck_header = new SettingsHeader (_("Spellcheck"));
            var spellcheck_label = new Gtk.Label (_("Enable Spellchecking:"));
            spellcheck_label.set_halign (Gtk.Align.END);
            spellcheck = new SettingsSwitch ("spellcheck");

            var statusbar_header = new SettingsHeader (_("Statusbar"));
            var statusbar_label = new Gtk.Label (_("Show Statusbar:"));
            statusbar_label.set_halign (Gtk.Align.END);
            statusbar = new SettingsSwitch ("statusbar");

            var close_button = add_button (_("Close"), Gtk.ResponseType.CLOSE);
            ((Gtk.Button) close_button).clicked.connect (() => destroy ());

            main_grid.attach (editor_header, 0, 1, 3, 1);
            main_grid.attach (save_button_label, 0, 2, 1, 1);
            main_grid.attach (save_button, 1, 2, 1, 1);
            main_grid.attach (focus_mode_label, 0, 3, 1, 1);
            main_grid.attach (focus_mode, 1, 3, 1, 1);
            main_grid.attach (dark_mode_label, 0, 4, 1, 1);
            main_grid.attach (dark_mode, 1, 4, 1, 1);

            main_grid.attach (font_header, 0, 5, 3, 1);
            main_grid.attach (use_custom_font_label , 0, 6, 1, 1);
            main_grid.attach (use_custom_font, 1, 6, 1, 1);
            main_grid.attach (select_font, 2, 6, 1, 1);

            main_grid.attach (spellcheck_header,  0, 7, 1, 1);
            main_grid.attach (spellcheck_label,  0, 8, 1, 1);
            main_grid.attach (spellcheck, 1, 8, 1, 1);

            main_grid.attach (statusbar_header,  0, 9, 1, 1);
            main_grid.attach (statusbar_label,  0, 10, 1, 1);
            main_grid.attach (statusbar, 1, 10, 1, 1);

            ((Gtk.Container) get_content_area ()).add (main_grid);
            get_action_area ().margin = 6;
        }

        private class TitleHeader : Gtk.Label {
            public TitleHeader (string text) {
                label = text;
                this.margin_bottom = 6;
                get_style_context ().add_class ("h2");
                halign = Gtk.Align.START;
            }
        }

        private class SettingsHeader : Gtk.Label {
            public SettingsHeader (string text) {
                label = text;
                get_style_context ().add_class ("h4");
                halign = Gtk.Align.START;
            }
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
