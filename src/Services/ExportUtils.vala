/*
 * Copyright (C) 2017-2021 Lains
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

namespace Quilter.Services.ExportUtils {
    public MainWindow window;
    public static File? export_html (string? file_path = null) {
        Widgets.Preview.get_instance ().update_html_view ();

        File file;
        if (file_path == null) {
            file = get_html_from_user ();
            if (!file.get_basename ().down ().has_suffix (".html")) {
                file = File.new_for_path (file.get_path () + ".html");
            }
        } else {
            file = File.new_for_path (file_path);
        }

        if (file == null) {
          return null;
        }

        try {
            write_file (file, Widgets.Preview.get_instance ().html);
        } catch (Error e) {
            warning ("Could not write HTML file: %s", e.message);
            return null;
        }

        return file;
    }

    public static File? export_pdf (string? file_path = null) {
        window.render_func ();
        int type_of_mode = 0;

        if (Quilter.Application.gsettings.get_string ("visual-mode") == "dark") {
            Quilter.Application.gsettings.set_string ("visual-mode", "light");
            type_of_mode = 1;
        } else if (Quilter.Application.gsettings.get_string ("visual-mode") == "sepia") {
            Quilter.Application.gsettings.set_string ("visual-mode", "light");
            type_of_mode = 2;
        }

        Widgets.Preview.get_instance ().update_html_view ();

        File file;
        if (file_path == null) {
            file = get_pdf_from_user ();
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

        var psize = new Gtk.PaperSize(Gtk.PAPER_NAME_A4);
		var psetup = new Gtk.PageSetup();
		psetup.set_top_margin (0.75, Gtk.Unit.INCH);
		psetup.set_bottom_margin (0.75, Gtk.Unit.INCH);
		psetup.set_left_margin (0.75, Gtk.Unit.INCH);
		psetup.set_right_margin (0.75, Gtk.Unit.INCH);
        psetup.set_paper_size(psize);

        psettings[Gtk.PRINT_SETTINGS_OUTPUT_URI] = file.get_uri ();
        op.set_print_settings (psettings);
        op.set_page_setup (psetup);
        op.print ();

        if (type_of_mode == 1) {
            Quilter.Application.gsettings.set_string("visual-mode", "dark");
            type_of_mode = 0;
        } else if (type_of_mode == 2) {
            Quilter.Application.gsettings.set_string("visual-mode", "sepia");
            type_of_mode = 0;
        }

        return file;
    }

    public static void write_file (File file, string contents, bool overwrite = false) throws Error {
        if (file.query_exists () && overwrite) {
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

    public static File? get_pdf_from_user () {
        File? result = null;

        string title = "";
        Gtk.FileChooserAction chooser_action = Gtk.FileChooserAction.SAVE;
        string accept_button_label = "";
        List<Gtk.FileFilter> filters = new List<Gtk.FileFilter> ();

        title =  _("Select Destination PDF File");
        chooser_action = Gtk.FileChooserAction.SAVE;
        accept_button_label = _("Save");

        var pdf_filter = new Gtk.FileFilter ();
        pdf_filter.set_filter_name (_("PDF File"));

        pdf_filter.add_mime_type ("application/pdf");
        pdf_filter.add_pattern ("*.pdf");

        filters.append (pdf_filter);

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


        dialog.add_filter (pdf_filter);
        dialog.add_filter (all_filter);


        result = dialog.get_file ();

        dialog.close ();

        return result;
    }

    public static File? get_html_from_user () {
        Widgets.Preview.get_instance ().update_html_view ();

        var dialog = new Gtk.FileChooserNative (
            _("Select Destination HTML File"),
            window,
            Gtk.FileChooserAction.SAVE,
            _("Save"),
            _("Cancel")
        );

        var html_filter = new Gtk.FileFilter ();
        html_filter.set_filter_name (_("HTML File"));
        html_filter.add_mime_type ("text/html");
        html_filter.add_pattern ("*.html");
        dialog.add_filter (html_filter);

        var all_filter = new Gtk.FileFilter ();
        all_filter.set_filter_name (_("All Files"));
        all_filter.add_pattern ("*");
        dialog.add_filter (all_filter);

        int response = Gtk.ResponseType.CANCEL;
        File? file = null;
        dialog.response.connect ((res) => {
            response = res;

            if (response == Gtk.ResponseType.ACCEPT) {
                file = dialog.get_file ();
                dialog.destroy ();
            }
        });
        dialog.show ();

        return file;
    }
}
