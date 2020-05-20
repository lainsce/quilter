/*
* Copyright (c) 2018 Lains
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
        public Gtk.Grid prev_next_grid;
        public Gtk.Grid replace_grid;
        public Gtk.SearchEntry search_entry;
        public Gtk.SearchEntry replace_entry;
        private Gtk.Button replace_tool_button;
        private Gtk.Button replace_all_tool_button;
        private EditView? text_view = null;
        private Gtk.TextBuffer? text_buffer = null;
        public Gtk.SourceSearchContext search_context = null;

        public weak MainWindow window { get; construct; }

        public SearchBar (MainWindow window) {
            Object (window: window);
        }

        construct {
            replace_entry = new Gtk.SearchEntry ();
            replace_entry.hexpand = true;
            replace_entry.placeholder_text = _("Replace with…");
            replace_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.PRIMARY, "edit-find-replace-symbolic");
            replace_entry.activate.connect (on_replace_entry_activate);

            replace_tool_button = new Gtk.Button ();
            replace_tool_button.label = _("Replace");
            replace_tool_button.clicked.connect (on_replace_entry_activate);
            replace_tool_button.tooltip_text = (_("Use the arrows to target the text\nto replace before pressing this."));

            replace_all_tool_button = new Gtk.Button ();
            replace_all_tool_button.label = _("Replace all");
            replace_all_tool_button.always_show_image = true;
            replace_all_tool_button.clicked.connect (on_replace_all_entry_activate);

            grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.row_spacing = 6;
            grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);

            prev_next_grid = new Gtk.Grid ();
            prev_next_grid.row_spacing = 6;
            var pvcontext = prev_next_grid.get_style_context ();
            pvcontext.add_class (Gtk.STYLE_CLASS_LINKED);
            search_entry_item ();
            search_previous_item ();
            search_next_item ();

            grid.attach (prev_next_grid, 0, 0);

            replace_grid = new Gtk.Grid ();
            replace_grid.row_spacing = 6;
            var rcontext = replace_grid.get_style_context ();
            rcontext.add_class (Gtk.STYLE_CLASS_LINKED);
            replace_grid.add (replace_entry);
            replace_grid.add (replace_tool_button);
            replace_grid.add (replace_all_tool_button);

            grid.attach (replace_grid, 0, 1);

            var context = grid.get_style_context ();
            context.add_class ("quilter-searchbar");

            this.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            this.add (grid);
            this.margin_top = 6;
            this.text_view = window.edit_view_content;
            this.text_buffer = text_view.get_buffer ();
            this.reveal_child = Quilter.Application.gsettings.get_boolean("searchbar");
        }

        public void search_entry_item () {
            search_entry = new Gtk.SearchEntry ();
            search_entry.hexpand = true;
            search_entry.placeholder_text = _("Find text…");
            search_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.PRIMARY, "edit-find-symbolic");
            prev_next_grid.add (search_entry);

            var entry_path = new Gtk.WidgetPath ();
            entry_path.append_type (typeof (Gtk.Widget));

            var entry_context = new Gtk.StyleContext ();
            entry_context.set_path (entry_path);
            entry_context.add_class ("entry");

            search_entry.search_changed.connect (() => {
                search ();
            });
        }

        public void search_previous_item () {
            var tool_arrow_up = new Gtk.Button.from_icon_name ("go-up-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            tool_arrow_up.always_show_image = true;
            tool_arrow_up.clicked.connect (search_previous);
            tool_arrow_up.tooltip_text = _("Search previous");
            prev_next_grid.add (tool_arrow_up);
        }

        public void search_previous () {
            this.text_view = window.edit_view_content;
            Gtk.TextIter? start_iter, end_iter;
            if (text_buffer != null) {
                text_buffer.get_selection_bounds (out start_iter, out end_iter);
                if(!search_for_iter_backward (start_iter, out end_iter)) {
                    text_buffer.get_end_iter (out start_iter);
                    search_for_iter_backward (start_iter, out end_iter);
                }
            }
        }

        public void search_next_item () {
            var tool_arrow_down = new Gtk.Button.from_icon_name ("go-down-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            tool_arrow_down.always_show_image = true;
            tool_arrow_down.clicked.connect (search_next);
            tool_arrow_down.tooltip_text = _("Search next");
            prev_next_grid.add (tool_arrow_down);
        }

        public void search_next () {
            this.text_view = window.edit_view_content;
            Gtk.TextIter? start_iter, end_iter, end_iter_tmp;
            if (text_buffer != null) {
                text_buffer.get_selection_bounds (out start_iter, out end_iter);
                if(!search_for_iter (end_iter, out end_iter_tmp)) {
                    text_buffer.get_start_iter (out start_iter);
                    search_for_iter (start_iter, out end_iter);
                }
            }
        }

        private void update_replace_tool_sensitivities (string search_text) {
            replace_tool_button.sensitive = search_text != "";
            replace_all_tool_button.sensitive = search_text != "";
        }

        private void on_replace_entry_activate () {
            this.text_view = window.edit_view_content;
            this.text_buffer = text_view.get_buffer ();
            if (text_buffer == null) {
                warning ("No valid buffer to replace");
                return;
            }

            Gtk.TextIter? start_iter, end_iter;
            text_buffer.get_iter_at_offset (out start_iter, text_buffer.cursor_position);

            if (search_for_iter (start_iter, out end_iter)) {
                string replace_string = replace_entry.text;
                try {
                    search_context.replace2 (start_iter, end_iter, replace_string, replace_string.length);
                    update_replace_tool_sensitivities (search_entry.text);
                    debug ("Replace \"%s\" with \"%s\"", search_entry.text, replace_entry.text);
                } catch (Error e) {
                    critical (e.message);
                }
            }
        }

        private void on_replace_all_entry_activate () {
            this.text_view = window.edit_view_content;
            this.text_buffer = text_view.get_buffer ();
            if (text_buffer == null) {
                debug ("No valid buffer to replace");
                return;
            }

            string replace_string = replace_entry.text;
            try {
                search_context.replace_all (replace_string, replace_string.length);
                update_replace_tool_sensitivities (search_entry.text);
            } catch (Error e) {
                critical (e.message);
            }

        }

        private bool search_for_iter (Gtk.TextIter? start_iter, out Gtk.TextIter? end_iter) {
            end_iter = start_iter;
            bool found = search_context.forward2 (start_iter, out start_iter, out end_iter, null);
            if (found) {
                text_buffer.select_range (start_iter, end_iter);
                text_view.scroll_to_iter (start_iter, 0, false, 0, 0);
            }

            return found;
        }

        public bool search_for_iter_backward (Gtk.TextIter? start_iter, out Gtk.TextIter? end_iter) {
            end_iter = start_iter;
            bool found = search_context.backward2 (start_iter, out start_iter, out end_iter, null);
            if (found) {
                text_buffer.select_range (start_iter, end_iter);
                text_view.scroll_to_iter (start_iter, 0, false, 0, 0);
            }

            return found;
        }

        public bool search () {
            this.text_view = window.edit_view_content;
            this.text_buffer = text_view.get_buffer ();
            var search_string = search_entry.text;

            this.search_context = new Gtk.SourceSearchContext (text_buffer as Gtk.SourceBuffer, null);
            search_context.settings.regex_enabled = false;
            search_context.settings.search_text = search_string;
            bool case_sensitive = !((search_string.up () == search_string) || (search_string.down () == search_string));
            text_view.search_context.settings.case_sensitive = case_sensitive;

            if (text_buffer == null || text_buffer.text == "") {
                debug ("Can't search anything in an inexistant buffer and/or without anything to search.");
                return false;
            }

            if (text_view == null) {
                warning ("No SourceView is associated with SearchManager!");
                return false;
            }

            Gtk.TextIter? start_iter;
            text_buffer.get_iter_at_offset (out start_iter, text_buffer.cursor_position);
            bool found = (search_entry.text != "" && search_entry.text in this.text_buffer.text);
            if (found) {
                search_entry.get_style_context ().remove_class (Gtk.STYLE_CLASS_ERROR);
                text_buffer.select_range (start_iter, start_iter);
            } else if (search_entry.text != "") {
                search_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);
            }

            return true;
        }
    }
}
