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
    public class AppSettings : Granite.Services.Settings {
        public bool dark_mode { get; set; }
        public bool focus_mode { get; set; }
        public bool fullscreen { get; set; }
        public bool show_num_lines { get; set; }
        public bool show_save_button { get; set; }
        public bool spellcheck { get; set; }
        public bool statusbar { get; set; }
        public bool use_system_font { get; set; }
        public int margins { get; set; }
        public int spacing { get; set; }
        public int window_height { get; set; }
        public int window_width { get; set; }
        public int window_x { get; set; }
        public int window_y { get; set; }
        public string font { get; set; }
        public string last_file { get; set; }
        public string subtitle { get; set; }
        public string spellcheck_language { get; set; }

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
