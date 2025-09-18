/*
 * Copyright (c) 2017-2023 Your Name
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */
namespace Quilter {
    [GtkTemplate (ui = "/io/github/lainsce/Quilter/main_window.ui")]
    public class MainWindow : He.ApplicationWindow {
        // UI Elements
        [GtkChild]
        private unowned Gtk.Overlay about_overlay;
        [GtkChild]
        private unowned Gtk.Box root_box;
        [GtkChild]
        private unowned Gtk.Box content_box;
        [GtkChild]
        private unowned Gtk.Button focus_overlay_button;
        [GtkChild]
        private unowned Gtk.Revealer overlay_button_revealer;
        [GtkChild]
        private unowned Gtk.Revealer appbar_revealer;
        [GtkChild]
        private unowned Gtk.Stack appbar_stack;

        // Widgets
        private Gtk.ScrolledWindow edit_view;
        private Gtk.Box preview_revealer;
        public Widgets.EditView edit_view_content;
        public Widgets.Headerbar appbar;
        public Widgets.HeaderBarButton samenu_button;
        public Widgets.Preview preview_view_content;
        public Widgets.SearchBar searchbar;
        public Widgets.StatusBar statusbar;
        public Widgets.SideBar sidebar;

        // Other properties
        public Gtk.Adjustment eadj;
        private bool is_opening;
        public SimpleActionGroup actions { get; construct; }
        public weak Quilter.Application app { get; construct; }

        // Services
        private Services.FileManager file_manager;

        // Constants
        public const string ACTION_PREFIX = "win.";
        public const string ACTION_CHEATSHEET = "action_cheatsheet";
        public const string ACTION_EXPORT_HTML = "action_export_html";
        public const string ACTION_EXPORT_PDF = "action_export_pdf";
        public const string ACTION_FOCUS = "action_focus";
        public const string ACTION_SEARCH = "action_search";
        public const string ACTION_PREFS = "action_preferences";
        public const string ACTION_ABOUT = "action_about";

        // Static properties
        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        // Signals
        public signal void toggle_sidebar (bool is_active);

        public new bool is_fullscreen {
            get {
                return Quilter.Application.gsettings.get_boolean ("fullscreen");
            }
            set {
                Quilter.Application.gsettings.set_boolean ("fullscreen", value);
                if (value) {
                    fullscreen ();
                    if (Quilter.Application.gsettings.get_string ("preview-type") != "full") {
                        Quilter.Application.gsettings.set_string ("preview-type", "full");
                    }
                    edit_view_content.add_css_class ("full-text");
                    edit_view_content.remove_css_class ("small-text");
                    sidebar.visible = false;
                } else {
                    unfullscreen ();
                    edit_view_content.add_css_class ("small-text");
                    edit_view_content.remove_css_class ("full-text");
                    sidebar.visible = true;
                }
            }
        }

        public MainWindow (Quilter.Application application) {
            Object (
                    application: application,
                    app: application,
                    title: "Quilter",
                    actions: new SimpleActionGroup ()
            );
        }

        static construct {
            setup_action_accelerators ();
        }
        construct {
            file_manager = Services.FileManager.get_instance ();
            insert_action_group ("win", actions);
            create_action_entries ();
            setup_widgets ();
            setup_signals ();
            initialize_file_handling ();
            initialize_preview_state ();
            initialize_sidebar_state ();

            show ();
        }

        private void initialize_file_handling () {
            file_manager.get_cache_path ();
            var path = Quilter.Application.gsettings.get_string ("current-file");

            if (path == "") {
                var open_files = file_manager.load_open_files ();
                sidebar.load_files_from_list (open_files);
                sidebar.outline_populate ();
            } else {
                // Restore last current file, select it and load its content
                var box = sidebar.add_file (path);
                sidebar.column.select_row (box);
                load_file_content (path);
            }

            eadj = edit_view.get_vadjustment ();
            eadj.notify["value"].connect (() => {
                scroll_to ();
            });
        }

        private void initialize_preview_state () {
            bool show_preview = Quilter.Application.gsettings.get_boolean ("show-preview");
            appbar.update_preview_toggle_state (show_preview);
            update_preview_visibility ();
        }

        private void setup_widgets () {
            // Headerbar
            appbar = new Widgets.Headerbar (this);
            appbar_revealer.set_child (appbar);
            appbar_revealer.set_reveal_child (true);

            samenu_button = new Widgets.HeaderBarButton ();
            samenu_button.update_title (_("New Document"));
            samenu_button.rename_requested.connect (on_rename_requested);
            samenu_button.sidebar_toggle_button.toggled.connect (() => {
                toggle_sidebar (samenu_button.sidebar_toggle_button.active);
                update_title_buttons_visibility (!samenu_button.sidebar_toggle_button.active);
            });
            samenu_button.sidebar_toggle_button.active = true;

            appbar.headerbar.viewtitle_widget = samenu_button;

            // Create an overlay container for the main content area
            var main_overlay = new Gtk.Overlay ();

            // Create the main content box (editor + preview)
            var editor_preview_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            editor_preview_box.hexpand = true;
            editor_preview_box.vexpand = true;
            editor_preview_box.homogeneous = true;

            // EditView
            edit_view_content = new Widgets.EditView (this);
            edit_view = new Gtk.ScrolledWindow ();
            edit_view.hexpand = true;
            edit_view.vexpand = true;
            edit_view_content.css_classes = { "edit-view-paned" };
            edit_view.set_child (edit_view_content);
            edit_view_content.buffer.changed.connect (on_buffer_changed);
            editor_preview_box.append (edit_view);

            // Preview
            preview_view_content = new Widgets.Preview (this, edit_view_content);
            preview_revealer = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            preview_view_content.css_classes = { "preview-view-paned" };
            preview_revealer.hexpand = true;
            preview_revealer.vexpand = true;
            preview_revealer.append (preview_view_content);
            preview_revealer.visible = true;
            editor_preview_box.append (preview_revealer);

            // Add the editor/preview box as the main child of the overlay
            main_overlay.set_child (editor_preview_box);

            // StatusBar - overlay at the bottom
            statusbar = new Widgets.StatusBar (this, edit_view_content.buffer);
            statusbar.add_css_class ("statusbar-overlay");

            // Add statusbar as an overlay
            main_overlay.add_overlay (statusbar);

            // Sidebar
            sidebar = new Widgets.SideBar (this, edit_view_content);
            sidebar.column.row_selected.connect (on_sidebar_row_selected);
            root_box.prepend (sidebar);

            // SearchBar - still goes in content_box above the main content
            searchbar = new Widgets.SearchBar (this);
            var search_revealer = new Gtk.Revealer () {
                transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
                reveal_child = Quilter.Application.gsettings.get_boolean ("searchbar"),
                visible = true
            };
            search_revealer.set_child (searchbar);
            content_box.append (search_revealer);

            // Add the main overlay to content_box
            content_box.append (main_overlay);
        }

        private void initialize_sidebar_state () {
            bool show_sidebar = Quilter.Application.gsettings.get_boolean ("sidebar");
            update_sidebar_toggle_state (show_sidebar);
            sidebar.visible = show_sidebar;
        }

        public void update_sidebar_toggle_state (bool is_active) {
            samenu_button.sidebar_toggle_button.active = is_active;
            update_title_buttons_visibility (!is_active);
        }

        private void on_toggle_sidebar (bool is_active) {
            Quilter.Application.gsettings.set_boolean ("sidebar", is_active);
            sidebar.visible = is_active;
            update_sidebar_toggle_state (is_active);
        }

        private void update_title_buttons_visibility (bool visible) {
            appbar.headerbar.show_left_title_buttons = visible;
        }

        private void setup_signals () {
            Quilter.Application.gsettings.changed.connect (on_settings_changed);
            appbar.open.connect (() => { print ("DEBUG: open clicked\n"); on_open (); });
            appbar.save.connect (() => { print ("DEBUG: save clicked\n"); on_save (); });
            appbar.save_as.connect (() => { print ("DEBUG: save_as clicked\n"); on_save_as (); });
            appbar.create_new.connect (() => { print ("DEBUG: new clicked\n"); on_create_new (); });
            appbar.preview_toggled.connect (on_preview_toggled);
            toggle_sidebar.connect (on_toggle_sidebar);
            focus_overlay_button.clicked.connect (() => {
                toggle_focus_mode_action ();
            });
        }

        private void on_preview_toggled (bool is_active) {
            preview_revealer.set_visible (is_active);
            Quilter.Application.gsettings.set_boolean ("show-preview", is_active);
            update_preview_visibility ();
        }

        private void update_preview_visibility () {
            bool show_preview = Quilter.Application.gsettings.get_boolean ("show-preview");
            preview_revealer.set_visible (show_preview);

            if (show_preview) {
                preview_view_content.update_html_view ();
            }
        }

        private void on_sidebar_row_selected (Gtk.ListBoxRow? row) {
            if (row == null) {
                edit_view_content.buffer.text = "";
                edit_view_content.modified = false;
                update_samenu_title ("");
            } else {
                var sidebar_box = row as Widgets.SideBarBox;
                if (sidebar_box != null) {
                    load_file_content (sidebar_box.path);
                }
            }
        }

        private void load_file_content (string path) {
            try {
                string content;
                FileUtils.get_contents (path, out content);
                edit_view_content.buffer.text = content;
                edit_view_content.modified = false;
                update_samenu_title (path);
                Quilter.Application.gsettings.set_string ("current-file", path);
                sidebar.outline_populate ();
                file_manager.save_open_files (this);
            } catch (Error e) {
                warning ("Error loading file content: %s", e.message);
            }
        }

        private void on_rename_requested (string new_name) {
            unowned Widgets.SideBarBox? row = sidebar.get_selected_row ();
            if (row == null) {
                var cf = Quilter.Application.gsettings.get_string ("current-file");
                if (cf != null && cf != "") {
                    var maybe = sidebar.find_file_box (cf);
                    if (maybe != null) {
                        sidebar.column.select_row (maybe);
                        row = maybe;
                    }
                }
                if (row == null) return;
            }

            try {
                string old_path = row.path;
                string dir = Path.get_dirname (old_path);
                string new_path = Path.build_filename (dir, new_name);

                if (!new_name.has_suffix (".md")) {
                    new_path += ".md";
                }

                File old_file = File.new_for_path (old_path);
                File new_file = File.new_for_path (new_path);

                if (old_file.move (new_file, FileCopyFlags.NONE)) {
                    row.path = new_path;
                    update_samenu_title (new_path);
                    // Update by referencing the new path
                    sidebar.update_file_title (new_path, Path.get_basename (new_path));
                    file_manager.save_open_files (this);
                    Quilter.Application.gsettings.set_string ("current-file", new_path);
                    sidebar.outline_populate ();
                }
            } catch (Error e) {
                warning ("Error renaming file: %s", e.message);
            }
        }

        public void update_samenu_title (string path) {
            string title;
            if (file_manager.is_temp_file (path)) {
                title = _("New Document");
            } else {
                title = Path.get_basename (path);
            }
            samenu_button.update_title (title);
        }

        private static void setup_action_accelerators () {
            action_accelerators.set (ACTION_CHEATSHEET, "<Control>h");
            action_accelerators.set (ACTION_EXPORT_HTML, "<Control>g");
            action_accelerators.set (ACTION_EXPORT_PDF, "<Control>p");
            action_accelerators.set ("quit", "<Control>q");
            action_accelerators.set ("new", "<Control>n");
            action_accelerators.set ("save", "<Control>s");
            action_accelerators.set ("save_as", "<Control><Shift>S");
            action_accelerators.set ("open", "<Control>o");
            action_accelerators.set ("search", "<Control>f");
            action_accelerators.set ("undo", "<Control>z");
            action_accelerators.set ("redo", "<Control><Shift>Z");
            action_accelerators.set ("fullscreen", "F11");
            action_accelerators.set ("toggle_sidebar", "<Control>2");
            action_accelerators.set ("toggle_focus_mode", "<Control>3");
        }

        private void create_action_entries () {
            var entries = new GLib.ActionEntry[] {
                { ACTION_CHEATSHEET, action_cheatsheet },
                { ACTION_EXPORT_HTML, action_export_html },
                { ACTION_EXPORT_PDF, action_export_pdf },
                { ACTION_FOCUS, action_focus },
                { ACTION_SEARCH, action_search },
                { ACTION_PREFS, action_preferences },
                { ACTION_ABOUT, action_about },
                { "new", on_create_new },
                { "save", on_save },
                { "save_as", on_save_as },
                { "open", on_open },
                { "quit", quit_action },
                { "undo", undo_action },
                { "redo", redo_action },
                { "fullscreen", fullscreen_action },
                { "toggle_sidebar", toggle_sidebar_action },
                { "toggle_focus_mode", toggle_focus_mode_action }
            };

            actions.add_action_entries (entries, this);
        }

        private void quit_action () {
            this.close ();
        }

        private void undo_action () {
            edit_view_content.buffer.undo ();
        }

        private void redo_action () {
            edit_view_content.buffer.redo ();
        }

        private void fullscreen_action () {
            is_fullscreen = !is_fullscreen;
        }

        private void toggle_sidebar_action () {
            var current_sidebar_state = Quilter.Application.gsettings.get_boolean ("sidebar");
            Quilter.Application.gsettings.set_boolean ("sidebar", !current_sidebar_state);
            sidebar.visible = !current_sidebar_state;
            update_sidebar_toggle_state (!current_sidebar_state);
        }

        private void toggle_focus_mode_action () {
            var current_focus_mode = Quilter.Application.gsettings.get_boolean ("focus-mode");
            Quilter.Application.gsettings.set_boolean ("focus-mode", !current_focus_mode);
            if (!current_focus_mode) {
                action_focus ();
            } else {
                exit_focus_mode ();
            }
        }

        private void on_settings_changed () {
            update_count ();
            edit_view_content.dynamic_margins ();
            show_searchbar ();
            show_statusbar ();
            update_preview_visibility ();
            appbar.update_preview_toggle_state (Quilter.Application.gsettings.get_boolean ("show-preview"));
            show_sidebar ();
            exit_focus_mode ();

            if (Quilter.Application.gsettings.get_boolean ("focus-mode")) {
                action_focus ();
            } else {
                exit_focus_mode ();
            }

            render_func ();
        }

        private void on_buffer_changed () {
            edit_view_content.modified = true;
            if (Quilter.Application.gsettings.get_boolean ("pos")) {
                edit_view_content.pos_syntax_start ();
            }
            render_func ();
            update_count ();
            scroll_to ();
            sidebar.outline_populate ();
        }

        private void action_cheatsheet () {
            var cheatsheet = new Widgets.Cheatsheet (this);
            cheatsheet.present ();
        }

        private void action_preferences () {
            var prefs = new Widgets.Preferences (this);
            prefs.present ();
        }

        private void action_focus () {
            print ("action_focus called\n");
            overlay_button_revealer.reveal_child = true;
            overlay_button_revealer.visible = true;
            sidebar.visible = false;

            // Hide statusbar using its built-in revealer
            if (statusbar != null) {
                statusbar.statusbar.set_reveal_child (false);
            }

            appbar_revealer.set_reveal_child (false);
        }

        private void exit_focus_mode () {
            overlay_button_revealer.reveal_child = false;
            overlay_button_revealer.visible = false;
            appbar_revealer.set_reveal_child (true);
            show_statusbar (); // Restore statusbar when exiting focus mode
            show_sidebar ();
        }

        private void action_search () {
            Quilter.Application.gsettings.set_boolean ("searchbar", true);
        }

        private void action_export_pdf () {
            Quilter.Services.ExportUtils.window = this;
            print ("Export PDF action triggered\n");
            Quilter.Services.ExportUtils.export_pdf ();
        }

        private void action_export_html () {
            Quilter.Services.ExportUtils.window = this;
            print ("Export HTML action triggered\n");
            Quilter.Services.ExportUtils.export_html ();
        }

        private void action_about () {
            var about = new He.AboutWindow (
                                            this,
                                            _("Quilter"),
                                            Config.APP_ID,
                                            Config.VERSION,
                                            Config.APP_ID,
                                            null,
                                            "https://github.com/lainsce/quilter/issues",
                                            "https://github.com/lainsce/quilter",
                                            null,
                                            { "Lains" },
                                            2016,
                                            He.AboutWindow.Licenses.GPLV3,
                                            He.Colors.BLUE
            );
            about_overlay.add_overlay (about);
            about.present ();
        }

        private void on_create_new () {
            print ("DEBUG: on_create_new()\n");
            create_new_document ();
            file_manager.save_open_files (this);
        }

        private void create_new_document () {
            edit_view_content.text = "";
            appbar_stack.set_visible_child_name ("title");
            sidebar.visible = true;
            Quilter.Application.gsettings.set_boolean ("sidebar", true);
            edit_view_content.modified = false;

            string temp_path = file_manager.create_temp_file ();
            var new_file_box = sidebar.add_file (temp_path);
            sidebar.column.select_row (new_file_box);

            preview_view_content.update_html_view ();
            sidebar.outline_populate ();
            update_samenu_title (temp_path);
        }

        private void on_open () {
            print ("DEBUG: on_open()\n");
            on_open_async.begin ((obj, res) => {
                try {
                    on_open_async.end (res);
                } catch (Error e) {
                    warning ("Error in open operation: %s", e.message);
                }
            });
        }

        private async void on_open_async () {
            print ("DEBUG: on_open_async() start\n");
            if (is_opening)return;
            is_opening = true;

            try {
                var result = yield file_manager.open (this);
                
                if (result == null) {
                    print ("DEBUG: open canceled or null result\n");
                    is_opening = false;
                    return;
                }

                // Check if file is already open and select it; otherwise add and select
                var existing_box = sidebar.find_file_box (result.path);
                if (existing_box != null) {
                    sidebar.column.select_row (existing_box);
                } else {
                    var new_box = sidebar.add_file (result.path);
                    sidebar.column.select_row (new_box);
                    file_manager.save_open_files (this);
                }

                edit_view_content.text = result.contents;
                edit_view_content.modified = false;
                update_samenu_title (result.path);
                Quilter.Application.gsettings.set_string ("current-file", result.path);
                save_last_files ();
                appbar_stack.set_visible_child_name ("title");
                Quilter.Application.gsettings.set_boolean ("sidebar", true);
                sidebar.outline_populate ();
            } catch (Error e) {
                warning ("Error opening file: %s", e.message);
            }

            is_opening = false;
        }

        private void on_save () {
            print ("DEBUG: on_save()\n");
            unowned Widgets.SideBarBox? row = sidebar.get_selected_row ();
            if (row == null) {
                // Fallback to current-file if no row is selected
                var cf = Quilter.Application.gsettings.get_string ("current-file");
                if (cf != null && cf != "") {
                    var maybe = sidebar.find_file_box (cf);
                    if (maybe == null) {
                        maybe = sidebar.add_file (cf);
                    }
                    if (maybe != null) {
                        sidebar.column.select_row (maybe);
                        row = maybe;
                    }
                }
                if (row == null) return;
            }

            try {
                // If this is a temp/unsaved file, route to Save As
                if (file_manager.is_temp_file (row.path)) {
                    print ("DEBUG: on_save() -> temp file, delegating to Save As\n");
                    on_save_as ();
                    return;
                }

                file_manager.save_file (row.path, edit_view_content.text);
                edit_view_content.modified = false;
                sidebar.outline_populate ();
                update_samenu_title (row.path);
                row.update_title (Path.get_basename (row.path));
                Quilter.Application.gsettings.set_string ("current-file", row.path);
                file_manager.save_open_files (this);
            } catch (Error e) {
                warning ("Error saving file: %s", e.message);
            }
        }

        private void on_save_as () {
            print ("DEBUG: on_save_as()\n");
            on_save_as_async.begin ((obj, res) => {
                try {
                    on_save_as_async.end (res);
                } catch (Error e) {
                    warning ("Error in save as operation: %s", e.message);
                }
            });
        }

        private async void on_save_as_async () {
            print ("DEBUG: on_save_as_async() start\n");
            unowned Widgets.SideBarBox? row = sidebar.get_selected_row ();
            if (row == null) {
                // Fallback to current-file if no row is selected
                var cf = Quilter.Application.gsettings.get_string ("current-file");
                if (cf != null && cf != "") {
                    var maybe = sidebar.find_file_box (cf);
                    if (maybe == null) {
                        maybe = sidebar.add_file (cf);
                    }
                    if (maybe != null) {
                        sidebar.column.select_row (maybe);
                        row = maybe;
                    }
                }
                if (row == null) return;
            }

            try {
                string new_path = yield file_manager.save_as (edit_view_content.text, this);

                if (new_path != "") {
                    print ("DEBUG: save_as -> new path: %s\n", new_path);
                    edit_view_content.modified = false;
                    update_samenu_title (new_path);
                    row.path = new_path;
                    sidebar.update_file_title (new_path, Path.get_basename (new_path));
                    file_manager.save_open_files (this);
                    Quilter.Application.gsettings.set_string ("current-file", new_path);
                    sidebar.outline_populate ();
                }
            } catch (Error e) {
                warning ("Error in save as: %s", e.message);
            }
        }

        private void update_count () {
            if (Quilter.Application.gsettings.get_string ("track-type") == "words") {
                statusbar.update_wordcount ();
            } else if (Quilter.Application.gsettings.get_string ("track-type") == "lines") {
                statusbar.update_linecount ();
            } else if (Quilter.Application.gsettings.get_string ("track-type") == "rtc") {
                statusbar.update_readtimecount ();
            }
        }

        public async void render_func_async () {
            render_func ();
            yield;
        }

        public void render_func () {
            preview_view_content.update_html_view ();
            if (edit_view_content.buffer.get_modified () == true) {
                preview_view_content.update_html_view ();
                edit_view_content.buffer.set_modified (false);
            }
        }

        public void show_searchbar () {
            // Find the search revealer (should be second-to-last child of content_box)
            Gtk.Widget? child = content_box.get_first_child ();
            while (child != null) {
                if (child is Gtk.Revealer) {
                    var revealer = child as Gtk.Revealer;
                    var search_child = revealer.get_child ();
                    if (search_child is Widgets.SearchBar) {
                        bool should_show = Quilter.Application.gsettings.get_boolean ("searchbar");
                        revealer.set_reveal_child (should_show);
                        break;
                    }
                }
                child = child.get_next_sibling ();
            }
        }

        public void show_statusbar () {
            if (statusbar != null) {
                bool should_show = Quilter.Application.gsettings.get_boolean ("statusbar");
                statusbar.statusbar.set_reveal_child (should_show);
            }
        }

        public void show_sidebar () {
            bool show_sidebar = Quilter.Application.gsettings.get_boolean ("sidebar");
            sidebar.visible = show_sidebar;
            update_sidebar_toggle_state (show_sidebar);
        }

        private void set_prev_workfile () {
            if (((Widgets.SideBarBox) sidebar.column.get_selected_row ()) != null) {
                Quilter.Application.gsettings.set_string ("current-file", ((Widgets.SideBarBox) sidebar.column.get_selected_row ()).path);
            }
        }

        public void save_last_files () {
            file_manager.save_open_files (this);
        }

        public void scroll_to () {
            Gtk.Adjustment vap = edit_view.get_vadjustment ();
            var upper = vap.get_upper ();
            var value = vap.get_value ();
            preview_view_content.scroll_value = value / upper;
        }

        public override bool close_request () {
            if (sidebar.column != null) {
                Quilter.Application.gsettings.set_string ("current-file", "");
            }

            set_prev_workfile ();
            if (edit_view_content.modified) {
                on_save ();
            }

            file_manager.save_open_files (this);

            Quilter.Application.gsettings.changed.disconnect (on_settings_changed);

            return false;
        }
    }
}
