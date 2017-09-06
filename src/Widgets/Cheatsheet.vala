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
        private Gtk.Stack main_stack;
        private Gtk.StackSwitcher main_stackswitcher;

        public Cheatsheet () {
            create_layout ();
        }

        construct {
            title = _("Cheatsheet");
            set_default_size (600, 600);
            resizable = false;
            deletable = false;

            main_stack = new Gtk.Stack ();
            main_stackswitcher = new Gtk.StackSwitcher ();
            main_stackswitcher.set_stack (main_stack);
            main_stackswitcher.halign = Gtk.Align.CENTER;
        }

        private void create_layout () {
            this.main_stack.add_titled (get_textstyle_grid (), "textstyle", _("Text Style"));
            this.main_stack.add_titled (get_links_grid (), "links", _("Links & Special"));

            // Close button
            var close_button = new Gtk.Button.with_label (_("Close"));
            close_button.clicked.connect (() => {this.destroy ();});

            var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
            button_box.set_layout (Gtk.ButtonBoxStyle.END);
            button_box.pack_end (close_button);
            button_box.margin = 12;
            button_box.margin_bottom = 0;

            // Pack everything into the dialog
            var main_grid = new Gtk.Grid ();
            main_grid.attach (this.main_stackswitcher, 0, 0, 1, 1);
            main_grid.attach (this.main_stack, 0, 1, 1, 1);
            main_grid.attach (button_box, 0, 2, 1, 1);

            ((Gtk.Container) get_content_area ()).add (main_grid);
        }

        private Gtk.Widget get_textstyle_grid () {
            var textstyle_grid = new Gtk.Grid ();
            textstyle_grid.row_spacing = 6;
            textstyle_grid.column_spacing = 12;
            textstyle_grid.margin = 12;

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

            textstyle_grid.attach (header_header, 0, 0, 5, 1);
            textstyle_grid.attach (header_one_label, 0, 1, 3, 1);
            textstyle_grid.attach (header_two_label, 0, 2, 3, 1);
            textstyle_grid.attach (header_three_label, 0, 3, 3, 1);
            textstyle_grid.attach (header_four_label, 0, 4, 3, 1);
            textstyle_grid.attach (font_header, 0, 5, 5, 1);
            textstyle_grid.attach (bold_font_label , 0, 6, 3, 1);
            textstyle_grid.attach (emph_font_label , 0, 7, 3, 1);
            textstyle_grid.attach (code_font_label , 0, 8, 3, 1);
            textstyle_grid.attach (quote_font_label , 0, 9, 3, 1);

            return textstyle_grid;
        }

        private Gtk.Widget get_links_grid () {
            var links_grid = new Gtk.Grid ();
            links_grid.row_spacing = 6;
            links_grid.column_spacing = 12;
            links_grid.margin = 12;

            var link_header = new Header (_("Links"));
            var link_label = new Label (_("[Link Label](http://link.url.here.com)"));
            var image_label = new Label (_("![Image Label](http://image.url.here.com)"));

            var special_header = new Header (_("Special"));
            var codeblocks_label = new Label (_("```This is a code block```"));
            var hr_label = new Label (_("--- ← This creates an horizontal rule"));

            links_grid.attach (link_header, 0, 0, 5, 1);
            links_grid.attach (link_label, 0, 1, 3, 1);
            links_grid.attach (image_label, 0, 2, 3, 1);
            links_grid.attach (special_header, 0, 3, 5, 1);
            links_grid.attach (codeblocks_label, 0, 4, 3, 1);
            links_grid.attach (hr_label, 0, 5, 3, 1);

            return links_grid;
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
