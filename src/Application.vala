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
    public class Application : Granite.Application {
        private static bool print_version = false;
        private static bool show_about_dialog = false;

        private static string _cwd;

        construct {
            flags |= ApplicationFlags.HANDLES_COMMAND_LINE;
            flags |= ApplicationFlags.HANDLES_OPEN;
            application_id = "com.github.lainsce.quilter";
            program_name = "Quilter";
            app_years = "2017";
            exec_name = "com.github.lainsce.quilter";
            app_launcher = "com.github.lainsce.quilter";
            build_version = "1.1.4";
            app_icon = "com.github.lainsce.quilter";
            main_url = "https://github.com/lainsce/quilter/";
            bug_url = "https://github.com/lainsce/quilter/issues";
            help_url = "https://github.com/lainsce/quilter/";
            about_authors = {"Lains <lainsce@airmail.cc>", null};
            about_license_type = Gtk.License.GPL_3_0;
        }

        protected override void activate () {
            if (get_windows () != null) {
                get_windows ().data.present (); // present window if app is already running
                return;
            }

            var window = new MainWindow (this);

            var settings = AppSettings.get_default ();
            int x = settings.window_x;
            int y = settings.window_y;
            int h = settings.window_height;
            int w = settings.window_width;

            if (x != -1 && y != -1) {
                window.move (x, y);
            }
            if (w != 0 && h != 0) {
                window.resize (w, h);
            }
            if (settings.window_maximized) {
                window.maximize ();
            }

            window.show_all ();
        }

        public static int main (string[] args) {
            var app = new Quilter.Application ();
            return app.run (args);
        }

        public void new_window () {
            new MainWindow (this).show_all ();
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
                stdout.printf ("com.github.lainsce.quilter: ERROR: " + e.message + "\n");
                return 0;
            }

            if (print_version) {
                stdout.printf ("Quilter %s\n", this.build_version);
                stdout.printf ("Copyright 2017 Lains\n");
                return 0;
            } else {
                new_window ();
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
                                    reason = _("Maybe you do not have the necessary permissions.");
                                } else if (e is FileError.NOENT) {
                                    reason = _("Maybe the file path provided is not valid.");
                                } else if (e is FileError.ROFS) {
                                    reason = _("The location is read-only.");
                                } else if (e is FileError.NOTDIR) {
                                    reason = _("The parent directory doesn't exist.");
                                } else {
                                    // Otherwise we simple use the error notification from glib
                                    msg = e.message;
                                }

                                if (reason.length > 0) {
                                    msg = _("File \"%s\" cannot be created.\n%s").printf ("<b>%s</b>".printf (file.get_path ()), reason);
                                }

                                // Escape to the outer catch clause, and overwrite
                                // the weird glib's standard errors.
                                throw new Error (e.domain, e.code, msg);
                            }
                        }

                        var info = file.query_info ("standard::*", FileQueryInfoFlags.NONE, null);
                        string err_msg = _("File \"%s\" cannot be opened.\n%s");
                        string reason = "";

                        switch (info.get_file_type ()) {
                            case FileType.REGULAR:
                            case FileType.SYMBOLIC_LINK:
                                files += file;
                                break;
                            case FileType.MOUNTABLE:
                                reason = _("It is a mountable location.");
                                break;
                            case FileType.DIRECTORY:
                                reason = _("It is a directory.");
                                break;
                            case FileType.SPECIAL:
                                reason = _("It is a \"special\" file such as a socket,\n fifo, block device, or character device.");
                                break;
                            default:
                                reason = _("It is an \"unknown\" file type.");
                                break;
                        }

                        if (reason.length > 0) {
                            msg = err_msg.printf ("<b>%s</b>".printf (file.get_path ()), reason);
                        }

                    } catch (Error e) {
                        warning (e.message);
                    }
                }

                if (files.length > 0)
                    open (files, "");
            }

            return 0;
        }

        protected override void open (File[] files, string hint) {
            foreach (var file in files) {
                string text;
                try {
                    FileUtils.get_contents (file.get_path (), out text);
                } catch (Error e) {
                    print ("Error: %s", e.message);
                }
                Widgets.SourceView.buffer.text = text;;
                //MainWindow.subtitle = file.get_path ();
            }
        }

        const OptionEntry[] entries = {
            { "version", 'v', 0, OptionArg.NONE, out print_version, N_("Print version info and exit"), null },
            { "about", 'a', 0, OptionArg.NONE, out show_about_dialog, N_("Show about dialog"), null },
            { null }
        };
    }
}
