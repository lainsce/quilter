/*
 * Copyright (C) 2017-2021 Lains
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
[GtkTemplate (ui = "/io/github/lainsce/Quilter/header_button.ui")]
public class Quilter.Widgets.HeaderBarButton : He.Bin {
    public signal void clicked ();
    public signal void rename_requested (string new_name);

    [GtkChild]
    public unowned Gtk.MenuButton menu;
    [GtkChild]
    public unowned Gtk.ToggleButton sidebar_toggle_button;

    [GtkChild]
    public unowned Gtk.Label titlel;

    private string? _title;
    public string? title {
        owned get {
            return _title;
        }
        set {
            _title = value;
            titlel.label = value;
        }
    }

    private Gtk.Entry rename_entry;
    private Gtk.Button rename_button;

    construct {
        var popover = menu.popover;
        if (popover == null) {
            popover = new Gtk.Popover ();
            menu.popover = popover;
        }

        menu.get_first_child ().remove_css_class ("toggle");
        menu.add_css_class ("rename-button");

        sidebar_toggle_button.remove_css_class ("toggle");
        sidebar_toggle_button.remove_css_class ("image-button");

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        box.margin_start = box.margin_end = box.margin_top = box.margin_bottom = 12;

        rename_entry = new Gtk.Entry ();
        rename_entry.placeholder_text = _("Enter new file name");

        rename_button = new Gtk.Button.with_label (_("Rename"));
        rename_button.add_css_class ("suggested-action");

        box.append (rename_entry);
        box.append (rename_button);

        popover.set_child (box);

        rename_button.clicked.connect (() => {
            string new_name = rename_entry.text.strip ();
            if (new_name != "") {
                rename_requested (new_name);
                popover.popdown ();
                rename_entry.text = "";
            }
        });
    }

    public void update_title (string new_title) {
        titlel.label = new_title;
    }
}