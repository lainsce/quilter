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
        public Gtk.Label wordcount_label;
        public MainWindow window;

        public StatusBar () {
            wordcount_item ();
            darkmode_item ();
            focusmode_item ();
        }

        construct {
            var context = this.get_style_context ();
            context.add_class ("quilter-statusbar");
        }

        public void wordcount_item () {
            wordcount_label = new Gtk.Label("");
            wordcount_label.set_width_chars (6);
            update_wordcount ();
            pack_start (wordcount_label);
        }

        public void update_wordcount () {
            var wc = get_count();
		    wordcount_label.set_text((_("Words: ")) + wc.words.to_string());
        }

        public void darkmode_item () {
            var darkmode_button = new Gtk.ToggleButton.with_label ((_("Dark Mode")));
            darkmode_button.set_image (new Gtk.Image.from_icon_name ("weather-clear-night-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            darkmode_button.set_always_show_image (true);

            var settings = AppSettings.get_default ();
            darkmode_button.toggled.connect (() => {
    			if (darkmode_button.active) {
    				settings.dark_mode = true;
                    darkmode_button.active = true;
    			} else {
    				settings.dark_mode = false;
                    darkmode_button.active = false;
    			}

    		});

            pack_end (darkmode_button);
        }

        public void focusmode_item () {
            var focusmode_button = new Gtk.ToggleButton.with_label ((_("Focus Mode")));
            focusmode_button.set_image (new Gtk.Image.from_icon_name ("zoom-fit-best-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            focusmode_button.set_always_show_image (true);

            var settings = AppSettings.get_default ();
            focusmode_button.toggled.connect (() => {
    			if (focusmode_button.active) {
    				settings.focus_mode = true;
                    focusmode_button.active = true;
    			} else {
    				settings.focus_mode = false;
                    focusmode_button.active = false;
    			}

    		});

            pack_end (focusmode_button);
        }

        public WordCount get_count() {
    		try {
    			var reg = new Regex("[\\s\\W]+", RegexCompileFlags.OPTIMIZE);
    			string text = Widgets.SourceView.buffer.text;
    			string result = reg.replace (text, text.length, 0, " ");

    			return new WordCount(result.strip().split(" ").length, result.length);
    		} catch (Error e) {
    			return new WordCount(0, 0);
    		}
    	}
    }

    public class Widgets.WordCount {
        public int words { get; private set; }
        public int chars { get; private set; }

        public WordCount(int words, int chars) {
            this.words = words;
            this.chars = chars;
        }
    }
}
