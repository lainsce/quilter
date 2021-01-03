use gtk::*;
use gtk::SearchBarExt;

pub struct Searchbar {
    pub container:  gtk::Revealer,
    pub searchbar: gtk::SearchBar,
}

impl Searchbar {
    pub fn new() -> Searchbar {
        let container = gtk::Revealer::new();
        let searchbar = gtk::SearchBar::new();
        searchbar.set_show_close_button(false);
        searchbar.set_visible(true);
        container.add (&searchbar);
        container.show_all();

        Searchbar {
            container,
            searchbar,
        }
    }
}
