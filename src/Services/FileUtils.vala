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

namespace Quilter.Services.FileUtils {
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
                if (Application.window != null)
                    Application.window.view.buffer.text = text;
            } catch (Error e) {
                warning ("%s", e.message);
            }
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
            Application.window.view.buffer.get_bounds (out start, out end);

            string buffer = Application.window.view.buffer.get_text (start, end, true);
            uint8[] binbuffer = buffer.data;

            try {
                save_file (file, binbuffer);
            } catch (Error e) {
                warning ("Exception found: "+ e.message);
            }
        }
    }

    // File I/O
    public bool new_document () throws Error {
        if (Application.window.view.is_modified == true) {
            debug ("Buffer was modified. Asking user to save first.");
            int wanna_save = Services.DialogUtils.display_save_confirm ();
            if (wanna_save == Gtk.ResponseType.CANCEL ||
                wanna_save == Gtk.ResponseType.DELETE_EVENT) {
                debug ("User canceled save confirm. Aborting operation.");
            }

            if (wanna_save == Gtk.ResponseType.YES) {
                debug ("Saving file before loading new file.");
                try {
                    bool was_saved = save_document ();
                    if (!was_saved) {
                        debug ("Cancelling open document too.");
                        Application.window.view.buffer.text = "";
                    }
                } catch (Error e) {
                    warning ("Unexpected error during save: " + e.message);
                }
            }

            if (wanna_save == Gtk.ResponseType.NO) {
                debug ("User cancelled the dialog. Remove document from Application.window.view then.");
                Application.window.view.buffer.text = "";
                var settings = AppSettings.get_default ();
                settings.last_file = "";
            }
        }
        return true;
    }

    public bool open_from_outside (File[] files, string hint) {
        if (files.length > 0) {
            var file = files[0];
            string text;

            try {
                var settings = AppSettings.get_default ();
                window.toolbar.subtitle = settings.last_file;
                GLib.FileUtils.get_contents (file.get_path (), out text);
                if (Application.window != null)
                    Application.window.view.buffer.text = text;
            } catch (Error e) {
                warning ("Error: %s", e.message);
            }
        }
        return true;
    }

    public bool open_document () throws Error {
        debug ("Asking the user what to open.");
        var file = Services.DialogUtils.display_open_dialog ();
        if (file == null) {
            debug ("User cancelled operation. Aborting.");
            return false;
        } else {
            string text;
            GLib.FileUtils.get_contents (file.get_path (), out text);
            if (Application.window != null)
                Application.window.view.buffer.text = text;
            var settings = AppSettings.get_default ();
            settings.last_file = file.get_path ();
            return true;
        }
    }

    public bool save_document () throws Error {
        debug ("Asking the user where to save.");
        var file = Services.DialogUtils.display_save_dialog ();
        if (file == null) {
            debug ("User cancelled operation. Aborting.");
            return false;
        } else {
            if (file.query_exists ()) {
              file.delete ();
            }

            Gtk.TextIter start, end;
            Application.window.view.buffer.get_bounds (out start, out end);
            string buffer = Application.window.view.buffer.get_text (start, end, true);
            uint8[] binbuffer = buffer.data;
            save_file (file, binbuffer);
            var settings = AppSettings.get_default ();
            settings.last_file = file.get_path ();
            return true;
        }
    }
}
