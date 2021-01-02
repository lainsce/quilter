use gtk::*;

pub struct Popover {
    pub container: gtk::Popover,
}

impl Popover {
    pub fn new(menu_button : &gtk::MenuButton) -> Popover {
        let container = gtk::Popover::new(Some(menu_button));

        let prefs_button = gtk::ModelButton::new ();
        prefs_button.set_label("Preferences");
        prefs_button.set_visible(true);

        let grid = gtk::Grid::new();
        grid.set_orientation(gtk::Orientation::Vertical);
        grid.add (&prefs_button);
        grid.set_visible(true);

        container.add(&grid);
        
        Popover {
            container,
        }
    }
}
