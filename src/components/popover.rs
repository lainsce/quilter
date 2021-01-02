use gtk::*;

use crate::components::header::Header;

pub struct Popover {
    pub container: gtk::Popover,
}

impl Popover {
    pub fn new() -> Popover {
        let header = Header::new();
        let container = gtk::Popover::new(Some(&header.menu_button));

        let prefs_button = gtk::ModelButton::new ();
        container.add(&prefs_button);
        
        Popover {
            container,
        }
    }
}
