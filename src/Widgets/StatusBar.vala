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

        /* Average normal reading speed is 275 WPM */
        int WPM = 275;

        public StatusBar () {
            actionbar = new Gtk.ActionBar ();
            wordcount_item ();
            linecount_item ();
            readtimecount_item ();

            this.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
            this.add (actionbar);
        }

        public void wordcount_item () {
            wordcount_label = new Gtk.Label("");
            wordcount_label.set_width_chars (12);
            update_wordcount ();
            actionbar.pack_start (wordcount_label);
        }

        public void update_wordcount () {
            var wc = get_count();
		    wordcount_label.set_text((_("Words: ")) + wc.words.to_string());
        }

        public void linecount_item () {
            linecount_label = new Gtk.Label("");
            linecount_label.set_width_chars (12);
            update_linecount ();
            actionbar.pack_start (linecount_label);
        }

        public void update_linecount () {
            var lc = get_count();
		    linecount_label.set_text((_("Lines: ")) + lc.lines.to_string());
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

    			return new WordCount(result.strip().split(" ").length, lines,  result.length);
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
