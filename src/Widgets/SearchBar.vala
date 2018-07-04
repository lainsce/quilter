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
    public class SearchBar : Gtk.Revealer {
        public Gtk.Grid grid;
        public Gtk.SearchEntry search_entry;
        private EditView? text_view = null;
        private Gtk.TextBuffer? text_buffer = null;
        private Gtk.SourceSearchContext search_context = null;
        private Gtk.SourceStyle srcstyle;
        private Gtk.TextTag found_tag;

        public weak MainWindow window { get; construct; }

        public SearchBar (MainWindow window) {
            Object (window: window);
        }

        construct {
            grid = new Gtk.Grid ();
            grid.row_spacing = 6;
            grid.column_spacing = 12;
            grid.orientation = Gtk.Orientation.VERTICAL;

            search_entry_item ();

            var context = grid.get_style_context ();
            context.add_class ("quilter-searchbar");

            this.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            this.add (grid);

            this.text_view = window.edit_view_content;
            this.text_buffer = text_view.get_buffer ();
            found_tag = EditView.buffer.create_tag(null, "background", "#787839");
            srcstyle.apply (found_tag);
            search_context = new Gtk.SourceSearchContext (text_buffer as Gtk.SourceBuffer, null);
            search_context.match_style = srcstyle;
        }

        public void search_entry_item () {
            search_entry = new Gtk.SearchEntry ();
            search_entry.hexpand = true;
            search_entry.placeholder_text = _("Find text…");
            grid.add (search_entry);

            var entry_path = new Gtk.WidgetPath ();
            entry_path.append_type (typeof (Gtk.Widget));

            var entry_context = new Gtk.StyleContext ();
            entry_context.set_path (entry_path);
            entry_context.add_class ("entry");

            search_entry.search_changed.connect (() => {
                search ();
            });
        }

        public bool search () {
            this.text_view = window.edit_view_content;
            this.text_buffer = text_view.get_buffer ();
            search_context.settings.regex_enabled = false;
            var search_string = search_entry.text;
            search_context.settings.search_text = search_string;
            bool case_sensitive = !((search_string.up () == search_string) || (search_string.down () == search_string));
            search_context.settings.case_sensitive = case_sensitive;

            search_context.highlight = false;

            if (text_buffer == null || text_buffer.text == "") {
                debug ("Can't search anything in an inexistant buffer and/or without anything to search.");
                return false;
            }

            if (text_view == null) {
                warning ("No SourceView is associated with SearchManager!");
                return false;
            }

            search_context.highlight = true;

            // Determine the search entry color
            Gtk.TextIter? start_iter;
            text_buffer.get_iter_at_offset (out start_iter, text_buffer.cursor_position);
            bool found = (search_entry.text != "" && search_entry.text in this.text_buffer.text);
            if (found) {
                search_entry.get_style_context ().remove_class (Gtk.STYLE_CLASS_ERROR);
                text_buffer.select_range (start_iter, start_iter);
                text_view.scroll_to_iter (start_iter, 0, false, 0, 0);
            } else {
                if (search_entry.text != "") {
                    search_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);
                }
            }

            return true;
        }
    }
}
