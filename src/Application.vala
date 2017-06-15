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

        construct {
            flags |= ApplicationFlags.HANDLES_COMMAND_LINE;
            application_id = "com.github.lainsce.quilter";
            program_name = "Quilter";
            app_years = "2017";
            exec_name = "com.github.lainsce.quilter";
            app_launcher = "com.github.lainsce.quilter";
            build_version = "1.0.9";
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

            try {
                unowned string[] tmp = args;
                context.parse (ref tmp);
            } catch (Error e) {
                stdout.printf ("com.github.lainsce.quilter: ERROR: " + e.message + "\n");
                return 0;
            }

            if (print_version) {
                stdout.printf ("Quilter %s\n", this.build_version);
                stdout.printf ("Copyright 2017 Lains\n");
            } else {
                new_window ();
            }
            return 0;
        }

        const OptionEntry[] entries = {
            { "version", 'v', 0, OptionArg.NONE, out print_version, N_("Print version info and exit"), null },
            { "about", 'a', 0, OptionArg.NONE, out show_about_dialog, N_("Show about dialog"), null },
            { null }
        };
    }
}
