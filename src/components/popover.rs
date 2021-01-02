use gtk::*;
use gtk::WidgetExt;

pub struct Popover {
    pub container: gtk::Popover,
    pub color_button_light: gtk::RadioButton,
    pub color_button_dark: gtk::RadioButton,
    pub prefs_button: gtk::ModelButton,
}

impl Popover {
    pub fn new(menu_button : &gtk::MenuButton) -> Popover {
        let container = gtk::Popover::new(Some(menu_button));

        let color_button_light = gtk::RadioButton::new();
        color_button_light.set_halign(gtk::Align::Center);
        color_button_light.set_property_height_request(40);
        color_button_light.set_property_width_request(40);
        color_button_light.set_property_draw_indicator(false);
        color_button_light.set_label ("");

        color_button_light.get_style_context().add_class("color-button");
        color_button_light.get_style_context().add_class("color-light");

        let color_button_dark = gtk::RadioButton::from_widget(&color_button_light);
        color_button_dark.set_halign(gtk::Align::Center);
        color_button_dark.set_property_height_request(40);
        color_button_dark.set_property_width_request(40);
        color_button_dark.set_property_draw_indicator(false);
        color_button_dark.set_label ("");

        color_button_dark.get_style_context().add_class("color-button");
        color_button_dark.get_style_context().add_class("color-dark");

        let colors_grid = gtk::Grid::new ();
        colors_grid.set_margin_top(12);
        colors_grid.set_margin_bottom(12);
        colors_grid.set_margin_start(12);
        colors_grid.set_margin_end(12);
        colors_grid.set_column_homogeneous(true);
        colors_grid.set_hexpand(true);
        colors_grid.attach(&color_button_light, 0, 0, 1, 1);
        colors_grid.attach(&color_button_dark, 1, 0, 1, 1);
        colors_grid.show_all();

        let prefs_button = gtk::ModelButton::new ();
        prefs_button.set_label("Preferences");
        prefs_button.set_property_centered(false);
        prefs_button.set_property_role(gtk::ButtonRole::Normal);

        let grid = gtk::Grid::new();
        grid.set_orientation(gtk::Orientation::Vertical);
        grid.attach (&colors_grid, 0, 0, 2, 1);
        grid.attach (&prefs_button, 0, 1, 1, 1);
        grid.show_all();

        container.add(&grid);
        
        Popover {
            container,
            color_button_light,
            color_button_dark,
            prefs_button,
        }
    }
}
