/*
 * Copyright (c) 2019-2020 Lains
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
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Co-authored by: Felipe Escoto <felescoto95@hotmail.com>
 */

public class Quilter.Filep : Plugins.Plugin {
    private PatternSpec spec = new PatternSpec ("*/*:file*");

    construct {}

    public override string get_desctiption () {
        return _("Load an embeded file");
    }

    public override string get_name () {
        return _("File");
    }

    public override Gtk.Widget? editor_button () {
        return null;
    }

    public override string request_string (string selection) {
        return selection;
    }

    public override string get_button_desctiption () {
        return "";
    }

    public override bool has_match (string text) {
        return spec.match_string (text);
    }

    public override string convert (string line_) {
        string text = "";
        int initial = line_.index_of ("/") + 1;
        int last = line_.index_of (" :file", initial);
        string subline = line_.substring (initial, last - initial);

        File file = File.new_for_path (subline);

        try {
            if (file.query_exists ()) {
                GLib.FileUtils.get_contents (subline, out text);
                var flags = new Markdown.Flags ();
                flags.set_flag_num (14); // TOC
                flags.set_flag_num (15); // AUTOLINK
                flags.set_flag_num (21); // EXTRA_FOOTNOTE
                flags.set_flag_num (24); // DLEXTRA
                var mkd = new Markdown.Document.from_string (text.data, flags);

                mkd.compile (flags);

                string result;
                mkd.get_document (out result);

                return line_.replace ("/%s :file".printf (subline), """%s""".printf (result));
            }
        } catch (Error e) {
            warning ("Error: %s", e.message);
        }

        return "No file.";
    }
}
