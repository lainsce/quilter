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
        public Gtk.Label readtimecount_label;
        public MainWindow window;

        /* Average normal reading speed is 90 words per minute */
        int WPM = 90;

        public StatusBar () {
            wordcount_item ();
            readtimecount_item ();
            darkmode_item ();
            focusmode_item ();
        }

        public void wordcount_item () {
            wordcount_label = new Gtk.Label("");
            wordcount_label.set_width_chars (12);
            update_wordcount ();
            pack_start (wordcount_label);
        }

        public void update_wordcount () {
            var wc = get_count();
		    wordcount_label.set_text((_("Words: ")) + wc.words.to_string());
        }

        public void readtimecount_item () {
            readtimecount_label = new Gtk.Label("");
            readtimecount_label.set_width_chars (12);
            update_readtimecount ();
            pack_start (readtimecount_label);
        }

        public void update_readtimecount () {
            var wc = get_count();
            int rtc = (wc.words / WPM);
		    readtimecount_label.set_text((_("Reading Time: ")) + rtc.to_string() + "m");
        }

        public void darkmode_item () {
            var darkmode_button = new Gtk.ToggleButton.with_label ((_("Dark Mode")));
            darkmode_button.set_image (new Gtk.Image.from_icon_name ("weather-clear-night-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            darkmode_button.set_always_show_image (true);

            var settings = AppSettings.get_default ();
            if (settings.dark_mode == false) {
                darkmode_button.set_active (false);
            } else {
                darkmode_button.set_active (settings.dark_mode);
            }

            darkmode_button.toggled.connect (() => {
    			if (darkmode_button.active) {
    				settings.dark_mode = true;
    			} else {
    				settings.dark_mode = false;
    			}

    		});

            pack_end (darkmode_button);
        }

        public void focusmode_item () {
            var focusmode_button = new Gtk.ToggleButton.with_label ((_("Focus Mode")));
            focusmode_button.set_image (new Gtk.Image.from_icon_name ("zoom-fit-best-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
            focusmode_button.set_always_show_image (true);

            var settings = AppSettings.get_default ();
            if (settings.focus_mode == false) {
                focusmode_button.set_active (false);
            } else {
                focusmode_button.set_active (settings.focus_mode);
            }

            focusmode_button.toggled.connect (() => {
    			if (focusmode_button.active) {
    				settings.focus_mode = true;
    			} else {
    				settings.focus_mode = false;
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
