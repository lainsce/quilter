/*
* Copyright (c) 2019 Lains
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

public class Quilter.Highlighter : Plugins.Plugin {
    private PatternSpec spec = new PatternSpec ("*==*==*");

    construct {}

    public override string get_desctiption () {
        return _("Highlight text in marker yellow.");
    }

    public override string get_name () {
        return _("Highlight");
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
        int initial = line_.index_of ("==") + 2;
        int last = line_.index_of ("==", initial);
        string subline = line_.substring (initial, last - initial);
        if (Quilter.Application.gsettings.get_string("visual-mode") == "dark") {
            build = build + """<span style="background-color:#0DBCEE; color:#000; border: 3px solid #0DBCEE;">%s</span>""".printf(subline);
            return build;
        } if (Quilter.Application.gsettings.get_string("visual-mode") == "sepia") {
            build = build + """<span style="background-color:#00897b; color:#FFF; border: 3px solid #00897b;">%s</span>""".printf(subline);
            return build;
        } else {
            build = build + """<span style="background-color:#0073c5; color:#FFF; border: 3px solid #0073c5;">%s</span>""".printf(subline);
            return build;
        }
    }
}
