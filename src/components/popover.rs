use gtk::WidgetExt;
use gtk::PopoverExt;
use gtk::prelude::BuilderExtManual;

pub struct Popover {
    pub container: gtk::Popover,
    pub color_button_light: gtk::RadioButton,
    pub color_button_sepia: gtk::RadioButton,
    pub color_button_dark: gtk::RadioButton,
    pub prefs_button: gtk::ModelButton,
    pub toggle_view_button: gtk::ModelButton,
}

impl Popover {
    pub fn new(menu_button : gtk::MenuButton) -> Popover {
        let builder = gtk::Builder::from_resource("/com/github/lainsce/quilter/menu_popover.ui");
        get_widget!(builder, gtk::Popover, container);
        gtk::Popover::set_relative_to(&container, Some(&menu_button));

        get_widget!(builder, gtk::RadioButton, color_button_light);
        color_button_light.set_visible (true);

        get_widget!(builder, gtk::RadioButton, color_button_sepia);
        color_button_sepia.set_visible (true);

        get_widget!(builder, gtk::RadioButton, color_button_dark);
        color_button_dark.set_visible (true);

        get_widget!(builder, gtk::RadioButton, color_button_dark);
        color_button_dark.set_visible (true);

        get_widget!(builder, gtk::ModelButton, prefs_button);
        prefs_button.set_visible (true);

        get_widget!(builder, gtk::ModelButton, toggle_view_button);

        Popover {
            container,
            color_button_light,
            color_button_sepia,
            color_button_dark,
            prefs_button,
            toggle_view_button,
        }
    }
}
