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
namespace Quilter {
    [GtkTemplate (ui = "/io/github/lainsce/Quilter/prefs_window.ui")]
    public class Widgets.Preferences : Hdy.PreferencesWindow {

        [GtkChild]
        Gtk.ComboBoxText font_type;
        [GtkChild]
        Hdy.ExpanderRow autosave;
        [GtkChild]
        Gtk.SpinButton delay;
        [GtkChild]
        Gtk.Switch pos;

        [GtkChild]
        Gtk.RadioButton light;
        [GtkChild]
        Gtk.RadioButton sepia;
        [GtkChild]
        Gtk.RadioButton dark;
        [GtkChild]
        Hdy.ExpanderRow focus_mode;
        [GtkChild]
        Gtk.Switch scope;
        [GtkChild]
        Gtk.Switch typewriter;
        [GtkChild]
        Gtk.Switch sidebar;

        [GtkChild]
        Gtk.ComboBoxText preview_font_type;
        [GtkChild]
        Gtk.Switch center;
        [GtkChild]
        Gtk.Switch highlight;
        [GtkChild]
        Gtk.Switch latex;
        [GtkChild]
        Gtk.Switch mermaid;

        construct {
            weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
            default_theme.add_resource_path ("/com/github/lainsce/quilter");

            get_editor_grid ();
            get_interface_grid ();
            get_preview_grid ();
        }

        private void get_editor_grid () {
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

            Quilter.Application.gsettings.bind ("autosave", autosave, "enable_expansion", GLib.SettingsBindFlags.DEFAULT);
            Quilter.Application.gsettings.bind ("autosave", autosave, "expanded", GLib.SettingsBindFlags.DEFAULT);

            delay.set_value (Quilter.Application.gsettings.get_int("autosave-delay"));
            Quilter.Application.gsettings.bind ("autosave-delay", delay, "value", GLib.SettingsBindFlags.DEFAULT);

            Quilter.Application.gsettings.bind ("pos", pos, "active", GLib.SettingsBindFlags.DEFAULT);
        }

        private void get_interface_grid () {
            var mode_type = Quilter.Application.gsettings.get_string("visual-mode");
            switch (mode_type) {
                case "sepia":
                    sepia.set_active (true);
                    break;
                case "dark":
                    dark.set_active (true);
                    break;
                case "":
                default:
                    light.set_active (true);
                    break;
            }

            dark.clicked.connect (() => {
                Quilter.Application.gsettings.set_string("visual-mode", "dark");
            });

            sepia.clicked.connect (() => {
                Quilter.Application.gsettings.set_string("visual-mode", "sepia");
            });

            light.clicked.connect (() => {
                Quilter.Application.gsettings.set_string("visual-mode", "light");
            });

            Quilter.Application.gsettings.bind ("focus-mode", focus_mode, "enable_expansion", GLib.SettingsBindFlags.DEFAULT);
            Quilter.Application.gsettings.bind ("focus-mode", focus_mode, "expanded", GLib.SettingsBindFlags.DEFAULT);
            Quilter.Application.gsettings.bind ("focus-mode-type", scope, "active", SettingsBindFlags.DEFAULT);
            Quilter.Application.gsettings.bind ("typewriter-scrolling", typewriter, "active", SettingsBindFlags.DEFAULT);
            Quilter.Application.gsettings.bind ("sidebar", sidebar, "active", SettingsBindFlags.DEFAULT);
        }

        private void get_preview_grid () {
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

            Quilter.Application.gsettings.bind ("center-headers", center, "active", SettingsBindFlags.DEFAULT);
            Quilter.Application.gsettings.bind ("highlight", highlight, "active", SettingsBindFlags.DEFAULT);
            Quilter.Application.gsettings.bind ("latex", latex, "active", SettingsBindFlags.DEFAULT);
            Quilter.Application.gsettings.bind ("mermaid", mermaid, "active", SettingsBindFlags.DEFAULT);
        }
    }
}
