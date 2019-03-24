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

        /* Average normal reading speed is 275 WPM */
        int WPM = 275;

        public StatusBar () {
            var settings = AppSettings.get_default ();
            actionbar = new Gtk.ActionBar ();

            var side_button = new Gtk.ToggleButton ();
            side_button.has_tooltip = true;
            side_button.set_image (new Gtk.Image.from_icon_name ("pane-hide-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            side_button.tooltip_text = _("Show/Hide Sidebar");

            if (settings.sidebar == false) {
                side_button.set_active (false);
            } else {
                side_button.set_active (settings.sidebar);
            }

            side_button.toggled.connect (() => {
    			if (side_button.active) {
    				settings.sidebar = true;
                    side_button.set_image (new Gtk.Image.from_icon_name ("pane-show-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
    			} else {
    				settings.sidebar = false;
                    side_button.set_image (new Gtk.Image.from_icon_name ("pane-hide-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
    			}

            });
            actionbar.pack_start (side_button);

            track_type_menu_item ();

            if (settings.track_type == "words") {
                update_wordcount ();
            } else if (settings.track_type == "lines") {
                update_linecount ();
            } else if (settings.track_type == "chars") {
                update_charcount ();
            }

            readtimecount_item ();

            this.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
            this.add (actionbar);
        }

        public void track_type_menu_item () {
            var settings = AppSettings.get_default ();

            var track_chars = new Gtk.RadioButton.with_label_from_widget (null, _("Track Characters"));
	        track_chars.toggled.connect (() => {
	            settings.track_type = "chars";
	        });

	        var track_words = new Gtk.RadioButton.with_label_from_widget (track_chars, _("Track Words"));
	        track_words.toggled.connect (() => {
	            settings.track_type = "words";
	        });

	        var track_lines = new Gtk.RadioButton.with_label_from_widget (track_chars, _("Track Lines"));
	        track_lines.toggled.connect (() => {
	            settings.track_type = "lines";
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
            var settings = AppSettings.get_default ();
            var wc = get_count();
            track_type_menu.set_label ((_("Words: ")) + wc.words.to_string());
            settings.track_type = "words";
        }

        public void update_linecount () {
            var settings = AppSettings.get_default ();
            var lc = get_count();
            track_type_menu.set_label ((_("Lines: ")) + lc.lines.to_string());
            settings.track_type = "lines";
        }

        public void update_charcount () {
            var settings = AppSettings.get_default ();
            var cc = get_count();
            track_type_menu.set_label ((_("Characters: ")) + cc.chars.to_string());
            settings.track_type = "chars";
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
    		try {
    			var reg = new Regex("[\\s\\W]+", RegexCompileFlags.OPTIMIZE);
                var buffer = Widgets.EditView.buffer;

    			string text = buffer.text;
    			string result = reg.replace (text, text.length, 0, " ");

                var lines = buffer.get_line_count ();

                var chars = result.length;

    			return new WordCount(result.strip().split(" ").length, lines,  chars);
    		} catch (Error e) {
    			return new WordCount(0, 0, 0);
    		}
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
