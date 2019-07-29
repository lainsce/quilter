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
    public class SideBar : Gtk.Revealer {
        public Gtk.ListBox column;
        public Widgets.SideBarBox row;
        public Widgets.SideBarBox filebox;
        public Widgets.EditView ev;
        public Widgets.SearchBar seb;
        public MainWindow win;
        public Gtk.Grid files_grid;
        public Gtk.Grid outline_grid;
        public Gtk.Stack stack;
        private Gtk.StackSwitcher stackswitcher;
        public Gtk.TreeStore store;
        public Gtk.TreeView view;
        public Gtk.TreeViewColumn tvc;
        public Gtk.CellRendererText crt;
        private Gtk.TreeIter root;
        private Gtk.TreeIter subheader;
        private Gtk.TreeIter section;
        private Gtk.TreeIter subsection;
        private Gtk.TreeIter subsubsection;
        private Gtk.TreeIter paragraph;
        private GLib.File file;
        private Gtk.Label no_files;
        private string[] files;
        public Gee.LinkedList<SideBarBox> s_files = null;
        public bool show_this {get; set; default = false;}

        public signal void save_as ();
        public signal void row_selected (Widgets.SideBarBox box);

        private static SideBar? instance = null;
        public static SideBar get_instance () {
            if (instance == null) {
                instance = new Widgets.SideBar (Application.win);
            }

            return instance;
        }

        public SideBar (MainWindow win) {
            var settings = AppSettings.get_default ();
            this.win = win;

            no_files = new Gtk.Label (_("No files…"));
            no_files.halign = Gtk.Align.CENTER;
            var no_files_style_context = no_files.get_style_context ();
            no_files_style_context.add_class ("h2");
            no_files.sensitive = false;
            no_files.margin = 12;
            no_files.show_all ();

            stack = new Gtk.Stack ();
            stackswitcher = new Gtk.StackSwitcher ();
            var s_context = stackswitcher.get_style_context ();
            s_context.add_class ("linked");
            stackswitcher.halign = Gtk.Align.FILL;
            stackswitcher.homogeneous = true;
            stackswitcher.margin = 0;
            stackswitcher.stack = stack;
            stack.add_titled (sidebar_files_list (), "files", _("Files"));
            stack.child_set_property (files_grid, "icon-name", "text-x-generic-symbolic");
            stack.add_titled (sidebar_outline (), "outline", _("Outline"));
            stack.child_set_property (outline_grid, "icon-name", "format-justify-left-symbolic");

            if (settings.current_file != "") {
                get_file_contents_as_items ();
                view.expand_all ();
            }

            var grid = new Gtk.Grid ();
            var g_context = grid.get_style_context ();
            g_context.add_class ("quilter-sidebar");
            g_context.add_class (Gtk.STYLE_CLASS_SIDEBAR);
            grid.margin_top = 0;
            grid.attach (stackswitcher, 0, 0, 1, 1);
            grid.attach (stack, 0, 1, 1, 1);

            this.add (grid);

            this.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;

            show_this = false;
            if (show_this) {
                this.show_all ();
            } else if (!show_this) {
                this.hide ();
            }
        }

        public Gtk.Widget sidebar_files_list () {
            var settings = AppSettings.get_default ();
            column = new Gtk.ListBox ();
            column.hexpand = true;
            column.vexpand = true;
            column.set_size_request (280,-1);
            column.activate_on_single_click = true;
            column.selection_mode = Gtk.SelectionMode.SINGLE;
            column.set_sort_func (list_sort);
            column.set_placeholder (no_files);

            if (settings.current_file == "") {
                filebox = new SideBarBox (this.win, Services.FileManager.get_temp_document_path ());
                column.insert (filebox, 1);
                column.select_row (filebox);
            }

            foreach (string f in settings.last_files) {
                var row = add_file (f);
                if (f == settings.current_file) {
                    column.select_row (row);
                }
            }

            column.row_selected.connect ((row) => {
                if (((Widgets.SideBarBox)row) != null) {
                    row_selected ((Widgets.SideBarBox)row);
                }
            });

            var file_clean_button = new Gtk.Button ();
            var fcb_context = file_clean_button.get_style_context ();
            fcb_context.add_class ("quilter-sidebar-button");
            file_clean_button.always_show_image = true;
            file_clean_button.vexpand = false;
            file_clean_button.hexpand = false;
            file_clean_button.valign = Gtk.Align.CENTER;
            file_clean_button.tooltip_text = "Removes files from the Sidebar, leaving it empty again.\nNo files will be saved however!";
            file_clean_button.set_label (_("Remove All Files"));
            var file_clean_button_style_context = file_clean_button.get_style_context ();
            file_clean_button_style_context.add_class (Gtk.STYLE_CLASS_FLAT);
            file_clean_button.set_image (new Gtk.Image.from_icon_name ("edit-clear-all-symbolic", Gtk.IconSize.LARGE_TOOLBAR));

            file_clean_button.clicked.connect (() => {
                delete_row ();
                win.edit_view_content.buffer.text = "";
                Services.FileManager.file = null;
                win.toolbar.set_subtitle (_("No Documents Open"));
            });

            column.show_all ();

            files_grid = new Gtk.Grid ();
            files_grid.hexpand = false;
            files_grid.set_size_request (280, -1);
            files_grid.attach (column, 0, 0, 1, 1);
            files_grid.attach (file_clean_button, 0, 1, 1, 1);
            files_grid.show_all ();
            return files_grid;
        }

        public Gtk.Widget sidebar_outline () {
            var settings = AppSettings.get_default ();
            view = new Gtk.TreeView ();
            view.expand = true;
            view.hexpand = false;
            view.headers_visible = false;
            view.margin_top = 6;
            view.set_activate_on_single_click (true);
            store = new Gtk.TreeStore (1, typeof (string));
            view.set_model (store);
            crt = new Gtk.CellRendererText ();
            crt.font = "Open Sans 11";
            tvc = new Gtk.TreeViewColumn.with_attributes ("Outline", crt, "text", 0, null);
            tvc.set_spacing (6);
            tvc.set_sort_column_id (0);
            tvc.set_sort_order (Gtk.SortType.DESCENDING);
            view.append_column (tvc);

            store.clear ();

            if (settings.current_file != "") {
                store.clear ();
                get_file_contents_as_items ();
                view.expand_all ();
            }

            settings.changed.connect (() => {
                store.clear ();
                if (settings.current_file != "") {
                    get_file_contents_as_items ();
                    view.expand_all ();
                }
            });

            outline_grid = new Gtk.Grid ();
            outline_grid.hexpand = false;
            outline_grid.vexpand = false;
            outline_grid.set_size_request (280, -1);
            outline_grid.attach (view, 0, 0, 1, 1);
            outline_grid.show_all ();
            return outline_grid;
        }

        public void get_file_contents_as_items () {
            var settings = AppSettings.get_default ();
            file = GLib.File.new_for_path (settings.current_file);
            if (file.query_exists ()) {
                try {
                    var reg = new Regex("(?m)^(?<header>\\#{1,6})\\s(?<text>.+)");
                    string buffer = "";
                    GLib.FileUtils.get_contents (file.get_path (), out buffer, null);
                    GLib.MatchInfo match;

                    if (reg.match (buffer, 0, out match)) {
                        do {
                            if (match.fetch_named ("header") == "#") {
                                store.insert (out root, null, -1);
                                store.set (root, 0, match.fetch_named ("header") + " " + match.fetch_named ("text"), -1);
                            } else if (match.fetch_named ("header") == "##") {
                                store.insert (out subheader, root, -1);
                                store.set (subheader, 0, match.fetch_named ("header") + " " + match.fetch_named ("text"), -1);
                            } else if (match.fetch_named ("header") == "###") {
                                store.insert (out section, subheader, -1);
                                store.set (section, 0, match.fetch_named ("header") + " " + match.fetch_named ("text"), -1);
                            } else if (match.fetch_named ("header") == "####") {
                                store.insert (out subsection, section, -1);
                                store.set (subsection, 0, match.fetch_named ("header") + " " + match.fetch_named ("text"), -1);
                            } else if (match.fetch_named ("header") == "#####") {
                                store.insert (out subsubsection, subsection, -1);
                                store.set (subsubsection, 0, match.fetch_named ("header") + " " + match.fetch_named ("text"), -1);
                            } else if (match.fetch_named ("header") == "######") {
                                store.insert (out paragraph, subsubsection, -1);
                                store.set (paragraph, 0, match.fetch_named ("header") + " " + match.fetch_named ("text"), -1);
                            }
                        } while (match.next ());
                    }
                } catch (GLib.Error e) {
                    warning ("ERR: %s", e.message);
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
        public unowned SideBarBox? get_selected_row () {
            return (SideBarBox) column.get_selected_row ();
        }

        public SideBarBox add_file (string file) {
            var filebox = new SideBarBox (this.win, file);
            filebox.save_as.connect (() => save_as ());
            column.insert (filebox, 1);
            column.select_row (filebox);

            return filebox;
        }

        public void delete_row () {
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
