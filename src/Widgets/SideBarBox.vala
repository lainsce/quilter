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
        public MainWindow win;
        public Gtk.Label file_name_label;
        public Gtk.Label file_label;
        public Gtk.Grid file_grid;
        public SideBar sb;
        public string file;

        public SideBarBox (MainWindow win, string file) {
            this.win = win;
            this.file = file;
            this.activatable = true;
            var sbr_context = this.get_style_context ();
            sbr_context.add_class ("quilter-sidebar-box");

            file_name_label = new Gtk.Label ("New Document");
            file_name_label.halign = Gtk.Align.START;
            var fnl_context = file_name_label.get_style_context ();
            fnl_context.add_class (Granite.STYLE_CLASS_H3_LABEL);
            string file_name = this.file;
            string filename = GLib.Filename.display_basename (file_name);
            file_name_label.label = filename;

            file_label = new Gtk.Label ("~/new_document.md");
            string file_path = this.file;
            file_label.label = file_path;

            var file_icon = new Gtk.Image.from_icon_name ("text-markdown", Gtk.IconSize.DND);

            file_grid = new Gtk.Grid ();
            file_grid.hexpand = false;
            file_grid.row_spacing = 6;
            file_grid.column_spacing = 6;
            file_grid.margin = 12;
            file_grid.attach (file_icon, 0, 0, 1, 2);
            file_grid.attach (file_name_label, 1, 0, 1, 1);
            file_grid.attach (file_label, 1, 1, 1, 1);

            this.add (file_grid);
            this.hexpand = true;
            this.show_all ();
        }

        public void delete_row () {
            this.destroy ();
        }
    }
}
