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

        public Cheatsheet (Gtk.Window? parent) {
            Object (
                border_width: 6,
                deletable: false,
                resizable: false,
                title: _("Cheatsheet"),
                transient_for: parent,
                destroy_with_parent: true,
                window_position: Gtk.WindowPosition.CENTER_ON_PARENT
            );
        }

        construct {
            main_stack = new Gtk.Stack ();
            main_stack.margin = 12;
            main_stack.margin_top = 0;
            main_stackswitcher = new Gtk.StackSwitcher ();
            main_stackswitcher.stack = main_stack;
            main_stackswitcher.halign = Gtk.Align.CENTER;
            main_stackswitcher.homogeneous = true;
            main_stackswitcher.margin = 12;
            main_stackswitcher.margin_top = 0;

            this.main_stack.add_titled (get_textstyle_grid (), "textstyle", _("Text"));
            this.main_stack.add_titled (get_links_grid (), "links", _("Links & Special"));
            this.main_stack.add_titled (get_tables_grid (), "tables", _("Tables"));

            // Close button
            var close_button = add_button (_("Close"), Gtk.ResponseType.CLOSE);
            ((Gtk.Button) close_button).clicked.connect (() => destroy ());

            // Pack everything into the dialog
            var main_grid = new Gtk.Grid ();
            main_grid.margin_top = 0;
            main_grid.attach (this.main_stackswitcher, 0, 0, 1, 1);
            main_grid.attach (this.main_stack, 0, 1, 1, 1);

            ((Gtk.Container) get_content_area ()).add (main_grid);

            this.key_press_event.connect ((e) => {
                uint keycode = e.hardware_keycode;
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.h, keycode)) {
                        this.destroy ();
                    }
                }
                return false;
            });
        }

        private Gtk.Widget get_textstyle_grid () {
            var textstyle_grid = new Gtk.Grid ();
            textstyle_grid.row_spacing = 6;
            textstyle_grid.column_spacing = 12;

            var header_header = new Granite.HeaderLabel (_("Heading"));
            var header_one_label = new Label (_("# Heading 1"));
            var header_two_label = new Label (_("## Heading 2"));
            var header_three_label = new Label (_("### Heading 3"));
            var header_four_label = new Label (_("#### Heading 4"));
            var header_five_label = new Label (_("##### Heading 5"));
            var header_six_label = new Label (_("###### Heading 6"));
            var font_header = new Granite.HeaderLabel (_("Special Text"));
            var bold_font_label = new Label (_("** Bold text **"));
            var emph_font_label = new Label (_("* Emphasized text *"));
            var code_font_label = new Label (_("` Code text `"));
            var quote_font_label = new Label (_("> Quoting text"));
            var strike_font_label = new Label (_("~~Strikethrough text~~"));

            textstyle_grid.attach (header_header, 0, 0, 5, 1);
            textstyle_grid.attach (header_one_label, 0, 1, 3, 1);
            textstyle_grid.attach (header_two_label, 0, 2, 3, 1);
            textstyle_grid.attach (header_three_label, 0, 3, 3, 1);
            textstyle_grid.attach (header_four_label, 0, 4, 3, 1);
            textstyle_grid.attach (header_five_label, 0, 5, 3, 1);
            textstyle_grid.attach (header_six_label, 0, 6, 3, 1);
            textstyle_grid.attach (font_header, 0, 7, 5, 1);
            textstyle_grid.attach (bold_font_label , 0, 8, 3, 1);
            textstyle_grid.attach (emph_font_label , 0, 9, 3, 1);
            textstyle_grid.attach (code_font_label , 0, 10, 3, 1);
            textstyle_grid.attach (quote_font_label , 0, 11, 3, 1);
            textstyle_grid.attach (strike_font_label , 0, 12, 3, 1);

            return textstyle_grid;
        }

        private Gtk.Widget get_links_grid () {
            var links_grid = new Gtk.Grid ();
            links_grid.row_spacing = 6;
            links_grid.column_spacing = 12;

            var link_header = new Granite.HeaderLabel (_("Links"));
            var link_label = new Label (_("[Link Label](http://link.url.here.com)"));
            var image_label = new Label (_("![Image Label](http://image.url.here.com)"));
            var special_header = new Granite.HeaderLabel (_("Special"));
            var codeblocks_label = new Label (_("```This is a code block```"));
            var hr_label = new Label (_("This creates a horizontal rule → ---"));
            var sp_image_label = new Label (_("This embeds a local image → /Folder/Image.png :image"));
            var sp_file_label = new Label (_("This embeds a local Markdown file → /Folder/File.md :file"));

            links_grid.attach (link_header, 0, 0, 5, 1);
            links_grid.attach (link_label, 0, 1, 3, 1);
            links_grid.attach (image_label, 0, 2, 3, 1);
            links_grid.attach (special_header, 0, 3, 5, 1);
            links_grid.attach (codeblocks_label, 0, 4, 3, 1);
            links_grid.attach (hr_label, 0, 5, 3, 1);
            links_grid.attach (sp_image_label, 0, 6, 3, 1);
            links_grid.attach (sp_file_label, 0, 7, 3, 1);

            return links_grid;
        }

        private Gtk.Widget get_tables_grid () {
            var tables_grid = new Gtk.Grid ();
            tables_grid.row_spacing = 6;
            tables_grid.column_spacing = 12;

            var table_header = new Granite.HeaderLabel (_("Tables"));
            var table_label = new Label ("|\tA\t|\tB\t|\n|\t---\t|\t---\t|\n|\t1\t|\t2\t|");
            var table_explain_label = new Text (_("To make a column's content go to the left, change --- to :--- ."));
            var table_explain_label2 = new Text (_("To make a column's content centered, change --- to :---: ."));
            var table_explain_label3 = new Text (_("To make a column's content go to the right, change --- to ---: ."));

            tables_grid.attach (table_header, 0, 0, 5, 1);
            tables_grid.attach (table_label, 0, 1, 1, 1);
            tables_grid.attach (table_explain_label, 0, 2, 5, 1);
            tables_grid.attach (table_explain_label2, 0, 3, 5, 1);
            tables_grid.attach (table_explain_label3, 0, 4, 5, 1);

            return tables_grid;
        }

        private class Label : Gtk.Label {
            public Label (string text) {
                label = text;
                halign = Gtk.Align.START;
                margin_start = 12;
            }
        }

        private class Text : Gtk.Label {
            public Text (string text) {
                label = text;
                halign = Gtk.Align.START;
                margin_start = 6;
            }
        }

#if VALA_0_42
        protected bool match_keycode (uint keyval, uint code) {
#else
        protected bool match_keycode (int keyval, uint code) {
#endif
            Gdk.KeymapKey [] keys;
            Gdk.Keymap keymap = Gdk.Keymap.get_for_display (Gdk.Display.get_default ());
            if (keymap.get_entries_for_keyval (keyval, out keys)) {
                foreach (var key in keys) {
                    if (code == key.keycode)
                        return true;
                    }
                }

            return false;
        }
    }
}
