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
    public Gtk.FileChooserNative create_file_chooser (string title, Gtk.FileChooserAction action, Gtk.Window? parent = null) {
        var chooser = new Gtk.FileChooserNative (title, parent, action, null, null);
        chooser.set_modal (true);
        var filter1 = new Gtk.FileFilter ();
        filter1.set_filter_name (_("Markdown files"));
        filter1.add_pattern ("*.md");
        chooser.add_filter (filter1);
        var filter = new Gtk.FileFilter ();
        filter.set_filter_name (_("All files"));
        filter.add_pattern ("*");
        chooser.add_filter (filter);
        chooser.select_multiple = false;
        return chooser;
    }

    public static async int run_file_chooser_async (Gtk.FileChooserNative chooser) {
        var loop = new MainLoop ();
        int response = Gtk.ResponseType.CANCEL;

        chooser.response.connect ((res) => {
            response = res;
            loop.quit ();
        });

        chooser.show ();
        // Block this async function with a nested loop until the user responds.
        // This keeps the UI responsive and avoids returning prematurely.
        loop.run ();

        return response;
    }

    // Note: Deprecated MessageDialog wrappers were removed.
}
