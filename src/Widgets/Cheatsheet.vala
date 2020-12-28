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
        private Gtk.Grid chgrid;
        private Gtk.Grid exgrid;

        public Cheatsheet (Gtk.Window? parent) {
            Object (
                title: _("Cheatsheet"),
                resizable: false,
                type_hint: Gdk.WindowTypeHint.DIALOG,
                transient_for: parent,
                modal: true,
                destroy_with_parent: true,
                window_position: Gtk.WindowPosition.CENTER_ON_PARENT
            );
        }

        construct {
            weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
            default_theme.add_resource_path ("/com/github/lainsce/quilter");

            get_chgrid ();
            get_exgrid ();

            var window_pager = new Hdy.Carousel ();
            window_pager.margin = 12;
            window_pager.margin_top = 0;
            window_pager.insert (chgrid, 0);
            window_pager.insert (exgrid, 1);

            var window_pager_indicators = new Hdy.CarouselIndicatorLines ();
            window_pager_indicators.set_carousel (window_pager);

            var titlebar = new Gtk.HeaderBar ();
            titlebar.spacing = 4;
            titlebar.set_show_close_button (true);

            var window_title = new Hdy.WindowHandle ();
            window_title.add (titlebar);

            var grid = new Gtk.Grid ();
            grid.attach (window_title, 0, 0);
            grid.attach (window_pager, 0, 1);
            grid.attach (window_pager_indicators, 0, 2);

            add (grid);

            this.key_press_event.connect ((e) => {
                uint keycode = e.hardware_keycode;
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.h, keycode)) {
                        this.destroy ();
                    }
                }
                return false;
            });

            var context = this.get_style_context ();
            context.add_class ("quilter-dialog-hb");
        }

        private void get_chgrid () {
            chgrid = new Gtk.Grid ();
            chgrid.row_spacing = 12;
            chgrid.column_spacing = 12;
            chgrid.margin = 6;

            var header_header = new Granite.HeaderLabel (_("Headers & Text"));
            var header_one_label = new Label (_("# Header 1"));
            var header_two_label = new Label (_("## Header 2"));
            var header_three_label = new Label (_("### Header 3"));
            var bold_font_label = new Label (_("** Bold **"));
            var emph_font_label = new Label (_("* Emphasized *"));
            var code_font_label = new Label (_("` Code Line `"));
            var codeblocks_label = new Label (_("``` Code Block ```"));
            var quote_font_label = new Label (_("> Quote"));

            var link_header = new Granite.HeaderLabel (_("Links"));
            var link_label = new Label (_("[Link Label](http://link.url.com)\n![Image Label](http://image.url.com)"));

            var special_header = new Granite.HeaderLabel (_("Special"));
            var lx_label = new Label (_("LaTeX:\n\t- $$…$$ for equation block.\n\t- \\\\(…\\\\) for inline equation."));
            var mm_label = new Label (_("Mermaid.js:\n\t- <div class=\"mermaid\">...</div>"));

            chgrid.attach (header_header, 0, 0, 2, 1);
            chgrid.attach (header_one_label, 0, 1, 1, 1);
            chgrid.attach (header_two_label, 0, 2, 1, 1);
            chgrid.attach (header_three_label, 0, 3, 1, 1);
            chgrid.attach (bold_font_label , 0, 4, 1, 1);
            chgrid.attach (emph_font_label , 0, 5, 1, 1);
            chgrid.attach (code_font_label , 0, 6, 1, 1);
            chgrid.attach (codeblocks_label, 0, 7, 1, 1);
            chgrid.attach (quote_font_label , 0, 8, 1, 1);
            chgrid.attach (link_header, 0, 9, 2, 1);
            chgrid.attach (link_label, 0, 10, 1, 1);
            chgrid.attach (special_header, 0, 12, 2, 1);
            chgrid.attach (lx_label, 0, 13, 1, 1);
            chgrid.attach (mm_label, 0, 14, 1, 1);
        }

        private void get_exgrid () {
            exgrid = new Gtk.Grid ();
            exgrid.row_spacing = 12;
            exgrid.column_spacing = 12;
            exgrid.margin = 6;

            var header2_header = new Granite.HeaderLabel (_("Extras"));
            var hr_label = new Label (_("Horizontal rule → ---"));
            var strike_font_label = new Label (_("~~Strikethrough~~"));
            var high_font_label = new Label (_("==Highlight=="));
            var sub_font_label = new Label (_("Subscript: H~2~O"));
            var sup_font_label = new Label (_("Superscript: E = MC^2^"));
            var checkbox_label = new Label (_("[] Empty Checkbox."));
            var checkedbox_label = new Label (_("[x] Checked Checkbox."));
            var custom_help = new Gtk.Image.from_icon_name ("dialog-information-symbolic", Gtk.IconSize.BUTTON);
            custom_help.halign = Gtk.Align.START;
            custom_help.margin_start = 6;
            custom_help.tooltip_text = _("Period needed to avoid conflicts.");
            var check_grid = new Gtk.Grid ();
            check_grid.attach (checkbox_label, 0, 0);
            check_grid.attach (checkedbox_label, 0, 1);
            check_grid.attach (custom_help, 1, 0);
            var sp_image_label = new Label (_("Embeds a local image\n\t/Folder/Image.png :image"));
            var sp_file_label = new Label (_("Embeds a local Markdown file\n\t/Folder/File.md :file"));
            var table_header = new Granite.HeaderLabel (_("Tables"));
            var table_label = new Label ("|\tA\t|\tB\t|\n|\t---\t|\t---\t|\n|\t1\t|\t2\t|");
            var custom_help2 = new Gtk.Image.from_icon_name ("dialog-information-symbolic", Gtk.IconSize.BUTTON);
            custom_help2.halign = Gtk.Align.START;
            custom_help2.margin_start = 6;
            custom_help2.tooltip_text = _("Left Column, change --- to :--- .\nCentered Column, change --- to :---: .\nRight Column, change --- to ---: .");
            var table_grid = new Gtk.Grid ();
            table_grid.attach (table_label, 0, 0);
            table_grid.attach (custom_help2, 1, 0);

            exgrid.attach (header2_header , 2, 0, 2, 1);
            exgrid.attach (hr_label, 2, 1, 1, 1);
            exgrid.attach (strike_font_label , 2, 2, 1, 1);
            exgrid.attach (sub_font_label , 2, 3, 1, 1);
            exgrid.attach (sup_font_label , 2, 4, 1, 1);
            exgrid.attach (high_font_label , 2, 5, 1, 1);
            exgrid.attach (check_grid , 2, 6, 1, 1);
            exgrid.attach (sp_image_label, 2, 7, 1, 1);
            exgrid.attach (sp_file_label, 2, 8, 1, 1);
            exgrid.attach (table_header, 2, 9, 2, 1);
            exgrid.attach (table_grid, 2, 10, 1, 1);
        }

        private class Label : Gtk.Label {
            public Label (string text) {
                label = text;
                halign = Gtk.Align.START;
                valign = Gtk.Align.START;
                use_markup = true;
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
