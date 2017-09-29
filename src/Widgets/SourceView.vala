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
        public static new Gtk.SourceBuffer buffer;
        public static bool is_modified;
        public File file;
        public WebView webview;
        private string font;

        public signal void changed ();

        public SourceView () {
            update_settings ();
            var settings = AppSettings.get_default ();
            settings.changed.connect (update_settings);

            try {
                string text;
                var file = File.new_for_path (settings.last_file);
                string filename = file.get_path ();
                GLib.FileUtils.get_contents (filename, out text);
                set_text (text, true);
            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }
        }

        construct {
            var settings = AppSettings.get_default ();
            var context = this.get_style_context ();
            context.add_class ("quilter-note");
            var manager = Gtk.SourceLanguageManager.get_default ();
            var language = manager.guess_language (null, "text/x-markdown");
            buffer = new Gtk.SourceBuffer.with_language (language);
            buffer.highlight_syntax = true;
            buffer.set_max_undo_levels (20);
            buffer.changed.connect (on_text_modified);

            is_modified = false;
            Timeout.add_seconds (20, () => {
                on_text_modified ();
                return true;
            });

            this.set_buffer (buffer);
            this.set_wrap_mode (Gtk.WrapMode.WORD);
            this.left_margin = 80;
            this.top_margin = 40;
            this.right_margin = 80;
            this.bottom_margin = 40;
            this.expand = true;
            this.has_focus = true;
            this.set_tab_width (4);
            this.set_insert_spaces_instead_of_tabs (true);
        }

        public void on_text_modified () {
            if (!is_modified) {
                is_modified = true;
            } else {
                changed ();
                Services.FileManager.save_work_file ();
                is_modified = false;
            }
        }

        public void set_text (string text, bool opening = true) {
            if (opening) {
                buffer.begin_not_undoable_action ();
                buffer.changed.disconnect (on_text_modified);
            }

            buffer.text = text;

            if (opening) {
                buffer.end_not_undoable_action ();
                buffer.changed.connect (on_text_modified);
            }

            Gtk.TextIter? start = null;
            buffer.get_start_iter (out start);
            buffer.place_cursor (start);
        }

        public void use_default_font (bool value) {
            if (!value) {
                return;
            }

            var default_font = "PT Mono 11";

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
                this.font = "PT Mono 13";
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
                provider.load_from_resource ("/com/github/lainsce/quilter/app-stylesheet.css");
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                return "quilter";
            } else {
                var provider = new Gtk.CssProvider ();
                provider.load_from_resource ("/com/github/lainsce/quilter/app-stylesheet-dark.css");
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                return "quilter-dark";
            }
        }
    }
}
