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
    public class Cheatsheet : Gtk.Dialog {
        public Cheatsheet () {
            create_layout ();
        }

        construct {
            title = _("Cheatsheet");
            set_default_size (600, 600);
            resizable = false;
            deletable = false;
        }

        private void create_layout () {
            var main_grid = new Gtk.Grid ();
            main_grid.row_spacing = 6;
            main_grid.column_spacing = 12;
            main_grid.margin = 12;

            var title_header = new TitleHeader (_("Markdown Cheatsheet"));

            var header_header = new Header (_("Header"));
            var header_one_label = new Label (_("# Header 1"));
            var header_two_label = new Label (_("## Header 2"));
            var header_three_label = new Label (_("### Header 3"));
            var header_four_label = new Label (_("#### Header 4"));

            var font_header = new Header (_("Special Text"));
            var bold_font_label = new Label (_("** Bold text **"));
            var emph_font_label = new Label (_("* Emphasized text *"));
            var code_font_label = new Label (_("` Code text `"));
            var quote_font_label = new Label (_("> Quoting text"));

            var close_button = new Gtk.Button.with_label (_("Close"));
            close_button.clicked.connect (() => {this.destroy ();});
            var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
            button_box.set_layout (Gtk.ButtonBoxStyle.END);
            button_box.pack_end (close_button);
            button_box.margin = 12;
            button_box.margin_bottom = 0;

            main_grid.attach (title_header, 0, 0, 1, 1);
            main_grid.attach (header_header, 0, 1, 5, 1);
            main_grid.attach (header_one_label, 0, 2, 3, 1);
            main_grid.attach (header_two_label, 0, 3, 3, 1);
            main_grid.attach (header_three_label, 0, 4, 3, 1);
            main_grid.attach (header_four_label, 0, 5, 3, 1);
            main_grid.attach (font_header, 0, 6, 5, 1);
            main_grid.attach (bold_font_label , 0, 7, 3, 1);
            main_grid.attach (emph_font_label , 0, 8, 3, 1);
            main_grid.attach (code_font_label , 0, 9, 3, 1);
            main_grid.attach (quote_font_label , 0, 10, 3, 1);
            main_grid.attach (button_box, 0, 11, 5, 1);

            ((Gtk.Container) get_content_area ()).add (main_grid);
        }

        private class TitleHeader : Gtk.Label {
            public TitleHeader (string text) {
                label = text;
                this.margin_bottom = 6;
                get_style_context ().add_class ("h3");
                halign = Gtk.Align.START;
            }
        }

        private class Header : Gtk.Label {
            public Header (string text) {
                label = text;
                get_style_context ().add_class ("h4");
                halign = Gtk.Align.START;
            }
        }

        private class Label : Gtk.Label {
            public Label (string text) {
                label = text;
                halign = Gtk.Align.END;
                margin_start = 12;
            }
        }
    }
}
