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
    public class SideBarBox : Hdy.ActionRow {
        public EditView ev;
        public Gtk.Button file_remove_button;
        public MainWindow win;
        public int uid;
        private static int uid_counter;

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
            this.activatable = true;
            var sbr_context = this.get_style_context ();
            sbr_context.add_class ("quilter-sidebar-box");

            var file_icon = new Gtk.Image.from_icon_name ("markdown-symbolic", Gtk.IconSize.BUTTON);
            this.add_prefix (file_icon);

            file_remove_button = new Gtk.Button ();
            file_remove_button.always_show_image = true;
            file_remove_button.valign = Gtk.Align.CENTER;
            file_remove_button.halign = Gtk.Align.CENTER;
            file_remove_button.tooltip_text = _("Remove file from sidebar");
            var file_remove_button_style_context = file_remove_button.get_style_context ();
            file_remove_button_style_context.add_class (Gtk.STYLE_CLASS_FLAT);
            file_remove_button_style_context.add_class ("quilter-sidebar-button");
            file_remove_button_style_context.add_class ("tiny-circular-button");
            file_remove_button.set_image (new Gtk.Image.from_icon_name ("window-close-symbolic", Gtk.IconSize.BUTTON));

            file_remove_button.clicked.connect (() => {
                this.dispose ();
                win.edit_view_content.buffer.text = "";
                win.edit_view_content.modified = false;
                win.save_last_files ();
                win.sidebar.column.select_row (((Widgets.SideBarBox)win.sidebar.column.get_row_at_index ((this.uid - 1) < 0 ? (this.uid + 1) : (this.uid - 1))));
                win.sidebar.store.clear ();
            });

            this.add (file_remove_button);
            this.show_all ();
            this.path = path;
        }
    }
}
