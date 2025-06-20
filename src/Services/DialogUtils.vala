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
        yield run_async (loop);

        return response;
    }

    private static async void run_async (MainLoop loop) {
        Idle.add (() => {
            loop.run ();
            return false;
        });
        yield;
    }

    public class Dialog : He.Bin {
        public MainWindow win { get; construct; }
        public Gtk.MessageDialog dialog;

        public Dialog (MainWindow win) {
            Object (win: win);

            dialog = new Gtk.MessageDialog (
                                            win,
                                            Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                            Gtk.MessageType.QUESTION,
                                            Gtk.ButtonsType.NONE,
                                            _("Save Open File?")
            );

            dialog.secondary_text = _("There are unsaved changes to the file, any changes will be lost if not saved.");

            dialog.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
            dialog.add_button (_("Close Without Saving"), Gtk.ResponseType.REJECT);
            dialog.add_button (_("Save"), Gtk.ResponseType.ACCEPT);

            dialog.set_default_response (Gtk.ResponseType.ACCEPT);

            this.child = dialog;
        }
    }

    public class Dialog2 : He.Bin {
        public MainWindow win { get; construct; }
        public Gtk.MessageDialog dialog;

        public Dialog2 (MainWindow win) {
            Object (win: win);

            dialog = new Gtk.MessageDialog (
                                            win,
                                            Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                            Gtk.MessageType.QUESTION,
                                            Gtk.ButtonsType.NONE,
                                            _("Remove File From Sidebar?")
            );

            dialog.secondary_text = _("By removing this file from the Sidebar, any changes will be lost if not saved.");

            dialog.add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
            dialog.add_button (_("Remove Without Saving"), Gtk.ResponseType.REJECT);
            dialog.add_button (_("Save"), Gtk.ResponseType.ACCEPT);

            dialog.set_default_response (Gtk.ResponseType.ACCEPT);

            this.child = dialog;
        }
    }
}
