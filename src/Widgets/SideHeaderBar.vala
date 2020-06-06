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
    public class SideHeaderbar : Hdy.HeaderBar {
        public MainWindow win;
        public Hdy.ViewSwitcher stackswitcher;
        private Gtk.Button new_button;
        public signal void create_new ();

        public SideHeaderbar (MainWindow win) {
            this.win = win;
            show_close_button = true;

            stackswitcher = new Hdy.ViewSwitcher ();
            stackswitcher.policy = Hdy.ViewSwitcherPolicy.NARROW;

            this.set_size_request (200,46);
            this.set_custom_title (stackswitcher);
            this.has_subtitle = false;
            this.set_title (null);

            new_button = new Gtk.Button ();
            new_button.set_image (new Gtk.Image.from_icon_name ("document-new-symbolic", Gtk.IconSize.BUTTON));
            new_button.has_tooltip = true;
            new_button.tooltip_markup = Granite.markup_accel_tooltip (
                {"<Ctrl>n"},
                _("New file")
            );

            new_button.clicked.connect (() => create_new ());

            this.pack_end (new_button);

            var this_context = this.get_style_context ();
            this_context.add_class (Gtk.STYLE_CLASS_FLAT);
            this_context.add_class ("quilter-toolbar");
            this_context.add_class ("quilter-toolbar-side");
        }
    }
}
