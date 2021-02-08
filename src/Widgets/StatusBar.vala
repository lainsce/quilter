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
    [GtkTemplate (ui = "/io/github/lainsce/Quilter/statusbar.ui")]
    public class Widgets.StatusBar : Gtk.Box {
        [GtkChild]
        public Gtk.MenuButton track_type_menu;
        [GtkChild]
        public Gtk.RadioButton track_words;
        [GtkChild]
        public Gtk.RadioButton track_lines;
        [GtkChild]
        public Gtk.RadioButton track_rtc;
        [GtkChild]
        public Gtk.Box track_box;

        public Gtk.SourceBuffer buf;
        public MainWindow win;
        private int WPM = 264;

        public StatusBar (MainWindow win, Gtk.SourceBuffer buf) {
            this.win = win;
            this.buf = buf;

            tracker ();
        }

        private void tracker () {
            track_box.show_all ();

	        track_words.toggled.connect (() => {
	            Quilter.Application.gsettings.set_string("track-type", "words");
	            update_wordcount ();
	        });

	        track_lines.toggled.connect (() => {
	            Quilter.Application.gsettings.set_string("track-type", "lines");
	            update_linecount ();
            });

	        track_rtc.toggled.connect (() => {
	            Quilter.Application.gsettings.set_string("track-type", "rtc");
	            update_readtimecount ();
	        });

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
