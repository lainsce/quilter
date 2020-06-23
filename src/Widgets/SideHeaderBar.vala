/*
* Copyright (c) 2017-2020 Lains
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
namespace Quilter.Widgets {
    public class SideHeaderbar : Gtk.Revealer {
        public MainWindow win;
        public Hdy.ViewSwitcher stackswitcher;
        public Hdy.HeaderBar header;

        public SideHeaderbar (MainWindow win) {
            this.win = win;

            header = new Hdy.HeaderBar ();
            header.show_close_button = true;

            stackswitcher = new Hdy.ViewSwitcher ();
            stackswitcher.policy = Hdy.ViewSwitcherPolicy.NARROW;

            header.set_size_request (300,54);
            header.set_custom_title (stackswitcher);
            header.has_subtitle = false;
            header.set_title (null);

            var this_context = header.get_style_context ();
            this_context.add_class (Gtk.STYLE_CLASS_FLAT);
            this_context.add_class ("quilter-toolbar");
            this_context.add_class ("quilter-toolbar-side");
            this_context.remove_class ("titlebar");

            this.add (header);
            this.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
            this.reveal_child = Quilter.Application.gsettings.get_boolean ("sidebar");
        }
    }
}
