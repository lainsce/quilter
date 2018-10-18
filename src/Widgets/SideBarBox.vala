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
    public class SideBarBox : Gtk.ListBoxRow {
        public Gtk.Label file_name_label;
        public Gtk.Label file_label;
        public Gtk.Grid file_grid;

        public SideBarBox (string file) {
            this.activatable = true;
            var sbr_context = this.get_style_context ();
            sbr_context.add_class ("quilter-sidebar-box");

            file_name_label = new Gtk.Label ("");
            file_name_label.halign = Gtk.Align.START;
            string file_name = file;
            string filename = GLib.Filename.display_basename (file_name);
            file_name_label.label = filename;

            file_label = new Gtk.Label ("");
            string file_path = file;
            file_label.label = file_path;

            file_grid = new Gtk.Grid ();
            file_grid.hexpand = false;
            file_grid.row_spacing = 6;
            file_grid.margin = 12;
            file_grid.attach (file_name_label, 0, 0, 1, 1);
            file_grid.attach (file_label, 0, 1, 1, 1);

            this.add (file_grid);
            this.hexpand = true;
            this.show_all ();
        }
    }
}
