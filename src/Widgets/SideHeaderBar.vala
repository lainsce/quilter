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
        private Gtk.Button new_button;
        public signal void create_new ();

        public SideHeaderbar (MainWindow win) {
            this.win = win;

            stackswitcher = new Hdy.ViewSwitcher ();

            header = new Hdy.HeaderBar ();
            header.set_size_request (200,46);
            header.set_custom_title (stackswitcher);
            header.set_show_close_button (true);
            header.has_subtitle = false;
            header.set_title (null);
            header.set_decoration_layout ("close:");

            new_button = new Gtk.Button ();
            new_button.set_image (new Gtk.Image.from_icon_name ("document-new-symbolic", Gtk.IconSize.BUTTON));
            new_button.has_tooltip = true;
            new_button.tooltip_markup = Granite.markup_accel_tooltip (
                {"<Ctrl>n"},
                _("New file")
            );

            new_button.clicked.connect (() => create_new ());

            header.pack_end (new_button);

            var header_context = header.get_style_context ();
            header_context.add_class (Gtk.STYLE_CLASS_FLAT);
            header_context.add_class ("quilter-toolbar");
            header_context.add_class ("quilter-toolbar-side");
            header_context.add_class ("titlebar");

            this.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
            this.add (header);
            this.reveal_child = true;
            this.visible = true;
        }
    }
}
