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
*/
namespace Quilter {
    [GtkTemplate (ui = "/io/github/lainsce/Quilter/headerbar.ui")]
    public class Widgets.Headerbar : Adw.Bin {
        public Widgets.HeaderBarButton samenu_button;
        public MainWindow win;
        public Preview preview;
        public EditView editor;

        public signal void create_new ();
        public signal void open ();
        public signal void save ();
        public signal void save_as ();

        [GtkChild]
        public unowned Gtk.HeaderBar headerbar;

        [GtkChild]
        public unowned Gtk.Grid top_grid;
        [GtkChild]
        public unowned Gtk.Box save_grid;
        [GtkChild]
        public unowned Gtk.Box view_menu;

        [GtkChild]
        public unowned Gtk.Button new_button;
        [GtkChild]
        public unowned Gtk.Button save_button;
        [GtkChild]
        public unowned Gtk.MenuButton save_as_button;
        [GtkChild]
        public unowned Gtk.Button open_button;

        [GtkChild]
        public unowned Gtk.CheckButton color_button_light;
        [GtkChild]
        public unowned Gtk.CheckButton color_button_sepia;
        [GtkChild]
        public unowned Gtk.CheckButton color_button_dark;

        [GtkChild]
        public unowned Gtk.ToggleButton sidebar_toggler;

        public MainWindow window;

        public Headerbar (MainWindow win) {
            this.win = win;

            build_ui ();
        }

        private void build_ui () {
            new_button.clicked.connect (() => create_new ());
            open_button.clicked.connect (() => open ());
            save_button.clicked.connect (() => save ());

            sidebar_toggler.icon_name = ("sidebar-symbolic");
            Quilter.Application.gsettings.bind ("sidebar", sidebar_toggler, "active", GLib.SettingsBindFlags.DEFAULT);

            var mode_type = Quilter.Application.gsettings.get_string("visual-mode");

            switch (mode_type) {
                case "sepia":
                    color_button_sepia.set_active (true);
                    break;
                case "dark":
                    color_button_dark.set_active (true);
                    break;
                case "light":
                default:
                    color_button_light.set_active (true);
                    break;
            }

            color_button_dark.toggled.connect (() => {
                Quilter.Application.gsettings.set_string("visual-mode", "dark");
            });

            color_button_sepia.toggled.connect (() => {
                Quilter.Application.gsettings.set_string("visual-mode", "sepia");
            });

            color_button_light.toggled.connect (() => {
                Quilter.Application.gsettings.set_string("visual-mode", "light");
            });

            var rename_entry = new Gtk.Entry ();
            rename_entry.margin_bottom = 6;

            var rename_button = new Gtk.Button ();
            rename_button.label = (_("Rename"));
            rename_button.get_style_context ().add_class ("suggested-action");

            rename_button.clicked.connect (() => {
                try {
                    var new_filename = rename_entry.get_text ();
                    Gtk.ListBoxRow child = win.sidebar.get_selected_row ();
                    if (child != null) {
                        var path_new = ((Widgets.SideBarBox)child).path.replace (Path.get_basename(((Widgets.SideBarBox)child).path), new_filename);
                        Services.FileManager.save_file (path_new, win.edit_view_content.text);

                        ((Widgets.SideBarBox)child).path = path_new;
                        samenu_button.title = Path.get_basename(path_new);
                        samenu_button.subtitle = path_new.replace(GLib.Environment.get_home_dir (), "~");
                    }

                    rename_entry.set_text ("");
                } catch (Error e) {
                    warning ("Unexpected error during rename: " + e.message);
                }
            });

            var rename_label = new Gtk.Label (_("Rename File:"));
            rename_label.add_css_class ("dim-label");

            var samenu_grid = new Gtk.Grid ();
            samenu_grid.margin_top = samenu_grid.margin_end = samenu_grid.margin_bottom = samenu_grid.margin_start = 12;
            samenu_grid.column_homogeneous = true;
            samenu_grid.row_spacing = 6;
            samenu_grid.attach (rename_label, 0, 0);
            samenu_grid.attach (rename_entry, 0, 1, 2, 1);
            samenu_grid.attach (rename_button, 1, 2);

            var samenu = new Gtk.Popover ();
            samenu.set_child (samenu_grid);

            samenu_button = new Widgets.HeaderBarButton ();
            samenu_button.has_tooltip = true;
            samenu_button.tooltip_text = (_("Rename File"));
            samenu_button.menu.popover = samenu;

            rename_entry.set_placeholder_text (_("new_name.md"));

            headerbar.set_title_widget (samenu_button);

            var view_mode = new Gtk.ToggleButton ();
            view_mode.action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_TOGGLE_VIEW;
            view_mode.label = _("Toggle View");
            view_mode.add_css_class ("flat");

            top_grid.attach (view_mode, 0, 9, 4, 1);

            Quilter.Application.gsettings.changed.connect (() => {
                if (Quilter.Application.gsettings.get_string("preview-type") == "full") {
                    view_mode.visible = true;
                } else {
                    view_mode.visible = false;
                }
            });
        }
    }
}
