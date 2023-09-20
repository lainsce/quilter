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
namespace Quilter.Services.DialogUtils {
    public Gtk.FileChooserNative create_file_chooser (string title, Gtk.FileChooserAction action) {
        var chooser = new Gtk.FileChooserNative (title, null, action, null, null);
        var filter1 = new Gtk.FileFilter ();
        filter1.set_filter_name (_("Markdown files"));
        filter1.add_pattern ("*.md");
        chooser.add_filter (filter1);
        var filter = new Gtk.FileFilter ();
        filter.set_filter_name (_("All files"));
        filter.add_pattern ("*");
        chooser.add_filter (filter);
        chooser.select_multiple = true;
        return chooser;
    }

    public class Dialog : Adw.MessageDialog {
        public MainWindow win {get; construct;}
        public Dialog (MainWindow win) {
            Object (
                heading: _("Save Open File?"),
                body: _("There are unsaved changes to the file, any changes will be lost if not saved.")
            );

            this.add_response ("cancel", _("Cancel"));
            this.add_response ("no", _("Close Without Saving"));
            this.add_response ("ok", _("Save"));
            this.set_default_response ("ok");
            this.set_close_response ("cancel");
        }
    }

    public class Dialog2 : Adw.MessageDialog {
        public MainWindow win {get; construct;}
        public Dialog2 (MainWindow win) {
            Object (
                heading: _("Remove File From Sidebar?"),
                body: _("By removing this file from the Sidebar, any changes will be lost if not saved.")
            );

            this.add_response ("cancel", _("Cancel"));
            this.add_response ("no", _("Remove Without Saving"));
            this.add_response ("ok", _("Save"));
            this.set_default_response ("ok");
            this.set_close_response ("cancel");
        }
    }
}
