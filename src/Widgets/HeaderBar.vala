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
namespace Quilter.Widgets {
    [GtkTemplate (ui = "/io/github/lainsce/Quilter/headerbar.ui")]
    public class Headerbar : He.Bin {
         [GtkChild]
         public unowned He.AppBar headerbar;
         [GtkChild]
         public unowned Gtk.Box save_grid;
         [GtkChild]
         public unowned Gtk.Button new_button;
         [GtkChild]
         public unowned Gtk.Button save_button;
         [GtkChild]
         public unowned Gtk.MenuButton doc_button;
         [GtkChild]
         public unowned Gtk.Button open_button;
         [GtkChild]
         public unowned Gtk.ToggleButton preview_toggle_button;

         public unowned MainWindow win { get; construct; }

         public signal void create_new ();
         public signal void open ();
         public signal void save ();
         public signal void save_as ();
         public signal void toggle_preview ();
         public signal void preview_toggled (bool is_active);

         public Headerbar (MainWindow window) {
             Object (win: window);
         }

         construct {
             build_ui ();
         }

         private void build_ui () {
             new_button.clicked.connect (() => create_new ());
             open_button.clicked.connect (() => open ());
             save_button.clicked.connect (() => save ());

             preview_toggle_button.icon_name = "view-paged-symbolic";
             preview_toggle_button.tooltip_text = _("Toggle Preview");
             preview_toggle_button.toggled.connect (() => {
                 preview_toggled (preview_toggle_button.active);
             });
         }

         public void update_preview_toggle_state (bool is_active) {
             preview_toggle_button.active = is_active;
         }
     }
 }
