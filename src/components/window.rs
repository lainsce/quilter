extern crate sourceview4;
extern crate foreach;

use crate::config::{APP_ID, PROFILE};
use crate::components::window_state;
use crate::components::css::CSS;
use crate::components::header::Header;
use crate::components::sidebar::Sidebar;
use crate::components::searchbar::Searchbar;
use crate::components::prefs_window::PreferencesWindow;
use pulldown_cmark::{Parser, Options, html};
use gtk::*;
use gtk::prelude::*;
use gtk::IconThemeExt;
use sourceview4::LanguageManagerExt;
use sourceview4::BufferExt;
use sourceview4::StyleSchemeManagerExt;
use gtk::SettingsExt as GtkSettings;
use gio::SettingsExt;
use gtk::RevealerExt;
use gtk::WidgetExt;
use webkit2gtk::WebViewExt as WebSettings;
use webkit2gtk::SettingsExt as _;

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
    pub prefs_win: PreferencesWindow,
}

impl Window {
    pub fn new() -> Window {
        let settings = gio::Settings::new(APP_ID);
        let header = Header::new();
        let sidebar = Sidebar::new();
        let prefs_win = PreferencesWindow::new();

        let builder = gtk::Builder::from_resource("/com/github/lainsce/quilter/window.ui");
        get_widget!(builder, libhandy::ApplicationWindow, win);
        
        let builder2 = gtk::Builder::from_resource("/com/github/lainsce/quilter/main_view.ui");
        get_widget!(builder2, gtk::Stack, main);
        main.set_visible (true);

        get_widget!(builder2, gtk::ScrolledWindow, sc);
        sc.get_style_context().remove_class("frame");

        get_widget!(builder2, gtk::ScrolledWindow, sc1);
        sc1.get_style_context().remove_class("frame");

        get_widget!(builder2, gtk::Grid, half_stack);
        half_stack.set_visible (true);

        get_widget!(builder2, gtk::Stack, full_stack);
        full_stack.set_visible (true);

        get_widget!(builder2, sourceview4::View, view);
        view.set_visible (true);
        let table = gtk::TextTagTable::new();
        let buffer = sourceview4::Buffer::new(Some(&table));
        view.set_buffer(Some(&buffer));
        view.set_left_margin (settings.get_int ("margins"));
        view.set_right_margin (settings.get_int ("margins"));

        get_widget!(builder2, webkit2gtk::WebView, webview);
        webview.set_visible (true);

        //
        //
        //
        // Editor (view) Block
        //
        //
        //

        let last_file = settings.get_string("current-file").unwrap();
        if last_file.as_str() != "" {
            let filename = last_file.as_str();
            let buf = glib::file_get_contents(filename).expect("Unable to get data");
            let contents = String::from_utf8_lossy(&buf);

            view.clone ().get_buffer ().unwrap ().set_text(&contents);
        }

        view.get_buffer ().unwrap ().connect_changed(glib::clone!(@strong settings, @weak view, @weak webview => move |_| {
            reload_func (&view, &webview);

            let last_file = settings.get_string("current-file").unwrap();
            let filename = last_file.as_str();
            let (start, end) = view.clone ().get_buffer ().unwrap ().get_bounds();
            let contents = view.clone ().get_buffer ().unwrap ().get_text(&start, &end, true);

            glib::file_set_contents(filename, contents.unwrap().as_bytes()).expect("Unable to write data");
        }));

        let md_lang = sourceview4::LanguageManager::get_default()
            .map_or(None, |lm| lm.get_language("markdown"));
        
        if let Some(md_lang) = md_lang.clone() {
            buffer.set_highlight_matching_brackets(true);
            buffer.set_language(Some(&md_lang));
            buffer.set_highlight_syntax(true);
        }
        
        //
        //
        //
        // Preview (preview) Block
        //
        //
        //

        let webkit_settings = webkit2gtk::Settings::new ();
        webkit_settings.set_javascript_can_open_windows_automatically (false);
        webkit_settings.set_enable_java (false);
        webkit_settings.set_enable_page_cache (true);
        webkit_settings.set_enable_plugins (false);
        webview.set_settings (&webkit_settings);

        reload_func(&view, &webview);
        change_layout (&main, &full_stack, &half_stack, &sc, &sc1);

        //
        //
        //
        // CSS Block
        //
        //
        //

        let settingsgtk = gtk::Settings::get_default();
        let vm = settings.get_string("visual-mode").unwrap();
        let pft = settings.get_string("preview-font-type").unwrap();
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

        settings.connect_changed (glib::clone!( @strong settings,
                                                @weak webview,
                                                @weak view,
                                                @weak prefs_win.ptype as pt,
                                                @weak prefs_win.light as light,
                                                @weak prefs_win.sepia as sepia,
                                                @weak prefs_win.dark as dark,
                                                @weak prefs_win.small as pws,
                                                @weak prefs_win.medium as pwm,
                                                @weak prefs_win.large as pwl,
                                                @weak prefs_win.small1 as pws1,
                                                @weak prefs_win.medium1 as pwm1,
                                                @weak prefs_win.large1 as pwl1,
                                                @weak prefs_win.small2 as pws2,
                                                @weak prefs_win.medium2 as pwm2,
                                                @weak prefs_win.large2 as pwl2
                                                => move |settings, _| {
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

            let pft = settings.get_string("preview-font-type").unwrap();
            if pft.as_str() == "mono" {
                pt.set_active(Some(2));
            } else if pft.as_str() == "sans" {
                pt.set_active(Some(0));
            } else if pft.as_str() == "serif" {
                pt.set_active(Some(1));
            } else {
                pt.set_active(Some(1));
            }

            reload_func(&view, &webview);

            pws.connect_toggled(glib::clone!(@weak view => move |_| {
                view.set_pixels_above_lines (2);
                view.set_pixels_inside_wrap (2);
            }));

            pwm.connect_toggled(glib::clone!(@weak view => move |_| {
                view.set_pixels_above_lines (4);
                view.set_pixels_inside_wrap (4);
            }));

            pwl.connect_toggled(glib::clone!(@weak view => move |_| {
                view.set_pixels_above_lines (8);
                view.set_pixels_inside_wrap (8);
            }));

            pws1.connect_toggled(glib::clone!(@weak view => move |_| {
                view.set_left_margin (20);
                view.set_right_margin (20);
            }));

            pwm1.connect_toggled(glib::clone!(@weak view => move |_| {
                view.set_left_margin (40);
                view.set_right_margin (40);
            }));

            pwl1.connect_toggled(glib::clone!(@weak view => move |_| {
                view.set_left_margin (80);
                view.set_right_margin (80);
            }));

            pws2.connect_toggled(glib::clone!(@weak view => move |_| {
                view.get_style_context().add_class("small-font");
                view.get_style_context().remove_class("medium-font");
                view.get_style_context().remove_class("large-font");
            }));

            pwm2.connect_toggled(glib::clone!(@weak view => move |_| {
                view.get_style_context().add_class("medium-font");
                view.get_style_context().remove_class("small-font");
                view.get_style_context().remove_class("large-font");
            }));

            pwl2.connect_toggled(glib::clone!(@weak view => move |_| {
                view.get_style_context().add_class("large-font");
                view.get_style_context().remove_class("medium-font");
                view.get_style_context().remove_class("small-font");
            }));
        }));

        //
        //
        //
        // Preferences Window
        //
        //
        //

        if vm.as_str() == "light" {
            prefs_win.light.set_active (true);
        } else if vm.as_str() == "dark" {
            prefs_win.dark.set_active (true);
        } if vm.as_str() == "sepia" {
            prefs_win.sepia.set_active (true);
        }

        prefs_win.light.connect_toggled(glib::clone!(@weak settings as s => move |_| {
            s.set_string("visual-mode", "light").unwrap();
        }));

        prefs_win.dark.connect_toggled(glib::clone!(@weak settings as s => move |_| {
            s.set_string("visual-mode", "dark").unwrap();
        }));

        prefs_win.sepia.connect_toggled(glib::clone!(@weak settings as s => move |_| {
            s.set_string("visual-mode", "sepia").unwrap();
        }));

        if pft.as_str() == "mono" {
            prefs_win.ptype.set_active(Some(2));
        } else if pft.as_str() == "sans" {
            prefs_win.ptype.set_active(Some(0));
        } else if pft.as_str() == "serif" {
            prefs_win.ptype.set_active(Some(1));
        } else {
            prefs_win.ptype.set_active(Some(1));
        }

        if prefs_win.ptype.get_active() == Some(1) {
            settings.set_string("preview-font-type", "serif").expect ("Oops!");
        } else if prefs_win.ptype.get_active() == Some(0) {
            settings.set_string("preview-font-type", "sans").expect ("Oops!");
        } else if prefs_win.ptype.get_active() == Some(2) {
            settings.set_string("preview-font-type", "mono").expect ("Oops!");
        } else {
            settings.set_string("preview-font-type", "serif").expect ("Oops!");
        }

        settings.bind ("center-headers", &prefs_win.centering, "active", gio::SettingsBindFlags::DEFAULT);
        settings.bind ("highlight", &prefs_win.highlight, "active", gio::SettingsBindFlags::DEFAULT);
        settings.bind ("latex", &prefs_win.latex, "active", gio::SettingsBindFlags::DEFAULT);
        settings.bind ("mermaid", &prefs_win.mermaid, "active", gio::SettingsBindFlags::DEFAULT);

        prefs_win.mermaid.bind_property (
            "active",
            &prefs_win.highlight,
            "active"
        );

        if settings.get_int("spacing") == 2 {
            prefs_win.small.set_active (true);
        } else if settings.get_int("spacing") == 4 {
            prefs_win.medium.set_active (true);
        } else if settings.get_int("spacing") == 8 {
            prefs_win.large.set_active (true);
        } else {
            prefs_win.medium.set_active (true);
        }

        if prefs_win.small.get_active () == true {
            settings.set_int("spacing", 2).expect ("Oops!");
        } else if prefs_win.medium.get_active () == true {
            settings.set_int("spacing", 4).expect ("Oops!");
        } else if prefs_win.large.get_active() == true {
            settings.set_int("spacing", 8).expect ("Oops!");
        } else {
            settings.set_int("spacing", 4).expect ("Oops!");
        }

        if settings.get_int("margins") == 20 {
            prefs_win.small1.set_active (true);
        } else if settings.get_int("margins") == 40 {
            prefs_win.medium1.set_active (true);
        } else if settings.get_int("margins") == 80 {
            prefs_win.large1.set_active (true);
        } else {
            prefs_win.medium1.set_active (true);
        }

        if prefs_win.small1.get_active () == true {
            settings.set_int("margins", 20).expect ("Oops!");
        } else if prefs_win.medium1.get_active () == true {
            settings.set_int("margins", 40).expect ("Oops!");
        } else if prefs_win.large1.get_active() == true {
            settings.set_int("margins", 80).expect ("Oops!");
        } else {
            settings.set_int("margins", 40).expect ("Oops!");
        }

        if settings.get_int("font-sizing") == 1 {
            prefs_win.small2.set_active (true);
        } else if settings.get_int("font-sizing") == 2 {
            prefs_win.medium2.set_active (true);
        } else if settings.get_int("font-sizing") == 3 {
            prefs_win.large2.set_active (true);
        } else {
            prefs_win.medium2.set_active (true);
        }

        if prefs_win.small2.get_active () == true {
            settings.set_int("font-sizing", 1).expect ("Oops!");
        } else if prefs_win.medium2.get_active () == true {
            settings.set_int("font-sizing", 2).expect ("Oops!");
        } else if prefs_win.large2.get_active() == true {
            settings.set_int("font-sizing", 3).expect ("Oops!");
        } else {
            settings.set_int("font-sizing", 2).expect ("Oops!");
        }

        //
        //
        //
        // Headerbar Buttons Block
        //
        //
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

        header.viewpopover.full_button.connect_toggled(glib::clone!(@strong settings, @weak main, @weak full_stack, @weak half_stack, @weak sc1, @weak sc => move |_| {
            let key: glib::GString = "full".into();
            if settings.get_string("preview-type") == Some(key) {
                main.set_visible_child(&full_stack);
                change_layout (&main, &full_stack, &half_stack, &sc, &sc1);
            } else {
                main.set_visible_child(&half_stack);
                change_layout (&main, &full_stack, &half_stack, &sc, &sc1);
            }
        }));

        header.viewpopover.half_button.connect_toggled(glib::clone!(@strong settings, @weak main, @weak full_stack, @weak half_stack, @weak sc1, @weak sc => move |_| {
            let key: glib::GString = "half".into();
            if settings.get_string("preview-type") == Some(key) {
                main.set_visible_child(&half_stack);
                change_layout (&main, &full_stack, &half_stack, &sc, &sc1);
            } else {
                main.set_visible_child(&full_stack);
                change_layout (&main, &full_stack, &half_stack, &sc, &sc1);
            }
        }));

        header.popover.toggle_view_button.connect_clicked(glib::clone!(@weak full_stack, @weak view, @weak webview, @weak sc, @weak sc1 => move |_| {
            let key: glib::GString = "editor".into();
            if full_stack.get_visible_child_name() == Some(key) {
                full_stack.set_visible_child(&sc1);
                reload_func(&view, &webview)
            } else {
                full_stack.set_visible_child(&sc);
                reload_func(&view, &webview);
            }
        }));

        header.popover.prefs_button.connect_clicked(glib::clone!(@weak win as window, @weak prefs_win.prefs as pw => move |_| {
            pw.set_transient_for(Some(&window));
            pw.show();
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
            prefs_win,
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

//
//
//
// Misc. Functions Block
//
//
//

fn change_layout (main: &gtk::Stack, full_stack: &gtk::Stack, half_stack: &gtk::Grid, sc: &gtk::ScrolledWindow, sc1: &gtk::ScrolledWindow,) {
    let settings = gio::Settings::new(APP_ID);
    let layout = settings.get_string("preview-type").unwrap();
    if layout.as_str() == "full" {
        for w in half_stack.get_children () {
            half_stack.remove (&w);
        }
        full_stack.add_titled (sc, "editor", &"Edit");
        full_stack.add_titled (sc1, "preview", &"Preview");
        main.set_visible_child (full_stack);
    } else {
        for w in full_stack.get_children () {
            full_stack.remove (&w);
        }
        half_stack.add (sc);
        half_stack.add (sc1);
        main.set_visible_child (half_stack);
    }
}

fn reload_func(view: &sourceview4::View, webview: &webkit2gtk::WebView) {
    let (start, end) = view.clone ().get_buffer ().unwrap ().get_bounds();
    let buf = view.clone ().get_buffer ().unwrap ().get_text(&start, &end, true).unwrap();
    let contents = buf.as_str();

    let css = CSS::new();

    let mut style = "";
    let mut font = "";
    let mut cheader;
    cheader = "".to_string();

    let settings = gio::Settings::new(APP_ID);
    let vm = settings.get_string("visual-mode").unwrap();
    if vm.as_str() == "dark" {
        style = &css.dark;
    } else if vm.as_str() == "sepia" {
        style = &css.sepia;
    } else if vm.as_str() == "light" {
        style = &css.light;
    }

    let pft = settings.get_string("preview-font-type").unwrap();
    if pft.as_str() == "serif" {
        font = &css.serif;
    } else if pft.as_str() == "sans" {
        font = &css.sans;
    } else if pft.as_str() == "mono" {
        font = &css.mono;
    }

    let ch = settings.get_boolean("center-headers");
    if ch == true {
        cheader = (&css.center).to_string();
    }

    let mut options = Options::empty();
    options.insert(Options::ENABLE_STRIKETHROUGH);
    let parser = Parser::new_ext(&contents, options);

    let mut md = String::new();
    html::push_html(&mut md, parser);

    let html = format! ("
    <!doctype html>
    <html>
      <head>
          <meta charset=\"utf-8\">
          <style>{}<style>
          <style>{}{}</style>
      </head>
      <body>
          <div class=\"markdown-body\">
              {}
          </div>
      </body>
    </html>
    ", style,
       cheader,
       font,
       md);

    webview.load_html(&html, Some("file:///"));
}
