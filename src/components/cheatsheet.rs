use gtk::prelude::BuilderExtManual;
use gtk::WidgetExt;

pub struct Cheatsheet {
    pub cheatsheet: libhandy::PreferencesWindow,
}

impl Cheatsheet {
    pub fn new() -> Cheatsheet {
        let builder = gtk::Builder::from_resource("/com/github/lainsce/quilter/cheatsheet.ui");
        get_widget!(builder, libhandy::PreferencesWindow, cheatsheet);
        cheatsheet.set_visible (true);
        cheatsheet.set_size_request(600, 600);

        Cheatsheet {
            cheatsheet,
        }
    }
}
