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
    public class Widgets.StatusBar : Gtk.ActionBar {
        public SourceView editor;
        public Gtk.Label wordcount_label;

        public StatusBar () {
            wordcount_label = new Gtk.Label("");
            wordcount_label.set_width_chars (18);
            update_wordcount ();
            pack_start (wordcount_label);
        }

        construct {
            var context = this.get_style_context ();
            context.add_class ("quilter-statusbar");
        }

        public void update_wordcount () {
            var wc = get_count();
		    wordcount_label.set_text("Words: " + wc.words.to_string());
        }

        public WordCount get_count() {
    		try {
    			var reg = new Regex("[\\s\\W]+", RegexCompileFlags.OPTIMIZE);
    			string text = editor.buffer.text;
    			string result = reg.replace (text, text.length, 0, " ");

    			return new WordCount(result.strip().split(" ").length, result.length);
    		} catch (Error e) {
    			return new WordCount(0, 0);
    		}
    	}
    }

    public class WordCount {
        public int words { get; private set; }
        public int chars { get; private set; }

        public WordCount(int words, int chars) {
            this.words = words;
            this.chars = chars;
        }
    }
}