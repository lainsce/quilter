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
    [GtkTemplate (ui = "/io/github/lainsce/Quilter/sidebar.ui")]
    public class SideBar : He.Bin {
        public Widgets.SideBarBox row;
        public Widgets.SideBarBox filebox;
        public Widgets.EditView ev;
        public Widgets.SearchBar seb;
        public MainWindow win;
        public Gtk.TreeStore store;
        public Gtk.TreeSelection selection;
        public Gtk.CellRendererText crt;
        private new Gtk.TreeIter root;
        private Gtk.TreeIter subheader;
        private Gtk.TreeIter section;
        private GLib.MatchInfo match;
        public bool is_modified { get; set; default = false; }

        [GtkChild]
        public unowned He.SideBar flap;
        [GtkChild]
        public unowned He.ViewTitle viewtitle;
        [GtkChild]
        public unowned Gtk.Box navbox;
        [GtkChild]
        public unowned Gtk.Stack stack;
        [GtkChild]
        public unowned Gtk.ListBox column;
        [GtkChild]
        public unowned Gtk.TreeView view;
        [GtkChild]
        public unowned Gtk.Grid top_grid;
        [GtkChild]
        public unowned Gtk.CheckButton color_button_light;
        [GtkChild]
        public unowned Gtk.CheckButton color_button_sepia;
        [GtkChild]
        public unowned Gtk.CheckButton color_button_dark;

        public signal void save_as ();

        private static SideBar? instance = null;
        public static SideBar get_instance () {
            if (instance == null) {
                instance = new Widgets.SideBar (Quilter.Application.win, Quilter.Application.win.edit_view_content);
            }

            return instance;
        }

        public SideBar (MainWindow win, Widgets.EditView ev) {
            this.win = win;
            this.ev = ev;
            this.is_modified = false;

            flap.remove_css_class ("sidebar-view");

            stack.set_visible_child_name ("files");
            var visible_child_name = stack.get_visible_child_name ();
            if (visible_child_name == "files") {
                viewtitle.label = "Files";
            } else if (visible_child_name == "outline") {
                viewtitle.label = "Outline";
            }

            stack.notify["visible-child-name"].connect (() => {
                if (visible_child_name == "files") {
                    viewtitle.label = "Files";
                } else if (visible_child_name == "outline") {
                    viewtitle.label = "Outline";
                }
            });

            sidebar_files_list ();
            sidebar_outline ();

            column.row_selected.connect (on_row_selected);

            if (Quilter.Application.gsettings.get_string ("visual-mode") == "sepia") {
                flap.add_css_class ("quilter-sidebar-sepia");
                stack.add_css_class ("quilter-sidebar-sepia");
                column.add_css_class ("quilter-sidebar-sepia");
                view.add_css_class ("quilter-sidebar-sepia");
            } else {
                if (Quilter.Application.gsettings.get_string ("visual-mode") == "light") {
                    flap.remove_css_class ("quilter-sidebar-sepia");
                    stack.remove_css_class ("quilter-sidebar-sepia");
                    column.remove_css_class ("quilter-sidebar-sepia");
                    view.remove_css_class ("quilter-sidebar-sepia");
                } else {
                    flap.remove_css_class ("quilter-sidebar-sepia");
                    stack.remove_css_class ("quilter-sidebar-sepia");
                    column.remove_css_class ("quilter-sidebar-sepia");
                    view.remove_css_class ("quilter-sidebar-sepia");
                }
            }

            Quilter.Application.gsettings.changed.connect (() => {
                if (Quilter.Application.gsettings.get_string ("visual-mode") == "sepia") {
                    flap.add_css_class ("quilter-sidebar-sepia");
                    stack.add_css_class ("quilter-sidebar-sepia");
                    column.add_css_class ("quilter-sidebar-sepia");
                    view.add_css_class ("quilter-sidebar-sepia");
                } else {
                    if (Quilter.Application.gsettings.get_string ("visual-mode") == "light") {
                        flap.remove_css_class ("quilter-sidebar-sepia");
                        stack.remove_css_class ("quilter-sidebar-sepia");
                        column.remove_css_class ("quilter-sidebar-sepia");
                        view.remove_css_class ("quilter-sidebar-sepia");
                    } else {
                        flap.remove_css_class ("quilter-sidebar-sepia");
                        stack.remove_css_class ("quilter-sidebar-sepia");
                        column.remove_css_class ("quilter-sidebar-sepia");
                        view.remove_css_class ("quilter-sidebar-sepia");
                    }
                }

                if (Quilter.Application.gsettings.get_boolean ("sidebar")) {
                    this.visible = true;
                } else {
                    this.visible = false;
                }
            });

            build_ui ();
        }

        private void build_ui () {
            var mode_type = Quilter.Application.gsettings.get_string ("visual-mode");

            switch (mode_type) {
            case "sepia" :
                color_button_sepia.set_active (true);
                break;
            case "dark":
                color_button_dark.set_active (true);
                break;
            case "light":
            default:
                color_button_light.set_active (true);
                break;
            }

            color_button_dark.toggled.connect (() => {
                Quilter.Application.gsettings.set_string ("visual-mode", "dark");
            });

            color_button_sepia.toggled.connect (() => {
                Quilter.Application.gsettings.set_string ("visual-mode", "sepia");
            });

            color_button_light.toggled.connect (() => {
                Quilter.Application.gsettings.set_string ("visual-mode", "light");
            });
        }

        public void sidebar_files_list () {
            column.hexpand = true;
            column.activate_on_single_click = true;
            column.selection_mode = Gtk.SelectionMode.SINGLE;
            column.set_sort_func (list_sort);
        }

        public void sidebar_outline () {
            view.remove_css_class ("view");
            crt = new Gtk.CellRendererText ();
            crt.ellipsize = Pango.EllipsizeMode.END;
            view.insert_column_with_attributes (-1, "Outline", crt, "text", 0);
            store = new Gtk.TreeStore (1, typeof (string));
            view.set_model (store);
            outline_populate ();
            selection = view.get_selection ();
            selection.set_mode (Gtk.SelectionMode.SINGLE);
        }

        public void selchanged (Gtk.TreeSelection row) {
            // Get string value from row clicked from TreeView and scroll to it in Editor
            Gtk.TreeModel pathmodel;
            Gtk.TreeIter pathiter;
            if (row.count_selected_rows () == 1) {
                row.get_selected (out pathmodel, out pathiter);
                Value val;
                pathmodel.get_value (pathiter, 0, out val);

                Gtk.TextIter start, end, match_start, match_end;
                ev.buffer.get_bounds (out start, out end);

                bool found = start.forward_search (val.get_string (), 0, out match_start, out match_end, null);
                if (found) {
                    ev.scroll_to_iter (match_start, 0.0, true, 0.5, 0.1);
                }
            }
        }

        public void outline_populate () {
            if (Quilter.Application.gsettings.get_string ("current-file") != "") {
                var file = GLib.File.new_for_path (Quilter.Application.gsettings.get_string ("current-file"));
                store.clear ();
                if (file != null && file.query_exists ()) {
                    try {
                        string buffer = "";
                        GLib.FileUtils.get_contents (file.get_path (), out buffer, null);
                        var reg = new Regex ("(?m)^(?<header>\\#{1,3})\\s(?<text>.*\\$?)");
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
                                }
                            } while (match.next ());
                        }
                    } catch (GLib.Error e) {
                        warning ("ERR: %s", e.message);
                    }
                }
                view.expand_all ();
            }
        }

        public unowned SideBarBox get_selected_row () {
            return (SideBarBox) column.get_selected_row ();
        }

        // Simplified file management methods
        public SideBarBox add_file (string path, string? title = null) {
            // Check if file already exists
            var existing_box = find_file_box (path);
            if (existing_box != null) {
                column.select_row (existing_box);
                return existing_box;
            }

            // Create new file box
            var filebox = new SideBarBox (this.win, path);
            filebox.remove_requested.connect (() => {
                remove_file (filebox);
            });

            column.append (filebox);

            // Set title
            if (title != null) {
                filebox.row.title = title;
            } else if (Services.FileManager.get_instance ().is_temp_file (path)) {
                filebox.row.title = _("New File");
            } else {
                filebox.row.title = Path.get_basename (path);
            }

            return filebox;
        }

        public SideBarBox ? find_file_box (string path) {
            var child = column.get_first_child ();
            while (child != null) {
                if (child is SideBarBox) {
                    var box = (SideBarBox) child;
                    if (box.path == path) {
                        return box;
                    }
                }
                child = child.get_next_sibling ();
            }
            return null;
        }

        public void update_file_title (string path, string new_title) {
            var box = find_file_box (path);
            if (box != null) {
                box.row.title = new_title;
                box.path = path;
                box.remove_css_class ("temp-file");
            }
        }

        public void clear_all_files () {
            while (column.get_first_child () != null) {
                column.remove (column.get_first_child ());
            }
        }

        public void load_files_from_list (Gee.List<OpenFile> files) {
            clear_all_files ();
            foreach (var file in files) {
                var box = add_file (file.path);
                box.row.title = file.title;
            }
        }

        public int list_sort (Gtk.ListBoxRow first_row, Gtk.ListBoxRow second_row) {
            var row_1 = first_row;
            var row_2 = second_row;

            string name_1 = row_1.name;
            string name_2 = row_2.name;

            return name_1.collate (name_2);
        }

        private void on_row_selected (Gtk.ListBoxRow? selected_row) {
            if (selected_row == null)return;

            var box = selected_row as SideBarBox;
            if (box == null || box.path == null)return;

            try {
                File file = File.new_for_path (box.path);
                if (!file.query_exists () || file.query_file_type (FileQueryInfoFlags.NONE) != FileType.REGULAR) {
                    warning ("Invalid file: %s", box.path);
                    return;
                }

                string text;
                FileUtils.get_contents (box.path, out text);
                Quilter.Application.gsettings.set_string ("current-file", box.path);

                win.update_samenu_title (box.path);
                win.edit_view_content.text = text;

                if (win.edit_view_content.modified) {
                    Services.FileManager.get_instance ().save_file (box.path, text);
                    win.edit_view_content.modified = false;
                    outline_populate ();
                }
            } catch (Error e) {
                warning ("Error loading file: %s", e.message);
            }

            Services.FileManager.get_instance ().save_open_files (win);
        }

        private void remove_file (SideBarBox box) {
            var dialog = new Gtk.MessageDialog (win,
                                                Gtk.DialogFlags.MODAL,
                                                Gtk.MessageType.QUESTION,
                                                Gtk.ButtonsType.YES_NO,
                                                _("Remove this file from the sidebar?"));
            dialog.secondary_text = _("This will not delete the file from your computer.");

            dialog.response.connect ((response) => {
                if (response == Gtk.ResponseType.YES) {
                    column.remove (box);

                    // Select next available row
                    var next_row = column.get_selected_row ();
                    if (next_row == null) {
                        next_row = column.get_row_at_index (0);
                    }

                    if (next_row != null) {
                        column.select_row (next_row);
                    } else {
                        win.edit_view_content.buffer.text = "";
                        win.edit_view_content.modified = false;
                        store.clear ();
                    }

                    Services.FileManager.get_instance ().save_open_files (win);
                }
                dialog.destroy ();
            });

            dialog.show ();
        }

        // Legacy compatibility methods
        public void delete_rows () {
            clear_all_files ();
            Services.FileManager.get_instance ().save_open_files (win);
        }

        public void reorder_files (Gee.List<OpenFile> files) {
            load_files_from_list (files);
        }
    }
}