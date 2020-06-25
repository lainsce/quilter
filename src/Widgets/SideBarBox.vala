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

        private string? _path;
        public new string? path {
            owned get {
                return _path;
            }
            set {
                _path = value;
                if (Services.FileManager.is_temp_file (_path)) {
                    file_name_label.label = _("New Document");
                    file_label.label = _("New File");
                    win.toolbar.title = _("New File");
                    win.toolbar.set_subtitle ("");
                } else {
                    file_name_label.label = Path.get_basename (_path).replace (".md", "");
                    file_label.label = path.replace (Environment.get_home_dir (), "~");
                    win.toolbar.title = file_name_label.label;
                    win.toolbar.subtitle = file_label.label.replace (Path.get_basename (_path), "");
                }
            }
        }

        public string title {
            owned get {
                if (Services.FileManager.is_temp_file (path)) {
                    return _("No Documents Open");
                } else {
                    return file_label.label;
                }
            }
        }

        public signal void save_as ();

        public SideBarBox (MainWindow win, string? path) {
            this.win = win;
            this.activatable = true;
            this.set_size_request (200,-1);
            var sbr_context = this.get_style_context ();
            sbr_context.add_class ("quilter-sidebar-box");

            file_name_label = new Gtk.Label ("");
            file_name_label.halign = Gtk.Align.START;
            file_name_label.hexpand = true;
            file_name_label.xalign = 0;
            file_name_label.ellipsize = Pango.EllipsizeMode.END;
            var fnl_context = file_name_label.get_style_context ();
            fnl_context.add_class ("title");

            file_label = new Gtk.Label ("");
            file_label.halign = Gtk.Align.START;
            file_name_label.xalign = 0;
            file_label.ellipsize = Pango.EllipsizeMode.START;
            var fl_context = file_label.get_style_context ();
            fl_context.add_class ("subtitle");

            var file_icon = new Gtk.Image.from_icon_name ("text-markdown", Gtk.IconSize.DND);

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
                win.sidebar.delete_row_with_name ();
                win.edit_view_content.buffer.text = "";
                win.edit_view_content.modified = false;
                win.toolbar.set_subtitle ("");
                win.sidebar.store.clear ();

                var rows = win.sidebar.get_rows ();
                for (int i = 0; i < Quilter.Application.gsettings.get_strv("last-files").length; i++) {
                    if (Quilter.Application.gsettings.get_strv("last-files")[i] != null) {
                        foreach (unowned SideBarBox r in rows) {
                            win.sidebar.column.select_row (r);
                        }
                    } else if (Quilter.Application.gsettings.get_strv("last-files")[i] == null) {
                        win.sidebar.add_file (Services.FileManager.get_temp_document_path ());
                    }
                }
            });

            var file_labels_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
            var flb_context = file_labels_box.get_style_context ();
            flb_context.add_class ("quilter-flb");
            file_labels_box.pack_start (file_name_label);
            file_labels_box.pack_start (file_label);

            file_grid = new Gtk.Grid ();
            file_grid.column_spacing = 12;
            file_grid.margin = 12;
            file_grid.attach (file_icon, 0, 0, 1, 1);
            file_grid.attach (file_labels_box, 1, 0, 1, 1);
            file_grid.attach (file_remove_button, 2, 0, 1, 1);

            this.add (file_grid);
            this.show_all ();
            this.path = path;
        }
    }
}
