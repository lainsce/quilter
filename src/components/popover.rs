use gtk::*;
use gtk::WidgetExt;
use gio::SettingsExt;

use crate::config::APP_ID;

pub struct Popover {
    pub container: gtk::Popover,
    pub settings: gio::Settings,
    pub color_button_light: gtk::RadioButton,
    pub color_button_dark: gtk::RadioButton,
    pub prefs_button: gtk::ModelButton,
    pub toggle_view_button: gtk::ModelButton,
}

impl Popover {
    pub fn new(menu_button : &gtk::MenuButton) -> Popover {
        let settings = gio::Settings::new(APP_ID);
        let container = gtk::Popover::new(Some(menu_button));

        let color_button_light = gtk::RadioButton::new();
        color_button_light.set_halign(gtk::Align::Center);
        color_button_light.set_property_height_request(40);
        color_button_light.set_property_width_request(40);
        color_button_light.set_label ("");

        color_button_light.get_style_context().add_class("color-button");
        color_button_light.get_style_context().add_class("color-light");

        let color_button_dark = gtk::RadioButton::from_widget(&color_button_light);
        color_button_dark.set_halign(gtk::Align::Center);
        color_button_dark.set_property_height_request(40);
        color_button_dark.set_property_width_request(40);
        color_button_dark.set_label ("");

        color_button_dark.get_style_context().add_class("color-button");
        color_button_dark.get_style_context().add_class("color-dark");

        let colors_grid = gtk::Grid::new ();
        colors_grid.set_margin_top(12);
        colors_grid.set_margin_bottom(12);
        colors_grid.set_column_homogeneous(true);
        colors_grid.set_hexpand(true);
        colors_grid.attach(&color_button_light, 0, 0, 1, 1);
        colors_grid.attach(&color_button_dark, 1, 0, 1, 1);
        colors_grid.show_all();

        let prefs_button = gtk::ModelButton::new ();
        prefs_button.set_label("Preferences");
        prefs_button.set_property_centered(false);

        let toggle_view_button = gtk::ModelButton::new ();
        toggle_view_button.set_label("Toggle View...");
        toggle_view_button.set_property_centered(false);

        let grid = gtk::Grid::new();
        grid.set_orientation(gtk::Orientation::Vertical);
        grid.attach (&colors_grid, 0, 0, 2, 1);
        grid.attach (&toggle_view_button, 0, 1, 1, 1);
        grid.attach (&prefs_button, 0, 2, 1, 1);
        grid.show_all();

        container.add(&grid);
        
        let vm = settings.get_string("visual-mode").unwrap();
        if vm.as_str() == "light" {
            color_button_light.set_active (true);
        } else if vm.as_str() == "dark" {
            color_button_dark.set_active (true);
        }

        color_button_light.connect_toggled(glib::clone!(@weak settings as settings => move |_| {
            settings.set_string("visual-mode", "light").unwrap();
        }));

        color_button_dark.connect_toggled(glib::clone!(@weak settings as settings => move |_| {
            settings.set_string("visual-mode", "dark").unwrap();
        }));

        Popover {
            container,
            settings,
            color_button_light,
            color_button_dark,
            prefs_button,
            toggle_view_button,
        }
    }
}
