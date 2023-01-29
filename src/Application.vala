/*
* Copyright (c) 2017-2021 Lains
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
        private static bool open_view = false;
        private static bool print_ver = false;
        private static string _cwd;
        public Widgets.Headerbar toolbar;
        public static GLib.Settings gsettings;
        public static MainWindow win = null;
        public static string[] supported_mimetypes;

        static construct {
            gsettings = new GLib.Settings ("io.github.lainsce.Quilter");
        }

        construct {
            flags |= ApplicationFlags.HANDLES_COMMAND_LINE;
            flags |= ApplicationFlags.HANDLES_OPEN;
            application_id = Config.APP_ID;

            supported_mimetypes = {"text/markdown"};
        }

        protected override void activate () {
            new_win ();
        }

        public static int main (string[] args) {
            Intl.setlocale (LocaleCategory.ALL, "");

            var app = new Quilter.Application ();
            return app.run (args);
        }

        public void new_win () {
            if (win != null) {
                win.present ();
                return;
            }
            win = new MainWindow (this);
            win.show ();
        }

        protected override int command_line (ApplicationCommandLine command_line) {
            string[] args = command_line.get_arguments ();
            var context = new OptionContext ("File");
            context.add_main_entries (entries, Config.APP_ID);
            int unclaimed_args;

            try {
                unowned string[] tmp = args;
                context.parse (ref tmp);
                unclaimed_args = tmp.length - 1;
            } catch (Error e) {
                warning ("ERROR: " + e.message + "\n");
                return 0;
            }

            if (print_ver) {
                stdout.printf ("Quilter %s - Copyright 2017-2021 Lains\n".printf(Config.VERSION));
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
                                    reason = ("Does not have the necessary permissions.");
                                } else if (e is FileError.NOENT) {
                                    reason = ("File path provided is not valid.");
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
                        dialog.show ();
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

        const OptionEntry[] entries = {
            { "about", 'v', 0, OptionArg.NONE, out print_ver, ("Open About Dialog"), null },
            { "version", 'v', 0, OptionArg.NONE, out print_ver, ("Print version and copyright info and exit"), null },
            { "view", 'V', 0, OptionArg.NONE, out open_view, ("Open document for preview"), null },
            { null }
        };
    }
}
