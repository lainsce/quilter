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
    public class SourceView : Gtk.SourceView {
        public Quilter.MainWindow window;

        public static Gtk.SourceBuffer buffer;
        public static bool is_modified;
        private string font;

        public File file;

        private const string COLOR_PRIMARY = """
            @define-color colorPrimary %s;
            @define-color textColorPrimary %s;
            .quilter-window {
                background-color: @colorPrimary;
            }
            .quilter-toolbar {
                background-color: @colorPrimary;
                background: @colorPrimary;
                border-bottom-color: transparent;
                color: @textColorPrimary;
                box-shadow: inset 0px 1px 2px -2px white;
                icon-shadow: 0 1px 0px shade (@colorPrimary, 0.52);
                text-shadow: 0 1px 0px shade (@colorPrimary, 0.52);
            }
        """;

        public SourceView () {
            update_settings ();
            var settings = AppSettings.get_default ();
            settings.changed.connect (update_settings);
        }

        construct {
            var settings = AppSettings.get_default ();
            var context = this.get_style_context ();
            context.add_class ("quilter-note");

            var manager = Gtk.SourceLanguageManager.get_default ();
            var language = manager.guess_language (null, "text/x-markdown");
            buffer = new Gtk.SourceBuffer.with_language (language);
            this.set_buffer (buffer);

            is_modified = false;
            buffer.changed.connect (on_text_modified);

            this.set_wrap_mode (Gtk.WrapMode.WORD);
            this.left_margin = 45;
            this.top_margin = 45;
            this.right_margin = 45;
            this.bottom_margin = 45;
            this.expand = true;
            this.has_focus = true;
            this.set_tab_width (4);
            this.set_insert_spaces_instead_of_tabs (true);
        }

        public void on_text_modified () {
            var settings = AppSettings.get_default ();
            Utils.FileUtils.save_tmp_file ();

            var file = File.new_for_path (settings.last_file);

            if (file.query_exists ())
                file.delete ();

            Gtk.TextIter start, end;
            buffer.get_bounds (out start, out end);
            string buffer = buffer.get_text (start, end, true);
            uint8[] binbuffer = buffer.data;
            Utils.FileUtils.save_file (file, binbuffer);
            if (!is_modified) {
                is_modified = true;
            }
        }

        public void use_default_font (bool value) {
            if (!value)
                return;

            var default_font = new GLib.Settings ("org.gnome.desktop.interface").get_string ("monospace-font-name");

            this.font = default_font;
        }

        private void update_settings () {
            var settings = AppSettings.get_default ();
            if (!settings.focus_mode) {
                this.highlight_current_line = false;
                this.font = settings.font;
                use_default_font (settings.use_system_font);
                this.override_font (Pango.FontDescription.from_string (this.font));
            } else {
                this.highlight_current_line = true;
                this.font = "Cousine 16";
                this.override_font (Pango.FontDescription.from_string (this.font));
            }

            set_scheme (get_default_scheme ());
        }

        public void set_scheme (string id) {
            var style_manager = Gtk.SourceStyleSchemeManager.get_default ();
            var style = style_manager.get_scheme (id);
            buffer.set_style_scheme (style);
        }

        private string get_default_scheme () {
            var settings = AppSettings.get_default ();
            if (!settings.dark_mode) {
                var provider = new Gtk.CssProvider ();
                var color_primary = "#F1F1F1";
                var text_primary = "#7A7A7A";
                try {
                    var colored_css = COLOR_PRIMARY.printf (color_primary, text_primary);
                    provider.load_from_data (colored_css, colored_css.length);

                    Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                } catch (GLib.Error e) {
                    critical (e.message);
                }
                return "quilter";
            } else {
                var provider = new Gtk.CssProvider ();
                var color_primary = "#1A1A1A";
                var text_primary = "#ABABAB";
                try {
                    var colored_css = COLOR_PRIMARY.printf (color_primary, text_primary);
                    provider.load_from_data (colored_css, colored_css.length);

                    Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                } catch (GLib.Error e) {
                    critical (e.message);
                }
                return "quilter-dark";
            }
        }
    }
}
