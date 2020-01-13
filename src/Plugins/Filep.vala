/*
* Copyright (c) 2020 Lains
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
        string build = "";
        string text = "";
        int initial = line_.index_of ("/") + 1;
        int last = line_.index_of (" :file", initial);
        string subline = line_.substring (initial, last - initial);

        File file = File.new_for_path (subline);

        try {
            if (file.query_exists()) {
                GLib.FileUtils.get_contents(subline, out text);
                var mkd = new Markdown.Document.gfm_format (text.data,
                                                            0x00004000 +
                                                            0x00200000 +
                                                            0x00400000 +
                                                            0x02000000 +
                                                            0x01000000 +
                                                            0x04000000 +
                                                            0x10000000 +
                                                            0x40000000);
                mkd.compile (0x00004000 +
                             0x00200000 +
                             0x00400000 +
                             0x02000000 +
                             0x01000000 +
                             0x04000000 +
                             0x10000000 +
                             0x40000000);

                string result;
                mkd.get_document (out result);

                build = build + result;
                return build;
            }
        } catch (Error e) {
            warning ("Error: %s", e.message);
        }

        return "No file.";
    }
}
