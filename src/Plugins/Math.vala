/*
* Copyright (c) 2018 Lains
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
*                 David Pinto   <tri.davidpinto@gmail.com>
*/
namespace Quilter { 
    public class Plugins.Math : Plugins.Plugin {
        private PatternSpec spec = new PatternSpec ("*$$*$$*");
    
        construct {
        }
    
        public override bool is_active () {
            return true;
        }
    
        public override void set_active (bool active) {
        }
    
        public override string get_desctiption () {
            return _("Create math functions using LaTeX");
        }
    
        public override string get_name () {
            return _("Math");
        }
    
        public override Gtk.Widget? editor_button () {
            return null;
        }
    
        public override string get_button_desctiption () {
            return _("Insert Maths function");
        }
    
        public override bool has_match (string text) {
            return spec.match_string (text);
        }
    
        public override string convert (string line_) {
            string build = "";
            int initial = line_.index_of ("$$") + 2;
            int last = line_.index_of ("$$", initial);
            string subline = line_.substring (initial, last - initial);
            var settings = AppSettings.get_default ();
            if (settings.dark_mode) {
                build = build + "<img style=\"margin-top: 16px; margin-bottom: 16px;filter: invert(100%);\" src=\"http://latex.codecogs.com/png.latex?" + subline + "\" border=\"0\"/>";
            } else {
                build = build + "<img style=\"margin-top: 16px; margin-bottom: 16px;\" src=\"http://latex.codecogs.com/png.latex?" + subline + "\" border=\"0\"/>";
            }
            return build;
        }
    }    
}