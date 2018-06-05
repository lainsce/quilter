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
    public MainWindow window;
    public Widgets.SourceView view;

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
            var settings = AppSettings.get_default ();
            settings.last_file = file.get_path ();
            settings.subtitle = file.get_basename ();

            try {
                GLib.FileUtils.get_contents (file.get_path (), out text);
                Widgets.SourceView.buffer.text = text;
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
        settings.subtitle = file.get_basename ();

        try {
            debug ("Opening file...");
            if (file == null) {
                debug ("User cancelled operation. Aborting.");
            } else {
                string text;
                GLib.FileUtils.get_contents (file.get_path (), out text);
                Widgets.SourceView.buffer.text = text;
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
        settings.subtitle = file.get_basename ();

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
        view.is_modified = false;
    }

    public void save_as () throws Error {
        debug ("Save as button pressed.");
        var settings = AppSettings.get_default ();
        var file = Services.DialogUtils.display_save_dialog ();
        settings.last_file = file.get_path ();
        settings.subtitle = file.get_basename ();

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
            }
        } catch (Error e) {
            warning ("Unexpected error during save: " + e.message);
        }

        file = null;
        view.is_modified = false;
    }

    public static File? export_pdf (string? file_path = null) {
        Widgets.Preview.get_instance ().update_html_view ();

        File file;
        if (file_path == null) {
            file = get_file_from_user ();
            if (!file.get_basename ().down ().has_suffix (".pdf")) {
                file = File.new_for_path (file.get_path () + ".pdf");
            }
        } else {
            file = File.new_for_path (file_path);
        }

        if (file == null) {
          return null;
        }

        try {
            write_file (file, "");
        } catch (Error e) {
            warning ("Could not write initial PDF file: %s", e.message);
            return null;
        }

        var op = new WebKit.PrintOperation (Widgets.Preview.get_instance());
        var psettings = new Gtk.PrintSettings ();
        psettings.set_printer (_("Print to File"));


        psettings[Gtk.PRINT_SETTINGS_OUTPUT_URI] = file.get_uri ();
        op.set_print_settings (psettings);

        op.print ();

        return file;
    }

    public static void write_file (File file, string contents, bool overrite = false) throws Error {
        if (file.query_exists () && overrite) {
            file.delete ();
        }

        if (!file.query_exists ()) {
            try {
                file.create (FileCreateFlags.REPLACE_DESTINATION);
            } catch (Error e) {
                throw new Error (Quark.from_string (""), -1, "Could not write file: %s", e.message);
            }
        }

        file.open_readwrite_async.begin (Priority.DEFAULT, null, (obj, res) => {
            try {
                var iostream = file.open_readwrite_async.end (res);
                var ostream = iostream.output_stream;
                ostream.write_all (contents.data, null);
            } catch (Error e) {
                warning ("Could not write file \"%s\": %s", file.get_basename (), e.message);
            }
        });
    }

    public static File? get_file_from_user (bool save_as_pdf = true) {
        File? result = null;

        string title = "";
        Gtk.FileChooserAction chooser_action = Gtk.FileChooserAction.SAVE;
        string accept_button_label = "";
        List<Gtk.FileFilter> filters = new List<Gtk.FileFilter> ();

        if (save_as_pdf) {
            title =  _("Select destination PDF file");
            chooser_action = Gtk.FileChooserAction.SAVE;
            accept_button_label = _("Save");

            var pdf_filter = new Gtk.FileFilter ();
            pdf_filter.set_filter_name (_("PDF File"));

            pdf_filter.add_mime_type ("application/pdf");
            pdf_filter.add_pattern ("*.pdf");

            filters.append (pdf_filter);
        }

        var all_filter = new Gtk.FileFilter ();
        all_filter.set_filter_name (_("All Files"));
        all_filter.add_pattern ("*");

        filters.append (all_filter);

        var dialog = new Gtk.FileChooserDialog (
            title,
            window,
            chooser_action,
            _("Cancel"), Gtk.ResponseType.CANCEL,
            accept_button_label, Gtk.ResponseType.ACCEPT);


        filters.@foreach ((filter) => {
            dialog.add_filter (filter);
        });

        if (dialog.run () == Gtk.ResponseType.ACCEPT) {
            result = dialog.get_file ();
        }

        dialog.close ();

        return result;
    }
}
