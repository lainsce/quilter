use gtk::*;

use libhandy::HeaderBarExt;

pub struct Sidebar {
    pub container: gtk::Grid,
    pub sideheader: libhandy::HeaderBar,
}

impl Sidebar {
    pub fn new() -> Sidebar {
        let sideheader = libhandy::HeaderBar::new();
        sideheader.set_show_close_button(true);
        sideheader.set_has_subtitle(false);
        sideheader.set_decoration_layout(Some("close:"));
        sideheader.set_size_request(200, 38);
        sideheader.get_style_context().add_class("quilter-toolbar");
        sideheader.get_style_context().add_class("quilter-toolbar-side");
        sideheader.get_style_context().add_class("flat");

        let container = gtk::Grid::new();
        container.attach (&sideheader, 0, 0, 1, 1);

        Sidebar {
            container,
            sideheader,
        }
    }
}
