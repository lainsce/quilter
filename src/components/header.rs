use gtk::*;

use libhandy::HeaderBarExt;

use crate::components::popover::Popover;

pub struct Header {
    pub container: libhandy::HeaderBar,
    pub popover: Popover,
    pub new_button: gtk::Button,
    pub new_image: gtk::Image,
    pub open_button: gtk::Button,
    pub open_image: gtk::Image,
    pub save_button: gtk::Button,
    pub save_image: gtk::Image,
    pub menu_button: gtk::MenuButton,
    pub menu_image: gtk::Image,
}

impl Header {
    pub fn new() -> Header {
        let container = libhandy::HeaderBar::new();
        container.set_show_close_button(true);
        container.set_title(Some("Quilter"));
        container.set_has_subtitle(false);
        container.set_decoration_layout(Some("close:maximize"));
        container.set_size_request(-1, 38);

        let new_image = gtk::Image::from_icon_name(Some("list-add-symbolic"), gtk::IconSize::Button);
        let new_button = gtk::Button::new ();
        new_button.get_style_context().add_class("image-button");
        new_button.set_image(Some(&new_image));
        new_button.set_always_show_image(true);
        container.pack_start(&new_button);

        let open_image = gtk::Image::from_icon_name(Some("document-open-symbolic"), gtk::IconSize::Button);
        let open_button = gtk::Button::new ();
        open_button.get_style_context().add_class("image-button");
        open_button.set_image(Some(&open_image));
        open_button.set_always_show_image(true);
        container.pack_start(&open_button);

        let save_image = gtk::Image::from_icon_name(Some("document-save-as-symbolic"), gtk::IconSize::Button);
        let save_button = gtk::Button::new ();
        save_button.get_style_context().add_class("image-button");
        save_button.set_image(Some(&save_image));
        save_button.set_always_show_image(true);
        container.pack_start(&save_button);

        let menu_image = gtk::Image::from_icon_name(Some("open-menu-symbolic"), gtk::IconSize::Button);
        let menu_button = gtk::MenuButton::new ();
        menu_button.get_style_context().add_class("image-button");
        menu_button.set_image(Some(&menu_image));
        menu_button.set_always_show_image(true);
        let popover = Popover::new(menu_button.as_ref());
        menu_button.set_popover(Some(&popover.container));
        container.pack_end(&menu_button);

        Header {
            container,
            popover,
            new_button,
            new_image,
            open_button,
            open_image,
            save_button,
            save_image,
            menu_button,
            menu_image,
        }
    }
}
