use gtk::prelude::BuilderExtManual;
use gtk::WidgetExt;

pub struct Cheatsheet {
    pub cheatsheet: libhandy::Window,
}

impl Cheatsheet {
    pub fn new() -> Cheatsheet {
        let builder = gtk::Builder::from_resource("/com/github/lainsce/quilter/cheatsheet.ui");
        get_widget!(builder, libhandy::Window, cheatsheet);
        cheatsheet.set_visible (true);
        cheatsheet.set_size_request(600, 600);

        Cheatsheet {
            cheatsheet,
        }
    }
}
