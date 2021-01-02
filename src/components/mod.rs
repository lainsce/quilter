extern crate sourceview4;

pub mod window_state;

pub mod window;
use self::window::Window;

pub mod header;

pub mod popover;

use gtk;
use gtk::*;

pub struct App {
    pub window:  Window,
}

impl App {
    pub fn new() -> App {
        let settingsgtk = gtk::Settings::get_default();
        settingsgtk.clone ().unwrap().set_property_gtk_theme_name(Some("io.elementary.stylesheet.blueberry"));
        settingsgtk.clone ().unwrap().set_property_gtk_icon_theme_name(Some("elementary"));
        settingsgtk.clone ().unwrap().set_property_gtk_font_name(Some("Inter Regular 9"));
    
        let window = Window::new();

        window.container.connect_delete_event(move |_, _| {
            main_quit();
            Inhibit(false)
        });

        //return
        App {
            window,
        }
    }
}
