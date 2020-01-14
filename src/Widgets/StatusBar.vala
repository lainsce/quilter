/*
* Copyright (C) 2017 Lains
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
using Gtk;
using Granite;
namespace Quilter {
    public class Widgets.StatusBar : Gtk.Revealer {
        public Gtk.Label wordcount_label;
        public Gtk.Label linecount_label;
        public Gtk.Label readtimecount_label;
        public MainWindow window;
        public Gtk.ActionBar actionbar;
        public Gtk.MenuButton track_type_menu;
        public Gtk.MenuButton preview_type_menu;
        public Gtk.SourceBuffer buf;

        /* Average normal reading speed is 275 WPM */
        int WPM = 275;

        public StatusBar (Gtk.SourceBuffer buf) {
            this.buf = buf;

            actionbar = new Gtk.ActionBar ();

            var side_button = new Gtk.ToggleButton ();
            side_button.has_tooltip = true;
            side_button.set_image (new Gtk.Image.from_icon_name ("pane-show-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            side_button.tooltip_markup = Granite.markup_accel_tooltip (
                {"F2"},
                _("Show/Hide Sidebar")
            );

            if (Quilter.Application.gsettings.get_boolean("sidebar") == false) {
                side_button.set_active (false);
            } else {
                side_button.set_active (Quilter.Application.gsettings.get_boolean("sidebar") );
            }

            side_button.toggled.connect (() => {
    			if (side_button.active) {
    				Quilter.Application.gsettings.set_boolean("sidebar", true);
                    side_button.set_image (new Gtk.Image.from_icon_name ("pane-show-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
    			} else {
    				Quilter.Application.gsettings.set_boolean("sidebar", false);
                    side_button.set_image (new Gtk.Image.from_icon_name ("pane-hide-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
    			}

            });
            actionbar.pack_start (side_button);

            track_type_menu_item ();

            preview_type_menu_item ();

            if (Quilter.Application.gsettings.get_string("track-type") == "words") {
                update_wordcount ();
            } else if (Quilter.Application.gsettings.get_string("track-type") == "lines") {
                update_linecount ();
            } else if (Quilter.Application.gsettings.get_string("track-type") == "chars") {
                update_charcount ();
            }

            readtimecount_item ();

            this.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
            this.add (actionbar);
        }

        public void preview_type_menu_item () {


            var preview_cbt = new Gtk.ComboBoxText();
            preview_cbt.append_text((_("Full-Width")));
            preview_cbt.append_text((_("Half-Width")));

            if (Quilter.Application.gsettings.get_string("preview-type") == "full") {
                preview_cbt.set_active(0);
                Quilter.Application.gsettings.set_string("preview-type", "full");
            } else if (Quilter.Application.gsettings.get_string("preview-type") == "half") {
                preview_cbt.set_active(1);
                Quilter.Application.gsettings.set_string("preview-type", "half");
            }

            preview_cbt.changed.connect (() => {
                var pcbt_value = preview_cbt.get_active();
                if (pcbt_value == 0) {
                    Quilter.Application.gsettings.set_string("preview-type", "full");
                } else if (pcbt_value == 1) {
                    Quilter.Application.gsettings.set_string("preview-type", "half");
                }
            });

            var preview_cbt_context = preview_cbt.get_style_context ();
            preview_cbt_context.add_class ("quilter-cbt");
            preview_cbt_context.add_class (Gtk.STYLE_CLASS_FLAT);
            actionbar.pack_end (preview_cbt);
        }

        public void track_type_menu_item () {


            var track_chars = new Gtk.RadioButton.with_label_from_widget (null, _("Track Characters"));
	        track_chars.toggled.connect (() => {
	            Quilter.Application.gsettings.set_string("track-type", "chars");
	        });

	        var track_words = new Gtk.RadioButton.with_label_from_widget (track_chars, _("Track Words"));
	        track_words.toggled.connect (() => {
	            Quilter.Application.gsettings.set_string("track-type", "words");
	        });

	        var track_lines = new Gtk.RadioButton.with_label_from_widget (track_chars, _("Track Lines"));
	        track_lines.toggled.connect (() => {
	            Quilter.Application.gsettings.set_string("track-type", "lines");
	        });
	        track_words.set_active (true);

            var track_type_grid = new Gtk.Grid ();
            track_type_grid.margin = 12;
            track_type_grid.row_spacing = 12;
            track_type_grid.column_spacing = 12;
            track_type_grid.orientation = Gtk.Orientation.VERTICAL;
            track_type_grid.add (track_chars);
            track_type_grid.add (track_words);
            track_type_grid.add (track_lines);
            track_type_grid.show_all ();

            var track_type_menu_pop = new Gtk.Popover (null);
            track_type_menu_pop.add (track_type_grid);

            track_type_menu = new Gtk.MenuButton ();
            track_type_menu.tooltip_text = _("Set Tracking Type");
            track_type_menu.popover = track_type_menu_pop;
            track_type_menu.label = "";

            var menu_context = track_type_menu.get_style_context ();
            menu_context.add_class ("quilter-menu");
            menu_context.add_class (Gtk.STYLE_CLASS_FLAT);

            actionbar.pack_start (track_type_menu);
        }

        public void update_wordcount () {

            var wc = get_count();
            track_type_menu.set_label ((_("Words: ")) + wc.words.to_string());
            Quilter.Application.gsettings.set_string("track-type", "words");
        }

        public void update_linecount () {

            var lc = get_count();
            track_type_menu.set_label ((_("Lines: ")) + lc.lines.to_string());
            Quilter.Application.gsettings.set_string("track-type", "lines");
        }

        public void update_charcount () {

            var cc = get_count();
            track_type_menu.set_label ((_("Characters: ")) + cc.chars.to_string());
            Quilter.Application.gsettings.set_string("track-type", "chars");
        }

        public void readtimecount_item () {
            readtimecount_label = new Gtk.Label("");
            readtimecount_label.set_width_chars (12);
            update_readtimecount ();
            actionbar.pack_start (readtimecount_label);
        }

        public void update_readtimecount () {
            var rtc = get_count();
            int rt = (rtc.words / WPM);
		    readtimecount_label.set_text((_("Reading Time: ")) + rt.to_string() + "m");
        }

        public WordCount get_count() {
    		Gtk.TextIter start, end;
            buf.get_bounds (out start, out end);
            var lines = buf.get_line_count ();
            var chars = buf.get_text (start, end, false).length;
            var words = buf.get_text (start, end, false).strip().split(" ").length;

    		return new WordCount(words, lines, chars);
    	}
    }

    public class Widgets.WordCount {
        public int words { get; private set; }
        public int lines { get; private set; }
        public int chars { get; private set; }

        public WordCount(int words, int lines, int chars) {
            this.words = words;
            this.lines = lines;
            this.chars = chars;
        }
    }
}
