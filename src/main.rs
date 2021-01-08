extern crate gtk;
extern crate libhandy;
extern crate log;
extern crate glib;

use gettextrs::*;

#[macro_use]
mod utils;

mod components;
mod config;
mod static_resources;
mod app;
use config::{GETTEXT_PACKAGE, LOCALEDIR};
use app::Application;

fn main() {
    // Prepare i18n
    setlocale(LocaleCategory::LcAll, "");
    bindtextdomain(GETTEXT_PACKAGE, LOCALEDIR);
    textdomain(GETTEXT_PACKAGE);

    gtk::init().expect("GTK not loaded!");
    libhandy::init();

    glib::set_program_name("Quilter".into());
    glib::set_application_name("Quilter");
    glib::set_prgname(Some("com.github.lainsce.quilter"));

    static_resources::init().expect("GResource initialization failed.");

    let app = Application::new();
    app.run ();
}
