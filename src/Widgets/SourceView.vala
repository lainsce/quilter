/*
* Copyright (C) 2017-2020 Lains
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
    public class EditView : Gtk.SourceView {
        private Gtk.TextTag blackfont;
        private Gtk.TextTag darkgrayfont;
        private Gtk.TextTag lightgrayfont;
        private Gtk.TextTag lightsepiafont;
        private Gtk.TextTag sepiafont;
        private Gtk.TextTag whitefont;
        private int last_height = 0;
        private int last_width = 0;
        private static EditView? instance = null;
        private uint update_idle_source = 0;
        public File file;
        public Gtk.SourceSearchContext search_context = null;
        public Gtk.SourceStyle srcstyle = null;
        public Gtk.TextTag adjfont;
        public Gtk.TextTag adverbfont;
        public Gtk.TextTag conjfont;
        public Gtk.TextTag verbfont;
        public Gtk.TextTag error_tag;
        public MainWindow window;
        public Services.POSFiles pos;
        public bool should_scroll {get; set; default = false;}
        public bool should_update_preview { get; set; default = false; }
        public double cursor_position = 0;
        public new unowned Gtk.SourceBuffer buffer;
        public string scroll_text = "";

        public static EditView get_instance () {
            if (instance == null && Application.win != null) {
                instance = new Widgets.EditView (Application.win);
            }

            return instance;
        }

        public string text {
            owned get {
                return buffer.text;
            }

            set {
                buffer.text = value;
            }
        }

        public bool modified {
            set {
                buffer.set_modified (value);
                should_scroll = value;
            }

            get {
                return buffer.get_modified ();
            }
        }

        public signal void save ();

        public EditView (MainWindow window) {
            this.window = window;

            var manager = Gtk.SourceLanguageManager.get_default ();
            var language = manager.guess_language (null, "text/x-markdown");
            var buffer = new Gtk.SourceBuffer.with_language (language);
            this.buffer = buffer;
            buffer.highlight_syntax = true;
            buffer.set_max_undo_levels (50);
            set_buffer (buffer);

            darkgrayfont = new Gtk.TextTag();
            lightgrayfont = new Gtk.TextTag();
            blackfont = new Gtk.TextTag();
            whitefont = new Gtk.TextTag();
            lightsepiafont = new Gtk.TextTag();
            sepiafont = new Gtk.TextTag();

            darkgrayfont = buffer.create_tag(null, "foreground", "#888");
            lightgrayfont = buffer.create_tag(null, "foreground", "#888");
            blackfont = buffer.create_tag(null, "foreground", "#151515");
            whitefont = buffer.create_tag(null, "foreground", "#f7f7f7");
            lightsepiafont = buffer.create_tag(null, "foreground", "#aa8866");
            sepiafont = buffer.create_tag(null, "foreground", "#331100");

            adverbfont = buffer.create_tag(null, "foreground", "#a56de2");
            verbfont = buffer.create_tag(null, "foreground", "#3689e6");
            adjfont = buffer.create_tag(null, "foreground", "#d48e15");
            conjfont = buffer.create_tag(null, "foreground", "#3a9104");

            pos = new Services.POSFiles ();

            modified = false;
            buffer.changed.connect (() => {
                modified = true;
                if (Quilter.Application.gsettings.get_boolean("pos")) {
                    pos_syntax_start ();
                }
            });

            if (Quilter.Application.gsettings.get_string("current-file") == "") {
                buffer.text = "";
                modified = false;
            }

            search_context = new Gtk.SourceSearchContext (buffer as Gtk.SourceBuffer, null);
            search_context.set_match_style (srcstyle);

            try {
                string text = "";
                string file_path = Quilter.Application.gsettings.get_string("current-file");

                var file = File.new_for_path (file_path);
                if (!file.query_exists ()) {
                    Services.FileManager.save_file (file_path, "");
                }

                GLib.FileUtils.get_contents (file.get_path (), out text);
                buffer.text = text;
                modified = false;
            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }

            if (Quilter.Application.gsettings.get_boolean("autosave")) {
                Timeout.add_seconds (Quilter.Application.gsettings.get_int("autosave-delay"), () => {
                    save ();
                    modified = false;
                    return true;
                });

            }

            update_settings ();

            Quilter.Application.grsettings.notify["prefers-color-scheme"].connect (() => {
                update_settings ();
            });

            Quilter.Application.gsettings.changed.connect (() => {
                update_settings ();
            });

            var rect = Gtk.Allocation ();
            Quilter.Application.gsettings.get ("window-size", "(ii)", out rect.width, out rect.height);
            last_width = rect.width;
            last_height = rect.height;

            // Sane defaults
            this.set_wrap_mode (Gtk.WrapMode.WORD);
            this.right_margin = this.left_margin = this.bottom_margin = this.top_margin = 40;
            this.has_focus = true;
            this.set_tab_width (4);
            this.set_insert_spaces_instead_of_tabs (true);
            this.auto_indent = true;
        }

        private void update_settings () {
            var buffer_context = this.get_style_context ();
            this.set_pixels_inside_wrap((int)(1.5*Quilter.Application.gsettings.get_int("spacing")));
            this.set_pixels_above_lines(Quilter.Application.gsettings.get_int("spacing"));
            this.set_pixels_below_lines(Quilter.Application.gsettings.get_int("spacing"));
            dynamic_margins ();

            if (!Quilter.Application.gsettings.get_boolean("focus-mode")) {
                Gtk.TextIter start, end;
                buffer.get_bounds (out start, out end);
                buffer.remove_tag(lightgrayfont, start, end);
                buffer.remove_tag(darkgrayfont, start, end);
                buffer.remove_tag(lightsepiafont, start, end);
                buffer.remove_tag(sepiafont, start, end);
                buffer.remove_tag(blackfont, start, end);
                buffer.remove_tag(whitefont, start, end);
                buffer_context.add_class ("medium-text");
                buffer_context.remove_class ("big-text");
                buffer.notify["cursor-position"].disconnect (set_focused_text);
            } else {
                set_focused_text ();
                buffer_context.add_class ("big-text");
                buffer_context.remove_class ("medium-text");
                buffer.notify["cursor-position"].connect (set_focused_text);
                if (Quilter.Application.gsettings.get_boolean("typewriter-scrolling")) {
                    Timeout.add(500, move_typewriter_scrolling);
                }
            }

            if (Quilter.Application.gsettings.get_int("font-sizing") == 1) {
                buffer_context.add_class ("small-text");
                buffer_context.remove_class ("medium-text");
                buffer_context.remove_class ("big-text");
            } else if (Quilter.Application.gsettings.get_int("font-sizing") == 2) {
                buffer_context.remove_class ("small-text");
                buffer_context.add_class ("medium-text");
                buffer_context.remove_class ("big-text");
            } else if (Quilter.Application.gsettings.get_int("font-sizing") == 3) {
                buffer_context.remove_class ("small-text");
                buffer_context.remove_class ("medium-text");
                buffer_context.add_class ("big-text");
            }

            if (Quilter.Application.gsettings.get_string("edit-font-type") == "mono") {
                buffer_context.add_class ("mono-font");
                buffer_context.remove_class ("vier-font");
                buffer_context.remove_class ("zwei-font");
            } else if (Quilter.Application.gsettings.get_string("edit-font-type") == "vier") {
                buffer_context.add_class ("vier-font");
                buffer_context.remove_class ("zwei-font");
                buffer_context.remove_class ("mono-font");
            } else if (Quilter.Application.gsettings.get_string("edit-font-type") == "zwei") {
                buffer_context.add_class ("zwei-font");
                buffer_context.remove_class ("vier-font");
                buffer_context.remove_class ("mono-font");
            }

            var style_manager = Gtk.SourceStyleSchemeManager.get_default ();
            var style = style_manager.get_scheme (setup_ui_scheme ());
            buffer.set_style_scheme (style);

            if (!Quilter.Application.gsettings.get_boolean("pos")) {
                Gtk.TextIter start, end;
                buffer.get_bounds (out start, out end);
                buffer.remove_tag(verbfont, start, end);
                buffer.remove_tag(adjfont, start, end);
                buffer.remove_tag(adverbfont, start, end);
                buffer.remove_tag(conjfont, start, end);
            } else {
                pos_syntax_start ();
            }
        }

        public void dynamic_margins () {
            int p;
            double m;
            var rect = Gtk.Allocation ();
            Quilter.Application.gsettings.get ("window-size", "(ii)", out rect.width, out rect.height);

            if (window != null) {
                p = (window.is_fullscreen) ? 40 : 0;

                var margins = Quilter.Application.gsettings.get_int("margins");
                switch (margins) {
                    case Constants.NARROW_MARGIN:
                        m = (rect.width * ((Constants.NARROW_MARGIN + p) / 100.0));
                        break;
                    case Constants.WIDE_MARGIN:
                        m = (rect.width * ((Constants.WIDE_MARGIN + p) / 100.0));
                        break;
                    default:
                    case Constants.MEDIUM_MARGIN:
                        m = (rect.width * ((Constants.MEDIUM_MARGIN + p) / 100.0));
                        break;
                }

                this.left_margin = (int)m;
                this.right_margin = (int)m;
            }

            if (Quilter.Application.gsettings.get_boolean("typewriter-scrolling") && Quilter.Application.gsettings.get_boolean("focus-mode")) {
                int titlebar_h = window.get_titlebar().get_allocated_height();
                this.bottom_margin = (int)(rect.height * (1 - Constants.TYPEWRITER_POSITION)) - titlebar_h;
                this.top_margin = (int)(rect.height * Constants.TYPEWRITER_POSITION) - titlebar_h;
            } else {
                this.top_margin = 40;
                this.bottom_margin = 40;
            }
        }

        private string setup_ui_scheme () {
            var provider = new Gtk.CssProvider ();
            Gtk.TextIter start, end;
            buffer.get_bounds (out start, out end);

            if (Quilter.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK) {
                provider.load_from_resource ("/com/github/lainsce/quilter/app-stylesheet-dark.css");
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                buffer.remove_tag(lightsepiafont, start, end);
                buffer.remove_tag(sepiafont, start, end);
                buffer.remove_tag(blackfont, start, end);
                return "quilter-dark";
            } else if (Quilter.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.NO_PREFERENCE) {
                if (Quilter.Application.gsettings.get_string("visual-mode") == "dark") {
                    provider.load_from_resource ("/com/github/lainsce/quilter/app-stylesheet-dark.css");
                    Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                    buffer.remove_tag(lightsepiafont, start, end);
                    buffer.remove_tag(sepiafont, start, end);
                    buffer.remove_tag(blackfont, start, end);
                    return "quilter-dark";
                } else if (Quilter.Application.gsettings.get_string("visual-mode") == "sepia") {
                    provider.load_from_resource ("/com/github/lainsce/quilter/app-stylesheet-sepia.css");
                    Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    buffer.remove_tag(whitefont, start, end);
                    buffer.remove_tag(blackfont, start, end);
                    return "quilter-sepia";
                } else {
                    provider.load_from_resource ("/com/github/lainsce/quilter/app-stylesheet.css");
                    Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                    buffer.remove_tag(whitefont, start, end);
                    buffer.remove_tag(lightsepiafont, start, end);
                    buffer.remove_tag(sepiafont, start, end);
                    return "quilter";
                }
            } else {
                provider.load_from_resource ("/com/github/lainsce/quilter/app-stylesheet.css");
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                buffer.remove_tag(whitefont, start, end);
                buffer.remove_tag(lightsepiafont, start, end);
                buffer.remove_tag(sepiafont, start, end);
                return "quilter";
            }

        }

        public bool move_typewriter_scrolling () {
            if (should_scroll) {
                var cursor = buffer.get_insert ();
                this.scroll_to_mark(cursor, 0.0, true, 0.0, Constants.TYPEWRITER_POSITION);
                should_scroll = false;
            }
            return (Quilter.Application.gsettings.get_boolean("typewriter-scrolling") && Quilter.Application.gsettings.get_boolean("focus-mode"));
        }

        public void pos_syntax_start () {
            if (update_idle_source > 0) {
                GLib.Source.remove (update_idle_source);
            }

            update_idle_source = GLib.Idle.add (() => {
                pos_syntax ();
                return false;
            });
        }

        private bool pos_syntax () {
            Gtk.TextIter start, end, match_start, match_end;
            buffer.get_bounds (out start, out end);

            string no_punct_buffer = buffer.get_text (start, end, false).delimit (".,/!?<>;:\'\"{}[]()", ' ').down ();
            string[] words = no_punct_buffer.strip ().split (" ");
            string[] articles = {"the", "an", "a"};
            int p = 0;

            foreach (string word in words) {
                if (word.length == 0) {
                    p += word.length + 1;
                    continue;
                }
                if (word in pos.vbuf_list || word.has_suffix ("ing") && !word.has_prefix ("ing")) {
                    buffer.get_iter_at_offset (out match_start, p);
                    buffer.get_iter_at_offset (out match_end, p + word.length);
                    buffer.apply_tag(verbfont, match_start, match_end);

                    if (word in get_words(words, articles)) {
                        buffer.remove_tag(verbfont, match_start, match_end);
    
                        debug ("Nounified verbs found!");
                    }

                    debug ("Verbs found!");
                }
                if (word in pos.abuf_list) {
                    buffer.get_iter_at_offset (out match_start, p);
                    buffer.get_iter_at_offset (out match_end, p + word.length);
                    buffer.apply_tag(adjfont, match_start, match_end);
                    buffer.remove_tag(verbfont, match_start, match_end);
                    buffer.remove_tag(adverbfont, match_start, match_end);
                    buffer.remove_tag(conjfont, match_start, match_end);

                    debug ("Adjectives found!");
                }
                if (word in pos.adbuf_list || word.has_suffix ("ly") && !word.has_prefix ("ly")) {
                    buffer.get_iter_at_offset (out match_start, p);
                    buffer.get_iter_at_offset (out match_end, p + word.length);
                    buffer.apply_tag(adverbfont, match_start, match_end);
                    buffer.remove_tag(verbfont, match_start, match_end);
                    buffer.remove_tag(adjfont, match_start, match_end);
                    buffer.remove_tag(conjfont, match_start, match_end);

                    debug ("Adverbs found!");
                }
                if (word in pos.cnbuf_list) {
                    buffer.get_iter_at_offset (out match_start, p);
                    buffer.get_iter_at_offset (out match_end, p + word.length);
                    buffer.apply_tag(conjfont, match_start, match_end);
                    buffer.remove_tag(verbfont, match_start, match_end);
                    buffer.remove_tag(adjfont, match_start, match_end);
                    buffer.remove_tag(adverbfont, match_start, match_end);

                    debug ("Conjunctions found!");
                }

                p += word.length + 1;
            }

            update_idle_source = 0;
            return GLib.Source.REMOVE;
        }

        public static string[] get_words (string[] source, string[] tokens) {
            string[] words = {};
            for (int i = 0; i < source.length - 1; i++) {
                if (source[i] in tokens) {
                    words += source[i + 1];
                }
            }
            return words;
        }

        public void set_focused_text () {
            Gtk.TextIter cursor_iter;
            Gtk.TextIter start, end;
            buffer.get_bounds (out start, out end);

            var cursor = buffer.get_insert ();
            buffer.get_iter_at_mark (out cursor_iter, cursor);

            if (Quilter.Application.gsettings.get_string("visual-mode") == "dark") {
                buffer.apply_tag(darkgrayfont, start, end);
                buffer.remove_tag(lightsepiafont, start, end);
                buffer.remove_tag(lightgrayfont, start, end);
                buffer.remove_tag(whitefont, start, end);
            } else if (Quilter.Application.gsettings.get_string("visual-mode") == "sepia") {
                buffer.remove_tag(darkgrayfont, start, end);
                buffer.apply_tag(lightsepiafont, start, end);
                buffer.remove_tag(lightgrayfont, start, end);
                buffer.remove_tag(sepiafont, start, end);
            } else {
                buffer.remove_tag(darkgrayfont, start, end);
                buffer.remove_tag(lightsepiafont, start, end);
                buffer.apply_tag(lightgrayfont, start, end);
                buffer.remove_tag(blackfont, start, end);
            }

            should_scroll = true;

            if (cursor != null) {
                var start_sentence = cursor_iter;
                var end_sentence = cursor_iter;
                var focus_type = Quilter.Application.gsettings.get_boolean ("focus-mode-type");
                if (cursor_iter != start && cursor_iter != end) {
                    if (focus_type) {
                        start_sentence.backward_sentence_start ();
                        end_sentence.forward_sentence_end ();
                    } else {
                        start_sentence.backward_lines (1);
                        end_sentence.forward_to_line_end ();
                    }
                }

                if (Quilter.Application.gsettings.get_string("visual-mode") == "dark") {
                    buffer.remove_tag(sepiafont, start_sentence, end_sentence);
                    buffer.remove_tag(lightsepiafont, start_sentence, end_sentence);
                    buffer.remove_tag(blackfont, start_sentence, end_sentence);
                    buffer.remove_tag(lightgrayfont, start_sentence, end_sentence);
                    buffer.apply_tag(whitefont, start_sentence, end_sentence);
                    buffer.remove_tag(lightgrayfont, start_sentence, end_sentence);
                } else if (Quilter.Application.gsettings.get_string("visual-mode") == "sepia") {
                    buffer.apply_tag(sepiafont, start_sentence, end_sentence);
                    buffer.remove_tag(lightsepiafont, start_sentence, end_sentence);
                    buffer.remove_tag(blackfont, start_sentence, end_sentence);
                    buffer.remove_tag(lightgrayfont, start_sentence, end_sentence);
                    buffer.remove_tag(whitefont, start_sentence, end_sentence);
                    buffer.remove_tag(lightgrayfont, start_sentence, end_sentence);
                } else {
                    buffer.remove_tag(sepiafont, start_sentence, end_sentence);
                    buffer.remove_tag(lightsepiafont, start_sentence, end_sentence);
                    buffer.apply_tag(blackfont, start_sentence, end_sentence);
                    buffer.remove_tag(lightgrayfont, start_sentence, end_sentence);
                    buffer.remove_tag(whitefont, start_sentence, end_sentence);
                    buffer.remove_tag(lightgrayfont, start_sentence, end_sentence);
                }
            }
        }
    }
}

namespace Quilter.Services {
    public class POSFiles {
        public File file_verbs;
        public File file_conj;
        public File file_adverbs;
        public File file_adj;
        public File file_nouns;
        public string vbuf = "";
        public string abuf = "";
        public string adbuf = "";
        public string cnbuf = "";
        public string nbuf = "";
        public Gee.TreeSet<string> vbuf_list = new Gee.TreeSet<string> ();
        public Gee.TreeSet<string> abuf_list = new Gee.TreeSet<string> ();
        public Gee.TreeSet<string> adbuf_list = new Gee.TreeSet<string> ();
        public Gee.TreeSet<string> cnbuf_list = new Gee.TreeSet<string> ();
        public Gee.TreeSet<string> nbuf_list = new Gee.TreeSet<string> ();

        public POSFiles () {
            file_verbs = File.new_for_path("/usr/share/com.github.lainsce.quilter/wordlist/verb.txt");
            file_adj = File.new_for_path("/usr/share/com.github.lainsce.quilter/wordlist/adjective.txt");
            file_adverbs = File.new_for_path("/usr/share/com.github.lainsce.quilter/wordlist/adverb.txt");
            file_conj = File.new_for_path("/usr/share/com.github.lainsce.quilter/wordlist/conjunction.txt");
            file_nouns = File.new_for_path("/usr/share/com.github.lainsce.quilter/wordlist/nouns.txt");

            try {
                GLib.FileUtils.get_contents (file_verbs.get_path (), out vbuf, null);
                GLib.FileUtils.get_contents (file_adj.get_path (), out abuf, null);
                GLib.FileUtils.get_contents (file_adverbs.get_path (), out adbuf, null);
                GLib.FileUtils.get_contents (file_conj.get_path (), out cnbuf, null);
                GLib.FileUtils.get_contents (file_nouns.get_path (), out nbuf, null);

                vbuf_list.add_all_array (vbuf.strip ().split ("\n"));
                abuf_list.add_all_array (abuf.strip ().split ("\n"));
                adbuf_list.add_all_array (adbuf.strip ().split ("\n"));
                cnbuf_list.add_all_array (cnbuf.strip ().split ("\n"));
                nbuf_list.add_all_array (nbuf.strip ().split ("\n"));
            } catch (Error e) {
                var msg = e.message;
                warning (@"Error: $msg");
            }
        }
    }
}
