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
        private Gtk.TextTag moonfont;
        private Gtk.TextTag lightmoonfont;
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
            var language = manager.guess_language (null, "text/markdown");
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
            lightmoonfont = new Gtk.TextTag();
            moonfont = new Gtk.TextTag();

            darkgrayfont = buffer.create_tag(null, "foreground", "#888");
            lightgrayfont = buffer.create_tag(null, "foreground", "#777");
            blackfont = buffer.create_tag(null, "foreground", "#333");
            whitefont = buffer.create_tag(null, "foreground", "#CCC");
            lightsepiafont = buffer.create_tag(null, "foreground", "#aa8866");
            sepiafont = buffer.create_tag(null, "foreground", "#331100");
            lightmoonfont = buffer.create_tag(null, "foreground", "#939699");
            moonfont = buffer.create_tag(null, "foreground", "#C3C6C9");

            modified = false;

            buffer.changed.connect (() => {
                modified = true;
            });

            if (settings.current_file == "") {
                buffer.text = "";
                modified = false;
            }

            search_context = new Gtk.SourceSearchContext (buffer as Gtk.SourceBuffer, null);
            search_context.set_match_style (srcstyle);

            try {
                string text = "";
                string file_path = settings.current_file;

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

            this.populate_popup.connect ((menu) => {
                menu.selection_done.connect (() => {
                    var selected = get_selected (menu);

                    if (selected != null) {
                        try {
                            spell.set_language (selected.label);
                            settings.spellcheck_language = selected.label;
                        } catch (Error e) {}
                    }
                });
            });

            warning_tag = new Gtk.TextTag ("warning_bg");
            warning_tag.underline = Pango.Underline.ERROR;
            warning_tag.underline_rgba = Gdk.RGBA () { red = 0.13, green = 0.55, blue = 0.13, alpha = 1.0 };
            error_tag = new Gtk.TextTag ("error_bg");
            error_tag.underline = Pango.Underline.ERROR;
            buffer.tag_table.add (error_tag);
            buffer.tag_table.add (warning_tag);

            spell = new GtkSpell.Checker ();
            if (settings.spellcheck != false) {
                try {
                    var lang_dict = settings.spellcheck_language;
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

            if (settings.autosave == true) {
                Timeout.add_seconds (30, () => {
                    save ();
                    modified = false;
                    return true;
                });
            }

            update_settings ();
            settings.changed.connect (update_settings);

            this.set_wrap_mode (Gtk.WrapMode.WORD);
            this.top_margin = 40;
            this.bottom_margin = 40;
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
            this.set_pixels_inside_wrap(settings.spacing);
            this.set_pixels_above_lines(settings.spacing);
            dynamic_margins();

            if (!settings.focus_mode) {
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
                if (settings.typewriter_scrolling) {
                    Timeout.add(500, move_typewriter_scrolling);
                }
            }

            if (settings.font_sizing == 1) {
                buffer_context.add_class ("small-text");
                buffer_context.remove_class ("medium-text");
                buffer_context.remove_class ("big-text");
            } else if (settings.font_sizing == 2) {
                buffer_context.remove_class ("small-text");
                buffer_context.add_class ("medium-text");
                buffer_context.remove_class ("big-text");
            } else if (settings.font_sizing == 3) {
                buffer_context.remove_class ("small-text");
                buffer_context.remove_class ("medium-text");
                buffer_context.add_class ("big-text");
            }

            if (settings.edit_font_type == "mono") {
                buffer_context.add_class ("mono-font");
                buffer_context.remove_class ("vier-font");
            } else if (settings.edit_font_type == "vier") {
                buffer_context.add_class ("vier-font");
                buffer_context.remove_class ("mono-font");
            }

            var style_manager = Gtk.SourceStyleSchemeManager.get_default ();
            var style = style_manager.get_scheme (get_default_scheme ());
            buffer.set_style_scheme (style);
        }

        public void dynamic_margins () {
            
            int w, h, m, p;
            window.get_size (out w, out h);

            p = (window.is_fullscreen) ? 5 : 0;

            var margins = settings.margins;
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

            if (settings.typewriter_scrolling && settings.focus_mode) {
                int titlebar_h = window.get_titlebar().get_allocated_height();
                this.bottom_margin = (int)(h * (1 - Constants.TYPEWRITER_POSITION)) - titlebar_h;
                this.top_margin = (int)(h * Constants.TYPEWRITER_POSITION) - titlebar_h;
            } else {
                this.bottom_margin = 40;
                this.top_margin = 40;
            }
        }

        private string get_default_scheme () {
            
            if (settings.dark_mode) {
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
            } else if (settings.sepia_mode) {
                var provider = new Gtk.CssProvider ();
                provider.load_from_resource ("/com/github/lainsce/quilter/app-stylesheet-sepia.css");
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
                Gtk.TextIter start, end;
                buffer.get_bounds (out start, out end);
                buffer.remove_tag(whitefont, start, end);
                buffer.remove_tag(blackfont, start, end);
                return "quilter-sepia";
            } else if (settings.moon_mode) {
                var provider = new Gtk.CssProvider ();
                provider.load_from_resource ("/com/github/lainsce/quilter/app-stylesheet-moon.css");
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
                Gtk.TextIter start, end;
                buffer.get_bounds (out start, out end);
                buffer.remove_tag(lightsepiafont, start, end);
                buffer.remove_tag(sepiafont, start, end);
                buffer.remove_tag(blackfont, start, end);
                return "quilter-moon";
            }

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

        public bool move_typewriter_scrolling () {
            
            if (should_scroll) {
                var cursor = buffer.get_insert ();
                this.scroll_to_mark(cursor, 0.0, true, 0.0, Constants.TYPEWRITER_POSITION);
                should_scroll = false;
            }
            return (settings.focus_mode && settings.typewriter_scrolling);
        }

        public void set_focused_text () {
            Gtk.TextIter cursor_iter;
            Gtk.TextIter start, end;
            

            buffer.get_bounds (out start, out end);

            var cursor = buffer.get_insert ();
            buffer.get_iter_at_mark (out cursor_iter, cursor);

            if (settings.dark_mode) {
                buffer.apply_tag(darkgrayfont, start, end);
                buffer.remove_tag(lightsepiafont, start, end);
                buffer.remove_tag(lightgrayfont, start, end);
                buffer.remove_tag(lightmoonfont, start, end);
                buffer.remove_tag(whitefont, start, end);
            } else if (settings.sepia_mode) {
                buffer.remove_tag(darkgrayfont, start, end);
                buffer.apply_tag(lightsepiafont, start, end);
                buffer.remove_tag(lightgrayfont, start, end);
                buffer.remove_tag(lightmoonfont, start, end);
                buffer.remove_tag(sepiafont, start, end);
            } else if (settings.moon_mode) {
                buffer.remove_tag(darkgrayfont, start, end);
                buffer.remove_tag(lightsepiafont, start, end);
                buffer.remove_tag(lightgrayfont, start, end);
                buffer.apply_tag(lightmoonfont, start, end);
                buffer.remove_tag(moonfont, start, end);
            } else {
                buffer.remove_tag(darkgrayfont, start, end);
                buffer.remove_tag(lightsepiafont, start, end);
                buffer.apply_tag(lightgrayfont, start, end);
                buffer.remove_tag(lightmoonfont, start, end);
                buffer.remove_tag(blackfont, start, end);
            }

            should_scroll = true;

            if (cursor != null) {
                var start_sentence = cursor_iter;
                var focus_type = settings.focus_mode_type;
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
                if (settings.dark_mode) {
                    buffer.remove_tag(sepiafont, start_sentence, end_sentence);
                    buffer.remove_tag(lightsepiafont, start_sentence, end_sentence);
                    buffer.remove_tag(blackfont, start_sentence, end_sentence);
                    buffer.remove_tag(lightgrayfont, start_sentence, end_sentence);
                    buffer.apply_tag(whitefont, start_sentence, end_sentence);
                    buffer.remove_tag(lightgrayfont, start_sentence, end_sentence);
                    buffer.remove_tag(moonfont, start_sentence, end_sentence);
                    buffer.remove_tag(lightmoonfont, start_sentence, end_sentence);
                } else if (settings.sepia_mode) {
                    buffer.apply_tag(sepiafont, start_sentence, end_sentence);
                    buffer.remove_tag(lightsepiafont, start_sentence, end_sentence);
                    buffer.remove_tag(blackfont, start_sentence, end_sentence);
                    buffer.remove_tag(lightgrayfont, start_sentence, end_sentence);
                    buffer.remove_tag(whitefont, start_sentence, end_sentence);
                    buffer.remove_tag(lightgrayfont, start_sentence, end_sentence);
                    buffer.remove_tag(moonfont, start_sentence, end_sentence);
                    buffer.remove_tag(lightmoonfont, start_sentence, end_sentence);
                } else if (settings.moon_mode) {
                    buffer.remove_tag(sepiafont, start_sentence, end_sentence);
                    buffer.remove_tag(lightsepiafont, start_sentence, end_sentence);
                    buffer.remove_tag(blackfont, start_sentence, end_sentence);
                    buffer.remove_tag(lightgrayfont, start_sentence, end_sentence);
                    buffer.remove_tag(whitefont, start_sentence, end_sentence);
                    buffer.remove_tag(lightgrayfont, start_sentence, end_sentence);
                    buffer.apply_tag(moonfont, start_sentence, end_sentence);
                    buffer.remove_tag(lightmoonfont, start_sentence, end_sentence);
                } else {
                    buffer.remove_tag(sepiafont, start_sentence, end_sentence);
                    buffer.remove_tag(lightsepiafont, start_sentence, end_sentence);
                    buffer.apply_tag(blackfont, start_sentence, end_sentence);
                    buffer.remove_tag(lightgrayfont, start_sentence, end_sentence);
                    buffer.remove_tag(whitefont, start_sentence, end_sentence);
                    buffer.remove_tag(lightgrayfont, start_sentence, end_sentence);
                    buffer.remove_tag(moonfont, start_sentence, end_sentence);
                    buffer.remove_tag(lightmoonfont, start_sentence, end_sentence);
                }
            }
        }
    }
}
