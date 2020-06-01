/*
 * Copyright (C) 2017-2020 Lains
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
    public Gtk.FileChooserDialog create_file_chooser (string title,
            Gtk.FileChooserAction action) {
        var chooser = new Gtk.FileChooserDialog (title, null, action);
        chooser.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        if (action == Gtk.FileChooserAction.OPEN) {
            chooser.add_button (_("Open"), Gtk.ResponseType.ACCEPT);
        } else if (action == Gtk.FileChooserAction.SAVE) {
            chooser.add_button (_("Save"), Gtk.ResponseType.ACCEPT);
            chooser.set_do_overwrite_confirmation (true);
        }
        var filter1 = new Gtk.FileFilter ();
        filter1.set_filter_name (_("Markdown files"));
        filter1.add_pattern ("*.md");
        chooser.add_filter (filter1);
        var filter = new Gtk.FileFilter ();
        filter.set_filter_name (_("All files"));
        filter.add_pattern ("*");
        chooser.add_filter (filter);
        return chooser;
    }

    public class Dialog : Granite.MessageDialog {
        public MainWindow win;
        public Dialog () {
            Object (
                image_icon: new ThemedIcon ("dialog-information"),
                primary_text: _("Save Open File?"),
                secondary_text: _("There are unsaved changes to the file. If you don't save, changes will be lost forever.")
            );
        }
        construct {
            var save = add_button (_("Save"), Gtk.ResponseType.OK);
            var cws = add_button (_("Close Without Saving"), Gtk.ResponseType.NO);
            var cancel = add_button (_("Cancel"), Gtk.ResponseType.CANCEL) as Gtk.Button;
            cancel.clicked.connect (() => { destroy (); });
        }
    }

    public class Dialog2 : Granite.MessageDialog {
        public MainWindow win;
        public Dialog2 () {
            Object (
                image_icon: new ThemedIcon ("dialog-information"),
                primary_text: _("Remove File from Sidebar?"),
                secondary_text: _("By removing this file from the Sidebar, you will lose any changes made if not saved. Otherwise, it will only be removed.")
            );
        }
        construct {
            var save = add_button (_("Save"), Gtk.ResponseType.OK);
            var cws = add_button (_("Remove Without Saving"), Gtk.ResponseType.NO);
            var cancel = add_button (_("Cancel"), Gtk.ResponseType.CANCEL) as Gtk.Button;
            cancel.clicked.connect (() => { destroy (); });
        }
    }
}
