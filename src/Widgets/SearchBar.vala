/*
 * Copyright (c) 2018-2021 Lains
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
    [GtkTemplate (ui = "/io/github/lainsce/Quilter/searchbar.ui")]
    public class Widgets.SearchBar : He.Bin {
        private EditView? text_view = null;
        private Gtk.TextBuffer? text_buffer = null;

        [GtkChild]
        private unowned Gtk.Button replace_all_button;
        [GtkChild]
        private unowned Gtk.Button replace_button;
        [GtkChild]
        private unowned Gtk.Button close_button;
        [GtkChild]
        private unowned Gtk.Button search_button_prev;
        [GtkChild]
        private unowned Gtk.Button search_button_next;
        [GtkChild]
        private unowned Gtk.Entry replace_entry;
        [GtkChild]
        private unowned Gtk.SearchEntry search_entry;

        [GtkChild]
        public unowned Gtk.Revealer searchbar;
        [GtkChild]
        private unowned Gtk.Box box1;
        [GtkChild]
        private unowned Gtk.Box box2;

        public GtkSource.SearchContext search_context = null;
        public weak MainWindow window { get; construct; }

        public SearchBar (MainWindow window) {
            Object (window : window);
        }

        construct {
            replace_entry.activate.connect (on_replace_entry_activate);

            replace_button.clicked.connect (on_replace_entry_activate);

            replace_all_button.clicked.connect (on_replace_all_entry_activate);

            close_button.clicked.connect (() => {
                Quilter.Application.gsettings.set_boolean ("searchbar", false);
            });

            search_entry_item ();
            search_previous_item ();
            search_next_item ();

            this.text_view = window.edit_view_content;
            this.text_buffer = text_view.get_buffer ();
        }

        public void search_entry_item () {
            search_entry.search_changed.connect (() => {
                search ();
            });
        }

        public void search_previous_item () {
            search_button_prev.clicked.connect (search_previous);
        }

        public void search_previous () {
            this.text_view = window.edit_view_content;
            Gtk.TextIter? start_iter, end_iter;
            if (text_buffer != null) {
                text_buffer.get_selection_bounds (out start_iter, out end_iter);
                if (!search_for_iter_backward (start_iter, out end_iter)) {
                    text_buffer.get_end_iter (out start_iter);
                    search_for_iter_backward (start_iter, out end_iter);
                }
            }
        }

        public void search_next_item () {
            search_button_next.clicked.connect (search_next);
        }

        public void search_next () {
            this.text_view = window.edit_view_content;
            Gtk.TextIter? start_iter, end_iter, end_iter_tmp;
            if (text_buffer != null) {
                text_buffer.get_selection_bounds (out start_iter, out end_iter);
                if (!search_for_iter (end_iter, out end_iter_tmp)) {
                    text_buffer.get_start_iter (out start_iter);
                    search_for_iter (start_iter, out end_iter);
                }
            }
        }

        private void update_replace_tool_sensitivities (string search_text) {
            replace_button.sensitive = search_text != "";
            replace_all_button.sensitive = search_text != "";
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
                    search_context.replace (start_iter, end_iter, replace_string, replace_string.length);
                    update_replace_tool_sensitivities (search_entry.text);
                } catch (Error e) {
                    critical (e.message);
                }
            }
        }

        private void on_replace_all_entry_activate () {
            this.text_view = window.edit_view_content;
            this.text_buffer = text_view.get_buffer ();
            if (text_buffer == null) {
                warning ("No valid buffer to replace");
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
            bool found = search_context.forward (start_iter, out start_iter, out end_iter, null);
            if (found) {
                text_buffer.select_range (start_iter, end_iter);
                text_view.scroll_to_iter (start_iter, 0, false, 0, 0);
            }

            return found;
        }

        public bool search_for_iter_backward (Gtk.TextIter? start_iter, out Gtk.TextIter? end_iter) {
            end_iter = start_iter;
            bool found = search_context.backward (start_iter, out start_iter, out end_iter, null);
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

            this.search_context = new GtkSource.SearchContext (text_buffer as GtkSource.Buffer, null);
            search_context.settings.regex_enabled = false;
            search_context.settings.search_text = search_string;
            bool case_sensitive = !((search_string.up () == search_string) || (search_string.down () == search_string));
            text_view.search_context.settings.case_sensitive = case_sensitive;

            if (text_buffer == null || text_buffer.text == "") {
                warning ("Can't search anything in an inexistant buffer and/or without anything to search.");
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
                search_entry.remove_css_class ("error");
                text_buffer.select_range (start_iter, start_iter);
            } else if (search_entry.text != "") {
                search_entry.add_css_class ("error");
            }

            return true;
        }
    }
}
