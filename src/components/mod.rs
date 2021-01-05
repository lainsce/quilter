extern crate sourceview4;

#[macro_use]
mod utils;

pub mod prefs_window;
pub mod window_state;
pub mod window;
use window::Window;
pub mod header;
pub mod sidebar;
pub mod viewpopover;
pub mod popover;
pub mod searchbar;
pub mod listboxrow;
pub mod css;

use gtk::*;
use gio::*;
use gio::prelude::*;
use crate::config::APP_ID;
use std::env;

pub struct App {
    app: gtk::Application,
    pub window:  Window,
}

impl App {
    pub fn new() -> App {
        gtk::Settings::get_default().unwrap().set_property_gtk_theme_name(Some("io.elementary.stylesheet.blueberry"));
        gtk::Settings::get_default().unwrap().set_property_gtk_icon_theme_name(Some("elementary"));
        gtk::Settings::get_default().unwrap().set_property_gtk_font_name(Some("Inter 9"));

        let app = gtk::Application::new(Some(APP_ID), gio::ApplicationFlags::FLAGS_NONE).unwrap();
        let window = Window::new();

        window.widget.connect_delete_event(move |_, _| {
            main_quit();
            Inhibit(false)
        });

        let application = App { app, window };
        application.setup_css();
        application.setup_gactions();
        application.setup_signals();
        application
    }

    fn setup_gactions(&self) {
        // Quit
        action!(
            self.app,
            "quit",
            glib::clone!(@strong self.app as app => move |_, _| {
                app.quit();
            })
        );
        self.app.set_accels_for_action("app.quit", &["<primary>q"]);
    }

    fn setup_signals(&self) {
        self.app
            .connect_activate(glib::clone!(@weak self.window.widget as window => move |app| {
                window.set_application(Some(app));
                app.add_window(&window);
                window.show_all();
            }));
    }


    fn setup_css(&self) {
        let p = gtk::CssProvider::new();
        gtk::CssProvider::load_from_resource(&p, "/com/github/lainsce/quilter/app.css");
        if let Some(screen) = gdk::Screen::get_default() {
            gtk::StyleContext::add_provider_for_screen(
                &screen,
                &p,
                500,
            );
        }
    }

    pub fn run(&self) {
        let args: Vec<String> = env::args().collect();
        self.app.run(&args);
    }
}
