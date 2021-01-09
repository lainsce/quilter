
use gtk::prelude::BuilderExtManual;
use gtk::*;
use gtk::SearchEntryExt;

pub struct Searchbar {
    pub container: gtk::SearchBar,
}

impl Searchbar {
    pub fn new(buffer: &sourceview4::Buffer, view: &sourceview4::View) -> Searchbar {
        let builder = gtk::Builder::from_resource("/com/github/lainsce/quilter/searchbar.ui");
        get_widget!(builder, gtk::SearchBar, container);
        container.set_visible (true);

        //TODO: Implement search and replace functions for the searchbar here.
        get_widget!(builder, gtk::SearchEntry, search_entry);
        search_entry.set_visible (true);
        get_widget!(builder, gtk::Button, search_button_next);
        search_button_next.set_visible (true);
        get_widget!(builder, gtk::Button, search_button_prev);
        search_button_prev.set_visible (true);

        search_entry.connect_search_changed (glib::clone!(@weak view, @weak buffer, @weak search_entry => move |_| {
            let search_string = search_entry.get_text();

            let start_iter = buffer.get_iter_at_offset (buffer.get_property_cursor_position ());
            let found = search_string != "" && buffer.get_text(&start_iter, &start_iter, false).unwrap().contains(&search_string[0..]) ;
            if found {
                search_entry.get_style_context ().remove_class (&gtk::STYLE_CLASS_ERROR);
                buffer.select_range (&start_iter, &start_iter);
            } else if search_string != "" {
                search_entry.get_style_context ().add_class (&gtk::STYLE_CLASS_ERROR);
            }
        }));

        search_entry.connect_previous_match (glib::clone!(@weak view, @weak buffer, @weak search_entry => move|_| {
            let key = search_entry.get_text();
            let start_iter =  buffer.get_start_iter();

            let found = start_iter.forward_search(&key, gtk::TextSearchFlags::CASE_INSENSITIVE, None);
            if found != None {
                if let Some((match_start, match_end)) =  found {
                    buffer.select_range(&match_start, &match_end);
                };
            }
        }));

        Searchbar {
            container,
        }
    }
}
