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
*/

using Gtk;
using Granite;

namespace Quilter.Widgets {
    public class Toolbar : Gtk.HeaderBar {
        private Gtk.Button new_button;
        private Gtk.Button open_button;
        private Gtk.Button save_button;
        private Gtk.Button menu_button;
        private Widgets.Preferences preferences_dialog;

        public File file;
        public Quilter.MainWindow win;

        public Toolbar () {
            var settings = AppSettings.get_default ();
            this.subtitle = settings.last_file;
			var header_context = this.get_style_context ();
            header_context.add_class ("quilter-toolbar");

            new_button = new Gtk.Button ();
            new_button.set_image (new Gtk.Image.from_icon_name ("document-new", Gtk.IconSize.LARGE_TOOLBAR));
			new_button.has_tooltip = true;
            new_button.tooltip_text = (_("New file"));

            new_button.clicked.connect (() => {
                new_button_pressed ();
            });

            save_button = new Gtk.Button ();
            save_button.set_image (new Gtk.Image.from_icon_name ("document-save-as", Gtk.IconSize.LARGE_TOOLBAR));
			save_button.has_tooltip = true;
            save_button.tooltip_text = (_("Save as…"));

            save_button.clicked.connect (() => {
                save_button_pressed ();
            });

            open_button = new Gtk.Button ();
            open_button.set_image (new Gtk.Image.from_icon_name ("document-open", Gtk.IconSize.LARGE_TOOLBAR));
			open_button.has_tooltip = true;
            open_button.tooltip_text = (_("Open…"));

            open_button.clicked.connect (() => {
                open_button_pressed ();
            });

            menu_button = new Gtk.Button ();
            menu_button.set_image (new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR));
			menu_button.has_tooltip = true;
            menu_button.tooltip_text = (_("Settings"));

            menu_button.clicked.connect (() => {
                debug ("Prefs button pressed.");
                preferences_dialog = new Widgets.Preferences ();
                preferences_dialog.show_all ();
            });

            this.pack_start (new_button);
            this.pack_start (open_button);
            this.pack_start (save_button);
            this.pack_end (menu_button);

            this.show_close_button = true;
            this.show_all ();
        }

        public void new_button_pressed () {


            if (Widgets.SourceView.is_modified = true) {
                try {
                    debug ("Opening file...");
                    new_document ();
                } catch (Error e) {
                    error ("Unexpected error during open: " + e.message);
                }
            }

            file = null;
            Widgets.SourceView.is_modified = false;
        }

        public void open_button_pressed () {
            debug ("Open button pressed.");

            if (Widgets.SourceView.is_modified = true) {
                try {
                    debug ("Opening file...");
                    open_document ();
                } catch (Error e) {
                    error ("Unexpected error during open: " + e.message);
                }
            }

            file = null;
            Widgets.SourceView.is_modified = false;
        }

        public void save_button_pressed () {
            debug ("Save button pressed.");

            if (Widgets.SourceView.is_modified = true) {
                try {
                    debug ("Saving file...");
                    save_document ();
                } catch (Error e) {
                    error ("Unexpected error during save: " + e.message);
                }
            }

            file = null;
            Widgets.SourceView.is_modified = false;
        }

        public bool new_document () throws Error {
            if (Widgets.SourceView.is_modified) {
                debug ("Buffer was modified. Asking user to save first.");
                int wanna_save = Utils.DialogUtils.display_save_confirm ();
                if (wanna_save == Gtk.ResponseType.CANCEL ||
                    wanna_save == Gtk.ResponseType.DELETE_EVENT) {
                    debug ("User canceled save confirm. Aborting operation.");
                }

                if (wanna_save == Gtk.ResponseType.YES) {
                    debug ("Saving file before loading new file.");
                    try {
                        bool was_saved = save_document ();
                        if (!was_saved) {
                            debug ("Cancelling open document too.");
                            Widgets.SourceView.buffer.text = "";
                        }
                    } catch (Error e) {
                        error ("Unexpected error during save: " + e.message);
                    }
                }

                if (wanna_save == Gtk.ResponseType.NO) {
                    debug ("User cancelled the dialog. Remove document from view then.");
                    Widgets.SourceView.buffer.text = "";
                    this.subtitle = "";
                    var settings = AppSettings.get_default ();
                    settings.last_file = "";
                }
            }
            Utils.FileUtils.save_tmp_file ();
            return true;
        }

        public bool open_document () throws Error {
            if (file == null) {
                debug ("Asking the user what to open.");
                file = Utils.DialogUtils.display_open_dialog ();
                if (file == null) {
                    debug ("User cancelled operation. Aborting.");
                    return false;
                }
            }

            string text;
            FileUtils.get_contents (file.get_path (), out text);
            Widgets.SourceView.buffer.text = text;
            var settings = AppSettings.get_default ();
            settings.last_file = file.get_path ();
            this.subtitle = file.get_path ();
            return true;
        }

        public bool save_document () throws Error {
            if (file == null) {
                debug ("Asking the user where to save.");
                file = Utils.DialogUtils.display_save_dialog ();
                if (file == null) {
                    debug ("User cancelled operation. Aborting.");
                    return false;
                }
            }

            if (file.query_exists ())
                file.delete ();

            Gtk.TextIter start, end;
            Widgets.SourceView.buffer.get_bounds (out start, out end);
            string buffer = Widgets.SourceView.buffer.get_text (start, end, true);
            uint8[] binbuffer = buffer.data;
            Utils.FileUtils.save_file (file, binbuffer);
            return true;
        }
    }
}
