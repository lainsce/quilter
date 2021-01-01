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
namespace Quilter.Widgets {
    public class SideBar : Gtk.Revealer {
        public Gtk.ListBox column;
        private Widgets.SideBarBox[] rows;
        public Widgets.SideBarBox row;
        public Widgets.SideBarBox filebox;
        public Widgets.EditView ev;
        public Widgets.SearchBar seb;
        public MainWindow win;
        public Gtk.Grid files_grid;
        public Gtk.Grid outline_grid;
        public Gtk.Stack stack;
        public Gtk.TreeStore store;
        public Gtk.TreeView view;
        public Gtk.TreeSelection selection;
        public Gtk.CellRendererText crt;
        private Gtk.TreeIter root;
        private Gtk.TreeIter subheader;
        private Gtk.TreeIter section;
        private Gtk.Label no_files;
        public Hdy.ViewSwitcher stackswitcher;
        public Gtk.ScrolledWindow scrolled_box;
        public Hdy.HeaderBar header;
        private string[] files;
        public Gee.LinkedList<SideBarBox> s_files = null;
        public bool is_modified {get; set; default = false;}

        public signal void save_as ();

        private static SideBar? instance = null;
        public static SideBar get_instance () {
            if (instance == null) {
                instance = new Widgets.SideBar (Quilter.Application.win, Quilter.Application.win.edit_view_content);
            }

            return instance;
        }

        public SideBar (MainWindow win, Widgets.EditView ev) {
            this.win = win;
            this.ev = ev;
            this.is_modified = false;

            scrolled_box = new Gtk.ScrolledWindow (null, null);
            scrolled_box.hscrollbar_policy = Gtk.PolicyType.NEVER;
            scrolled_box.max_content_height = 500;
            scrolled_box.propagate_natural_height = true;

            no_files = new Gtk.Label (_("No files…"));
            no_files.halign = Gtk.Align.CENTER;
            var no_files_style_context = no_files.get_style_context ();
            no_files_style_context.add_class (Granite.STYLE_CLASS_H2_LABEL);
            no_files_style_context.add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            no_files.sensitive = false;
            no_files.margin = 12;
            no_files.show_all ();

            stack = new Gtk.Stack ();
            stack.add_titled (sidebar_files_list (), "files", _("Files").up ());
            stack.add_titled (sidebar_outline (), "outline", _("Outline").up ());
            stack.child_set_property (files_grid, "icon-name", "text-x-generic-symbolic");
            stack.child_set_property (outline_grid, "icon-name", "outline-symbolic");

            scrolled_box.add (stack);

            header = new Hdy.HeaderBar ();
            header.show_close_button = true;

            stackswitcher = new Hdy.ViewSwitcher ();
            var sw_context = stackswitcher.get_style_context ();
            sw_context.add_class ("quilter-sidebar-switcher");
            stackswitcher.stack = stack;

            header.has_subtitle = false;
            header.set_title (null);
            header.set_custom_title (stackswitcher);
            header.set_size_request (200,38);

            var this_context = header.get_style_context ();
            this_context.add_class (Gtk.STYLE_CLASS_FLAT);
            this_context.add_class ("quilter-toolbar-side");

            var main_grid = new Gtk.Grid ();
            main_grid.orientation = Gtk.Orientation.VERTICAL;
            main_grid.add (header);
            main_grid.add (scrolled_box);
            main_grid.get_style_context ().add_class ("quilter-sidebar");

            add (main_grid);

            var sb_context = this.get_style_context ();
            sb_context.add_class ("quilter-sidebar");
            this.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
            this.reveal_child = Quilter.Application.gsettings.get_boolean ("sidebar");
        }

        public Gtk.Widget sidebar_files_list () {
            column = new Gtk.ListBox ();
            column.expand = true;
            column.activate_on_single_click = true;
            column.selection_mode = Gtk.SelectionMode.SINGLE;
            column.set_sort_func (list_sort);
            column.set_placeholder (no_files);
            column.margin_top = 6;
            column.margin_start = column.margin_end = 12;

            for (int i = 0; i < Quilter.Application.gsettings.get_strv("last-files").length; i++) {
                rows += add_file (Quilter.Application.gsettings.get_strv("last-files")[i]);
            }

            column.row_selected.connect ((selected_row) => {
                foreach (var row in rows) {
                    row.file_remove_button.visible = (row == get_selected_row ());
                }

                try {
                    row = get_selected_row ();
                    string text = "";
                    GLib.FileUtils.get_contents (row.path, out text);
                    Quilter.Application.gsettings.set_string("current-file", row.path);

                    if (win.edit_view_content.modified) {
                        Services.FileManager.save_file (row.path, text);
                        win.edit_view_content.modified = false;
                    }

                    win.edit_view_content.text = text;

                    win.grid.set_visible_child (win.main_leaf);
                    win.header.set_visible_child (win.titlebar);
                } catch (Error e) {
                    warning ("Unexpected error during selection: " + e.message);
                }
            });

            files_grid = new Gtk.Grid ();
            files_grid.hexpand = false;
            files_grid.attach (column, 0, 0, 1, 1);
            files_grid.show_all ();
            return files_grid;
        }

        public Gtk.Widget sidebar_outline () {
            view = new Gtk.TreeView ();
            view.expand = true;
            view.headers_visible = false;
            view.show_expanders = false;
            view.margin_top = 12;
            view.margin_start = view.margin_end = 12;
            view.activate_on_single_click = true;

            crt = new Gtk.CellRendererText ();
            crt.ellipsize = Pango.EllipsizeMode.END;

            view.insert_column_with_attributes (-1, "Outline", crt, "text", 0);

            store = new Gtk.TreeStore (1, typeof (string));
            view.set_model (store);

            store.clear ();
            outline_populate ();
            view.expand_all ();

            selection = view.get_selection ();
            selection.set_mode (Gtk.SelectionMode.SINGLE);

            view.button_press_event.connect ((widget, event) => {
                //capture which mouse button
                uint clicked_button;
                event.get_button(out clicked_button);
				//handle right button click for context menu
                if (event.get_event_type ()  == Gdk.EventType.BUTTON_PRESS  &&  clicked_button == 1){
                    Gtk.TreePath path; Gtk.TreeViewColumn column; int cell_x; int cell_y;
			        view.get_path_at_pos ((int)event.x, (int)event.y, out path, out column, out cell_x, out cell_y);
			        view.grab_focus ();
                    view.set_cursor (path, column, false);

					selchanged (selection);
				}
				return false;
            });

            outline_grid = new Gtk.Grid ();
            outline_grid.hexpand = false;
            outline_grid.vexpand = false;
            outline_grid.attach (view, 0, 0, 1, 1);
            outline_grid.show_all ();

            return outline_grid;
        }

        public void selchanged (Gtk.TreeSelection row) {
            // Get string value from row clicked from TreeView and scroll to it in Editor
            Gtk.TreeModel pathmodel;
            Gtk.TreeIter pathiter;
            if (row.count_selected_rows () == 1){
                row.get_selected (out pathmodel, out pathiter);
                Value val;
                pathmodel.get_value (pathiter, 0, out val);

                Gtk.TextIter start, end, match_start, match_end;
                ev.buffer.get_bounds (out start, out end);

                bool found = start.forward_search (val.get_string (), 0, out match_start, out match_end, null);
                if (found) {
                    ev.scroll_to_iter (match_start, 0.0, true, 0.5, 0.1);
                }
            }
        }

        public void outline_populate () {
            if (Quilter.Application.gsettings.get_string("current-file") != "" || Quilter.Application.gsettings.get_string("current-file") != _("No Documents Open")) {
               var file = GLib.File.new_for_path (Quilter.Application.gsettings.get_string("current-file"));
               if (file != null && file.query_exists ()) {
                    try {
                        string buffer = "";
                        GLib.FileUtils.get_contents (file.get_path (), out buffer, null);
                        GLib.MatchInfo match;
                        var reg = new Regex("(?m)^(?<header>\\#{1,3})\\s(?<text>.*\\$?)");
                        if (reg.match (buffer, 0, out match)) {
                            do {
                                if (match.fetch_named ("header") == "#") {
                                    store.insert (out root, null, -1);
                                    store.set (root, 0, match.fetch_named ("header") + " " + match.fetch_named ("text"), -1);
                                    get_selected_row ().title = match.fetch_named ("header") + " " + match.fetch_named ("text");
                                } else if (match.fetch_named ("header") == "##") {
                                    store.insert (out subheader, root, -1);
                                    store.set (subheader, 0, match.fetch_named ("header") + " " + match.fetch_named ("text"), -1);
                                } else if (match.fetch_named ("header") == "###") {
                                    store.insert (out section, subheader, -1);
                                    store.set (section, 0, match.fetch_named ("header") + " " + match.fetch_named ("text"), -1);
                                }
                            } while (match.next ());
                        }
                    } catch (GLib.Error e) {
                        warning ("ERR: %s", e.message);
                    }
                }

            }
        }

        public Gee.LinkedList<SideBarBox> get_files () {
            foreach (Gtk.Widget item in column.get_children ()) {
                if (files != null)
                    s_files.add ((SideBarBox)item);
            }
            return s_files;
        }

        public GLib.List<unowned SideBarBox> get_rows () {
            return (GLib.List<unowned SideBarBox>) column.get_children ();
        }
        public unowned SideBarBox get_selected_row () {
            return (SideBarBox) column.get_selected_row ();
        }

        public SideBarBox add_file (string file) {
            var filebox = new SideBarBox (this.win, file);
            filebox.save_as.connect (() => save_as ());
            column.insert (filebox, 1);
            column.select_row (filebox);

            return filebox;
        }

        public void delete_rows () {
            foreach (Gtk.Widget item in column.get_children ()) {
                item.destroy ();
            }
        }

        public int list_sort (Gtk.ListBoxRow first_row, Gtk.ListBoxRow second_row) {
            var row_1 = first_row;
            var row_2 = second_row;

            string name_1 = row_1.name;
            string name_2 = row_2.name;

            return name_1.collate (name_2);
        }
    }
}
