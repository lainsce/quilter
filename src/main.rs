extern crate gtk;
extern crate libhandy;
extern crate log;
extern crate glib;

use gettextrs::*;

mod components;
use components::window::Window;

mod config;
mod static_resources;

use config::{GETTEXT_PACKAGE, LOCALEDIR};

fn main() {
    // Prepare i18n
    setlocale(LocaleCategory::LcAll, "");
    bindtextdomain(GETTEXT_PACKAGE, LOCALEDIR);
    textdomain(GETTEXT_PACKAGE);

    gtk::init().expect("GTK not loaded!");
    static_resources::init().expect("GResource initialization failed.");
    libhandy::init();

    glib::set_program_name("Quilter".into());
    glib::set_application_name("Quilter");
    glib::set_prgname(Some("com.github.lainsce.quilter"));

    let app = Window::new();
    app.run ();

    gtk::main();
}
