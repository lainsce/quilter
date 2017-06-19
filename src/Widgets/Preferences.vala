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

        public Preferences () {
            create_layout ();
        }

        construct {
            title = _("Preferences");
            set_default_size (600, 400);
            resizable = false;
            deletable = false;
        }

        private void create_layout () {
            var main_grid = new Gtk.Grid ();
            main_grid.row_spacing = 6;
            main_grid.column_spacing = 12;
            main_grid.margin = 12;

            var header = new TitleHeader (_("Preferences"));

            var editor_header = new SettingsHeader (_("Editor"));
            var focus_mode_label = new SettingsLabel (_("Enable Focus Mode:"));
            focus_mode = new SettingsSwitch ("focus-mode");
            var dark_mode_label = new SettingsLabel (_("Enable Dark Mode:"));
            dark_mode = new SettingsSwitch ("dark-mode");

            var close_button = new Gtk.Button.with_label (_("Close"));
            close_button.clicked.connect (() => {this.destroy ();});

            var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
            button_box.set_layout (Gtk.ButtonBoxStyle.END);
            button_box.pack_end (close_button);
            button_box.margin = 12;
            button_box.margin_bottom = 0;

            main_grid.attach (header, 0, 0, 1, 1);
            main_grid.attach (editor_header, 0, 1, 3, 1);
            main_grid.attach (focus_mode_label, 0, 2, 1, 1);
            main_grid.attach (focus_mode, 1, 2, 1, 1);
            main_grid.attach (dark_mode_label, 0, 3, 1, 1);
            main_grid.attach (dark_mode, 1, 3, 1, 1);
            main_grid.attach (button_box, 0, 6, 4, 1);

            ((Gtk.Container) get_content_area ()).add (main_grid);
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
