use gio::prelude::*;
use gtk::prelude::*;
use std::env;

use crate::config;
use crate::components::window::Window;
use crate::config::APP_ID;

pub struct Application {
    app: gtk::Application,
    window: Window,
}

impl Application {
    pub fn new() -> Self {
        let app =
            gtk::Application::new(Some(config::APP_ID), gio::ApplicationFlags::FLAGS_NONE).unwrap();
        let window = Window::new();

        let application = Self { app, window };

        application.setup_signals();
        application.setup_actions();
        application
    }

    fn setup_signals(&self) {
        self.app
            .connect_activate(glib::clone!(@weak self.window.widget as window => move |app| {
                window.set_application(Some(app));
                app.add_window(&window);
                window.show_all();
                window.set_size_request(600, 350);
                window.set_icon_name(Some(APP_ID));
            }));
    }

    fn setup_actions(&self) {
        // Quit
        action!(
            self.window.widget,
            "quit",
            glib::clone!(@strong self.app as app => move |_, _| {
                app.quit();
            })
        );
        self.app.set_accels_for_action("app.quit", &["<primary>q"]);
    }

    pub fn run(&self) {
        let args: Vec<String> = env::args().collect();
        self.app.run(&args);
    }
}

