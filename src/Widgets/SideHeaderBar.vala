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
namespace Quilter.Widgets {
    public class SideHeaderbar : Gtk.Revealer {
        private Gtk.Button new_button;
        private Gtk.Button open_button;
        private Gtk.Button save_as_button;
        private Gtk.Button save_button;
        public EditView sourceview;
        public MainWindow win;
        public Preview preview;
        public Hdy.HeaderBar header;
        public signal void create_new ();
        public signal void open ();
        public signal void save ();
        public signal void save_as ();

        public SideHeaderbar (MainWindow win) {
            this.win = win;

            header = new Hdy.HeaderBar ();
            var header_context = header.get_style_context ();
            header_context.add_class (Gtk.STYLE_CLASS_FLAT);
            header_context.add_class ("quilter-toolbar");
            header_context.add_class ("titlebar");

            build_ui ();
            icons_toolbar ();
        }

        private void build_ui () {
            new_button = new Gtk.Button ();
            new_button.has_tooltip = true;
            new_button.tooltip_markup = Granite.markup_accel_tooltip (
                {"<Ctrl>n"},
                _("New file")
            );

            new_button.clicked.connect (() => create_new ());

            save_as_button = new Gtk.Button ();
            save_as_button.has_tooltip = true;
            save_as_button.tooltip_markup = Granite.markup_accel_tooltip (
                {"<Ctrl><Shift>s"},
                _("Save as…")
            );

            save_as_button.clicked.connect (() => save_as ());

            save_button = new Gtk.Button ();
            save_button.has_tooltip = true;
            save_button.tooltip_markup = Granite.markup_accel_tooltip (
                {"<Ctrl>s"},
                _("Save file")
            );

            save_button.clicked.connect (() => save ());

            open_button = new Gtk.Button ();
			open_button.has_tooltip = true;
            open_button.tooltip_markup = Granite.markup_accel_tooltip (
                {"<Ctrl>o"},
                _("Open…")
            );

            open_button.clicked.connect (() => open ());

            header.pack_start (new_button);
            header.pack_start (open_button);
            header.pack_start (save_as_button);

            // This makes the save button show or not, and it's necessary as-is.
            if (Quilter.Application.gsettings.get_boolean("autosave")) {
                save_button.visible = false;
                Quilter.Application.gsettings.set_boolean("autosave", true);
            } else {
                header.pack_start (save_button);
                save_button.visible = true;
                Quilter.Application.gsettings.set_boolean("autosave", false);
            }

            header.set_show_close_button (true);
            header.has_subtitle = false;
            header.set_title (null);
            header.set_decoration_layout ("close:");
            header.set_size_request (250,-1);

            this.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
            this.add (header);
            this.reveal_child = Quilter.Application.gsettings.get_boolean("sidebar-title");
        }

        public void icons_toolbar () {
            new_button.set_image (new Gtk.Image.from_icon_name ("document-new-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
            save_button.set_image (new Gtk.Image.from_icon_name ("document-save-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
            save_as_button.set_image (new Gtk.Image.from_icon_name ("document-save-as-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
            open_button.set_image (new Gtk.Image.from_icon_name ("document-open-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
        }
    }
}
