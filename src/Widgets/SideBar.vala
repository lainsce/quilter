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
        public Widgets.EditView ev;
        public MainWindow win;
        private string[] files;
        public string cache = Path.build_filename (Environment.get_user_data_dir (), "com.github.lainsce.quilter" + "/temp.md");
        public Gee.LinkedList<SideBarBox> s_files = null;
        public bool show_this {get; set; default = false;}

        public SideBar (MainWindow win) {
            this.win = win;
            var settings = AppSettings.get_default ();
            column = new Gtk.ListBox ();
            var sb_context = column.get_style_context ();
            sb_context.add_class ("quilter-sidebar");
            column.hexpand = false;
            column.vexpand = true;
            column.set_size_request (250,-1);
            column.activate_on_single_click = true;
            column.selection_mode = Gtk.SelectionMode.SINGLE;
            column.set_sort_func (list_sort);
            foreach (string f in settings.last_files) {
                add_file (f);
            }

            foreach (var file in get_files ()) {
                files += file.file_label.label;
                settings.last_files = files;
                if (file.file_label.label == settings.current_file) {
                    column.select_row (file);
                }
            }

            column.row_selected.connect ((row) => {
                if (((Widgets.SideBarBox)row) != null) {
                    try {
                        string text;
                        string file_path = ((Widgets.SideBarBox)row).file_label.label;
                        settings.current_file = file_path;
                        if (settings.current_file == cache)
                                settings.current_file = "No Documents Open";
                        var file = File.new_for_path (file_path);
                        GLib.FileUtils.get_contents (file.get_path (), out text);
                        Widgets.EditView.buffer.text = text;
                    } catch (Error e) {
                        warning ("Error: %s\n", e.message);
                    }
                }
            });

            var file_clean_button = new Gtk.Button ();
            var fcb_context = file_clean_button.get_style_context ();
            fcb_context.add_class ("quilter-sidebar-button");
            file_clean_button.vexpand = false;
            file_clean_button.hexpand = false;
            file_clean_button.valign = Gtk.Align.CENTER;
            file_clean_button.tooltip_text = "Clean files from Sidebar";
            var file_clean_button_style_context = file_clean_button.get_style_context ();
            file_clean_button_style_context.add_class (Gtk.STYLE_CLASS_FLAT);
            file_clean_button.set_image (new Gtk.Image.from_icon_name ("edit-clear-all-symbolic", Gtk.IconSize.LARGE_TOOLBAR));

            file_clean_button.clicked.connect (() => {
                clean_all_check ();
            });

            column.show_all ();

            var grid = new Gtk.Grid ();
            grid.hexpand = false;
            grid.set_size_request (250,-1);
            grid.attach (column, 0,0,1,1);
            grid.attach (file_clean_button, 0,1,1,1);

            this.add (grid);

            this.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;

            show_this = false;
            if (show_this) {
                this.show_all ();
            } else if (!show_this) {
                this.hide ();
            }
        }

        public SideBarBox get_file () {
            return ((SideBarBox)row.is_selected ());
        }

        public Gee.LinkedList<SideBarBox> get_files () {
            foreach (Gtk.Widget item in column.get_children ()) {
                if (files != null)
	                s_files.add ((SideBarBox)item);
            }
            return s_files;
        }

        public void add_file (string file) {
            var settings = AppSettings.get_default ();
            var filebox = new SideBarBox (this.win, file);
            column.insert (filebox, 1);
            if (filebox.file_label.label == settings.current_file) {
                column.select_row (filebox);
            } else if (filebox.file_label.label == cache) {
                filebox.file_name_label.label = "New Document";
                filebox.file_label.label = "";
                column.select_row (filebox);
                files += cache;
                settings.last_files = files;
            }
        }

        public int list_sort (Gtk.ListBoxRow first_row, Gtk.ListBoxRow second_row) {
            var row_1 = first_row;
            var row_2 = second_row;

            string name_1 = row_1.name;
            string name_2 = row_2.name;

            return name_1.collate (name_2);
        }

        public void clean_all () {
            var settings = AppSettings.get_default ();
            settings.last_files = null;
            settings.current_file = "No Documents Open";
            if (s_files != null)
                s_files.clear ();
            foreach (Gtk.Widget item in column.get_children ()) {
                item.destroy ();
            }
            Widgets.EditView.buffer.text = "";
        }

        public void clean_all_check () {
            var dialog = new Services.DialogUtils.ClearDialog ();
                dialog.transient_for = win;

                dialog.response.connect ((response_id) => {
                    switch (response_id) {
                        case Gtk.ResponseType.OK:
                            var settings = AppSettings.get_default ();
                            settings.last_files = null;
                            settings.current_file = "No Documents Open";
                            if (s_files != null)
                                s_files.clear ();
                            foreach (Gtk.Widget item in column.get_children ()) {
	                            item.destroy ();
                            }
                            Widgets.EditView.buffer.text = "";
                            dialog.close ();
                            break;
                        case Gtk.ResponseType.NO:
                        case Gtk.ResponseType.CANCEL:
                        case Gtk.ResponseType.CLOSE:
                        case Gtk.ResponseType.DELETE_EVENT:
                            dialog.close ();
                            break;
                        default:
                            assert_not_reached ();
                    }
                });


                if (Widgets.EditView.buffer.get_modified() == true) {
                    dialog.run ();
                }
        }
    }
}
