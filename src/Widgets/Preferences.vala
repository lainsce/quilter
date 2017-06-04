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
        private Gtk.Stack main_stack;
        private Gtk.StackSwitcher main_stackswitcher;

        Gtk.Switch highlight_current_line;
        Gtk.Switch use_custom_font;
        Gtk.FontButton select_font;

        public Preferences () {
            create_layout ();
        }

        construct {
            title = _("Preferences");
            set_default_size (630, 430);
            resizable = false;
            deletable = false;

            main_stack = new Gtk.Stack ();
            main_stackswitcher = new Gtk.StackSwitcher ();
            main_stackswitcher.set_stack (main_stack);
            main_stackswitcher.halign = Gtk.Align.CENTER;
        }

        private void create_layout () {
            this.main_stack.add_titled (get_editor_box (), "interface", _("Interface"));

            // Close button
            var close_button = new Gtk.Button.with_label (_("Close"));
            close_button.clicked.connect (() => {this.destroy ();});

            var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
            button_box.set_layout (Gtk.ButtonBoxStyle.END);
            button_box.pack_end (close_button);
            button_box.margin = 12;
            button_box.margin_bottom = 0;

            // Pack everything into the dialog
            var main_grid = new Gtk.Grid ();
            main_grid.attach (this.main_stackswitcher, 0, 0, 1, 1);
            main_grid.attach (this.main_stack, 0, 1, 1, 1);
            main_grid.attach (button_box, 0, 2, 1, 1);

            ((Gtk.Container) get_content_area ()).add (main_grid);

        }

        private Gtk.Widget get_editor_box () {
            var main_settings = AppSettings.get_default ();
            var content = new Gtk.Grid ();
            content.row_spacing = 6;
            content.column_spacing = 12;
            content.margin = 12;

            var editor_header = new SettingsHeader (_("Editor"));

            var highlight_current_line_label = new SettingsLabel (_("Enable Focus Mode:"));
            highlight_current_line = new SettingsSwitch ("highlight-current-line");

            var font_header = new SettingsHeader (_("Font"));
            var use_custom_font_label = new SettingsLabel (_("Custom font:"));
            use_custom_font = new Gtk.Switch ();
            use_custom_font.halign = Gtk.Align.START;
            main_settings.schema.bind ("use-system-font", use_custom_font, "active", SettingsBindFlags.INVERT_BOOLEAN);

            select_font = new Gtk.FontButton ();
            select_font.hexpand = true;
            main_settings.schema.bind ("font", select_font, "font-name", SettingsBindFlags.DEFAULT);
            main_settings.schema.bind ("use-system-font", select_font, "sensitive", SettingsBindFlags.INVERT_BOOLEAN);

            content.attach (editor_header, 0, 0, 3, 1);
            content.attach (highlight_current_line_label, 0, 1, 1, 1);
            content.attach (highlight_current_line, 1, 1, 1, 1);
            content.attach (font_header, 0, 3, 3, 1);
            content.attach (use_custom_font_label , 0, 4, 1, 1);
            content.attach (use_custom_font, 1, 4, 1, 1);
            content.attach (select_font, 2, 4, 1, 1);

            return content;
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
