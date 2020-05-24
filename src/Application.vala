/*
* Copyright (c) 2017 Lains
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
*/
namespace Quilter {
    public class Application : Gtk.Application {
        public static GLib.Settings gsettings;
        public static Granite.Settings grsettings;
        private static bool print_ver = false;
        private static bool open_view = false;
        private static string _cwd;

        public static MainWindow win = null;
        public Widgets.Headerbar toolbar;
        public static string[] supported_mimetypes;

        static construct {
            gsettings = new GLib.Settings ("com.github.lainsce.quilter");
        }

        construct {
            flags |= ApplicationFlags.HANDLES_COMMAND_LINE;
            flags |= ApplicationFlags.HANDLES_OPEN;
            application_id = "com.github.lainsce.quilter";

            supported_mimetypes = {"text/markdown"};
            register_default_handler ();

            grsettings = Granite.Settings.get_default ();
        }

        protected override void activate () {
            new_win ();
        }

        public static int main (string[] args) {
            Intl.setlocale (LocaleCategory.ALL, Intl.get_language_names ()[0]);

            var app = new Quilter.Application ();
            return app.run (args);
        }

        public void new_win () {
            if (win != null) {
                win.present ();
                return;
            }
            win = new MainWindow (this);

            if (gsettings.get_string("preview-type") == "full") {
                if (open_view) {
                    win.stack.set_visible_child (win.preview_view);
                    open_view = false;
                } else {
                    win.stack.set_visible_child (win.edit_view);
                }
            }

            win.show_all ();
        }

        protected override int command_line (ApplicationCommandLine command_line) {
            string[] args = command_line.get_arguments ();
            var context = new OptionContext ("File");
            context.add_main_entries (entries, "com.github.lainsce.quilter");
            context.add_group (Gtk.get_option_group (true));
            int unclaimed_args;

            try {
                unowned string[] tmp = args;
                context.parse (ref tmp);
                unclaimed_args = tmp.length - 1;
            } catch (Error e) {
                stdout.printf ("ERROR: " + e.message + "\n");
                return 0;
            }

            if (print_ver) {
                stdout.printf ("Quilter - Copyright 2017-2020 Lains\n");
                return 0;
            } else {
                new_win ();
            }

            // Set Current Directory
            Environment.set_current_dir (_cwd);

            if (unclaimed_args > 0) {
                File[] files = new File[unclaimed_args];
                files.length = 0;

                foreach (string arg in args[1:unclaimed_args + 1]) {
                    // We set a message, that later is informed to the user
                    // in a dialog if something noteworthy happens.
                    string msg = "";
                    try {
                        var file = File.new_for_commandline_arg (arg);

                        if (!file.query_exists ()) {
                            try {
                                FileUtils.set_contents (file.get_path (), "");
                            } catch (Error e) {
                                string reason = "";
                                // We list some common errors for quick feedback
                                if (e is FileError.ACCES) {
                                    reason = ("Maybe you do not have the necessary permissions.");
                                } else if (e is FileError.NOENT) {
                                    reason = ("Maybe the file path provided is not valid.");
                                } else if (e is FileError.ROFS) {
                                    reason = ("The location is read-only.");
                                } else if (e is FileError.NOTDIR) {
                                    reason = ("The parent directory doesn't exist.");
                                } else {
                                    // Otherwise we simple use the error notification from glib
                                    msg = e.message;
                                }

                                if (reason.length > 0) {
                                    msg = ("File \"%s\" cannot be created.\n%s").printf ("<b>%s</b>".printf (file.get_path ()), reason);
                                }

                                // Escape to the outer catch clause, and overwrite
                                // the weird glib's standard errors.
                                throw new Error (e.domain, e.code, msg);
                            }
                        }

                        var info = file.query_info ("standard::*", FileQueryInfoFlags.NONE, null);
                        string err_msg = ("File \"%s\" cannot be opened.\n%s");
                        string reason = "";

                        switch (info.get_file_type ()) {
                            case FileType.REGULAR:
                            case FileType.SYMBOLIC_LINK:
                                files += file;
                                break;
                            case FileType.MOUNTABLE:
                                reason = ("It is a mountable location.");
                                break;
                            case FileType.DIRECTORY:
                                reason = ("It is a directory.");
                                break;
                            case FileType.SPECIAL:
                                reason = ("It is a \"special\" file such as a socket,\n fifo, block device, or character device.");
                                break;
                            default:
                                reason = ("It is an \"unknown\" file type.");
                                break;
                        }

                        if (reason.length > 0) {
                            msg = err_msg.printf ("<b>%s</b>".printf (file.get_path ()), reason);
                        }

                    } catch (Error e) {
                        warning (e.message);
                    }

                    // Notify the user that something happened.
                    if (msg.length > 0) {
                        var parent_win = get_last_win () as Gtk.Window;
                        var dialog = new Gtk.MessageDialog.with_markup (parent_win,
                            Gtk.DialogFlags.MODAL,
                            Gtk.MessageType.ERROR,
                            Gtk.ButtonsType.CLOSE,
                            msg);
                        dialog.run ();
                        dialog.destroy ();
                        dialog.close ();
                    }
                }

                if (files.length > 0) {
                    Services.FileManager.open_from_outside (win, files, "");
                } else {
                    open_view = false;
                }
            }

            return 0;
        }

        public MainWindow? get_last_win () {
            unowned List<Gtk.Window> wins = get_windows ();
            return wins.length () > 0 ? wins.last ().data as MainWindow : null;
        }

        private static void register_default_handler () {
            var app_info = new DesktopAppInfo ("com.github.lainsce.quilter.desktop");
            if (app_info == null) {
                warning ("AppInfo object not found for Quilter.");
                return;
            }

            foreach (string mimetype in supported_mimetypes) {
                var handler = AppInfo.get_default_for_type (mimetype, false);
                if (handler == null) {
                    try {
                        debug ("Registering Quilter as the default handler for %s", mimetype);
                        app_info.set_as_default_for_type (mimetype);
                    } catch (Error e) {
                        warning (e.message);
                    }
                } else {
                    unowned string[] types = handler.get_supported_types ();
                    if (types == null || !(mimetype in types)) {
                        try {
                            debug ("Registering Quilter as the default handler for %s", mimetype);
                            app_info.set_as_default_for_type (mimetype);
                        } catch (Error e) {
                            warning (e.message);
                        }
                    }
                }
            }
        }

        const OptionEntry[] entries = {
            { "version", 'v', 0, OptionArg.NONE, out print_ver, ("Print version and copyright info and exit"), null },
            { "view", 'V', 0, OptionArg.NONE, out open_view, ("Open document for preview"), null },
            { null }
        };
    }
}
