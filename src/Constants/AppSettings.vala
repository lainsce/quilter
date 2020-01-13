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

    public class AppSettings : GLib.Settings {
        public bool autosave { 
            get { return get_boolean ("autosave"); }
            set { set_boolean ("autosave", value); }
        }
        public bool dark_mode { 
            get { return get_boolean ("dark-mode"); }
            set { set_boolean ("dark-mode", value); }
        }
        public bool focus_mode { 
            get { return get_boolean ("focus-mode"); }
            set { set_boolean ("focus-mode", value); }
        }
        public bool fullscreen { 
            get { return get_boolean ("fullscreen"); }
            set { set_boolean ("fullscreen", value); }
        }
        public bool highlight { 
            get { return get_boolean ("highlight"); }
            set { set_boolean ("highlight", value); }
        }
        public bool latex { 
            get { return get_boolean ("latex"); }
            set { set_boolean ("latex", value); }
        }
        public bool moon_mode { 
            get { return get_boolean ("moon-mode"); }
            set { set_boolean ("moon-mode", value); }
        }
        public bool searchbar { 
            get { return get_boolean ("searchbar"); }
            set { set_boolean ("searchbar", value); }
        }
        public bool sepia_mode { 
            get { return get_boolean ("sepia-mode"); }
            set { set_boolean ("sepia-mode", value); }
        }
        public bool show_filename { 
            get { return get_boolean ("show-filename"); }
            set { set_boolean ("show-filename", value); }
        }
        public bool shown_view { 
            get { return get_boolean ("shown-view"); }
            set { set_boolean ("shown-view", value); }
        }
        public bool spellcheck { 
            get { return get_boolean ("spellcheck"); }
            set { set_boolean ("spellcheck", value); }
        }
        public bool statusbar { 
            get { return get_boolean ("statusbar"); }
            set { set_boolean ("statusbar", value); }
        }
        public bool sidebar { 
            get { return get_boolean ("sidebar"); }
            set { set_boolean ("sidebar", value); }
        }
        public bool typewriter_scrolling { 
            get { return get_boolean ("typewriter-scrolling"); }
            set { set_boolean ("typewriter-scrolling", value); }
        }
        public int focus_mode_type {
            get { return get_int ("focus-mode-type"); }
            set { set_int ("focus-mode-type", value); }
        }
        public int font_sizing {
            get { return get_int ("font-sizing"); }
            set { set_int ("font-sizing", value); }
        }
        public int margins {
            get { return get_int ("margins"); }
            set { set_int ("margins", value); }
        }
        public int spacing {
            get { return get_int ("spacing"); }
            set { set_int ("spacing", value); }
        }
        public int window_height {
            get { return get_int ("window-height"); }
            set { set_int ("window-height", value); }
        }
        public int window_width {
            get { return get_int ("window-width"); }
            set { set_int ("window-width", value); }
        }
        public int window_x {
            get { return get_int ("window-x"); }
            set { set_int ("window-x", value); }
        }
        public int window_y {
            get { return get_int ("window-y"); }
            set { set_int ("window-y", value); }
        }
        public string current_file {
            owned get { return get_string ("current-file"); }
            set { set_string ("current-file", value); }
        }
        public string preview_font {
            owned get { return get_string ("preview-font"); }
            set { set_string ("preview-font", value); }
        }
        public string edit_font_type {
            owned get { return get_string ("edit-font-type"); }
            set { set_string ("edit-font-type", value); }
        }
        public string spellcheck_language {
            owned get { return get_string ("spellcheck-language"); }
            set { set_string ("spellcheck-language", value); }
        }
        public string track_type {
            owned get { return get_string ("track-type"); }
            set { set_string ("track-type", value); }
        }
        public string preview_type {
            owned get { return get_string ("preview-type"); }
            set { set_string ("preview-type", value); }
        }
        public string[] last_files {
            owned get { return get_strv ("last-files"); }
            set { set_strv ("last-files", value); }
        }

        public AppSettings () {
            debug ("Settings setupped correctly!");
            Object (schema_id: "com.github.lainsce.quilter");
        }
    }
}
