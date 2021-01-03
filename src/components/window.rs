extern crate sourceview4;

use pulldown_cmark::{Parser, Options, html};

use crate::components::header::Header;
use crate::components::sidebar::Sidebar;
use crate::components::searchbar::Searchbar;

use gtk::*;
use gtk::prelude::*;
use gtk::IconThemeExt;
use sourceview4::LanguageManagerExt;
use sourceview4::BufferExt;
use sourceview4::StyleSchemeManagerExt;
use gtk::SettingsExt as GtkSettings;
use gio::SettingsExt;
use gtk::RevealerExt;
use webkit2gtk::WebViewExt;

use crate::config::{APP_ID, PROFILE};
use crate::components::window_state;

pub struct Window {
    pub widget: libhandy::ApplicationWindow,
    pub settings: gio::Settings,
    pub header:  Header,
    pub sidebar:  Sidebar,
    pub searchbar: Searchbar,
    pub main: gtk::Stack,
    pub half_stack: gtk::Grid,
    pub full_stack: gtk::Stack,
    pub view: sourceview4::View,
    pub webview: webkit2gtk::WebView,
}

impl Window {
    pub fn new() -> Window {
        let settings = gio::Settings::new(APP_ID);
        let header = Header::new();
        let sidebar = Sidebar::new();
        let table = gtk::TextTagTable::new();
        let buffer = sourceview4::Buffer::new(Some(&table));
        let last_file = settings.get_string("current-file").unwrap();
        let builder = gtk::Builder::from_resource("/com/github/lainsce/quilter/window.ui");
        get_widget!(builder, libhandy::ApplicationWindow, win);
        
        let builder2 = gtk::Builder::from_resource("/com/github/lainsce/quilter/main_view.ui");
        get_widget!(builder2, gtk::Stack, main);
        main.set_visible (true);

        get_widget!(builder2, gtk::ScrolledWindow, sc);
        sc.get_style_context().remove_class("frame");

        get_widget!(builder2, gtk::Grid, half_stack);
        half_stack.set_visible (true);

        get_widget!(builder2, gtk::Stack, full_stack);
        full_stack.set_visible (true);

        get_widget!(builder2, sourceview4::View, view);
        view.set_visible (true);
        view.set_buffer(Some(&buffer));

        get_widget!(builder2, webkit2gtk::WebView, webview);
        webview.set_visible (true);

        if last_file.as_str() != "" {
            let filename = last_file.as_str();
            let buf = glib::file_get_contents(filename).expect("Unable to get data");
            let contents = String::from_utf8_lossy(&buf);

            view.clone ().get_buffer ().unwrap ().set_text(&contents);
        }

        let md_lang = sourceview4::LanguageManager::get_default()
            .map_or(None, |lm| lm.get_language("markdown"));
        
        if let Some(md_lang) = md_lang.clone() {
            buffer.set_highlight_matching_brackets(true);
            buffer.set_language(Some(&md_lang));
            buffer.set_highlight_syntax(true);
        }
        
        // Add custom CSS
        let settingsgtk = gtk::Settings::get_default();
        let vm = settings.get_string("visual-mode").unwrap();
        let lstylem = sourceview4::StyleSchemeManager::get_default()
            .map_or(None, |sm| sm.get_scheme ("quilter"));
        let dstylem = sourceview4::StyleSchemeManager::get_default()
            .map_or(None, |sm| sm.get_scheme ("quilter-dark"));
        let sstylem = sourceview4::StyleSchemeManager::get_default()
            .map_or(None, |sm| sm.get_scheme ("quilter-sepia"));
        if vm.as_str() == "light" {
            let stylevml = CssProvider::new();
            gtk::CssProviderExt::load_from_resource(&stylevml, "/com/github/lainsce/quilter/light.css");
            gtk::StyleContext::add_provider_for_screen(&gdk::Screen::get_default().unwrap(), &stylevml, 600);
            settingsgtk.clone ().unwrap().set_property_gtk_application_prefer_dark_theme(false);

            buffer.set_style_scheme(lstylem.as_ref());
        } else if vm.as_str() == "dark" {
            let stylevmd = CssProvider::new();
            gtk::CssProviderExt::load_from_resource(&stylevmd, "/com/github/lainsce/quilter/dark.css");
            gtk::StyleContext::add_provider_for_screen(&gdk::Screen::get_default().unwrap(), &stylevmd, 600);
            settingsgtk.clone ().unwrap().set_property_gtk_application_prefer_dark_theme(true);

            buffer.set_style_scheme(dstylem.as_ref());
        } else if vm.as_str() == "sepia" {
            let stylevms = CssProvider::new();
            gtk::CssProviderExt::load_from_resource(&stylevms, "/com/github/lainsce/quilter/sepia.css");
            gtk::StyleContext::add_provider_for_screen(&gdk::Screen::get_default().unwrap(), &stylevms, 600);
            settingsgtk.clone ().unwrap().set_property_gtk_application_prefer_dark_theme(false);

            buffer.set_style_scheme(sstylem.as_ref());
        }

        settings.connect_changed (move |settings, _| {
            let vm = settings.get_string("visual-mode").unwrap();
            let lstylem = sourceview4::StyleSchemeManager::get_default()
                .map_or(None, |sm| sm.get_scheme ("quilter"));
            let dstylem = sourceview4::StyleSchemeManager::get_default()
                .map_or(None, |sm| sm.get_scheme ("quilter-dark"));
            let sstylem = sourceview4::StyleSchemeManager::get_default()
                .map_or(None, |sm| sm.get_scheme ("quilter-sepia"));
            if vm.as_str() == "light" {
                let stylevml = CssProvider::new();
                gtk::CssProviderExt::load_from_resource(&stylevml, "/com/github/lainsce/quilter/light.css");
                gtk::StyleContext::add_provider_for_screen(&gdk::Screen::get_default().unwrap(), &stylevml, 600);
                settingsgtk.clone ().unwrap().set_property_gtk_application_prefer_dark_theme(false);

                buffer.set_style_scheme(lstylem.as_ref());
            } else if vm.as_str() == "dark" {
                let stylevmd = CssProvider::new();
                gtk::CssProviderExt::load_from_resource(&stylevmd, "/com/github/lainsce/quilter/dark.css");
                gtk::StyleContext::add_provider_for_screen(&gdk::Screen::get_default().unwrap(), &stylevmd, 600);
                settingsgtk.clone ().unwrap().set_property_gtk_application_prefer_dark_theme(true);

                buffer.set_style_scheme(dstylem.as_ref());
            } else if vm.as_str() == "sepia" {
                let stylevms = CssProvider::new();
                gtk::CssProviderExt::load_from_resource(&stylevms, "/com/github/lainsce/quilter/sepia.css");
                gtk::StyleContext::add_provider_for_screen(&gdk::Screen::get_default().unwrap(), &stylevms, 600);
                settingsgtk.clone ().unwrap().set_property_gtk_application_prefer_dark_theme(false);

                buffer.set_style_scheme(sstylem.as_ref());
            }
        });

        //

        header.open_button.connect_clicked(glib::clone!(@strong settings, @weak win, @weak view => move |_| {
            let file_chooser = gtk::FileChooserDialog::new(
                Some("Open File"),
                Some(&win),
                gtk::FileChooserAction::Open,
            );
            file_chooser.add_buttons(&[
                ("Open", gtk::ResponseType::Ok),
                ("Cancel", gtk::ResponseType::Cancel),
            ]);
            file_chooser.connect_response(glib::clone!(@strong settings, @weak win, @weak view => move |file_chooser, response| {
                if response == gtk::ResponseType::Ok {
                    let filename = file_chooser.get_filename().expect("Couldn't get filename");
                    settings.set_string("current-file", &filename.clone ().into_os_string().into_string().unwrap()).expect("Unable to set filename for GSchema");
                    let buf = glib::file_get_contents(filename).expect("Unable to get data");
                    let contents = String::from_utf8_lossy(&buf);

                    view.clone ().get_buffer ().unwrap ().set_text(&contents);
                }
                file_chooser.close();
            }));

            file_chooser.show_all();
        }));
        
        header.save_button.connect_clicked(glib::clone!(@weak win, @weak view => move |_| {
            let file_chooser = gtk::FileChooserDialog::new(
                Some("Save File"),
                Some(&win),
                gtk::FileChooserAction::Save,
            );
            file_chooser.add_buttons(&[
                ("Save", gtk::ResponseType::Ok),
                ("Cancel", gtk::ResponseType::Cancel),
            ]);
            file_chooser.connect_response(glib::clone!(@weak win, @weak view => move |file_chooser, response| {
                if response == gtk::ResponseType::Ok {
                    let filename = file_chooser.get_filename().expect("Couldn't get filename");
                    let (start, end) = view.clone ().get_buffer ().unwrap ().get_bounds();
                    let contents = view.clone ().get_buffer ().unwrap ().get_text(&start, &end, true);
                    
                    glib::file_set_contents(filename, contents.unwrap().as_bytes()).expect("Unable to write data");
                }
                file_chooser.close();
            }));

            file_chooser.show_all();
        }));
        
        header.new_button.connect_clicked(glib::clone!(@weak view => move |_| {
            view.get_buffer ().unwrap ().set_text("");
        }));

        let searchbar = Searchbar::new();

        header.search_button.connect_clicked(glib::clone!(@weak searchbar.container as r => move |_| {
            r.set_reveal_child (true);
        }));

        let grid = gtk::Grid::new();
        grid.set_hexpand(true);
        grid.set_orientation(gtk::Orientation::Vertical);
        grid.attach (&sidebar.container, 0, 0, 1, 3);
        grid.attach (&header.container, 1, 0, 1, 1);
        grid.attach (&searchbar.container, 1, 1, 1, 1);
        grid.attach (&main, 1, 2, 1, 1);
        grid.show_all ();

        win.add(&grid);
        win.set_size_request(600, 350);
        win.set_icon_name(Some(APP_ID));

        let def = gtk::IconTheme::get_default ();
        gtk::IconTheme::add_resource_path(&def.unwrap(), "/com/github/lainsce/quilter/");

        reload_func(&view, &webview);

        header.popover.toggle_view_button.connect_clicked(glib::clone!(@weak full_stack, @weak view, @weak sc, @weak webview => move |_| {
            let key: glib::GString = "editor".into();
            if full_stack.get_visible_child_name() == Some(key) {
                full_stack.set_visible_child(&webview);
                reload_func(&view, &webview);
            } else {
                full_stack.set_visible_child(&sc);
                reload_func(&view, &webview);
            }
        }));

        header.popover.prefs_button.connect_clicked(glib::clone!(@weak win as window => move |_| {
            let builder = gtk::Builder::from_resource("/com/github/lainsce/quilter/prefs_window.ui");
            get_widget!(builder, libhandy::PreferencesWindow, prefs);
            prefs.set_transient_for(Some(&window));
            prefs.show();
        }));

        header.viewpopover.full_button.connect_toggled(glib::clone!(@strong settings, @weak main, @weak full_stack, @weak half_stack => move |_| {
            let key: glib::GString = "full".into();
            if settings.get_string("preview-type") == Some(key) {
                main.set_visible_child(&full_stack);
            } else {
                main.set_visible_child(&half_stack);
            }
        }));

        header.viewpopover.half_button.connect_toggled(glib::clone!(@strong settings, @weak main, @weak full_stack, @weak half_stack => move |_| {
            let key: glib::GString = "half".into();
            if settings.get_string("preview-type") == Some(key) {
                main.set_visible_child(&half_stack);
            } else {
                main.set_visible_child(&full_stack);
            }
        }));

        view.get_buffer ().unwrap ().connect_changed(glib::clone!(@strong settings, @weak view, @weak webview => move |_| {
            reload_func (&view, &webview);

            let last_file = settings.get_string("current-file").unwrap();
            let filename = last_file.as_str();
            let (start, end) = view.clone ().get_buffer ().unwrap ().get_bounds();
            let contents = view.clone ().get_buffer ().unwrap ().get_text(&start, &end, true);

            glib::file_set_contents(filename, contents.unwrap().as_bytes()).expect("Unable to write data");
        }));

        let window_widget = Window {
            widget: win,
            settings,
            header,
            sidebar,
            searchbar,
            main,
            half_stack,
            full_stack,
            view,
            webview,
        };
        window_widget.init ();
        window_widget
    }

    fn init(&self) {
        // Devel Profile
        if PROFILE == "Devel" {
            self.widget.get_style_context().add_class("devel");
        }

        // load latest window state
        window_state::load(&self.widget, &self.settings);

        // save window state on delete event
        self.widget.connect_delete_event(
            glib::clone!(@strong self.settings as settings => move |win, _| {
                if let Err(err) = window_state::save(&win, &settings) {
                    log::warn!("Failed to save window state, {}", err);
                }
                Inhibit(false)
            }),
        );
    }
}

fn reload_func(view: &sourceview4::View, webview: &webkit2gtk::WebView) {
    let (start, end) = view.clone ().get_buffer ().unwrap ().get_bounds();
    let buf = view.clone ().get_buffer ().unwrap ().get_text(&start, &end, true).unwrap();
    let contents = buf.as_str();

    let mut options = Options::empty();
    options.insert(Options::ENABLE_STRIKETHROUGH);
    let parser = Parser::new_ext(&contents, options);

    let mut html_output = String::new();
    html::push_html(&mut html_output, parser);

    webview.load_html(&html_output, Some("file:///"));
}
