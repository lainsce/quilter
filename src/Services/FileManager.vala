/*
 * Copyright (C) 2017 Lains
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

namespace Quilter.Services.FileManager {
    public File tmp_file;
    public File file;
    public MainWindow win;
    public Widgets.EditView view;
    private string[] files;

    private static string? cache;
    public static string get_cache_path () {
        if (cache == null) {
            cache = Path.build_filename (Environment.get_user_data_dir (), "com.github.lainsce.quilter", "temp.md");
            try {
            	string cachedirpath = Path.build_filename (Environment.get_user_data_dir (), "com.github.lainsce.quilter");
            	File cachedir = File.new_for_path (cachedirpath);
                cachedir.make_directory_with_parents ();
                FileUtils.set_contents (cache, "");
            } catch (Error err) {
                print ("Error writing file: " + err.message);
            }
        }

        return cache;
    }

    public void save_file (string path, string contents) throws Error {
        try {
            GLib.FileUtils.set_contents (path, contents);
        } catch (Error err) {
            print ("Error writing file: " + err.message);
        }
    }
    public void save_tmp_file (string contents = "") {
        debug ("Saving cache...");
        try {
            save_file (get_cache_path (), contents);
        } catch (Error e) {
            warning ("Exception found: "+ e.message);
        }
    }

    // File I/O
    public bool open_from_outside (MainWindow win, File[] ofiles, string hint) {
        var settings = AppSettings.get_default ();
        foreach (File f in ofiles) {
            string text;
            string file_path = f.get_path ();
            settings.current_file = file_path;
            files += file_path;
            settings.last_files = files;
            if (win.sidebar != null && f != null) {
                win.sidebar.add_file (file_path);
            }
            try {
                GLib.FileUtils.get_contents (file_path, out text);
                win.edit_view_content.buffer.text = text;
                win.edit_view_content.buffer.set_modified (false);
                file = null;
            } catch (Error e) {
                warning ("Error: %s", e.message);
            }
        }
        return true;
    }

    public static string open (out string contents) {
        try {
            var chooser = Services.DialogUtils.create_file_chooser (_("Open file"),
                    Gtk.FileChooserAction.OPEN);
            if (chooser.run () == Gtk.ResponseType.ACCEPT)
                file = chooser.get_file ();
            chooser.destroy();
            GLib.FileUtils.get_contents (file.get_path (), out contents);
        } catch (Error e) {
            warning ("Error: %s", e.message);
        }
        return file.get_path ();
    }

    public void save_as (string contents) throws Error {
        debug ("Save as button pressed.");
        var chooser = Services.DialogUtils.create_file_chooser (_("Save file"),
                Gtk.FileChooserAction.SAVE);
        if (chooser.run () == Gtk.ResponseType.ACCEPT)
            file = chooser.get_file ();
        chooser.destroy();
        if (!file.get_basename ().down ().has_suffix (".md")) {
            file = File.new_for_path (file.get_path () + ".md");
        }

        string path = file.get_path ();

        try {
            debug ("Saving file...");
            if (file == null) {
                debug ("User cancelled operation. Aborting.");
            } else {
                save_file (path, contents);
                file = null;
            }
        } catch (Error e) {
            warning ("Unexpected error during save: " + e.message);
            throw e;
        }
    }
}
