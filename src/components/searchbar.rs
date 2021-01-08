use gtk::prelude::BuilderExtManual;
use gtk::*;

pub struct Searchbar {
    pub container: gtk::SearchBar,
}

impl Searchbar {
    pub fn new() -> Searchbar {
        let builder = gtk::Builder::from_resource("/com/github/lainsce/quilter/searchbar.ui");
        get_widget!(builder, gtk::SearchBar, container);
        container.set_visible (true);

        //TODO: Implement search and replace functions.

        Searchbar {
            container,
        }
    }
}
