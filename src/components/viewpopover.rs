use gtk::*;
use gtk::WidgetExt;
use gio::SettingsExt;
use gtk::PopoverExt;
use gtk::prelude::BuilderExtManual;

use crate::config::APP_ID;

pub struct ViewPopover {
    pub container: gtk::Popover,
    pub settings: gio::Settings,
    pub full_button: gtk::RadioButton,
    pub half_button: gtk::RadioButton,
}

impl ViewPopover {
    pub fn new(toggle_view_button : gtk::MenuButton) -> ViewPopover {
        let settings = gio::Settings::new(APP_ID);

        let builder = gtk::Builder::from_resource("/com/github/lainsce/quilter/view_popover.ui");
        get_widget!(builder, gtk::Popover, container);
        gtk::Popover::set_relative_to(&container, Some(&toggle_view_button));

        get_widget!(builder, gtk::RadioButton, full_button);
        full_button.set_visible (true);

        get_widget!(builder, gtk::RadioButton, half_button);
        half_button.set_visible (true);

        let pt = settings.get_string("preview-type").unwrap();
        if pt.as_str() == "full" {
            full_button.set_active (true);
        } else if pt.as_str() == "half" {
            half_button.set_active (true);
        }

        full_button.connect_toggled(glib::clone!(@weak settings as settings, @weak full_button, @weak half_button => move |_| {
            settings.set_string("preview-type", "full").unwrap();
            half_button.set_active (false);
        }));

        half_button.connect_toggled(glib::clone!(@weak settings as settings, @weak full_button, @weak half_button  => move |_| {
            settings.set_string("preview-type", "half").unwrap();
            full_button.set_active (false);
        }));

        ViewPopover {
            container,
            settings,
            full_button,
            half_button,
        }
    }
}
