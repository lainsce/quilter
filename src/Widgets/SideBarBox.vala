/*
* Copyright (c) 2018-2020 Lains
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
        private Gtk.Label file_label;
        private Gtk.Label file_name_label;
        public EditView ev;
        public Gtk.Button file_remove_button;
        public Gtk.Grid file_grid;
        public MainWindow win;
        private int uid;
        private static int uid_counter;

        private string? _path;
        public new string? path {
            owned get {
                return _path;
            }
            set {
                _path = value;
                if (Services.FileManager.is_temp_file (_path)) {
                    file_name_label.label = _("New File");
                } else {
                    file_name_label.label = Path.get_basename (_path);
                }
            }
        }

        public string title {
            owned get {
                return file_label.label;
            }
            set {
                if (Services.FileManager.is_temp_file (_path)) {
                    file_label.label = _("No header…");
                } else {
                    file_label.label = value;
                }
            }
        }

        public signal void save_as ();

        public SideBarBox (MainWindow win, string? path) {
            this.win = win;
            this.uid = uid_counter++;
            this.activatable = true;
            var sbr_context = this.get_style_context ();
            sbr_context.add_class ("quilter-sidebar-box");

            file_name_label = new Gtk.Label ("");
            file_name_label.halign = Gtk.Align.START;
            file_name_label.hexpand = true;
            file_name_label.ellipsize = Pango.EllipsizeMode.END;
            var fnl_context = file_name_label.get_style_context ();
            fnl_context.add_class ("title");

            file_label = new Gtk.Label ("");
            file_label.halign = Gtk.Align.START;
            file_label.ellipsize = Pango.EllipsizeMode.START;

            var file_icon = new Gtk.Image.from_icon_name ("markdown-symbolic", Gtk.IconSize.BUTTON);

            file_remove_button = new Gtk.Button ();
            file_remove_button.always_show_image = true;
            file_remove_button.valign = Gtk.Align.CENTER;
            file_remove_button.halign = Gtk.Align.CENTER;
            file_remove_button.tooltip_text = _("Remove File from Sidebar");
            var file_remove_button_style_context = file_remove_button.get_style_context ();
            file_remove_button_style_context.add_class (Gtk.STYLE_CLASS_FLAT);
            file_remove_button_style_context.add_class ("quilter-sidebar-button");
            file_remove_button.set_image (new Gtk.Image.from_icon_name ("window-close-symbolic", Gtk.IconSize.BUTTON));

            file_remove_button.clicked.connect (() => {
                if ((Widgets.SideBarBox) win.sidebar.column.get_selected_row () != null) {
                    ((Widgets.SideBarBox) win.sidebar.column.get_selected_row ()).destroy ();
                    win.edit_view_content.buffer.text = "";
                    win.edit_view_content.modified = false;
                    win.sidebar.store.clear ();
                    win.save_last_files ();
                }
                if (win.sidebar.column.get_children () == null) {
                    win.win_stack.set_visible_child (win.welcome_view);
                    win.welcome_titlebar.visible = true;
                    win.titlebar.visible = false;
                    win.main_stack.visible = false;
                    Quilter.Application.gsettings.set_boolean("sidebar", false);
                } else {
                    win.sidebar.column.select_row (((Widgets.SideBarBox)win.sidebar.column.get_row_at_index (this.uid - 1)));
                }
            });

            var file_labels_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
            var flb_context = file_labels_box.get_style_context ();
            flb_context.add_class ("quilter-flb");
            file_labels_box.pack_start (file_name_label);
            file_labels_box.pack_start (file_label);

            file_grid = new Gtk.Grid ();
            file_grid.column_spacing = 12;
            file_grid.margin = 6;
            file_grid.attach (file_icon, 0, 0, 1, 1);
            file_grid.attach (file_labels_box, 1, 0, 1, 1);
            file_grid.attach (file_remove_button, 2, 0, 1, 1);

            this.add (file_grid);
            this.margin_bottom = 6;
            this.show_all ();
            this.path = path;
        }
    }
}
