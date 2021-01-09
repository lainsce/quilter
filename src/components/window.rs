extern crate sourceview4;
extern crate foreach;
use crate::config::{APP_ID, PROFILE};
use crate::components::window_state;
use crate::components::css::CSS;
use crate::components::header::Header;
use crate::components::sidebar::Sidebar;
// use crate::components::listboxrow::ListBoxRow;
use crate::components::cheatsheet::Cheatsheet;
use crate::components::prefs_window::PreferencesWindow;
use pulldown_cmark::{Parser, Options, html};
use gtk::*;
use gtk::prelude::*;
use gtk::IconThemeExt;
use gtk::SettingsExt as GtkSettings;
use gio::SettingsExt;
use gio::ActionMapExt;
use gtk::RevealerExt;
use gtk::WidgetExt;
use gio::FileExt;
use webkit2gtk::WebViewExt as WebSettings;
use webkit2gtk::SettingsExt as _;
use libhandy::LeafletExt;
use libhandy::HeaderBarExt;
use sourceview4::StyleSchemeManagerExt;
use sourceview4::BufferExt;
use webkit2gtk::PrintOperationExt;
use crate::settings::{Key, SettingsManager};
use std::{
    fs::File,
    io::{prelude::*, BufReader},
    path::Path,
};
use sourceview4::LanguageManagerExt;

pub struct Window {
    pub widget: libhandy::ApplicationWindow,
    pub settings: gio::Settings,
    pub header:  Header,
    pub view:  sourceview4::View,
    pub buffer:  sourceview4::Buffer,
    pub sidebar:  Sidebar,
    pub searchbar: gtk::SearchBar,
    // pub lbr: ListBoxRow,
    pub main: gtk::Stack,
    pub sc: gtk::Overlay,
    pub sc1: gtk::ScrolledWindow,
    pub half_stack: gtk::Grid,
    pub full_stack: gtk::Stack,
    pub webview: webkit2gtk::WebView,
    pub statusbar: gtk::Revealer,
    pub focus_bar: gtk::Revealer,
}

impl Window {
    pub fn new() -> Window {
        gtk::Settings::get_default().unwrap().set_property_gtk_theme_name(Some("io.elementary.stylesheet.blueberry"));
        gtk::Settings::get_default().unwrap().set_property_gtk_icon_theme_name(Some("elementary"));
        gtk::Settings::get_default().unwrap().set_property_gtk_font_name(Some("Inter 9"));
        let def = gtk::IconTheme::get_default ();
        gtk::IconTheme::add_resource_path(&def.unwrap(), "/com/github/lainsce/quilter/");

        let settings = gio::Settings::new(APP_ID);
        let header = Header::new();
        let sidebar = Sidebar::new();
        // let lbr = ListBoxRow::new();

        let builder = gtk::Builder::from_resource("/com/github/lainsce/quilter/window.ui");
        get_widget!(builder, libhandy::ApplicationWindow, win);

        let builder2 = gtk::Builder::from_resource("/com/github/lainsce/quilter/main_view.ui");
        get_widget!(builder2, gtk::Overlay, over);
        over.set_visible (true);

        get_widget!(builder2, gtk::Stack, main);
        main.set_visible (true);

        get_widget!(builder2, gtk::Overlay, sc);

        get_widget!(builder2, gtk::ScrolledWindow, sc1);
        sc1.get_style_context().remove_class("frame");

        get_widget!(builder2, gtk::Grid, half_stack);
        half_stack.set_visible (true);

        get_widget!(builder2, gtk::Stack, full_stack);
        full_stack.set_visible (true);

        get_widget!(builder2, webkit2gtk::WebView, webview);
        webview.set_visible (true);

        get_widget!(builder2, sourceview4::View, view);
        view.set_visible (true);

        get_widget!(builder2, gtk::TextTagTable, table);
        let buffer = sourceview4::Buffer::new(Some(&table));
        view.set_buffer(Some(&buffer));

        let builder3 = gtk::Builder::from_resource("/com/github/lainsce/quilter/searchbar.ui");
        get_widget!(builder3, gtk::SearchBar, searchbar);
        searchbar.set_visible (true);

        //TODO: Implement replace functions for the searchbar here.
        get_widget!(builder3, gtk::SearchEntry, search_entry);
        search_entry.set_visible (true);
        get_widget!(builder3, gtk::Button, search_button_next);
        search_button_next.set_visible (true);
        get_widget!(builder3, gtk::Button, search_button_prev);
        search_button_prev.set_visible (true);

        search_entry.connect_search_changed (glib::clone!(@weak view, @weak buffer, @weak search_entry => move |_| {
            let search_string = search_entry.get_text().as_str().replace("ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvxyz");

            let start_iter = buffer.get_iter_at_offset (buffer.get_property_cursor_position ());
            let end_iter = buffer.get_iter_at_offset (buffer.get_property_cursor_position () + search_string.len() as i32);
            let (start, end) = buffer.get_bounds();
            let contents = buffer.get_text(&start, &end, true);
            let found = contents.unwrap().as_str().replace("ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvxyz").contains(&search_string);
            if found {
                search_entry.get_style_context ().remove_class (&gtk::STYLE_CLASS_ERROR);
                buffer.select_range (&start_iter, &end_iter);
            } else {
                search_entry.get_style_context ().add_class (&gtk::STYLE_CLASS_ERROR);
            }
        }));

        get_widget!(builder2, gtk::Revealer, statusbar);
        statusbar.set_visible (true);

        get_widget!(builder2, gtk::Revealer, focus_bar);

        get_widget!(builder2, gtk::Button, focus);

        focus.connect_clicked(glib::clone!(@strong settings => move |_| {
            let fm = SettingsManager::get_boolean(Key::FocusMode);
            if !fm {
                SettingsManager::set_boolean(Key::FocusMode, true);
            } else {
                SettingsManager::set_boolean(Key::FocusMode, false);
                SettingsManager::set_boolean(Key::TypewriterScrolling, false);
            }
        }));

        get_widget!(builder2, gtk::MenuButton, bar);
        bar.get_style_context().add_class("quilter-menu");
        bar.set_visible (true);

        get_widget!(builder2, gtk::RadioButton, words);
        get_widget!(builder2, gtk::RadioButton, lines);
        get_widget!(builder2, gtk::RadioButton, reading_time);
        get_widget!(builder2, gtk::Label, type_label);

        let tt = SettingsManager::get_string(Key::TrackType);
        if tt.as_str() == "words" {
            words.set_active (true);
        } else if tt.as_str() == "lines" {
            lines.set_active (true);
        } else if tt.as_str() == "rtc" {
            reading_time.set_active (true);
        }

        if SettingsManager::get_boolean(Key::Sidebar) {
            sidebar.container.set_reveal_child(true);
        } else {
            sidebar.container.set_reveal_child(false);
        }

        if SettingsManager::get_boolean(Key::Statusbar) {
            statusbar.set_reveal_child(true);
        } else {
            statusbar.set_reveal_child(false);
        }

        if SettingsManager::get_boolean(Key::Searchbar) {
            searchbar.set_search_mode(true);
        } else {
            searchbar.set_search_mode(false);
        }

        words.connect_toggled(glib::clone!(@strong settings, @weak type_label, @weak buffer as buffer => move |_| {
            let (start, end) = buffer.get_bounds();
            let words = buffer.get_text (&start, &end, false).unwrap ().split_whitespace().count();

            type_label.set_text (&format!("Words: {}", &words));
            SettingsManager::set_string(Key::TrackType, "words".to_string());
        }));

        lines.connect_toggled(glib::clone!(@strong settings, @weak type_label, @weak buffer as buffer => move |_| {
            let lines = buffer.get_line_count();

            type_label.set_text (&format!("Lines: {}", &lines));
            SettingsManager::set_string(Key::TrackType, "lines".to_string());
        }));

        reading_time.connect_toggled(glib::clone!(@strong settings, @weak type_label, @weak buffer as buffer => move |_| {
            let (start, end) = buffer.get_bounds();
            let rt = (buffer.get_text (&start, &end, false).unwrap ().split_whitespace().count()) / 200;
            let rt_min = rt;

            type_label.set_text (&format!("Reading Time: {:.8}min", &rt_min));
            SettingsManager::set_string(Key::TrackType, "rtc".to_string());
        }));

        //
        // EditorView (view) Block
        //
        let height = SettingsManager::get_integer(Key::WindowHeight) as f32;
        let tw = SettingsManager::get_boolean(Key::TypewriterScrolling);
        let pos = SettingsManager::get_boolean(Key::Pos);
        buffer.connect_changed(glib::clone!(@strong settings, @weak buffer as buffer, @weak webview => move |_| {
            reload_func (&buffer, &webview);
        }));

        let eadj = view.get_vadjustment ().unwrap();
        eadj.connect_property_value_notify(glib::clone!(@weak view as view, @weak webview  => move |_| {
            let vap: gtk::Adjustment = view.get_vadjustment ().unwrap();
            let upper = vap.get_upper();
            let valued = vap.get_value();
            let scroll_value = valued/upper;
            set_scrvalue(&webview, &scroll_value);
        }));

        focus_scope (&buffer);
        buffer.connect_property_cursor_position_notify(glib::clone!(@weak buffer => move |_| {
            focus_scope (&buffer);
        }));

        if tw {
            glib::timeout_add_local(
                500, glib::clone!(@weak buffer, @weak view => @default-return glib::Continue(true), move || {
                let cursor = buffer.get_insert ().unwrap();
                view.scroll_to_mark(&cursor, 0.0, true, 0.0, 0.55);
                glib::Continue(true)
            }));

            let titlebar_h = header.headerbar.get_allocated_height() as f32;
            let typewriterposition1 = ((height * (1.0 - 0.55)) - titlebar_h) as i32;
            let typewriterposition2 = ((height * 0.55) - titlebar_h) as i32;
            view.set_top_margin (typewriterposition1);
            view.set_bottom_margin (typewriterposition2);
        } else {
            view.set_top_margin (40);
            view.set_bottom_margin (40);
        }

        if pos {
            start_pos (&buffer);
        } else {
            let (start, end) = buffer.get_bounds();
            buffer.remove_tag_by_name("conjfont", &start, &end);
            buffer.remove_tag_by_name("advfont", &start, &end);
            buffer.remove_tag_by_name("adjfont", &start, &end);
            buffer.remove_tag_by_name("verbfont", &start, &end);
        }

        let asv = SettingsManager::get_boolean(Key::Autosave);
        let tw = SettingsManager::get_boolean(Key::TypewriterScrolling);
        let ts = SettingsManager::get_integer(Key::Spacing);
        let tm = SettingsManager::get_integer(Key::Margins);
        let tx = SettingsManager::get_integer(Key::FontSizing);
        let last_file = SettingsManager::get_string(Key::CurrentFile);
        let fft = SettingsManager::get_string(Key::EditFontType);
        let width = SettingsManager::get_integer(Key::WindowWidth) as f32;
        let md_lang = sourceview4::LanguageManager::get_default().and_then(|lm| lm.get_language("markdown"));

        if let Some(md_lang) = md_lang {
            buffer.set_highlight_matching_brackets(true);
            buffer.set_language(Some(&md_lang));
            buffer.set_highlight_syntax(true);
        }

        if ts == 1 {
            view.set_pixels_above_lines (1);
            view.set_pixels_inside_wrap (1);
        } else if ts == 4 {
            view.set_pixels_above_lines (4);
            view.set_pixels_inside_wrap (4);
        } else if ts == 8 {
            view.set_pixels_above_lines (8);
            view.set_pixels_inside_wrap (8);
        }

        if tx == 0 {
            view.get_style_context().add_class("small-font");
            view.get_style_context().remove_class("medium-font");
            view.get_style_context().remove_class("large-font");
        } else if tx == 1 {
            view.get_style_context().add_class("medium-font");
            view.get_style_context().remove_class("small-font");
            view.get_style_context().remove_class("large-font");
        } else if tx == 2 {
            view.get_style_context().add_class("large-font");
            view.get_style_context().remove_class("medium-font");
            view.get_style_context().remove_class("small-font");
        }

        if fft.as_str() == "mono" {
            view.get_style_context().add_class("mono-font");
            view.get_style_context().remove_class("zwei-font");
            view.get_style_context().remove_class("vier-font");
        } else if fft.as_str() == "zwei" {
            view.get_style_context().add_class("zwei-font");
            view.get_style_context().remove_class("mono-font");
            view.get_style_context().remove_class("vier-font");
        } else if fft.as_str() == "vier" {
            view.get_style_context().add_class("vier-font");
            view.get_style_context().remove_class("zwei-font");
            view.get_style_context().remove_class("mono-font");
        }

        if tm == 1 {
            let m = (width * (1.0 / 100.0)) as i32;
            view.set_left_margin (m);
            view.set_right_margin (m);
        } else if tm == 8 {
            let m = (width * (8.0 / 100.0)) as i32;
            view.set_left_margin (m);
            view.set_right_margin (m);
        } else if tm == 16 {
            let m = (width * (16.0 / 100.0)) as i32;
            view.set_left_margin (m);
            view.set_right_margin (m);
        }

        buffer.connect_changed(glib::clone!(@weak view, @weak webview, @weak buffer => move |_| {
            if tw {
                glib::timeout_add_local(
                    500, glib::clone!(@weak view, @weak buffer => @default-return glib::Continue(true), move || {
                    let cursor = buffer.get_insert ().unwrap();
                    view.scroll_to_mark(&cursor, 0.0, true, 0.0, 0.55);
                    glib::Continue(true)
                }));
            }

            if asv {
                let delay = SettingsManager::get_integer(Key::AutosaveDelay) as u32;
                glib::timeout_add_seconds_local(delay, glib::clone!(@weak view => @default-return glib::Continue(false), move || {
                    let last_file = SettingsManager::get_string(Key::CurrentFile);
                    let filename = last_file.as_str();
                    let (start, end) = buffer.get_bounds();
                    let contents = buffer.get_text(&start, &end, true);
                    glib::file_set_contents(filename, contents.unwrap().as_bytes()).expect("Unable to write data");
                    glib::Continue(false)
                }));
            }
        }));

        //
        // Preview (preview) Block
        //
        let webkit_settings = webkit2gtk::Settings::new ();
        webkit_settings.set_javascript_can_open_windows_automatically (false);
        webkit_settings.set_enable_java (false);
        webkit_settings.set_enable_page_cache (true);
        webkit_settings.set_enable_plugins (true);
        webview.set_settings (&webkit_settings);

        reload_func(&buffer, &webview);
        change_layout (&main,
                       &full_stack,
                       &half_stack,
                       &sc,
                       &sc1,
                       &view,
                       &header.popover.toggle_view_button);

        //
        // Settings Block
        //
        let settingsgtk = gtk::Settings::get_default();
        let vm = SettingsManager::get_string(Key::VisualMode);
        let sm = SettingsManager::get_boolean(Key::Sidebar);
        let st = SettingsManager::get_boolean(Key::Statusbar);
        let sh = SettingsManager::get_boolean(Key::Searchbar);
        let fs = SettingsManager::get_boolean(Key::FocusMode);
        let tt = SettingsManager::get_string(Key::TrackType);

        let lstylem = sourceview4::StyleSchemeManager::get_default().and_then(|sm| sm.get_scheme ("quilter"));
        let dstylem = sourceview4::StyleSchemeManager::get_default().and_then(|sm| sm.get_scheme ("quilter-dark"));
        let sstylem = sourceview4::StyleSchemeManager::get_default().and_then(|sm| sm.get_scheme ("quilter-sepia"));

        if vm.as_str() == "light" {
            let stylevml = CssProvider::new();
            gtk::CssProviderExt::load_from_resource(&stylevml, "/com/github/lainsce/quilter/light.css");
            gtk::StyleContext::add_provider_for_screen(&gdk::Screen::get_default().unwrap(), &stylevml, 600);
            settingsgtk.unwrap().set_property_gtk_application_prefer_dark_theme(false);
            header.popover.color_button_light.set_active (true);
            buffer.set_style_scheme(lstylem.as_ref());
        } else if vm.as_str() == "dark" {
            let stylevmd = CssProvider::new();
            gtk::CssProviderExt::load_from_resource(&stylevmd, "/com/github/lainsce/quilter/dark.css");
            gtk::StyleContext::add_provider_for_screen(&gdk::Screen::get_default().unwrap(), &stylevmd, 600);
            settingsgtk.unwrap().set_property_gtk_application_prefer_dark_theme(true);
            header.popover.color_button_dark.set_active (true);
            buffer.set_style_scheme(dstylem.as_ref());
        } else if vm.as_str() == "sepia" {
            let stylevms = CssProvider::new();
            gtk::CssProviderExt::load_from_resource(&stylevms, "/com/github/lainsce/quilter/sepia.css");
            gtk::StyleContext::add_provider_for_screen(&gdk::Screen::get_default().unwrap(), &stylevms, 600);
            settingsgtk.unwrap().set_property_gtk_application_prefer_dark_theme(false);
            header.popover.color_button_sepia.set_active (true);
            buffer.set_style_scheme(sstylem.as_ref());
        }

        if st {
            statusbar.set_reveal_child(true);
        } else {
            statusbar.set_reveal_child(false);
        }

        if sm {
            sidebar.container.set_reveal_child(true);
            header.headerbar.set_decoration_layout (Some(&":maximize"));
        } else {
            sidebar.container.set_reveal_child(false);
            header.headerbar.set_decoration_layout (Some(&"close:maximize"));
        }

        if fs {
            focus_bar.set_reveal_child(true);
            header.container.set_reveal_child(false);
            sidebar.container.set_reveal_child(false);
            statusbar.set_reveal_child(false);
        } else {
            focus_bar.set_reveal_child(false);
            header.container.set_reveal_child(true);
            sidebar.container.set_reveal_child(sm);
            statusbar.set_reveal_child(st);
        }

        if sh {
            searchbar.set_search_mode(true);
        } else {
            searchbar.set_search_mode(false);
        }

        if tt.as_str() == "words" {
            let (start, end) = buffer.get_bounds();
            let words = buffer.get_text (&start, &end, false).unwrap ().split_whitespace().count();
            type_label.set_text (&format!("Words: {}", &words));
        } else if tt.as_str() == "lines" {
            let lines = buffer.get_line_count();
            type_label.set_text (&format!("Lines: {}", &lines));
        } else if tt.as_str() == "rtc" {
            let (start, end) = buffer.get_bounds();
            let reading_time = buffer.get_text (&start, &end, false).unwrap ().split_whitespace().count();
            let rt_min = reading_time / 200;
            type_label.set_text (&format!("Reading Time: {:.8}min", &rt_min));
        }

        reload_func(&buffer, &webview);

        settings.connect_changed (glib::clone!( @strong settings,
                                                @weak webview,
                                                @weak buffer as buffer,
                                                @weak view as view,
                                                @weak statusbar,
                                                @weak focus_bar,
                                                @weak searchbar as sbc,
                                                @weak header.container as hc,
                                                @weak header.headerbar as hb,
                                                @weak header.search_button as hsb,
                                                @weak sidebar.container as sdb,
                                                @weak type_label
                                                => move |settings, _| {
            let settingsgtk = gtk::Settings::get_default();
            let vm = SettingsManager::get_string(Key::VisualMode);
            let sm = SettingsManager::get_boolean(Key::Sidebar);
            let st = SettingsManager::get_boolean(Key::Statusbar);
            let sh = SettingsManager::get_boolean(Key::Searchbar);
            let fs = SettingsManager::get_boolean(Key::FocusMode);
            let tw = SettingsManager::get_boolean(Key::TypewriterScrolling);
            let pos = SettingsManager::get_boolean(Key::Pos);
            let height = SettingsManager::get_integer(Key::WindowHeight) as f32;
            let lstylem = sourceview4::StyleSchemeManager::get_default().and_then(|sm| sm.get_scheme ("quilter"));
            let dstylem = sourceview4::StyleSchemeManager::get_default().and_then(|sm| sm.get_scheme ("quilter-dark"));
            let sstylem = sourceview4::StyleSchemeManager::get_default().and_then(|sm| sm.get_scheme ("quilter-sepia"));

            if vm.as_str() == "light" {
                let stylevml = CssProvider::new();
                gtk::CssProviderExt::load_from_resource(&stylevml, "/com/github/lainsce/quilter/light.css");
                gtk::StyleContext::add_provider_for_screen(&gdk::Screen::get_default().unwrap(), &stylevml, 600);
                settingsgtk.unwrap().set_property_gtk_application_prefer_dark_theme(false);
                buffer.set_style_scheme(lstylem.as_ref());
            } else if vm.as_str() == "dark" {
                let stylevmd = CssProvider::new();
                gtk::CssProviderExt::load_from_resource(&stylevmd, "/com/github/lainsce/quilter/dark.css");
                gtk::StyleContext::add_provider_for_screen(&gdk::Screen::get_default().unwrap(), &stylevmd, 600);
                settingsgtk.unwrap().set_property_gtk_application_prefer_dark_theme(true);
                buffer.set_style_scheme(dstylem.as_ref());
            } else if vm.as_str() == "sepia" {
                let stylevms = CssProvider::new();
                gtk::CssProviderExt::load_from_resource(&stylevms, "/com/github/lainsce/quilter/sepia.css");
                gtk::StyleContext::add_provider_for_screen(&gdk::Screen::get_default().unwrap(), &stylevms, 600);
                settingsgtk.unwrap().set_property_gtk_application_prefer_dark_theme(false);
                buffer.set_style_scheme(sstylem.as_ref());
            }

            if st {
                statusbar.set_reveal_child(true);
            } else {
                statusbar.set_reveal_child(false);
            }

            if sm {
                sdb.set_reveal_child(true);
                hb.set_decoration_layout (Some(&":maximize"));
            } else {
                sdb.set_reveal_child(false);
                hb.set_decoration_layout (Some(&"close:maximize"));
            }

            if fs {
                focus_bar.set_reveal_child(true);
                hc.set_reveal_child(false);
                sdb.set_reveal_child(false);
                statusbar.set_reveal_child(false);
            } else {
                focus_bar.set_reveal_child(false);
                hc.set_reveal_child(true);
                sdb.set_reveal_child(sm);
                statusbar.set_reveal_child(st);
            }

            if sh {
                sbc.set_search_mode(true);
            } else {
                sbc.set_search_mode(false);
            }
            hsb.connect_toggled(glib::clone!(@weak sbc, @weak hsb => move |_| {
                if hsb.get_active() {
                    sbc.set_search_mode(true);
                } else {
                    sbc.set_search_mode(false);
                }
            }));

            let tt = settings.get_string("track-type").unwrap();
            if tt.as_str() == "words" {
                let (start, end) = buffer.get_bounds();
                let words = buffer.get_text (&start, &end, false).unwrap ().split_whitespace().count();

                type_label.set_text (&format!("Words: {}", &words));
            } else if tt.as_str() == "lines" {
                let lines = buffer.get_line_count();

                type_label.set_text (&format!("Lines: {}", &lines));
            } else if tt.as_str() == "rtc" {
                let (start, end) = buffer.get_bounds();
                let reading_time = buffer.get_text (&start, &end, false).unwrap ().split_whitespace().count();
                let rt_min = reading_time / 200;

                type_label.set_text (&format!("Reading Time: {:.8}min", &rt_min));
            }

            if tw {
                glib::timeout_add_local(
                    500, glib::clone!(@weak buffer, @weak view => @default-return glib::Continue(true), move || {
                    let cursor = buffer.get_insert ().unwrap();
                    view.scroll_to_mark(&cursor, 0.0, true, 0.0, 0.55);
                    glib::Continue(true)
                }));

                let titlebar_h = hb.get_allocated_height() as f32;
                let typewriterposition1 = ((height * (1.0 - 0.55)) - titlebar_h) as i32;
                let typewriterposition2 = ((height * 0.55) - titlebar_h) as i32;
                view.set_top_margin (typewriterposition1);
                view.set_bottom_margin (typewriterposition2);
            } else {
                view.set_top_margin (40);
                view.set_bottom_margin (40);
            }

            focus_scope (&buffer);
            buffer.connect_property_cursor_position_notify(glib::clone!(@weak buffer => move |_| {
                focus_scope (&buffer);
            }));

            if pos {
                start_pos (&buffer);
            } else {
                let (start, end) = buffer.get_bounds();
                buffer.remove_tag_by_name("conjfont", &start, &end);
                buffer.remove_tag_by_name("advfont", &start, &end);
                buffer.remove_tag_by_name("adjfont", &start, &end);
                buffer.remove_tag_by_name("verbfont", &start, &end);
            }

            let ts = SettingsManager::get_integer(Key::Spacing);
            let tm = SettingsManager::get_integer(Key::Margins);
            let tx = SettingsManager::get_integer(Key::FontSizing);
            let fft = SettingsManager::get_string(Key::EditFontType);
            let width = SettingsManager::get_integer(Key::WindowWidth) as f32;

            if ts == 1 {
                view.set_pixels_above_lines (1);
                view.set_pixels_inside_wrap (1);
            } else if ts == 4 {
                view.set_pixels_above_lines (4);
                view.set_pixels_inside_wrap (4);
            } else if ts == 8 {
                view.set_pixels_above_lines (8);
                view.set_pixels_inside_wrap (8);
            }

            if tm == 1 {
                let m = (width * (1.0 / 100.0)) as i32;
                view.set_left_margin (m);
                view.set_right_margin (m);
            } else if tm == 8 {
                let m = (width * (8.0 / 100.0)) as i32;
                view.set_left_margin (m);
                view.set_right_margin (m);
            } else if tm == 16 {
                let m = (width * (16.0 / 100.0)) as i32;
                view.set_left_margin (m);
                view.set_right_margin (m);
            }

            if tx == 0 {
                view.get_style_context().add_class("small-font");
                view.get_style_context().remove_class("medium-font");
                view.get_style_context().remove_class("large-font");
            } else if tx == 1 {
                view.get_style_context().add_class("medium-font");
                view.get_style_context().remove_class("small-font");
                view.get_style_context().remove_class("large-font");
            } else if tx == 2 {
                view.get_style_context().add_class("large-font");
                view.get_style_context().remove_class("medium-font");
                view.get_style_context().remove_class("small-font");
            }

            if fft.as_str() == "mono" {
                view.get_style_context().add_class("mono-font");
                view.get_style_context().remove_class("zwei-font");
                view.get_style_context().remove_class("vier-font");
            } else if fft.as_str() == "zwei" {
                view.get_style_context().add_class("zwei-font");
                view.get_style_context().remove_class("mono-font");
                view.get_style_context().remove_class("vier-font");
            } else if fft.as_str() == "vier" {
                view.get_style_context().add_class("vier-font");
                view.get_style_context().remove_class("zwei-font");
                view.get_style_context().remove_class("mono-font");
            }

            reload_func(&buffer, &webview);
        }));

        //
        // Headerbar Buttons Block
        //
        header.open_button.connect_clicked(glib::clone!(@strong settings,
                                                        @weak win,
                                                        @weak buffer as buffer,
                                                        @weak sidebar.files_list as files_list
                                                        => move |_| {
            let file_chooser = gtk::FileChooserDialog::new(
                Some("Open File"),
                Some(&win),
                gtk::FileChooserAction::Open,
            );
            file_chooser.add_buttons(&[
                ("Open", gtk::ResponseType::Ok),
                ("Cancel", gtk::ResponseType::Cancel),
            ]);
            file_chooser.connect_response(glib::clone!(@strong settings,
                                                       @weak win,
                                                       @weak buffer,
                                                       @weak files_list
                                                       => move |file_chooser, response| {
                if response == gtk::ResponseType::Ok {
                    let filename = file_chooser.get_filename().expect("Couldn't get filename");
                    settings.set_string("current-file", &filename.clone ().into_os_string().into_string().unwrap()).expect("Unable to set filename for GSchema");
                    let buf = glib::file_get_contents(filename).expect("Unable to get data");
                    let contents = String::from_utf8_lossy(&buf);

                    // let nlbr = ListBoxRow::new();

                    buffer.set_text(&contents);

                    // nlbr.title.set_label (&this_file.to_string());
                    // nlbr.subtitle.set_label ("");

                    // files_list.insert (&nlbr.container, 1);
                    // files_list.select_row(Some(&nlbr.container));
                }
                file_chooser.close();
            }));

            file_chooser.show_all();
        }));
        
        header.save_button.connect_clicked(glib::clone!(@weak win, @weak buffer as buffer => move |_| {
            let file_chooser = gtk::FileChooserDialog::new(
                Some("Save File"),
                Some(&win),
                gtk::FileChooserAction::Save,
            );
            file_chooser.add_buttons(&[
                ("Save", gtk::ResponseType::Ok),
                ("Cancel", gtk::ResponseType::Cancel),
            ]);
            file_chooser.connect_response(glib::clone!(@weak win, @weak buffer => move |file_chooser, response| {
                if response == gtk::ResponseType::Ok {
                    let filename = file_chooser.get_filename().expect("Couldn't get filename");
                    let (start, end) = buffer.get_bounds();
                    let contents = buffer.get_text(&start, &end, true);
                    
                    glib::file_set_contents(filename, contents.unwrap().as_bytes()).expect("Unable to write data");
                }
                file_chooser.close();
            }));

            file_chooser.show_all();
        }));
        
        header.new_button.connect_clicked(glib::clone!(@weak buffer as buffer => move |_| {
            buffer.set_text("");
        }));

        // lbr.row_destroy_button.connect_clicked(glib::clone!(@weak buffer as buffer, @weak lbr.container as container => move |_| {
        //     buffer.set_text("");
        //     unsafe { container.destroy () }
        // }));

        header.search_button.connect_toggled(glib::clone!(@weak searchbar as sbc,
                                                          @weak header.search_button as hsb => move |_| {
            if hsb.get_active() {
                sbc.set_search_mode(true);
            } else {
                sbc.set_search_mode(false);
            }
        }));

        header.popover.color_button_light.connect_toggled(glib::clone!(@weak settings as settings => move |_| {
            SettingsManager::set_string(Key::VisualMode, "light".to_string());
        }));

        header.popover.color_button_dark.connect_toggled(glib::clone!(@weak settings as settings => move |_| {
            SettingsManager::set_string(Key::VisualMode, "dark".to_string());
        }));

        header.popover.color_button_sepia.connect_toggled(glib::clone!(@weak settings as settings => move |_| {
            SettingsManager::set_string(Key::VisualMode, "sepia".to_string());
        }));

        header.viewpopover.full_button.connect_toggled(glib::clone!(@strong settings,
                                                                    @weak main,
                                                                    @weak full_stack,
                                                                    @weak half_stack,
                                                                    @weak sc1,
                                                                    @weak sc,
                                                                    @weak view as editor,
                                                                    @weak header.popover.toggle_view_button as hpt
                                                                    => move |_| {
            let key: String = "full".into();
            if SettingsManager::get_string(Key::PreviewType) == key {
                main.set_visible_child(&full_stack);
                change_layout (&main, &full_stack, &half_stack, &sc, &sc1, &editor, &hpt);
            } else {
                main.set_visible_child(&half_stack);
                change_layout (&main, &full_stack, &half_stack, &sc, &sc1, &editor, &hpt);
            }
        }));

        header.viewpopover.half_button.connect_toggled(glib::clone!(@strong settings,
                                                                    @weak main,
                                                                    @weak full_stack,
                                                                    @weak half_stack,
                                                                    @weak sc1,
                                                                    @weak sc,
                                                                    @weak view as editor,
                                                                    @weak header.popover.toggle_view_button as hpt
                                                                    => move |_| {
            let key: String = "half".into();
            if SettingsManager::get_string(Key::PreviewType) == key {
                main.set_visible_child(&half_stack);
                change_layout (&main, &full_stack, &half_stack, &sc, &sc1, &editor, &hpt);
            } else {
                main.set_visible_child(&full_stack);
                change_layout (&main, &full_stack, &half_stack, &sc, &sc1, &editor, &hpt);
            }
        }));

        //
        // Sidebar Block
        // TODO: Implement loading the files from last-files gschema and then going and making a new LBR based on each file.
        // TODO: Implement changing rows, removing the close button from view and save if changed rows.
        //
        if last_file.as_str() != "" {
            let filename = last_file.as_str();
            let buf = glib::file_get_contents(filename).expect("Unable to get data");
            let contents = String::from_utf8_lossy(&buf);

            buffer.set_text(&contents);

            // lbr.title.set_label (&last_file.to_string());
            // lbr.subtitle.set_label ("");

            // sidebar.files_list.add(&lbr.container);
            // sidebar.files_list.select_row(Some(&lbr.container));
        }
        // sidebar.files_list.connect_row_selected (glib::clone!(@weak view, @weak settings as settings => move |_,row| {
        //
        // }));
        //

        //
        // Window
        //
        let sgrid = gtk::Grid::new();
        sgrid.set_orientation(gtk::Orientation::Vertical);
        sgrid.attach (&sidebar.container, 0, 0, 1, 1);
        sgrid.show_all ();

        let grid = gtk::Grid::new();
        grid.set_hexpand(true);
        grid.set_orientation(gtk::Orientation::Vertical);
        grid.attach (&header.container, 0, 0, 1, 1);
        grid.attach (&searchbar, 0, 1, 1, 1);
        grid.attach (&over, 0, 2, 1, 1);
        grid.attach (&statusbar, 0, 3, 1, 1);
        grid.show_all ();

        let leaflet = libhandy::Leaflet::new();
        leaflet.add (&sgrid);
        leaflet.add (&grid);
        leaflet.set_transition_type (libhandy::LeafletTransitionType::Under);
        leaflet.set_can_swipe_back (true);
        leaflet.set_visible_child (&grid);
        leaflet.show_all ();

        leaflet.connect_property_folded_notify (glib::clone!(@weak leaflet, @weak header.headerbar as hb, @weak sidebar.sideheader as sbcs => move |_| {
            if leaflet.get_folded() {
                hb.set_decoration_layout (Some(&":"));
                sbcs.set_decoration_layout (Some(&":"));
            } else {
                hb.set_decoration_layout (Some(&":maximize"));
                sbcs.set_decoration_layout (Some(&"close:"));
            }
        }));

        let mgrid = gtk::Grid::new ();
        mgrid.set_orientation(gtk::Orientation::Vertical);
        mgrid.attach (&leaflet,0,0,1,1);
        mgrid.show_all ();
        win.add(&mgrid);

        let window_widget = Window {
            widget: win,
            settings,
            header,
            sidebar,
            searchbar,
            // lbr,
            main,
            sc,
            sc1,
            half_stack,
            full_stack,
            view,
            buffer,
            webview,
            statusbar,
            focus_bar
        };

        window_widget.init ();
        window_widget.setup_actions ();
        window_widget.setup_css ();
        window_widget
    }

    fn init(&self) {
        // Devel Profile
        if PROFILE == "Devel" {
            self.widget.get_style_context().add_class("devel");
        }

        // TODO: Save last-files gschema based on open documents here.

        // load latest window state
        window_state::load(&self.widget, &self.settings);

        // save window state on delete event
        self.widget.connect_delete_event(
            glib::clone!(@strong self.settings as settings => move |win, _| {
                if let Err(err) = window_state::save(&win, &settings) {
                    log::warn!("Failed to save window state, {}", err);
                }
                main_quit();
                Inhibit(false)
            }),
        );
    }

    fn setup_actions(&self) {
        action!(
            self.widget,
            "export_html",
            glib::clone!(@weak self.widget as win, @weak self.webview as webview, @weak self.buffer as buffer => move |_, _| {
                let file_chooser = gtk::FileChooserDialog::new(
                    Some("Save File"),
                    Some(&win),
                    gtk::FileChooserAction::Save,
                );
                file_chooser.add_buttons(&[
                    ("Save", gtk::ResponseType::Ok),
                    ("Cancel", gtk::ResponseType::Cancel),
                ]);
                file_chooser.connect_response(glib::clone!(@weak win, @weak webview, @weak buffer => move |file_chooser, response| {
                    if response == gtk::ResponseType::Ok {
                        let filename = file_chooser.get_filename().expect("Couldn't get filename");

                        let contents = get_html(&buffer, &webview);

                        glib::file_set_contents(filename, contents.as_bytes()).expect("Unable to write data");
                    }
                    file_chooser.close();
                }));

                file_chooser.show_all();
            })
        );

        action!(
            self.widget,
            "export_pdf",
            glib::clone!(@weak self.widget as win, @weak self.webview as webview => move |_, _| {
                let file_chooser = gtk::FileChooserDialog::new(
                    Some("Save File"),
                    Some(&win),
                    gtk::FileChooserAction::Save,
                );
                file_chooser.add_buttons(&[
                    ("Save", gtk::ResponseType::Ok),
                    ("Cancel", gtk::ResponseType::Cancel),
                ]);
                file_chooser.connect_response(glib::clone!(@weak webview => move |file_chooser, response| {
                    if response == gtk::ResponseType::Ok {
                        // FIXME: Fix PDF export.
                        let filename = file_chooser.get_filename().expect("Couldn't get filename");
                        let file = gio::File::new_for_path (filename);
                        let file_path = file.get_path().unwrap().into_os_string().into_string().ok().unwrap();

                        let op = webkit2gtk::PrintOperation::new (&webview);
                        let psize = gtk::PaperSize::new (Some(&gtk::PAPER_NAME_A4));
		                let psetup = gtk::PageSetup::new();
		                let psettings = gtk::PrintSettings::new();

		                psetup.set_top_margin (0.75, gtk::Unit::Inch);
		                psetup.set_bottom_margin (0.75, gtk::Unit::Inch);
		                psetup.set_left_margin (0.75, gtk::Unit::Inch);
		                psetup.set_right_margin (0.75, gtk::Unit::Inch);
                        psetup.set_paper_size(&psize);

                        psettings.set(&gtk::PRINT_SETTINGS_OUTPUT_URI, Some(&file_path));
                        psettings.set_printer ("Print to File");

                        op.set_print_settings (&psettings);
                        op.set_page_setup (&psetup);
                        op.print ();
                    }
                    file_chooser.close();
                }));

                file_chooser.show_all();
            })
        );

        action!(
            self.widget,
            "cheatsheet",
            glib::clone!(@strong self.settings as settings => move |_, _| {
                let cheat = Cheatsheet::new();
                cheat.cheatsheet.show();
            })
        );

        action!(
            self.widget,
            "prefs",
            glib::clone!(@weak self.widget as win  => move |_, _| {
                let prefs_win = PreferencesWindow::new(&win);
                prefs_win.prefs.show();
            })
        );

        action!(
            self.widget,
            "toggle_view",
            glib::clone!(@weak self.full_stack as fst, @weak self.buffer as buffer, @weak self.webview as preview, @weak self.sc as a, @weak self.sc1 as b => move |_, _| {
                let key: glib::GString = "editor".into();
                if fst.get_visible_child_name() == Some(key) {
                    fst.set_visible_child(&b);
                } else {
                    fst.set_visible_child(&a);
                    reload_func(&buffer, &preview);
                }
            })
        );

        action!(
            self.widget,
            "focus_mode",
            glib::clone!(@strong self.settings as settings => move |_, _| {
                let fs = SettingsManager::get_boolean(Key::FocusMode);
                if fs {
                    SettingsManager::set_boolean(Key::FocusMode, false);
                    SettingsManager::set_boolean(Key::TypewriterScrolling, false);
                } else {
                    SettingsManager::set_boolean(Key::FocusMode, true);
                }
            })
        );
    }


    fn setup_css(&self) {
        let p = gtk::CssProvider::new();
        gtk::CssProvider::load_from_resource(&p, "/com/github/lainsce/quilter/app.css");
        if let Some(screen) = gdk::Screen::get_default() {
            gtk::StyleContext::add_provider_for_screen(
                &screen,
                &p,
                500,
            );
        }
    }
}

//
// Misc. Functions Block
//
fn change_layout (main: &gtk::Stack,
                  full_stack: &gtk::Stack,
                  half_stack: &gtk::Grid,
                  sc: &gtk::Overlay,
                  sc1: &gtk::ScrolledWindow,
                  view: &sourceview4::View,
                  toggle_view_button: &gtk::ModelButton
) {
    let layout = SettingsManager::get_string(Key::PreviewType);
    if layout.as_str() == "full" {
        for w in half_stack.get_children () {
            half_stack.remove (&w);
        }
        full_stack.add_titled (sc, "editor", &"Edit");
        full_stack.add_titled (sc1, "preview", &"Preview");
        main.set_visible_child (full_stack);
        view.get_style_context().remove_class("quilter-half-edit");
        toggle_view_button.set_visible (true);
    } else {
        for w in full_stack.get_children () {
            full_stack.remove (&w);
        }
        half_stack.add (sc);
        half_stack.add (sc1);
        main.set_visible_child (half_stack);
        view.get_style_context().add_class("quilter-half-edit");
        toggle_view_button.set_visible (false);
    }
}

fn reload_func(buffer: &sourceview4::Buffer, webview: &webkit2gtk::WebView) -> String {
    let (start, end) = buffer.get_bounds();
    let buf = buffer.get_text(&start, &end, true).unwrap();
    let contents = buf.as_str();

    let css = CSS::new();

    let mut style = "";
    let mut font = "";
    let vm = SettingsManager::get_string(Key::VisualMode);
    if vm.as_str() == "dark" {
        style = &css.dark;
    } else if vm.as_str() == "sepia" {
        style = &css.sepia;
    } else if vm.as_str() == "light" {
        style = &css.light;
    }

    // Highlight.js
    let mut highlight = "".to_string();
    if vm.as_str() == "dark" {
        highlight = glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/highlight.js/styles/dark.min.css";
    } else if vm.as_str() == "sepia" {
        highlight = glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/highlight.js/styles/sepia.min.css";
    } else if vm.as_str() == "light" {
        highlight = glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/highlight.js/styles/default.min.css";
    }
    let render;
    render = glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/highlight.js/lib/highlight.min.js";

    let mut stringhl = "".to_string();
    if SettingsManager::get_boolean(Key::Highlight) {
        stringhl = format! ("
            <link rel=\"stylesheet\" href=\"{}\">
            <script defer src=\"{}\" onload=\"hljs.initHighlightingOnLoad();\"></script>
        ", highlight, render);
    }

    // LaTeX (Katex)
    let renderl;
    let katexmain;
    let katexjs;
    katexmain = glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/katex/katex.css";
    katexjs = glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/katex/katex.js";
    renderl = glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/katex/render.js";

    let mut stringtex = "".to_string();
    if SettingsManager::get_boolean(Key::Latex) {
        stringtex = format!( "
                        <link rel=\"stylesheet\" href=\"{}\">
                        <script defer src=\"{}\"></script>
                        <script defer src=\"{}\" onload=\"renderMathInElement(document.body);\"></script>
                    ",  katexmain, katexjs, renderl);
    }

    let pft = SettingsManager::get_string(Key::PreviewFontType);
    if pft.as_str() == "serif" {
        font = &css.serif;
    } else if pft.as_str() == "sans" {
        font = &css.sans;
    } else if pft.as_str() == "mono" {
        font = &css.mono;
    }

    // Mermaid
    let mut stringmaid = "".to_string();
    let mermaid = glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/mermaid/mermaid.js";
    if SettingsManager::get_boolean(Key::Mermaid) {
        stringmaid = format! ("<script defer src=\"{}\"></script>", mermaid);
    }

    // Center Headers
    let mut cheader = "".to_string();
    if SettingsManager::get_boolean(Key::CenterHeaders) {
        cheader = (&css.center).to_string();
    }

    //TODO: Implement Plugins
    //      - File Embed
    //      - Image Embed
    //      - Highlighted style
    //      - Super and subscripts

    let mut opts = Options::empty();
        opts.insert(Options::ENABLE_TABLES);
        opts.insert(Options::ENABLE_FOOTNOTES);
        opts.insert(Options::ENABLE_STRIKETHROUGH);
        opts.insert(Options::ENABLE_TASKLISTS);
    let parser = Parser::new_ext(&contents, opts);

    let mut md = String::new();
    html::push_html(&mut md, parser);

    let html = format! ("
    <!doctype html>
    <html>
      <head>
          <meta charset=\"utf-8\">
          <style>{}</style>
          {}
          {}
          <style>{}</style>
          <style>{}</style>
      </head>
      <body>
        {}
          <div>
              {}
          </div>
      </body>
    </html>
    ", style,
       stringhl,
       stringtex,
       cheader,
       font,
       stringmaid,
       md);

    webview.load_html(&html, Some("file:///"));

    html
}

fn set_scrvalue (webview: &webkit2gtk::WebView, scroll_value: &f64) {
    let cl = gio::Cancellable::new();
    webview.run_javascript (
        format! ("
            var b = document.body,
            e = document.documentElement;
            var height = Math.max( b.scrollHeight,
                                   b.offsetHeight,
                                   e.clientHeight,
                                   e.scrollHeight,
                                   e.offsetHeight
                         );
            e.scrollTop = ({} * e.offsetHeight);
            e.scrollTop;
        ", scroll_value).as_str(),
         Some(&cl),
         move |v| {
            let jsg = webkit2gtk::JavascriptResult::get_global_context(&v.clone ().unwrap());
            webkit2gtk::JavascriptResult::get_value(&v.as_ref ().unwrap()).unwrap().to_number(&jsg.unwrap()).unwrap();
         }
    );
}

fn get_html (buffer: &sourceview4::Buffer, webview: &webkit2gtk::WebView) -> String {
    reload_func(buffer, webview)
}

fn focus_scope (buffer: &sourceview4::Buffer) {
    let (start, end) = buffer.get_bounds();
    let vm = SettingsManager::get_string(Key::VisualMode);
    let cursor = buffer.get_insert ().unwrap();
    let cursor_iter = buffer.get_iter_at_mark (&cursor);
    let fs = SettingsManager::get_boolean(Key::FocusMode);

    if fs {
        // Add focus stuff.
        if vm.as_str() == "dark" {
            buffer.remove_tag_by_name("lightsepiafont", &start, &end);
            buffer.remove_tag_by_name("lightgrayfont", &start, &end);
            buffer.remove_tag_by_name("whitefont", &start, &end);
            buffer.remove_tag_by_name("blackfont", &start, &end);
            buffer.remove_tag_by_name("sepiafont", &start, &end);
            buffer.apply_tag_by_name("darkgrayfont", &start, &end);
        } else if vm.as_str() == "sepia" {
            buffer.remove_tag_by_name("darkgrayfont", &start, &end);
            buffer.remove_tag_by_name("sepiafont", &start, &end);
            buffer.remove_tag_by_name("blackfont", &start, &end);
            buffer.remove_tag_by_name("whitefont", &start, &end);
            buffer.remove_tag_by_name("lightgrayfont", &start, &end);
            buffer.apply_tag_by_name("lightsepiafont", &start, &end);
        } else if vm.as_str() == "light" {
            buffer.remove_tag_by_name("darkgrayfont", &start, &end);
            buffer.remove_tag_by_name("lightsepiafont", &start, &end);
            buffer.remove_tag_by_name("sepiafont", &start, &end);
            buffer.remove_tag_by_name("blackfont", &start, &end);
            buffer.remove_tag_by_name("whitefont", &start, &end);
            buffer.apply_tag_by_name("lightgrayfont", &start, &end);
        }

        let mut start_sentence = cursor_iter.clone();
        let mut end_sentence = start_sentence.clone();

        let focus_type = SettingsManager::get_boolean(Key::FocusModeType);
        if cursor_iter != start &&
            cursor_iter != end {
            if focus_type {
                start_sentence.backward_sentence_start ();
                end_sentence.forward_sentence_end ();
            } else {
                start_sentence.backward_lines (1);
                end_sentence.forward_lines (2);
            }
        }

        if vm.as_str() == "dark" {
            buffer.remove_tag_by_name("sepiafont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("lightsepiafont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("blackfont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("lightgrayfont", &start_sentence, &end_sentence);
            buffer.apply_tag_by_name("whitefont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("darkgrayfont", &start_sentence, &end_sentence);
        } else if vm.as_str() == "sepia" {
            buffer.apply_tag_by_name("sepiafont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("lightsepiafont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("blackfont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("lightgrayfont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("whitefont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("darkgrayfont", &start_sentence, &end_sentence);
        } else if vm.as_str() == "light" {
            buffer.remove_tag_by_name("sepiafont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("lightsepiafont", &start_sentence, &end_sentence);
            buffer.apply_tag_by_name("blackfont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("lightgrayfont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("whitefont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("darkgrayfont", &start_sentence, &end_sentence);
        }
    } else {
        // Reset all stuff.
        let md_lang = sourceview4::LanguageManager::get_default().and_then(|lm| lm.get_language("markdown"));
        let lstylem = sourceview4::StyleSchemeManager::get_default().and_then(|sm| sm.get_scheme ("quilter"));
        let dstylem = sourceview4::StyleSchemeManager::get_default().and_then(|sm| sm.get_scheme ("quilter-dark"));
        let sstylem = sourceview4::StyleSchemeManager::get_default().and_then(|sm| sm.get_scheme ("quilter-sepia"));

        if let Some(md_lang) = md_lang {
            buffer.set_highlight_matching_brackets(true);
            buffer.set_language(Some(&md_lang));
            buffer.set_highlight_syntax(true);
        }

        if vm.as_str() == "light" {
            buffer.set_style_scheme(lstylem.as_ref());
            buffer.apply_tag_by_name("blackfont", &start, &end);
            buffer.remove_tag_by_name("sepiafont", &start, &end);
            buffer.remove_tag_by_name("whitefont", &start, &end);
            buffer.remove_tag_by_name("lightsepiafont", &start, &end);
            buffer.remove_tag_by_name("lightgrayfont", &start, &end);
            buffer.remove_tag_by_name("darkgrayfont", &start, &end);
        } else if vm.as_str() == "dark" {
            buffer.set_style_scheme(dstylem.as_ref());
            buffer.apply_tag_by_name("whitefont", &start, &end);
            buffer.remove_tag_by_name("sepiafont", &start, &end);
            buffer.remove_tag_by_name("blackfont", &start, &end);
            buffer.remove_tag_by_name("lightsepiafont", &start, &end);
            buffer.remove_tag_by_name("lightgrayfont", &start, &end);
            buffer.remove_tag_by_name("darkgrayfont", &start, &end);
        } else if vm.as_str() == "sepia" {
            buffer.set_style_scheme(sstylem.as_ref());
            buffer.apply_tag_by_name("sepiafont", &start, &end);
            buffer.remove_tag_by_name("whitefont", &start, &end);
            buffer.remove_tag_by_name("blackfont", &start, &end);
            buffer.remove_tag_by_name("lightsepiafont", &start, &end);
            buffer.remove_tag_by_name("lightgrayfont", &start, &end);
            buffer.remove_tag_by_name("darkgrayfont", &start, &end);
        }
    }
}

fn start_pos(buffer: &sourceview4::Buffer) {
    let (start, end) = buffer.get_bounds();
    let vbuf_list = lines_from_file(glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/wordlist/verb.txt");
    let abuf_list = lines_from_file(glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/wordlist/adjective.txt");
    let adbuf_list = lines_from_file(glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/wordlist/adverb.txt");
    let cnbuf_list = lines_from_file(glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/wordlist/conjunction.txt");
    let normal_buf = buffer.get_text (&start, &end, false).unwrap().to_string().replace("1234567890@$%^&*+=.,/!?<>;:\"{}[]()<>|\\’”“——…-# ", " ");
    let words: Vec<String> = normal_buf.split(' ').map(|s| s.to_string()).collect();
    let mut p = 0;

    let nounifier = ["the".to_string(), "an".to_string(), "a".to_string(), "and".to_string(), "or".to_string(), "this".to_string()];
    let verbifier = ["be".to_string(), "to".to_string(), "and".to_string()];

    for word in words {
        if word.chars().count() == 0 {
            p += word.chars().count() + 1;
            continue;
        }

        if vbuf_list.contains(&word) || (!word.starts_with("ing") && word.ends_with("ing")) || (!word.starts_with("ed") && word.ends_with("ed")) {
            let match_start = buffer.get_iter_at_offset(p as i32);
            let match_end = buffer.get_iter_at_offset((p as i32) + (word.chars().count() as i32));

            buffer.apply_tag_by_name("verbfont", &match_start, &match_end);
            buffer.remove_tag_by_name("advfont", &match_start, &match_end);
            buffer.remove_tag_by_name("adjfont", &match_start, &match_end);
            buffer.remove_tag_by_name("conjfont", &match_start, &match_end);


            // FIXME: Get the word before current one to check this.
            if nounifier.contains(&word) || (word.ends_with ("ction") && !word.starts_with ("ction")) {
               buffer.remove_tag_by_name("verbfont", &match_start, &match_end);
            }

            if verbifier.contains(&word) {
               buffer.apply_tag_by_name("verbfont", &match_start, &match_end);
            }
        }
        if abuf_list.contains(&word) {
            let match_start = buffer.get_iter_at_offset(p as i32);
            let match_end = buffer.get_iter_at_offset((p as i32) + (word.chars().count() as i32));

            buffer.apply_tag_by_name("adjfont", &match_start, &match_end);
            buffer.remove_tag_by_name("verbfont", &match_start, &match_end);
            buffer.remove_tag_by_name("conjfont", &match_start, &match_end);
            buffer.remove_tag_by_name("advfont", &match_start, &match_end);

            // FIXME: Get the word before current one to check this.
            if nounifier.contains(&word) {
               buffer.remove_tag_by_name("adjfont", &match_start, &match_end);
            }
        }
        if adbuf_list.contains(&word) {
            let match_start = buffer.get_iter_at_offset(p as i32);
            let match_end = buffer.get_iter_at_offset((p as i32) + (word.chars().count() as i32));

            buffer.apply_tag_by_name("advfont", &match_start, &match_end);
            buffer.remove_tag_by_name("adjfont", &match_start, &match_end);
            buffer.remove_tag_by_name("verbfont", &match_start, &match_end);
            buffer.remove_tag_by_name("conjfont", &match_start, &match_end);

            // FIXME: Get the word before current one to check this.
            if nounifier.contains(&word) {
               buffer.remove_tag_by_name("advfont", &match_start, &match_end);
            }
        }
        if cnbuf_list.contains(&word) {
            let match_start = buffer.get_iter_at_offset(p as i32);
            let match_end = buffer.get_iter_at_offset((p as i32) + (word.chars().count() as i32));

            buffer.apply_tag_by_name("conjfont", &match_start, &match_end);
            buffer.remove_tag_by_name("advfont", &match_start, &match_end);
            buffer.remove_tag_by_name("adjfont", &match_start, &match_end);
            buffer.remove_tag_by_name("verbfont", &match_start, &match_end);
        }

        p += word.chars().count() + 1;
    }
}

fn lines_from_file(filename: impl AsRef<Path>) -> Vec<String> {
    let file = File::open(filename).expect("no such file");
    let buf = BufReader::new(file);
    buf.lines()
        .map(|l| l.expect("Could not parse line"))
        .collect()
}

