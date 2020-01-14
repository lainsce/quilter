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
*
* Co-authored by: Felipe Escoto <felescoto95@hotmail.com>
*/
namespace Quilter {
    public abstract class Plugins.Plugin : GLib.Object {
        private const string CHILD_SCHEMA_ID = "com.github.lainsce.quilter.plugin_data.plugin";
        private const string CHILD_PATH = "/com/github/lainsce/quilter/plugin_data/plugin/%s";

        protected Settings? settings = null;
        protected bool state = true;

        protected string code_name = "";

        // Editor after string is requested
        public signal void string_cooked (string text);

        public virtual bool is_active () {
            return state;
        }

        public virtual void set_active (bool active) {
            if (settings != null) {
                settings.set_boolean("active", active);
            }
        }

        // Description of the plugin
        public abstract string get_desctiption ();

        // Plugin name
        public abstract string get_name ();

        // What the module looks for in order to convert
        public abstract bool has_match (string text);

        // Once the viewer finds the key, it will call this function
        public abstract string convert (string line);

        // Widget that will be placed on a button on the text editor.
        public abstract Gtk.Widget? editor_button ();

        public virtual string get_button_desctiption () {
            return get_desctiption ();
        }

        // Action called by the editor when the button is pressed
        public virtual string request_string (string selection) {
            return selection;
        }

        protected void connect_settings (string setting) {
            Quilter.Application.gsettings.bind (setting, this, "active", SettingsBindFlags.DEFAULT);
        }
    }
}