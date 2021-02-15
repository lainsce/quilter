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
    enum Font {
        QMONO,
        QZWEI,
        QVIER;

        public string to_string () {
            switch (this) {
                case QMONO:
                    return "Quilt Mono";

                case QZWEI:
                    return "Quilt Zwei";

                case QVIER:
                    return "Quilt Vier";

                default:
                    assert_not_reached();
            }
        }

        public static Font[] all () {
        	return {Font.QMONO, Font.QZWEI, Font.QVIER};
        }
    }

    enum PFont {
        SERIF,
        SANS,
        MONO;

        public string to_string () {
            switch (this) {
                case SERIF:
                    return "Serif";

                case SANS:
                    return "Sans-serif";

                case MONO:
                    return "Monospace";

                default:
                    assert_not_reached();
            }
        }

        public static PFont[] all () {
        	return {PFont.SERIF, PFont.SANS, PFont.MONO};
        }
    }

    [GtkTemplate (ui = "/io/github/lainsce/Quilter/prefs_window.ui")]
    public class Widgets.Preferences : Hdy.PreferencesWindow {

        [GtkChild]
        Hdy.ComboRow font_type;
        [GtkChild]
        Gtk.Switch autosave;
        [GtkChild]
        Gtk.Switch statusbar;
        [GtkChild]
        Gtk.Switch pos;
        [GtkChild]
        Gtk.Switch typewriter;
        [GtkChild]
        public Gtk.RadioButton scope_paragraph;
        [GtkChild]
        public Gtk.RadioButton scope_sentence;
        [GtkChild]
        Hdy.ComboRow preview_font_type;
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

            preferences_connect ();
        }

        private void preferences_connect () {
            font_type.set_for_enum (typeof (Font), e => {
                var i = e.get_value ();
                var f = Font.all ()[i];

                return f.to_string ();
            });

            font_type.selected_index = (int) Quilter.Application.gsettings.get_enum("edit-font");
            font_type.notify["selected-index"].connect (p => {
                var i = font_type.selected_index;
                Quilter.Application.gsettings.set_enum("edit-font", i);
            });

            preview_font_type.set_for_enum (typeof (PFont), e => {
                var i = e.get_value ();
                var f = PFont.all ()[i];

                return f.to_string ();
            });

            preview_font_type.selected_index = (int) Quilter.Application.gsettings.get_enum("preview-font");
            preview_font_type.notify["selected-index"].connect (p => {
                var i = preview_font_type.selected_index;
                Quilter.Application.gsettings.set_enum("preview-font", i);
            });

            scope_paragraph.toggled.connect (() => {
	            Quilter.Application.gsettings.set_boolean("focus-mode-type", false);
	        });

	        scope_sentence.toggled.connect (() => {
	            Quilter.Application.gsettings.set_boolean("focus-mode-type", true);
            });

            Quilter.Application.gsettings.bind ("autosave", autosave, "active", GLib.SettingsBindFlags.DEFAULT);
            Quilter.Application.gsettings.bind ("pos", pos, "active", GLib.SettingsBindFlags.DEFAULT);
            Quilter.Application.gsettings.bind ("statusbar", statusbar, "active", GLib.SettingsBindFlags.DEFAULT);
            Quilter.Application.gsettings.bind ("typewriter-scrolling", typewriter, "active", SettingsBindFlags.DEFAULT);
            Quilter.Application.gsettings.bind ("center-headers", center, "active", SettingsBindFlags.DEFAULT);
            Quilter.Application.gsettings.bind ("highlight", highlight, "active", SettingsBindFlags.DEFAULT);
            Quilter.Application.gsettings.bind ("latex", latex, "active", SettingsBindFlags.DEFAULT);
            Quilter.Application.gsettings.bind ("mermaid", mermaid, "active", SettingsBindFlags.DEFAULT);
        }
    }
}
