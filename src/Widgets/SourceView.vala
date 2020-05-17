/*
* Copyright (C) 2017 Lains
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
        public MainWindow window;
        private static EditView? instance = null;
        public bool should_scroll {get; set; default = false;}
        public File file;
        public GtkSpell.Checker spell;
        private Gtk.TextTag blackfont;
        private Gtk.TextTag lightgrayfont;
        private Gtk.TextTag darkgrayfont;
        private Gtk.TextTag whitefont;
        private Gtk.TextTag sepiafont;
        private Gtk.TextTag lightsepiafont;
        private Gtk.TextTag adverbfont;
        private Gtk.TextTag verbfont;
        private Gtk.TextTag adjfont;
        private Gtk.TextTag conjfont;
        public Gtk.TextTag warning_tag;
        public Gtk.TextTag error_tag;
        public Gtk.SourceSearchContext search_context = null;
        public Gtk.SourceStyle srcstyle = null;
        public new unowned Gtk.SourceBuffer buffer;

        public static EditView get_instance () {
            if (instance == null) {
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
            buffer.set_max_undo_levels (20);
            set_buffer (buffer);

            darkgrayfont = new Gtk.TextTag();
            lightgrayfont = new Gtk.TextTag();
            blackfont = new Gtk.TextTag();
            whitefont = new Gtk.TextTag();
            lightsepiafont = new Gtk.TextTag();
            sepiafont = new Gtk.TextTag();

            darkgrayfont = buffer.create_tag(null, "foreground", "#888");
            lightgrayfont = buffer.create_tag(null, "foreground", "#999");
            blackfont = buffer.create_tag(null, "foreground", "#000");
            whitefont = buffer.create_tag(null, "foreground", "#CCC");
            lightsepiafont = buffer.create_tag(null, "foreground", "#aa8866");
            sepiafont = buffer.create_tag(null, "foreground", "#331100");

            adverbfont = buffer.create_tag(null, "foreground", "#a56de2");
            verbfont = buffer.create_tag(null, "foreground", "#3689e6");
            adjfont = buffer.create_tag(null, "foreground", "#d48e15");
            conjfont = buffer.create_tag(null, "foreground", "#3a9104");

            modified = false;

            buffer.changed.connect (() => {
                modified = true;
                if (Quilter.Application.gsettings.get_boolean("pos")) {
                    pos_syntax ();
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

            warning_tag = new Gtk.TextTag ("warning_bg");
            warning_tag.underline = Pango.Underline.ERROR;
            warning_tag.underline_rgba = Gdk.RGBA () { red = 0.13, green = 0.55, blue = 0.13, alpha = 1.0 };
            error_tag = new Gtk.TextTag ("error_bg");
            error_tag.underline = Pango.Underline.ERROR;
            buffer.tag_table.add (error_tag);
            buffer.tag_table.add (warning_tag);

            spell = new GtkSpell.Checker ();
            if (Quilter.Application.gsettings.get_boolean("spellcheck") != false) {
                try {
                    var lang_dict = Quilter.Application.gsettings.get_string("spellcheck-language");
                    var language_list = GtkSpell.Checker.get_language_list ();
                    foreach (var element in language_list) {
                        if (lang_dict == element) {
                            spell.set_language (lang_dict);
                            break;
                        }
                    }
                    if (language_list.length () == 0) {
                        spell.set_language ("en");
                    } else {
                        spell.set_language (lang_dict);
                    }
                    spell.attach (this);
                } catch (Error e) {
                    warning (e.message);
                }
            } else {
                spell.detach ();
            }

            this.populate_popup.connect ((menu) => {
                menu.selection_done.connect (() => {
                    var selected = get_selected (menu);

                    if (selected != null) {
                        try {
                            spell.set_language (selected.label);
                            Quilter.Application.gsettings.set_string("spellcheck-language", selected.label);
                        } catch (Error e) {}
                    }
                });
            });

            if (Quilter.Application.gsettings.get_boolean("autosave")) {
                Timeout.add_seconds (30, () => {
                    save ();
                    modified = false;
                    return true;
                });
            }

            update_settings ();

            Quilter.Application.gsettings.changed.connect (() => {
                update_settings ();
            });

            this.set_wrap_mode (Gtk.WrapMode.WORD);
            this.top_margin = 40;
            this.bottom_margin = 40;
            this.margin = 2;
            this.margin_end = 0;
            this.expand = true;
            this.has_focus = true;
            this.set_tab_width (4);
            this.set_insert_spaces_instead_of_tabs (true);
            this.auto_indent = true;
            this.monospace = true;
        }

        private Gtk.MenuItem? get_selected (Gtk.Menu? menu) {
            if (menu == null) return null;
            var active = menu.get_active () as Gtk.MenuItem;

            if (active == null) return null;
            var sub_menu = active.get_submenu () as Gtk.Menu;
            if (sub_menu != null) {
                return sub_menu.get_active () as Gtk.MenuItem;
            }

            return null;
        }

        private void update_settings () {

            var buffer_context = this.get_style_context ();
            this.set_pixels_inside_wrap(Quilter.Application.gsettings.get_int("spacing"));
            this.set_pixels_above_lines(Quilter.Application.gsettings.get_int("spacing"));
            dynamic_margins();

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
            } else if (Quilter.Application.gsettings.get_string("edit-font-type") == "vier") {
                buffer_context.add_class ("vier-font");
                buffer_context.remove_class ("mono-font");
            }

            if (Quilter.Application.gsettings.get_boolean("pos")) {
                pos_syntax ();
            } else {
                 Gtk.TextIter start, end;
                 buffer.get_bounds (out start, out end);
                 buffer.remove_tag(verbfont, start, end);
                 buffer.remove_tag(adjfont, start, end);
                 buffer.remove_tag(adverbfont, start, end);
                 buffer.remove_tag(conjfont, start, end);
             }

            var style_manager = Gtk.SourceStyleSchemeManager.get_default ();
            var style = style_manager.get_scheme (get_default_scheme ());
            buffer.set_style_scheme (style);
        }

        public void dynamic_margins () {

            int w, h, m, p;
            window.get_size (out w, out h);

            p = (window.is_fullscreen) ? 5 : 0;

            var margins = Quilter.Application.gsettings.get_int("margins");
            switch (margins) {
                case Constants.NARROW_MARGIN:
                    m = (int)(w * ((Constants.NARROW_MARGIN + p) / 100.0));
                    break;
                case Constants.WIDE_MARGIN:
                    m = (int)(w * ((Constants.WIDE_MARGIN + p) / 100.0));
                    break;
                default:
                case Constants.MEDIUM_MARGIN:
                    m = (int)(w * ((Constants.MEDIUM_MARGIN + p) / 100.0));
                    break;
            }

            this.left_margin = m;
            this.right_margin = m;

            if (Quilter.Application.gsettings.get_boolean("typewriter-scrolling") && Quilter.Application.gsettings.get_boolean("focus-mode")) {
                int titlebar_h = window.get_titlebar().get_allocated_height();
                this.bottom_margin = (int)(h * (1 - Constants.TYPEWRITER_POSITION)) - titlebar_h;
                this.top_margin = (int)(h * Constants.TYPEWRITER_POSITION) - titlebar_h;
            } else {
                this.bottom_margin = 40;
                this.top_margin = 40;
            }
        }

        private string get_default_scheme () {
            if (Quilter.Application.gsettings.get_string("visual-mode") == "dark") {
                var provider = new Gtk.CssProvider ();
                provider.load_from_resource ("/com/github/lainsce/quilter/app-stylesheet-dark.css");
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                Gtk.TextIter start, end;
                buffer.get_bounds (out start, out end);
                buffer.remove_tag(lightsepiafont, start, end);
                buffer.remove_tag(sepiafont, start, end);
                buffer.remove_tag(blackfont, start, end);
                return "quilter-dark";
            } else if (Quilter.Application.gsettings.get_string("visual-mode") == "sepia") {
                var provider = new Gtk.CssProvider ();
                provider.load_from_resource ("/com/github/lainsce/quilter/app-stylesheet-sepia.css");
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                Gtk.TextIter start, end;
                buffer.get_bounds (out start, out end);
                buffer.remove_tag(whitefont, start, end);
                buffer.remove_tag(blackfont, start, end);
                return "quilter-sepia";
            } else {
                var provider = new Gtk.CssProvider ();
                provider.load_from_resource ("/com/github/lainsce/quilter/app-stylesheet.css");
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                Gtk.TextIter start, end;
                buffer.get_bounds (out start, out end);
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

        public void pos_syntax () {
            var file_verbs = File.new_for_path("/usr/share/com.github.lainsce.quilter/wordlist/verb.txt");
            var file_adj = File.new_for_path("/usr/share/com.github.lainsce.quilter/wordlist/adjective.txt");
            var file_adverbs = File.new_for_path("/usr/share/com.github.lainsce.quilter/wordlist/adverb.txt");
            var file_conj = File.new_for_path("/usr/share/com.github.lainsce.quilter/wordlist/conjunction.txt");

            var flags = Gtk.TextSearchFlags.TEXT_ONLY;
            flags += Gtk.TextSearchFlags.CASE_INSENSITIVE;

            Gtk.TextIter start, end, match_start, match_end;
            buffer.get_bounds (out start, out end);

            if (file_verbs != null && file_verbs.query_exists () &&
                file_adj != null && file_adj.query_exists () &&
                file_adverbs != null && file_adverbs.query_exists () &&
                file_conj != null && file_adverbs.query_exists ()) {
                try {

                    var vreg = new Regex("(?m)(?<verb>^\\w*$)");
                    string vbuf = "";
                    GLib.FileUtils.get_contents (file_verbs.get_path (), out vbuf, null);
                    GLib.MatchInfo vmatch;

                    if (vreg.match (vbuf, GLib.RegexMatchFlags.PARTIAL_SOFT, out vmatch)) {
                        do {
                          bool found = start.forward_search (vmatch.fetch_named ("verb"), flags, out match_start, out match_end, null);
                          if (found) {
                            if (match_start.starts_word ()) {
                                buffer.apply_tag(verbfont, match_start, match_end);
                            }
                          }
                        } while (vmatch.next ());
                        debug ("Verbs found!");
                    }


                    var areg = new Regex("(?m)(?<adj>^\\w*$)");
                    string abuf = "";
                    GLib.FileUtils.get_contents (file_adj.get_path (), out abuf, null);
                    GLib.MatchInfo amatch;

                    if (areg.match (abuf, GLib.RegexMatchFlags.PARTIAL_SOFT, out amatch)) {
                        do {
                            bool found = start.forward_search (amatch.fetch_named ("adj"), flags, out match_start, out match_end, null);
                            if (found) {
                                if (match_start.starts_word ()) {
                                    buffer.apply_tag(adjfont, match_start, match_end);
                                }
                            }
                        } while (amatch.next ());
                        debug ("Adjectives found!");
                    }


                    var adreg = new Regex("(?m)(?<adverb>^\\w*$)");
                    string adbuf = "";
                    GLib.FileUtils.get_contents (file_adverbs.get_path (), out adbuf, null);
                    GLib.MatchInfo admatch;

                    if (adreg.match (adbuf, GLib.RegexMatchFlags.PARTIAL_SOFT, out admatch)) {
                        do {
                            bool found = start.forward_search (admatch.fetch_named ("adverb"), flags, out match_start, out match_end, null);
                            if (found) {
                                if (match_start.starts_word ()) {
                                    buffer.apply_tag(adverbfont, match_start, match_end);
                                }
                            }
                        } while (admatch.next ());
                        debug ("Adverbs found!");
                    }

                    var cnreg = new Regex("(?m)(?<conj>^\\w*$)");
                    string cnbuf = "";
                    GLib.FileUtils.get_contents (file_conj.get_path (), out cnbuf, null);
                    GLib.MatchInfo cnmatch;

                    if (cnreg.match (cnbuf, GLib.RegexMatchFlags.PARTIAL_SOFT, out cnmatch)) {
                        do {
                            bool found = start.forward_search (cnmatch.fetch_named ("conj"), flags, out match_start, out match_end, null);
                            if (found) {
                                if (match_start.starts_word ()) {
                                    buffer.apply_tag(conjfont, match_start, match_end);
                                }
                            }
                        } while (cnmatch.next ());
                        debug ("Conjuctions found!");
                    }
                } catch (Error e) {
                    var msg = e.message;
                    warning (@"Error: $msg");
                }
            }
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
                var focus_type = Quilter.Application.gsettings.get_int("focus-mode-type");
                if (cursor_iter != start) {
                    switch (focus_type) {
                        case 0:
                            start_sentence.backward_lines (1);
                            break;
                        case 1:
                            start_sentence.backward_sentence_start ();
                            break;
                        default:
                            start_sentence.backward_lines (1);
                            break;
                    }
                }

                var end_sentence = cursor_iter;
                if (cursor_iter != end) {
                    switch (focus_type) {
                        case 0:
                            end_sentence.forward_lines (2);
                            break;
                        case 1:
                            end_sentence.forward_sentence_end ();
                            break;
                        default:
                            end_sentence.forward_lines (2);
                            break;
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
