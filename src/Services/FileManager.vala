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
    public MainWindow window;
    public Widgets.EditView view;

    public void save_file (File file, uint8[] buffer) throws Error {
        var output = new DataOutputStream (file.create(FileCreateFlags.REPLACE_DESTINATION));
        long written = 0;
        while (written < buffer.length)
            written += output.write (buffer[written:buffer.length]);
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
            Widgets.EditView.buffer.get_bounds (out start, out end);

            string buffer = Widgets.EditView.buffer.get_text (start, end, true);
            uint8[] binbuffer = buffer.data;

            try {
                save_file (file, binbuffer);
            } catch (Error e) {
                warning ("Exception found: "+ e.message);
            }
        }
    }

    public File setup_tmp_file () {
        debug ("Setupping cache...");
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
        return tmp_file;
    }

    private void save_tmp_file () {
        setup_tmp_file ();

        debug ("Saving cache...");
        if ( tmp_file.query_exists () ) {
            try {
                tmp_file.delete();
            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }

        }

        Gtk.TextIter start, end;
        Widgets.EditView.buffer.get_bounds (out start, out end);

        string buffer = Widgets.EditView.buffer.get_text (start, end, true);
        uint8[] binbuffer = buffer.data;

        try {
            save_file (tmp_file, binbuffer);
        } catch (Error e) {
            warning ("Exception found: "+ e.message);
        }
    }

    // File I/O
    public void new_file () {
        debug ("New button pressed.");
        debug ("Buffer was modified. Asking user to save first.");
        var settings = AppSettings.get_default ();
        var dialog = new Services.DialogUtils.Dialog.display_save_confirm (Application.window);
        dialog.response.connect ((response_id) => {
            switch (response_id) {
                case Gtk.ResponseType.YES:
                    debug ("User saves the file.");

                    try {
                        Services.FileManager.save ();
                        string cache = Path.build_filename (Environment.get_user_cache_dir (), "com.github.lainsce.quilter" + "/temp");
                        file = File.new_for_path (cache);
                        Widgets.EditView.buffer.text = "";
                        settings.last_file = file.get_path ();
                        
                    } catch (Error e) {
                        warning ("Unexpected error during save: " + e.message);
                    }
                    break;
                case Gtk.ResponseType.NO:
                    debug ("User doesn't care about the file, shoot it to space.");

                    string cache = Path.build_filename (Environment.get_user_cache_dir (), "com.github.lainsce.quilter" + "/temp");
                    file = File.new_for_path (cache);
                    Widgets.EditView.buffer.text = "";
                    settings.last_file = file.get_path ();
                    
                    break;
                case Gtk.ResponseType.CANCEL:
                    debug ("User cancelled, don't do anything.");
                    break;
                case Gtk.ResponseType.DELETE_EVENT:
                    debug ("User cancelled, don't do anything.");
                    break;
            }
            dialog.destroy();
        });

        if (view.is_modified) {
            dialog.show ();
            view.is_modified = false;
        } else {
            try {
                Services.FileManager.save ();
            } catch (Error e) {
                warning ("Unexpected error during save: " + e.message);
            }
            string cache = Path.build_filename (Environment.get_user_cache_dir (), "com.github.lainsce.quilter" + "/temp");
            file = File.new_for_path (cache);
            Widgets.EditView.buffer.text = "";
            settings.last_file = file.get_path ();
            
        }
    }

    public bool open_from_outside (File[] files, string hint) {
        if (files.length > 0) {
            var file = files[0];
            string text;
            var settings = AppSettings.get_default ();
            settings.last_file = file.get_path ();
            

            try {
                GLib.FileUtils.get_contents (file.get_path (), out text);
                Widgets.EditView.buffer.text = text;
            } catch (Error e) {
                warning ("Error: %s", e.message);
            }
        }
        return true;
    }

    public void open () throws Error {
        debug ("Open button pressed.");
        var settings = AppSettings.get_default ();
        var file = Services.DialogUtils.display_open_dialog ();
        settings.last_file = file.get_path ();
        

        try {
            debug ("Opening file...");
            if (file == null) {
                debug ("User cancelled operation. Aborting.");
            } else {
                string text;
                GLib.FileUtils.get_contents (file.get_path (), out text);
                Widgets.EditView.buffer.text = text;
            }
        } catch (Error e) {
            warning ("Unexpected error during open: " + e.message);
        }

        view.is_modified = false;
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
        Widgets.EditView.buffer.get_bounds (out start, out end);
        string buffer = Widgets.EditView.buffer.get_text (start, end, true);
        uint8[] binbuffer = buffer.data;

        try {
            save_file (file, binbuffer);
        } catch (Error e) {
            warning ("Unexpected error during save: " + e.message);
        }

        file = null;
        view.is_modified = false;
    }

    public void save_as () throws Error {
        debug ("Save as button pressed.");
        var settings = AppSettings.get_default ();
        var file = Services.DialogUtils.display_save_dialog ();
        settings.last_file = file.get_path ();
        

        try {
            debug ("Saving file...");
            if (file == null) {
                debug ("User cancelled operation. Aborting.");
            } else {
                if (file.query_exists ()) {
                    file.delete ();
                }

                Gtk.TextIter start, end;
                Widgets.EditView.buffer.get_bounds (out start, out end);
                string buffer = Widgets.EditView.buffer.get_text (start, end, true);
                uint8[] binbuffer = buffer.data;
                save_file (file, binbuffer);
            }
        } catch (Error e) {
            warning ("Unexpected error during save: " + e.message);
        }

        file = null;
        view.is_modified = false;
    }
}
