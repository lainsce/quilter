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

public class Quilter.Widgets.SettingsWindow.NoteBookPage : Gtk.Grid {
        public new string name { get; private set; }
        private const int IDENTATION_MARGIN = 12;

        public NoteBookPage (string name) {
            this.name = name;

            margin = 12;
            hexpand = true;
            column_spacing = 12;
            row_spacing = 6;
        }

        public void add_section (Gtk.Label name, ref int row) {
            name.set_text (name.get_text ());
            name.get_style_context ().add_class ("h4");
            name.halign = Gtk.Align.START;
            attach (name, 0, row, 1, 1);
            row ++;
        }

        public void add_option (Gtk.Widget label, Gtk.Widget switcher, ref int row) {
            label.set_hexpand (true);
            label.set_halign (Gtk.Align.END);
            label.set_margin_left (20);
            switcher.set_halign (Gtk.Align.FILL);
            switcher.set_hexpand (true);

            if (switcher is Gtk.Switch || switcher is Gtk.CheckButton
                || switcher is Gtk.Entry) {
                switcher.halign = Gtk.Align.START;
             }

            attach (label, 0, row, 1, 1);
            attach (switcher, 1, row, 3, 1);
            row ++;
        }

        public void add_full_option (Gtk.Widget big_widget, ref int row) {
            big_widget.set_halign (Gtk.Align.FILL);
            big_widget.set_hexpand (true);
            big_widget.set_margin_left (20);
            big_widget.set_margin_right (20);

            attach (big_widget, 0, row, 4, 1);
            row ++;
        }
}

public class Quilter.Widgets.PreferencesDialog : Gtk.Dialog {

    public const int MIN_WIDTH = 420;
    public const int MIN_HEIGHT = 300;

    private Gee.Map<int, unowned SettingsWindow.NoteBookPage> sections = new Gee.HashMap<int, unowned SettingsWindow.NoteBookPage> ();
    private Gtk.Stack main_stack;
    private Gtk.StackSwitcher main_stackswitcher;
    private int index = 0;

    public PreferencesDialog () {
        build_ui ();
        var general_section = new Quilter.Widgets.PreferencesGeneralPage ();
        add_page (general_section.page);
    }


    public int add_page (SettingsWindow.NoteBookPage section) {
        return_val_if_fail (section != null, -1);

        // Pack the section
        main_stack.add_titled (section, "%d".printf (index), section.name);
        sections.set (index, section);
        index++;

        section.show_all ();
        var children_number = main_stack.get_children ().length ();
        main_stackswitcher.no_show_all = children_number <= 1;
        main_stackswitcher.visible = children_number > 1;

        return index;
    }

    public void remove_section (int _index) {
        var section = sections.get (_index);
        section.destroy ();
        sections.unset (_index);
        var children_number = main_stack.get_children ().length ();
        main_stackswitcher.no_show_all = children_number <= 1;
        main_stackswitcher.visible = children_number > 1;
    }

    private void build_ui () {
        // Window properties
        title = _("Preferences");
        set_size_request (MIN_WIDTH, MIN_HEIGHT);
        resizable = false;
        deletable = false;
        destroy_with_parent = true;
        window_position = Gtk.WindowPosition.CENTER;

        main_stack = new Gtk.Stack ();
        main_stackswitcher = new Gtk.StackSwitcher ();
        main_stackswitcher.set_stack (main_stack);
        main_stackswitcher.halign = Gtk.Align.CENTER;

        var close_button = new Gtk.Button.with_label (_("Close"));
        close_button.clicked.connect (() => {this.destroy ();});

        var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_box.set_layout (Gtk.ButtonBoxStyle.END);
        button_box.pack_end (close_button);
        button_box.margin_right = 12;

        // Pack everything into the dialog
        Gtk.Grid main_grid = new Gtk.Grid ();
        main_grid.attach (main_stackswitcher, 0, 0, 1, 1);
        main_grid.attach (main_stack, 0, 1, 1, 1);
        main_grid.attach (button_box, 0, 2, 1, 1);

        ((Gtk.Container) get_content_area ()).add (main_grid);
    }
}

/**
 * General preferences section
 */
private class Quilter.Widgets.PreferencesGeneralPage {
    private Gtk.Switch invert_switch;
    public SettingsWindow.NoteBookPage page;

    public PreferencesGeneralPage () {
        page = new Widgets.SettingsWindow.NoteBookPage (_("General"));

        int row = 0;
        var main_settings = AppSettings.get_default ();

        invert_switch = new Gtk.Switch ();
        main_settings.schema.bind("invert-colors", invert_switch, "active", SettingsBindFlags.DEFAULT);
        page.add_option (new Gtk.Label (_("Invert the document colors:")), invert_switch, ref row);

    }
}
