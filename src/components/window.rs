extern crate sourceview4;

use crate::components::header::Header;
use crate::components::sidebar::Sidebar;

use gtk;
use gtk::*;
use gtk::prelude::*;
use sourceview4::LanguageManagerExt;
use sourceview4::BufferExt;
use sourceview4::StyleSchemeManagerExt;
use gtk::SettingsExt as GtkSettings;
use gio::SettingsExt;
use webkit2gtk::{WebContext, WebView, WebViewExt};

const CSS: &str = include_str!("styles/app.css");
const CSSLIGHT: &str = include_str!("styles/light.css");
const CSSDARK: &str = include_str!("styles/dark.css");

use crate::config::APP_ID;
use crate::components::window_state;

pub struct Window {
    pub container: libhandy::ApplicationWindow,
    pub settings: gio::Settings,
    pub header:  Header,
    pub sidebar:  Sidebar,
    pub view: sourceview4::View,
    pub webview: webkit2gtk::WebView,
}

impl Window {
    pub fn new() -> Window {
        let settings = gio::Settings::new(APP_ID);

        let container = libhandy::ApplicationWindow::new();
        let settingsgtk = gtk::Settings::get_default();
        settingsgtk.clone ().unwrap().set_property_gtk_theme_name(Some("io.elementary.stylesheet.blueberry"));
        settingsgtk.clone ().unwrap().set_property_gtk_icon_theme_name(Some("elementary"));
        settingsgtk.clone ().unwrap().set_property_gtk_font_name(Some("Inter Regular 9"));

        let style = CssProvider::new();
        let _ = CssProviderExt::load_from_data(&style, CSS.as_bytes());
        StyleContext::add_provider_for_screen(&gdk::Screen::get_default().unwrap(), &style, STYLE_PROVIDER_PRIORITY_USER);

        let header = Header::new();
        let sidebar = Sidebar::new();
        
        let table = gtk::TextTagTable::new();
        let buffer = sourceview4::Buffer::new(Some(&table));
        let view = sourceview4::View::with_buffer(&buffer);
        view.get_style_context().add_class("medium-font");
        view.get_style_context().add_class("mono-font");
        view.set_monospace(true);
        view.set_wrap_mode(gtk::WrapMode::Word);
        view.set_vexpand(true);
        view.set_left_margin(40);
        view.set_top_margin(40);
        view.set_right_margin(40);
        view.set_bottom_margin(40);

        let md_lang = sourceview4::LanguageManager::get_default()
            .map_or(None, |lm| lm.get_language("markdown"));
        
        if let Some(md_lang) = md_lang.clone() {
            buffer.set_highlight_matching_brackets(true);
            buffer.set_language(Some(&md_lang));
            buffer.set_highlight_syntax(true);
        }
        
                // Add custom CSS

        let vm = settings.get_string("visual-mode").unwrap();
        if vm.as_str() == "light" {
            header.popover.color_button_light.set_active (true);
        } else if vm.as_str() == "dark" {
            header.popover.color_button_dark.set_active (true);
        }

        let settingsgtk = gtk::Settings::get_default();

        let lstylem = sourceview4::StyleSchemeManager::get_default()
            .map_or(None, |sm| sm.get_scheme ("quilter"));
        let dstylem = sourceview4::StyleSchemeManager::get_default()
            .map_or(None, |sm| sm.get_scheme ("quilter-dark"));
        if vm.as_str() == "light" {
            let _ = CssProviderExt::load_from_data(&style, CSSLIGHT.as_bytes());
            let stylevml = CssProvider::new();
            StyleContext::add_provider_for_screen(&gdk::Screen::get_default().unwrap(), &stylevml, STYLE_PROVIDER_PRIORITY_USER);
            settingsgtk.clone ().unwrap().set_property_gtk_application_prefer_dark_theme(false);

            buffer.set_style_scheme(lstylem.as_ref());
        } else if vm.as_str() == "dark" {
            let _ = CssProviderExt::load_from_data(&style, CSSDARK.as_bytes());
            let stylevmd = CssProvider::new();
            StyleContext::add_provider_for_screen(&gdk::Screen::get_default().unwrap(), &stylevmd, STYLE_PROVIDER_PRIORITY_USER);
            settingsgtk.clone ().unwrap().set_property_gtk_application_prefer_dark_theme(true);

            buffer.set_style_scheme(dstylem.as_ref());
        }

        settings.connect_changed (move |settings, _| {
            let vm = settings.get_string("visual-mode").unwrap();
            let lstylem = sourceview4::StyleSchemeManager::get_default()
                .map_or(None, |sm| sm.get_scheme ("quilter"));
            let dstylem = sourceview4::StyleSchemeManager::get_default()
                .map_or(None, |sm| sm.get_scheme ("quilter-dark"));
            if vm.as_str() == "light" {
                let _ = CssProviderExt::load_from_data(&style, CSSLIGHT.as_bytes());
                let stylevml = CssProvider::new();
                StyleContext::add_provider_for_screen(&gdk::Screen::get_default().unwrap(), &stylevml, STYLE_PROVIDER_PRIORITY_USER);
                settingsgtk.clone ().unwrap().set_property_gtk_application_prefer_dark_theme(false);

                buffer.set_style_scheme(lstylem.as_ref());
            } else if vm.as_str() == "dark" {
                let _ = CssProviderExt::load_from_data(&style, CSSDARK.as_bytes());
                let stylevmd = CssProvider::new();
                StyleContext::add_provider_for_screen(&gdk::Screen::get_default().unwrap(), &stylevmd, STYLE_PROVIDER_PRIORITY_USER);
                settingsgtk.clone ().unwrap().set_property_gtk_application_prefer_dark_theme(true);

                buffer.set_style_scheme(dstylem.as_ref());
            }
        });

        //

        header.open_button.connect_clicked(glib::clone!(@weak container, @weak view => move |_| {
            let file_chooser = gtk::FileChooserDialog::new(
                Some("Open File"),
                Some(&container),
                gtk::FileChooserAction::Open,
            );
            file_chooser.add_buttons(&[
                ("Open", gtk::ResponseType::Ok),
                ("Cancel", gtk::ResponseType::Cancel),
            ]);
            file_chooser.connect_response(glib::clone!(@weak container, @weak view => move |file_chooser, response| {
                if response == gtk::ResponseType::Ok {
                    let filename = file_chooser.get_filename().expect("Couldn't get filename");
                    let buf = glib::file_get_contents(filename).expect("Unable to get data");
                    let contents = String::from_utf8_lossy(&buf);

                    view.clone ().get_buffer ().unwrap ().set_text(&contents);
                }
                file_chooser.close();
            }));

            file_chooser.show_all();
        }));
        
        header.save_button.connect_clicked(glib::clone!(@weak container, @weak view => move |_| {
            let file_chooser = gtk::FileChooserDialog::new(
                Some("Save File"),
                Some(&container),
                gtk::FileChooserAction::Save,
            );
            file_chooser.add_buttons(&[
                ("Save", gtk::ResponseType::Ok),
                ("Cancel", gtk::ResponseType::Cancel),
            ]);
            file_chooser.connect_response(glib::clone!(@weak container, @weak view => move |file_chooser, response| {
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
        
        header.popover.color_button_light.connect_toggled(glib::clone!(@weak settings => move |_| {
            settings.set_string("visual-mode", "light").unwrap();
        }));

        header.popover.color_button_dark.connect_toggled(glib::clone!(@weak settings => move |_| {
            settings.set_string("visual-mode", "dark").unwrap();
        }));

        let context = WebContext::get_default().unwrap();
        let webview = WebView::with_context(&context);
        webview.load_uri("file:///");
        
        let stack = gtk::Stack::new();
        stack.add(&view);
        stack.add(&webview);
        
        let grid = gtk::Grid::new();
        grid.set_hexpand(true);
        grid.set_orientation(gtk::Orientation::Vertical);
        grid.attach (&sidebar.container, 0, 0, 1, 2);
        grid.attach (&header.container, 1, 0, 1, 1);
        grid.attach (&stack, 1, 1, 1, 1);

        container.add(&grid);
        container.set_size_request(600, 350);

        let window_widget = Window {
            container,
            settings,
            header,
            sidebar,
            view,
            webview,
        };

        window_widget.init();
        window_widget
    }

    fn init(&self) {
        // load latest window state
        window_state::load(&self.container, &self.settings);

        // save window state on delete event
        self.container.connect_delete_event(
            glib::clone!(@strong self.settings as settings => move |window, _| {
                if let Err(err) = window_state::save(&window, &settings) {
                    log::warn!("Failed to save window state, {}", err);
                }
                Inhibit(false)
            }),
        );
    }
}
