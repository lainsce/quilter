use gtk::*;
use gtk::WidgetExt;
use gio::SettingsExt;
use gtk::PopoverExt;
use gtk::prelude::BuilderExtManual;

use crate::config::APP_ID;

pub struct Popover {
    pub container: gtk::Popover,
    pub settings: gio::Settings,
    pub color_button_light: gtk::RadioButton,
    pub color_button_sepia: gtk::RadioButton,
    pub color_button_dark: gtk::RadioButton,
    pub prefs_button: gtk::ModelButton,
    pub toggle_view_button: gtk::ModelButton,
}

impl Popover {
    pub fn new(menu_button : gtk::MenuButton) -> Popover {
        let settings = gio::Settings::new(APP_ID);

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
        toggle_view_button.set_visible (true);
        
        let vm = settings.get_string("visual-mode").unwrap();
        if vm.as_str() == "light" {
            color_button_light.set_active (true);
        } else if vm.as_str() == "dark" {
            color_button_dark.set_active (true);
        } if vm.as_str() == "sepia" {
            color_button_sepia.set_active (true);
        }

        color_button_light.connect_toggled(glib::clone!(@weak settings as settings => move |_| {
            settings.set_string("visual-mode", "light").unwrap();
        }));

        color_button_dark.connect_toggled(glib::clone!(@weak settings as settings => move |_| {
            settings.set_string("visual-mode", "dark").unwrap();
        }));

        color_button_sepia.connect_toggled(glib::clone!(@weak settings as settings => move |_| {
            settings.set_string("visual-mode", "sepia").unwrap();
        }));

        Popover {
            container,
            settings,
            color_button_light,
            color_button_sepia,
            color_button_dark,
            prefs_button,
            toggle_view_button,
        }
    }
}
