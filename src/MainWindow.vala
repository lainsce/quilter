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
*/
using Granite.Widgets;

namespace Quilter {
    public class MainWindow : Gtk.Window {
        public Gtk.ScrolledWindow scroll;

        public Widgets.Toolbar toolbar;
        public Widgets.SourceView view;

        public MainWindow (Gtk.Application application) {
            Object (application: application,
                    resizable: true,
                    title: _("Quilter"),
                    height_request: 800,
                    width_request: 920);

            Granite.Widgets.Utils.set_theming_for_screen (
                this.get_screen (),
                Stylesheet.PAGE,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        }

        construct {
            var context = this.get_style_context ();
            set_hide_titlebar_when_maximized (false);
            context.add_class ("quilter-window");
            this.toolbar = new Widgets.Toolbar ();

            this.window_position = Gtk.WindowPosition.CENTER;
            this.set_titlebar (toolbar);

            scroll = new Gtk.ScrolledWindow (null, null);
            this.add (scroll);
            this.view = new Widgets.SourceView ();
            this.view.monospace = true;
            scroll.add (view);

            var settings = AppSettings.get_default ();

            int x = settings.window_x;
            int y = settings.window_y;

            int h = settings.window_height;
            int w = settings.window_width;

            if (x != -1 && y != -1) {
                move (x, y);
            }

            if (w != 0 && h != 0) {
                resize (w, h);
            }

            if (settings.window_maximized) {
                maximize ();
            }

            Utils.FileUtils.load_tmp_file ();
        }

        public override bool delete_event (Gdk.EventAny event) {
            int x, y, w, h;
            get_position (out x, out y);
            get_size (out w, out h);

            var settings = AppSettings.get_default ();
            settings.window_x = x;
            settings.window_y = y;
            settings.window_width = w;
            settings.window_height = h;
            settings.window_maximized = is_maximized;

            Utils.FileUtils.save_tmp_file ();
            return false;
        }
    }
}
