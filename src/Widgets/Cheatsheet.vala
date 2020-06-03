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
    public class Cheatsheet : Hdy.Window {
        private Gtk.Grid links_grid;
        private Gtk.Grid tables_grid;
        private Gtk.Grid textstyle_grid;
        private Gtk.Stack main_stack;
        private Hdy.ViewSwitcher main_stackswitcher;

        public Cheatsheet (Gtk.Window? parent) {
            Object (
                resizable: false,
                title: _("Cheatsheet"),
                transient_for: parent,
                modal: true,
                destroy_with_parent: true,
                window_position: Gtk.WindowPosition.CENTER_ON_PARENT
            );
        }

        construct {
            this.set_size_request (360,-1);
            main_stack = new Gtk.Stack ();
            main_stack.margin = 12;

            // Let's make a new Dialog design for preferences, follow elementary OS UI cues.
            main_stackswitcher = new Hdy.ViewSwitcher ();
            main_stackswitcher.stack = main_stack;

            get_textstyle_grid ();
            get_links_grid ();
            get_tables_grid ();

            main_stack.add_titled (textstyle_grid, "textstyle", _("Text"));
            main_stack.add_titled (links_grid, "links", _("Special"));
            main_stack.add_titled (tables_grid, "tables", _("Tables"));

            main_stack.child_set_property (textstyle_grid, "icon-name", "font-select-symbolic");
            main_stack.child_set_property (links_grid, "icon-name", "insert-link-symbolic");
            main_stack.child_set_property (tables_grid, "icon-name", "view-column-symbolic");

            var titlebar = new Gtk.HeaderBar ();
            titlebar.set_decoration_layout ("close:");
            titlebar.set_custom_title (main_stackswitcher);
            titlebar.set_show_close_button (true);

            var window_handle = new Hdy.WindowHandle ();
            window_handle.add (titlebar);

            var grid = new Gtk.Grid ();
            grid.attach (window_handle, 0, 0);
            grid.attach (main_stack, 0, 1);

            add (grid);

            var context = this.get_style_context ();
            context.add_class ("quilter-dialog-hb");

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

        private void get_textstyle_grid () {
            textstyle_grid = new Gtk.Grid ();
            textstyle_grid.row_spacing = 6;
            textstyle_grid.column_spacing = 6;

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
            var high_font_label = new Label (_("==Highlight text=="));
            var sub_font_label = new Label (_("Subscripted text: H~2~O"));
            var sup_font_label = new Label (_("Superscripted text: E = MC^2^"));

            var header2_header = new Granite.HeaderLabel (_("Miscellaneous Styles"));
            var checkbox_label = new Label (_("[] This Makes an empty Checkbox.\n[x] This makes a checked Checkbox.\n\n\tPlease note the period, it's necessary to avoid conflicts.\n\tAlso, it's not needed to put this on a new paragraph.\n\tJust one new line between content and Checkboxes.\n\tAdding a - before will result in text-only Checkboxes."));

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
            textstyle_grid.attach (header2_header , 0, 13, 5, 1);
            textstyle_grid.attach (sub_font_label , 0, 14, 3, 1);
            textstyle_grid.attach (sup_font_label , 0, 15, 3, 1);
            textstyle_grid.attach (high_font_label , 0, 16, 3, 1);
            textstyle_grid.attach (checkbox_label , 0, 17, 3, 1);
        }

        private void get_links_grid () {
            links_grid = new Gtk.Grid ();
            links_grid.row_spacing = 6;
            links_grid.column_spacing = 6;

            var link_header = new Granite.HeaderLabel (_("Links"));
            var link_label = new Label (_("[Link Label](http://link.url.here.com)"));
            var image_label = new Label (_("![Image Label](http://image.url.here.com)"));
            var special_header = new Granite.HeaderLabel (_("Special"));
            var codeblocks_label = new Label (_("```This is a code block```"));
            var hr_label = new Label (_("This creates a horizontal rule → ---"));
            var sp_image_label = new Label (_("This embeds a local image → /Folder/Image.png :image"));
            var sp_file_label = new Label (_("This embeds a local Markdown file → /Folder/File.md :file"));
            var lx_label = new Label (_("LaTeX is processed with:\n\t- $$…$$ for equation block.\n\t- \\\\(…\\\\) for inline equation."));
            var mm_label = new Label (_("Mermaid is processed with:\n\t<div class=\"mermaid\">...</div>\n\tUsing Mermaid.js in other forms may clash with\n\tthe Code Highlightning plugin."));

            links_grid.attach (link_header, 0, 0, 5, 1);
            links_grid.attach (link_label, 0, 1, 3, 1);
            links_grid.attach (image_label, 0, 2, 3, 1);
            links_grid.attach (special_header, 0, 3, 5, 1);
            links_grid.attach (codeblocks_label, 0, 4, 3, 1);
            links_grid.attach (hr_label, 0, 5, 3, 1);
            links_grid.attach (sp_image_label, 0, 6, 3, 1);
            links_grid.attach (sp_file_label, 0, 7, 3, 1);
            links_grid.attach (lx_label, 0, 8, 3, 1);
            links_grid.attach (mm_label, 0, 9, 3, 1);
        }

        private void get_tables_grid () {
            tables_grid = new Gtk.Grid ();
            tables_grid.row_spacing = 6;
            tables_grid.column_spacing = 6;

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
