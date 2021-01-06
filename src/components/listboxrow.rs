use gtk::prelude::BuilderExtManual;
use gtk::*;

pub struct ListBoxRow {
    pub container: gtk::ListBoxRow,
    pub title: gtk::Label,
    pub subtitle: gtk::Label,
    pub row_destroy_button: gtk::Button,
}

impl ListBoxRow {
    pub fn new() -> ListBoxRow {
        let builder = gtk::Builder::from_resource("/com/github/lainsce/quilter/listboxrow.ui");
        get_widget!(builder, gtk::ListBoxRow, container);
        container.set_visible (true);

        get_widget!(builder, gtk::Label, title);
        title.set_visible (true);

        get_widget!(builder, gtk::Label, subtitle);
        subtitle.set_visible (true);

        get_widget!(builder, gtk::Button, row_destroy_button);
        row_destroy_button.set_visible (true);

        ListBoxRow {
            container,
            title,
            subtitle,
            row_destroy_button,
        }
    }
}
