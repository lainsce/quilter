use gtk::*;

use crate::components::popover::Popover;
use crate::components::viewpopover::ViewPopover;
use gtk::prelude::BuilderExtManual;
use gtk::MenuButtonExt;

pub struct Header {
    pub container: gtk::Revealer,
    pub headerbar: libhandy::HeaderBar,
    pub popover: Popover,
    pub viewpopover: ViewPopover,
    pub new_button: gtk::Button,
    pub open_button: gtk::Button,
    pub save_button: gtk::Button,
    pub search_button: gtk::ToggleButton,
    pub toggle_view_button: gtk::MenuButton,
    pub menu_button: gtk::MenuButton,
}

impl Header {
    pub fn new() -> Header {
        let builder = gtk::Builder::from_resource("/com/github/lainsce/quilter/headerbar.ui");
        get_widget!(builder, gtk::Revealer, container);

        get_widget!(builder, libhandy::HeaderBar, headerbar);
        headerbar.set_size_request(-1, 38);

        get_widget!(builder, gtk::Button, new_button);
        new_button.set_visible (true);

        get_widget!(builder, gtk::Button, open_button);
        open_button.set_visible (true);

        get_widget!(builder, gtk::Button, save_button);
        save_button.set_visible (true);

        get_widget!(builder, gtk::ToggleButton, search_button);
        search_button.set_visible (true);

        get_widget!(builder, gtk::MenuButton, toggle_view_button);
        toggle_view_button.set_visible (true);
        let viewpopover = ViewPopover::new(toggle_view_button.clone());
        toggle_view_button.set_popover(Some(&viewpopover.container));

        get_widget!(builder, gtk::MenuButton, menu_button);
        menu_button.set_visible (true);
        let popover = Popover::new(menu_button.clone());
        menu_button.set_popover(Some(&popover.container));

        Header {
            container,
            headerbar,
            popover,
            viewpopover,
            new_button,
            open_button,
            save_button,
            search_button,
            toggle_view_button,
            menu_button,
        }
    }
}
