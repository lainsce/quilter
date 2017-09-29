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
    File tmp_file;

    public MainWindow window;

    public void save_file (File file, uint8[] buffer) throws Error {
        var output = new DataOutputStream (file.create(FileCreateFlags.REPLACE_DESTINATION));
        long written = 0;
        while (written < buffer.length)
            written += output.write (buffer[written:buffer.length]);
    }

    private void load_work_file () {
      var settings = AppSettings.get_default ();
      var file = File.new_for_path (settings.last_file);

        if ( !file.query_exists () ) {
            try {
                file.create (FileCreateFlags.NONE);
            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }
        } else {
            try {
                string text;
                string filename = file.get_path ();

                GLib.FileUtils.get_contents (filename, out text);
                Widgets.SourceView.buffer.text = text;
            } catch (Error e) {
                warning ("%s", e.message);
            }
        }
    }

    private void load_tmp_file () {
        string cache_path = Path.build_filename (Environment.get_user_cache_dir (), "com.github.lainsce.quilter");
        var cache_folder = File.new_for_path (cache_path);
        if (!cache_folder.query_exists ()) {
            try {
                cache_folder.make_directory_with_parents ();
            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }
        }

        tmp_file = cache_folder.get_child ("temp");

        if ( !tmp_file.query_exists () ) {
            try {
                tmp_file.create (FileCreateFlags.NONE);
            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }
        }

        try {
            string text;
            string filename = tmp_file.get_path ();

            GLib.FileUtils.get_contents (filename, out text);
            Widgets.SourceView.buffer.text = text;
        } catch (Error e) {
            warning ("%s", e.message);
        }
    }

    private void save_work_file () {
        var settings = AppSettings.get_default ();
        var file = File.new_for_path (settings.last_file);

        if ( file.query_exists () ) {
            try {
                file.delete ();
            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }

            Gtk.TextIter start, end;
            Widgets.SourceView.buffer.get_bounds (out start, out end);

            string buffer = Widgets.SourceView.buffer.get_text (start, end, true);
            uint8[] binbuffer = buffer.data;

            try {
                save_file (file, binbuffer);
            } catch (Error e) {
                warning ("Exception found: "+ e.message);
            }
        }
    }

    private void save_tmp_file () {
        if ( tmp_file.query_exists () ) {
            try {
                tmp_file.delete();
            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }

        }

        Gtk.TextIter start, end;
        Widgets.SourceView.buffer.get_bounds (out start, out end);

        string buffer = Widgets.SourceView.buffer.get_text (start, end, true);
        uint8[] binbuffer = buffer.data;

        try {
            save_file (tmp_file, binbuffer);
        } catch (Error e) {
            warning ("Exception found: "+ e.message);
        }
    }

    // File I/O
    public bool open_from_outside (File[] files, string hint) {
        if (files.length > 0) {
            var file = files[0];
            string text;

            try {
                GLib.FileUtils.get_contents (file.get_path (), out text);
                Widgets.SourceView.buffer.text = text;
                var settings = AppSettings.get_default ();
                settings.last_file = file.get_path ();
            } catch (Error e) {
                warning ("Error: %s", e.message);
            }
        }
        return true;
    }

    public void new_file () {
        debug ("New button pressed.");
        var settings = AppSettings.get_default ();

        debug ("Making new file...");
        debug ("Buffer was modified. Asking user to save first.");
        int wanna_save = Services.DialogUtils.display_save_confirm ();

        if (wanna_save == Gtk.ResponseType.CANCEL ||
            wanna_save == Gtk.ResponseType.DELETE_EVENT) {
            debug ("User canceled save confirm. Aborting operation.");
        }

        if (wanna_save == Gtk.ResponseType.YES) {
            debug ("Saving file before loading new file.");

            try {
                save_as ();
            } catch (Error e) {
                warning ("Unexpected error during save: " + e.message);
            }
        }

        if (wanna_save == Gtk.ResponseType.NO) {
            debug ("User cancelled the dialog. Remove document from Widgets.SourceView then.");
            Widgets.SourceView.buffer.text = "";
        }

        string cache = Path.build_filename (Environment.get_user_cache_dir (), "com.github.lainsce.quilter");
        settings.last_file = @"$cache/temp";

        Widgets.SourceView.is_modified = false;
    }

    public void open () throws Error {
        debug ("Open button pressed.");
        var settings = AppSettings.get_default ();
        var file = Services.DialogUtils.display_open_dialog ();

        try {
            debug ("Opening file...");
            save_work_file ();
            if (file == null) {
                debug ("User cancelled operation. Aborting.");
            } else {
                string text;
                GLib.FileUtils.get_contents (file.get_path (), out text);
                Widgets.SourceView.buffer.text = text;
                settings.last_file = file.get_path ();
            }
        } catch (Error e) {
            warning ("Unexpected error during open: " + e.message);
        }

        Widgets.SourceView.is_modified = false;
        file = null;
    }

    public void save () throws Error {
        debug ("Save button pressed.");
        var settings = AppSettings.get_default ();
        var file = File.new_for_path (settings.last_file);

        if (file.query_exists ()) {
            try {
                file.delete ();
            } catch (Error e) {
                warning ("Error: " + e.message);
            }
        }

        Gtk.TextIter start, end;
        Widgets.SourceView.buffer.get_bounds (out start, out end);
        string buffer = Widgets.SourceView.buffer.get_text (start, end, true);
        uint8[] binbuffer = buffer.data;

        try {
            save_file (file, binbuffer);
        } catch (Error e) {
            warning ("Unexpected error during save: " + e.message);
        }

        file = null;
        Widgets.SourceView.is_modified = false;
    }

    public void save_as () throws Error {
        debug ("Save as button pressed.");
        var settings = AppSettings.get_default ();
        var file = Services.DialogUtils.display_save_dialog ();

        try {
            debug ("Saving file...");
            if (file == null) {
                debug ("User cancelled operation. Aborting.");
            } else {
                if (file.query_exists ()) {
                    file.delete ();
                }
    
                Gtk.TextIter start, end;
                Widgets.SourceView.buffer.get_bounds (out start, out end);
                string buffer = Widgets.SourceView.buffer.get_text (start, end, true);
                uint8[] binbuffer = buffer.data;
                save_file (file, binbuffer);
                settings.last_file = file.get_path ();
            }
        } catch (Error e) {
            warning ("Unexpected error during save: " + e.message);
        }

        file = null;
        Widgets.SourceView.is_modified = false;
    }
}
