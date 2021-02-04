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
    [GtkTemplate (ui = "/io/github/lainsce/Quilter/sidebarbox.ui")]
    public class SideBarBox : Hdy.ActionRow {
        public signal void clicked ();
        public EditView ev;
        public MainWindow win;
        public int uid;
        private static int uid_counter;

        [GtkChild]
        public Gtk.Button file_remove_button;

        private string? _path;
        public new string? path {
            owned get {
                return _path;
            }
            set {
                _path = value;
            }
        }

        private string? _header;
        public new string? header {
            owned get {
                return _header;
            }
            set {
                _header = value;
            }
        }

        public signal void save_as ();

        public SideBarBox (MainWindow win, string? path) {
            this.win = win;
            this.uid = uid_counter++;
            this.path = path;
            this.show_all ();

            file_remove_button.clicked.connect (() => {
                this.dispose ();
                win.edit_view_content.buffer.text = "";
                win.edit_view_content.modified = false;
                win.save_last_files ();
                win.sidebar.column.select_row (((Widgets.SideBarBox)win.sidebar.column.get_row_at_index ((this.uid - 1) < 0 ? (this.uid + 1) : (this.uid - 1))));
                win.sidebar.store.clear ();
            });
        }
    }
}
