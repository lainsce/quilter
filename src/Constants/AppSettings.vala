/*-
 * Copyright (c) 2017 Lains
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

namespace Quilter {
    public class Constants {
        // Margin Constants
        public const int NARROW_MARGIN = 2;
        public const int MEDIUM_MARGIN = 5;
        public const int WIDE_MARGIN = 10;

        // Font Size Constants
        public const int SMALL_FONT = 1;
        public const int MEDIUM_FONT = 2;
        public const int BIG_FONT = 3;

        // Typewriter Position
        public const double TYPEWRITER_POSITION = 0.50;
    }

    public class AppSettings : Granite.Services.Settings {
        public bool autosave { get; set; }
        public bool dark_mode { get; set; }
        public bool focus_mode { get; set; }
        public bool fullscreen { get; set; }
        public bool highlight { get; set; }
        public bool moon_mode { get; set; }
        public bool searchbar { get; set; }
        public bool sepia_mode { get; set; }
        public bool show_filename { get; set; }
        public bool show_num_lines { get; set; }
        public bool shown_view { get; set; }
        public bool spellcheck { get; set; }
        public bool statusbar { get; set; }
        public bool sidebar { get; set; }
        public bool typewriter_scrolling { get; set; }
        public bool use_system_font { get; set; }
        public int focus_mode_type { get; set; }
        public int font_sizing { get; set; }
        public int margins { get; set; }
        public int spacing { get; set; }
        public int window_height { get; set; }
        public int window_width { get; set; }
        public int window_x { get; set; }
        public int window_y { get; set; }
        public string current_file { get; set; }
        public string[] last_files { get; set; }
        public string preview_font { get; set; }
        public string edit_font_type { get; set; }
        public string spellcheck_language { get; set; }
        public string track_type { get; set; }
        public string preview_type { get; set; }

        private static AppSettings? instance;
        public static unowned AppSettings get_default () {
            if (instance == null) {
                instance = new AppSettings ();
            }

            return instance;
        }

        private AppSettings () {
            base ("com.github.lainsce.quilter");
        }
    }
}
