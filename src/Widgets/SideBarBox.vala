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
        private Gtk.Label file_name_label;
        private Gtk.Label file_label;
        public Gtk.Grid file_grid;
        public EditView ev;

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
                } else {
                    file_name_label.label = Path.get_basename (_path);
                    file_label.label = path;
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
            this.set_size_request (180,-1);
            this.hexpand = false;
            var sbr_context = this.get_style_context ();
            sbr_context.add_class ("quilter-sidebar-box");

            file_name_label = new Gtk.Label ("");
            file_name_label.halign = Gtk.Align.START;
            file_name_label.hexpand = false;
            file_name_label.ellipsize = Pango.EllipsizeMode.END;
            file_name_label.max_width_chars = 25;
            var fnl_context = file_name_label.get_style_context ();
            fnl_context.add_class (Granite.STYLE_CLASS_H3_LABEL);

            file_label = new Gtk.Label ("");
            file_label.halign = Gtk.Align.START;
            file_label.ellipsize = Pango.EllipsizeMode.START;
            file_label.max_width_chars = 25;
            file_label.hexpand = false;

            var file_icon = new Gtk.Image.from_icon_name ("text-markdown", Gtk.IconSize.DND);

            var file_remove_button = new Gtk.Button ();
            file_remove_button.always_show_image = true;
            file_remove_button.vexpand = false;
            file_remove_button.hexpand = true;
            file_remove_button.valign = Gtk.Align.CENTER;
            file_remove_button.halign = Gtk.Align.END;
            file_remove_button.tooltip_text = _("Remove File from Sidebar");
            var file_remove_button_style_context = file_remove_button.get_style_context ();
            file_remove_button_style_context.add_class (Gtk.STYLE_CLASS_FLAT);
            file_remove_button_style_context.add_class ("quilter-sidebar-button");
            file_remove_button_style_context.remove_class ("image-button");
            file_remove_button.set_image (new Gtk.Image.from_icon_name ("close-symbolic", Gtk.IconSize.SMALL_TOOLBAR));

            file_remove_button.clicked.connect (() => {
                win.sidebar.delete_row_with_name ();
                win.edit_view_content.buffer.text = "";
                win.edit_view_content.modified = false;
                win.toolbar.set_subtitle (_("No Documents Open"));
                win.sidebar.store.clear ();
                win.statusbar.readtimecount_label.set_text((_("Reading Time: ")) + "0m");

                var rows = win.sidebar.get_rows ();
                for (int i = 0; i < Quilter.Application.gsettings.get_strv("last-files").length; i++) {
                    if (Quilter.Application.gsettings.get_strv("last-files")[i] != null) {
                        foreach (unowned SideBarBox r in rows) {
                            win.sidebar.column.select_row (r);
                        }
                    } else if (Quilter.Application.gsettings.get_strv("last-files")[i] == null) {
                        win.sidebar.add_file (Services.FileManager.get_temp_document_path ());
                        //Quilter.Application.gsettings.set_string("current-file", Services.FileManager.get_cache_path ());
                    }
                }
            });

            file_grid = new Gtk.Grid ();
            file_grid.hexpand = false;
            file_grid.row_spacing = 3;
            file_grid.column_spacing = 6;
            file_grid.margin = 6;
            file_grid.attach (file_icon, 0, 0, 1, 2);
            file_grid.attach (file_name_label, 1, 0, 1, 1);
            file_grid.attach (file_label, 1, 1, 1, 1);
            file_grid.attach (file_remove_button, 2, 0, 1, 2);

            this.add (file_grid);
            this.hexpand = true;
            this.show_all ();
            this.path = path;
        }
    }
}
