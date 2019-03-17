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
        public MainWindow win;
        public Gtk.Grid files_grid;
        public Gtk.Grid outline_grid;
        public Gtk.Stack stack;
        private Gtk.StackSwitcher stackswitcher;
        private string[] files;
        public string cache = Path.build_filename (Environment.get_user_data_dir (), "com.github.lainsce.quilter" + "/temp.md");
        public Gee.LinkedList<SideBarBox> s_files = null;
        public bool show_this {get; set; default = false;}

        public signal void save_as ();
        public signal void row_selected (Widgets.SideBarBox box);

        public SideBar (MainWindow win) {
            this.win = win;

            stack = new Gtk.Stack ();
            stackswitcher = new Gtk.StackSwitcher ();
            var s_context = stackswitcher.get_style_context ();
            s_context.add_class ("linked");
            stackswitcher.halign = Gtk.Align.FILL;
            stackswitcher.homogeneous = true;
            stackswitcher.margin = 4;
            stackswitcher.stack = stack;
            stack.add_titled (sidebar_files_list (), "files", _("Files"));
            stack.add_titled (sidebar_outline (), "outline", _("Outline"));

            var grid = new Gtk.Grid ();
            var g_context = grid.get_style_context ();
            g_context.add_class ("quilter-sidebar");
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
            column.hexpand = false;
            column.vexpand = true;
            column.set_size_request (280,-1);
            column.activate_on_single_click = true;
            column.selection_mode = Gtk.SelectionMode.SINGLE;
            column.set_sort_func (list_sort);

            if (settings.current_file == "") {
                filebox = new SideBarBox (this.win, Services.FileManager.get_cache_path ());
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

            column.show_all ();

            files_grid = new Gtk.Grid ();
            files_grid.hexpand = false;
            files_grid.set_size_request (280,-1);
            files_grid.attach (column, 0,0,1,1);

            files_grid.show_all ();

            return files_grid;
        }

        public Gtk.Widget sidebar_outline () {
            var view = new Gtk.TreeView ();
            view.expand = true;
            view.headers_visible = false;
            view.margin_top = 6;
            var store = new Gtk.TreeStore (1, typeof (string));
            view.set_model (store);
            view.insert_column_with_attributes (-1, "Outline", new Gtk.CellRendererText (), "text", 0, null);
            Gtk.TreeIter root;

            // TODO: Append to root with regex all occurences of headers
            //       and style them accordingly.

            store.append (out root, null);
            store.set (root, 0, "# TO-DO (YEAR 19)", -1);

            store.append (out root, null);
            store.set (root, 0, "    ## MONTH G", -1);

            outline_grid = new Gtk.Grid ();
            outline_grid.hexpand = false;
            outline_grid.set_size_request (280,-1);
            outline_grid.attach (view, 0,0,1,1);

            outline_grid.show_all ();

            return outline_grid;
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

        public int list_sort (Gtk.ListBoxRow first_row, Gtk.ListBoxRow second_row) {
            var row_1 = first_row;
            var row_2 = second_row;

            string name_1 = row_1.name;
            string name_2 = row_2.name;

            return name_1.collate (name_2);
        }
    }
}
