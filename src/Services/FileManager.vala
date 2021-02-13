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

namespace Quilter.Services.FileManager {
    public File tmp_file;
    public File file;
    public File cachedir;
    public MainWindow win;
    public Widgets.EditView view;
    private string[] files;

    private static string? cache;
    public static string get_cache_path () {
        if (cache == null) {
            cache = Path.build_filename (Environment.get_user_data_dir (), "com.github.lainsce.quilter");
            string cachedirpath = Path.build_filename (Environment.get_user_data_dir (), "com.github.lainsce.quilter");
            cachedir = File.new_for_path (cachedirpath);
            try {
                if (!cachedir.query_exists()) {
                    cachedir.make_directory_with_parents ();
                }
            } catch (Error e) {
                warning ("Error writing file: " + e.message);
            }
        }

        return cache;
    }

    public static string get_temp_document_path () {
        var name = new GLib.DateTime.now ();
        return Path.build_filename (get_cache_path (), @"~$name.md");
    }

    public void save_file (string path, string contents) throws Error {
        try {
            GLib.FileUtils.set_contents (path, contents);
        } catch (Error e) {
            var msg = e.message;
            warning (@"Error writing file: $msg");
        }
    }

    public bool is_temp_file (string path) {
        return get_cache_path () in path;
    }

    // File I/O
    public bool open_from_outside (MainWindow win, File[] ofiles, string hint) {
        foreach (File f in ofiles) {
            string text;
            string file_path = f.get_path ();
            files += file_path;
            Quilter.Application.gsettings.set_strv("last-files", files);
            if (win.sidebar != null && f != null) {
                win.sidebar.add_file (file_path);
            }
            try {
                GLib.FileUtils.get_contents (file_path, out text);
                win.edit_view_content.buffer.text = text;
                win.edit_view_content.buffer.set_modified (false);
                file = null;
            } catch (Error e) {
                warning ("Error: %s", e.message);
            }
        }
        win.save_last_files ();
        win.welcome_view.visible = false;
        win.main_stack.visible = true;
        return true;
    }

    public static string open (out string contents) {
        try {
            var chooser = Services.DialogUtils.create_file_chooser (_("Open File"),
                    Gtk.FileChooserAction.OPEN);
            if (chooser.run () == Gtk.ResponseType.ACCEPT)
                file = chooser.get_file ();
            chooser.destroy();
            GLib.FileUtils.get_contents (file.get_path (), out contents);
        } catch (Error e) {
            warning ("Error: %s", e.message);
        }
        return file.get_path ();
    }

    public void save_as (string contents, out string path) throws Error {
        var chooser = Services.DialogUtils.create_file_chooser (_("Save File"),
                Gtk.FileChooserAction.SAVE);
        if (chooser.run () == Gtk.ResponseType.ACCEPT)
            file = chooser.get_file ();
        chooser.destroy();
        if (!file.get_basename ().down ().has_suffix (".md")) {
            file = File.new_for_path (file.get_path () + ".md");
        }

        path = file.get_path ();

        try {
            if (file == null) {
                warning ("User cancelled operation. Aborting.");
            } else {
                save_file (path, contents);
                file = null;
            }
        } catch (Error e) {
            warning ("Unexpected error during save: " + e.message);
            throw e;
        }
    }

    public string get_yamlless_markdown (
        string markdown,
        int lines,
        out string title,
        out string date,
        bool non_empty = true,
        bool include_title = true,
        bool include_date = true)
    {
        string buffer = markdown;
        Regex headers = null;
        try {
            headers = new Regex ("^\\s*(.+)\\s*:\\s+(.*)", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
        } catch (Error e) {
            warning ("Could not compile regex: %s", e.message);
        }

        string temp_title = "";
        string temp_date = "";

        MatchInfo matches;
        var markout = new StringBuilder ();
        int mklines = 0;

        if (buffer.length > 4 && buffer[0:4] == "---\n") {
            int i = 0;
            int last_newline = 3;
            int next_newline;
            bool valid_frontmatter = true;
            string line = "";

            while (valid_frontmatter) {
                next_newline = buffer.index_of_char('\n', last_newline + 1);
                if (next_newline == -1 && !((buffer.length > last_newline + 1) && buffer.substring (last_newline + 1).has_prefix("---"))) {
                    valid_frontmatter = false;
                    break;
                }

                if (next_newline == -1) {
                    line = buffer.substring (last_newline + 1);
                } else {
                    line = buffer[last_newline+1:next_newline];
                }
                last_newline = next_newline;

                if (line == "---") {
                    break;
                }

                if (headers != null) {
                    if (headers.match (line, RegexMatchFlags.NOTEMPTY_ATSTART, out matches)) {
                        if (matches.fetch (1).ascii_down() == "title") {
                            temp_title = matches.fetch (2).chug ().chomp ();
                            if (temp_title.has_prefix ("\"") && temp_title.has_suffix ("\"")) {
                                temp_title = temp_title.substring (1, temp_title.length - 2);
                            }
                            if (include_title) {
                                markout.append ("# " + temp_title + "\n");
                                mklines++;
                            }
                        } else if (matches.fetch (1).ascii_down() == "date") {
                            temp_date = matches.fetch (2).chug ().chomp ();
                            if (include_date) {
                                markout.append ("## " + temp_date + "\n");
                                mklines++;
                            }
                        }
                    } else {
                        line = line.down ().chomp ();
                        if (!line.has_prefix ("-") && line != "") {
                            valid_frontmatter = false;
                            break;
                        }
                    }
                } else {
                    string quick_parse = line.chomp ();
                    if (quick_parse.has_prefix ("title")) {
                        temp_title = quick_parse.substring (quick_parse.index_of (":") + 1);
                        if (temp_title.has_prefix ("\"") && temp_title.has_suffix ("\"")) {
                            temp_title = temp_title.substring (1, temp_title.length - 2);
                        }
                        if (include_title) {
                            markout.append ("# " + temp_title);
                            mklines++;
                        }
                    } else if (quick_parse.has_prefix ("date")) {
                        temp_date = quick_parse.substring (quick_parse.index_of (":") + 1).chug ().chomp ();
                        if (include_date) {
                            markout.append ("## " + temp_date);
                            mklines++;
                        }
                    }
                }

                i++;
            }

            if (!valid_frontmatter) {
                markout.erase ();
                markout.append (markdown);
            } else {
                markout.append (buffer[last_newline:buffer.length]);
            }
        } else {
            markout.append (markdown);
        }

        title = temp_title;
        date = temp_date;

        return markout.str;
    }
}
