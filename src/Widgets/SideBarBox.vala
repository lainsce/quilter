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
[GtkTemplate (ui = "/io/github/lainsce/Quilter/sidebarbox.ui")]
public class Quilter.Widgets.SideBarBox : Gtk.ListBoxRow {
    [GtkChild]
    public unowned He.MiniContentBlock row;
    [GtkChild]
    public unowned Gtk.Button file_remove_button;

    public EditView ev;
    public MainWindow win;
    public int uid;

    public signal void remove_requested ();

    private string? _path;
    public string? path {
        owned get {
            return _path;
        }
        set {
            _path = value;
            update_display ();
        }
    }

    public SideBarBox (MainWindow win, string? path) {
        this.win = win;
        this.path = path;

        file_remove_button.clicked.connect (() => {
            remove_requested ();
        });
    }

    private void update_display () {
        if (_path == null)return;

        string display_name;
        string? subtitle = null;

        if (Services.FileManager.get_instance ().is_temp_file (_path)) {
            display_name = _("New Document");
            subtitle = _("Unsaved");
        } else {
            display_name = Path.get_basename (_path);
            string dir_path = Path.get_dirname (_path);

            // Simple path shortening - just replace home with ~
            if (dir_path.has_prefix (Environment.get_home_dir ())) {
                subtitle = dir_path.replace (Environment.get_home_dir (), "~");
            } else {
                subtitle = dir_path;
            }
        }

        row.title = display_name;
        row.subtitle = subtitle;
    }

    public void update_title (string new_title) {
        if (Services.FileManager.get_instance ().is_temp_file (_path)) {
            row.title = _("New Document");
        } else {
            row.title = new_title;
        }

        // Update subtitle to current directory
        string dir_path = Path.get_dirname (_path);
        if (dir_path.has_prefix (Environment.get_home_dir ())) {
            row.subtitle = dir_path.replace (Environment.get_home_dir (), "~");
        } else {
            row.subtitle = dir_path;
        }
    }
}
