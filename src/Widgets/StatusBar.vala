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
namespace Quilter {
    public class Widgets.StatusBar : Gtk.Revealer {
        public Gtk.ActionBar actionbar;
        public Gtk.Label linecount_label;
        public Gtk.Label wordcount_label;
        public Gtk.MenuButton preview_type_menu;
        public Gtk.MenuButton track_type_menu;
        public Gtk.SourceBuffer buf;
        public Gtk.RadioButton track_words;
        public Gtk.RadioButton track_lines;
        public Gtk.RadioButton track_rtc;
        public MainWindow window;

        /* Averaged normal reading speed is 265 WPM */
        int WPM = 265;

        public StatusBar (Gtk.SourceBuffer buf) {
            this.buf = buf;
            this.valign = Gtk.Align.END;
            actionbar = new Gtk.ActionBar ();

	        track_words = new Gtk.RadioButton.with_label (null, _("Words"));
	        track_words.toggled.connect (() => {
	            Quilter.Application.gsettings.set_string("track-type", "words");
	            update_wordcount ();
	        });

	        track_lines = new Gtk.RadioButton.with_label_from_widget (track_words, _("Sentences"));
	        track_lines.toggled.connect (() => {
	            Quilter.Application.gsettings.set_string("track-type", "lines");
	            update_linecount ();
            });
            
            track_rtc = new Gtk.RadioButton.with_label_from_widget (track_words, _("Reading Time"));
	        track_rtc.toggled.connect (() => {
	            Quilter.Application.gsettings.set_string("track-type", "rtc");
	            update_readtimecount ();
	        });

            var track_type_grid = new Gtk.Grid ();
            track_type_grid.margin = 12;
            track_type_grid.row_spacing = 12;
            track_type_grid.column_spacing = 12;
            track_type_grid.orientation = Gtk.Orientation.VERTICAL;
            track_type_grid.add (track_words);
            track_type_grid.add (track_lines);
            track_type_grid.add (track_rtc);
            track_type_grid.show_all ();

            var track_type_menu_pop = new Gtk.Popover (null);
            track_type_menu_pop.add (track_type_grid);

            track_type_menu = new Gtk.MenuButton ();
            track_type_menu.tooltip_text = _("Set Tracking Type");
            track_type_menu.popover = track_type_menu_pop;
            track_type_menu.label = "";

            var sidebar_toggler = new Gtk.ToggleButton ();

            if (Quilter.Application.gsettings.get_boolean("sidebar")) {
                sidebar_toggler.set_image (new Gtk.Image.from_icon_name("sidebar-hide-symbolic", Gtk.IconSize.BUTTON));
            } else {
                sidebar_toggler.set_image (new Gtk.Image.from_icon_name("sidebar-show-symbolic", Gtk.IconSize.BUTTON));
            }

            Quilter.Application.gsettings.changed.connect (() => {
                if (Quilter.Application.gsettings.get_boolean("sidebar")) {
                    sidebar_toggler.set_image (new Gtk.Image.from_icon_name("sidebar-hide-symbolic", Gtk.IconSize.BUTTON));
                } else {
                    sidebar_toggler.set_image (new Gtk.Image.from_icon_name("sidebar-show-symbolic", Gtk.IconSize.BUTTON));
                }
            });

            Quilter.Application.gsettings.bind ("sidebar", sidebar_toggler, "active", GLib.SettingsBindFlags.DEFAULT);

            actionbar.pack_start (sidebar_toggler);
            actionbar.pack_end (track_type_menu);

            if (Quilter.Application.gsettings.get_string("track-type") == "words") {
                update_wordcount ();
                track_words.set_active (true);
            } else if (Quilter.Application.gsettings.get_string("track-type") == "lines") {
                update_linecount ();
                track_lines.set_active (true);
            } else if (Quilter.Application.gsettings.get_string("track-type") == "rtc") {
                update_readtimecount ();
                track_rtc.set_active (true);
            }

            this.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
            this.add (actionbar);
            this.reveal_child = true;
        }

        public void update_wordcount () {
            var wc = get_count();
            track_type_menu.set_label ((_("Words: ")) + wc.words.to_string());
        }

        public void update_linecount () {
            var lc = get_count();
            track_type_menu.set_label ((_("Sentences: ")) + lc.lines.to_string());
        }

        public void update_readtimecount () {
            var rtc = get_count();
            double rt = Math.round((rtc.words / WPM));
		    track_type_menu.set_label ((_("Reading Time: ")) + rt.to_string() + "m");
        }

        public WordCount get_count() {
            Gtk.TextIter start, end;
            buf.get_bounds (out start, out end);
            var buffer = buf.get_text (start, end, false);
            int i = 0;
            try {
                GLib.MatchInfo match;
                var reg = new Regex("(?m)(?<header>\\.)");
                if (reg.match (buffer, 0, out match)) {
                    do {
                        i++;
                    } while (match.next ());
                }
            } catch (Error e) {
                warning (e.message);
            }

            var lines = i;
            var words = buf.get_text (start, end, false).split(" ").length;

            return new WordCount(words, lines);
    	}
    }

    public class Widgets.WordCount {
        public int words { get; private set; }
        public int lines { get; private set; }

        public WordCount(int words, int lines) {
            this.words = words;
            this.lines = lines;
        }
    }
}
