use gtk::prelude::BuilderExtManual;

pub struct Searchbar {
    pub container: gtk::Revealer,
}

impl Searchbar {
    pub fn new() -> Searchbar {
        let builder = gtk::Builder::from_resource("/com/github/lainsce/quilter/searchbar.ui");
        get_widget!(builder, gtk::Revealer, container);

        Searchbar {
            container,
        }
    }
}
