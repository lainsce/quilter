/*
 * Copyright (C) 2017-2021 Lains
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

namespace Quilter.Services {
    public class FileManager : Object {
        private static FileManager? instance;
        private string? cache_path;
        private File? cache_dir;

        public static FileManager get_instance () {
            if (instance == null) {
                instance = new FileManager ();
            }
            return instance;
        }

        private Gee.HashMap<string, bool> temp_files;

        private FileManager () {
            temp_files = new Gee.HashMap<string, bool> ();
            cache_path = null;
            cache_dir = null;
        }

        public string get_cache_path () {
            if (cache_path == null) {
                cache_path = Path.build_filename (Environment.get_user_data_dir (), "io.github.lainsce.Quilter");
                cache_dir = File.new_for_path (cache_path);
                try {
                    if (!cache_dir.query_exists ()) {
                        cache_dir.make_directory_with_parents ();
                    }
                } catch (Error e) {
                    warning ("Error creating cache directory: %s", e.message);
                }
            }
            return cache_path;
        }

        public string get_temp_document_path () {
            var name = new GLib.DateTime.now_local ().format ("%H%M%S");
            return Path.build_filename (get_cache_path (), @"~markdown-$name.md");
        }

        public string create_temp_file () {
            string path = get_temp_document_path ();
            temp_files.set (path, true);
            return path;
        }

        public bool is_temp_file (string path) {
            return temp_files.has_key (path);
        }

        public void save_file (string path, string contents) throws Error {
            try {
                FileUtils.set_contents (path, contents);
                if (is_temp_file (path)) {
                    temp_files.unset (path);
                }
            } catch (Error e) {
                throw new FileError.FAILED (@"Error writing file: $(e.message)");
            }
        }

        public struct OpenResult {
            public string path;
            public string contents;
        }

        public async OpenResult ? open (Gtk.Window? parent = null) throws Error {
            var chooser = Services.DialogUtils.create_file_chooser (_("Open File"),
                                                                    Gtk.FileChooserAction.OPEN,
                                                                    parent);
            int response = yield DialogUtils.run_file_chooser_async (chooser);

            if (response == Gtk.ResponseType.ACCEPT) {
                var file = chooser.get_file ();
                string path = file.get_path ();
                uint8[] bytes;
                yield file.load_contents_async (null, out bytes, null);

                string contents = (string) bytes;

                return OpenResult () {
                           path = path,
                           contents = contents
                };
            }
            return null;
        }

        public async string save_as (string contents, Gtk.Window? parent = null) throws Error {
            var chooser = Services.DialogUtils.create_file_chooser (_("Save File"),
                                                                    Gtk.FileChooserAction.SAVE,
                                                                    parent);
            var response = yield DialogUtils.run_file_chooser_async (chooser);

            if (response == Gtk.ResponseType.ACCEPT) {
                var file = chooser.get_file ();
                if (!file.get_basename ().down ().has_suffix (".md")) {
                    file = File.new_for_path (file.get_path () + ".md");
                }

                string path = file.get_path ();

                try {
                    yield save_file_async (path, contents);

                    // If it was a temp file, update its status
                    if (is_temp_file (path)) {
                        temp_files.unset (path);
                    }

                    return path;
                } catch (Error e) {
                    warning ("Unexpected error during save: " + e.message);
                    throw e;
                }
            } else {
                throw new IOError.CANCELLED ("File selection cancelled");
            }
        }

        public bool open_from_outside (MainWindow win, File[] files, string hint) {
            string[] file_paths = {};
            foreach (File f in files) {
                string file_path = f.get_path ();
                file_paths += file_path;
                if (win.sidebar != null && f != null) {
                    win.sidebar.add_file (file_path);
                }
                try {
                    string text;
                    FileUtils.get_contents (file_path, out text);
                    win.edit_view_content.buffer.text = text;
                    win.edit_view_content.buffer.set_modified (false);
                } catch (Error e) {
                    warning ("Error opening file: %s", e.message);
                    return false;
                }
            }
            Quilter.Application.gsettings.set_strv ("last-files", file_paths);
            win.save_last_files ();
            return true;
        }

        private async void save_file_async (string path, string contents) throws Error {
            var file = File.new_for_path (path);
            yield file.replace_contents_async (contents.data, null, false, FileCreateFlags.REPLACE_DESTINATION, null, null);
        }

        // Simplified file list management - just use a simple text file instead of JSON
        public void save_open_files (MainWindow win) {
            try {
                var cache_dir = File.new_for_path (get_cache_path ());
                if (!cache_dir.query_exists ()) {
                    cache_dir.make_directory_with_parents ();
                }

                var file = File.new_for_path (Path.build_filename (get_cache_path (), "open_files.txt"));
                var output = new StringBuilder ();

                var child = win.sidebar.column.get_first_child ();
                while (child != null) {
                    if (child is Widgets.SideBarBox) {
                        var box = (Widgets.SideBarBox) child;
                        // Simple format: path|title
                        output.append_printf ("%s|%s\n", box.path, box.row.title);
                    }
                    child = child.get_next_sibling ();
                }

                FileUtils.set_contents (file.get_path (), output.str);
            } catch (Error e) {
                warning ("Failed to save open files: %s", e.message);
            }
        }

        public Gee.List<OpenFile> load_open_files () {
            var files = new Gee.ArrayList<OpenFile> ();
            var file = File.new_for_path (Path.build_filename (get_cache_path (), "open_files.txt"));

            if (!file.query_exists ()) {
                return files;
            }

            try {
                string content;
                FileUtils.get_contents (file.get_path (), out content);
                string[] lines = content.strip ().split ("\n");

                int id = 0;
                foreach (string line in lines) {
                    if (line.strip () == "")continue;

                    string[] parts = line.split ("|", 2);
                    if (parts.length == 2) {
                        files.add (new OpenFile (id++, parts[1], parts[0]));
                    }
                }
            } catch (Error e) {
                warning ("Failed to load open files: %s", e.message);
            }

            return files;
        }

        // Simplified YAML processing - just extract title and date without complex regex
        public string get_yamlless_markdown (string markdown,
                                             int lines,
                                             out string title,
                                             out string date,
                                             bool non_empty = true,
                                             bool include_title = true,
                                             bool include_date = true) {
            title = "";
            date = "";

            if (!markdown.has_prefix ("---\n")) {
                return markdown;
            }

            string[] lines_array = markdown.split ("\n");
            var result = new StringBuilder ();
            bool in_frontmatter = true;
            bool found_end = false;

            for (int i = 1; i < lines_array.length; i++) {
                string line = lines_array[i];

                if (in_frontmatter) {
                    if (line == "---") {
                        found_end = true;
                        in_frontmatter = false;
                        continue;
                    }

                    // Simple title/date extraction
                    if (line.has_prefix ("title:")) {
                        title = line.substring (6).strip ();
                        if (title.has_prefix ("\"") && title.has_suffix ("\"")) {
                            title = title.substring (1, title.length - 2);
                        }
                        if (include_title && title != "") {
                            result.append_printf ("# %s\n", title);
                        }
                    } else if (line.has_prefix ("date:")) {
                        date = line.substring (5).strip ();
                        if (include_date && date != "") {
                            result.append_printf ("## %s\n", date);
                        }
                    }
                } else {
                    result.append_printf ("%s\n", line);
                }
            }

            if (!found_end) {
                return markdown; // Invalid frontmatter, return original
            }

            return result.str;
        }
    }
}
