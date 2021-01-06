extern crate sourceview4;
extern crate foreach;

use crate::config::{APP_ID, PROFILE};
use crate::components::window_state;
use crate::components::css::CSS;
use crate::components::header::Header;
use crate::components::sidebar::Sidebar;
use crate::components::searchbar::Searchbar;
use crate::components::listboxrow::ListBoxRow;
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
use gio::ActionMapExt;
use gio::ApplicationExt;
use gio::prelude::ApplicationExtManual;
use gtk::RevealerExt;
use gtk::WidgetExt;
use webkit2gtk::WebViewExt as WebSettings;
use webkit2gtk::SettingsExt as _;
use libhandy::LeafletExt;
use libhandy::HeaderBarExt;
use libhandy::ExpanderRowExt;
use std::env;
use std::time::{Duration, Instant};

pub struct Window {
    pub app: gtk::Application,
    pub widget: libhandy::ApplicationWindow,
    pub settings: gio::Settings,
    pub header:  Header,
    pub sidebar:  Sidebar,
    pub searchbar: Searchbar,
    pub lbr: ListBoxRow,
    pub main: gtk::Stack,
    pub sc: gtk::Overlay,
    pub sc1: gtk::ScrolledWindow,
    pub half_stack: gtk::Grid,
    pub full_stack: gtk::Stack,
    pub view: sourceview4::View,
    pub webview: webkit2gtk::WebView,
    pub prefs_win: PreferencesWindow,
    pub statusbar: gtk::Revealer,
    pub focus_bar: gtk::Revealer,
}

impl Window {
    pub fn new() -> Window {
        gtk::Settings::get_default().unwrap().set_property_gtk_theme_name(Some("io.elementary.stylesheet.blueberry"));
        gtk::Settings::get_default().unwrap().set_property_gtk_icon_theme_name(Some("elementary"));
        gtk::Settings::get_default().unwrap().set_property_gtk_font_name(Some("Inter 9"));

        let settings = gio::Settings::new(APP_ID);
        let header = Header::new();
        let sidebar = Sidebar::new();
        let searchbar = Searchbar::new();
        let lbr = ListBoxRow::new();
        let prefs_win = PreferencesWindow::new();
        let app = gtk::Application::new(Some(APP_ID), gio::ApplicationFlags::FLAGS_NONE).unwrap();

        let builder = gtk::Builder::from_resource("/com/github/lainsce/quilter/window.ui");
        get_widget!(builder, libhandy::ApplicationWindow, win);

        win.set_application(Some(&app));
        app.add_window(&win);
        win.show_all();

        win.connect_delete_event(move |_, _| {
            main_quit();
            Inhibit(false)
        });

        let builder2 = gtk::Builder::from_resource("/com/github/lainsce/quilter/main_view.ui");
        get_widget!(builder2, gtk::Overlay, over);
        over.set_visible (true);

        get_widget!(builder2, gtk::Stack, main);
        main.set_visible (true);

        get_widget!(builder2, gtk::Overlay, sc);
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

        get_widget!(builder2, gtk::Revealer, statusbar);
        statusbar.set_visible (true);

        get_widget!(builder2, gtk::Revealer, focus_bar);

        get_widget!(builder2, gtk::Button, focus);

        focus.connect_clicked(glib::clone!(@strong settings => move |_| {
            let fm = settings.get_boolean("focus-mode");
            if !fm {
                settings.set_boolean("focus-mode", true).expect ("Oops!");
            } else {
                settings.set_boolean("focus-mode", false).expect ("Oops!");
            }
        }));

        get_widget!(builder2, gtk::MenuButton, bar);
        bar.get_style_context().add_class("quilter-menu");
        bar.set_visible (true);

        get_widget!(builder2, gtk::RadioButton, words);
        get_widget!(builder2, gtk::RadioButton, lines);
        get_widget!(builder2, gtk::RadioButton, reading_time);
        get_widget!(builder2, gtk::Label, type_label);

        let tt = settings.get_string("track-type").unwrap();
        if tt.as_str() == "words" {
            words.set_active (true);
        } else if tt.as_str() == "lines" {
            lines.set_active (true);
        } else if tt.as_str() == "rtc" {
            reading_time.set_active (true);
        }

        if settings.get_boolean("sidebar"){
            sidebar.container.set_reveal_child(true);
        } else {
            sidebar.container.set_reveal_child(false);
        }

        if settings.get_boolean("statusbar") {
            statusbar.set_reveal_child(true);
        } else {
            statusbar.set_reveal_child(false);
        }

        if settings.get_boolean("searchbar") {
            searchbar.container.set_search_mode(true);
        } else {
            searchbar.container.set_search_mode(false);
        }

        words.connect_toggled(glib::clone!(@strong settings, @weak type_label, @weak view => move |_| {
            let (start, end) = view.get_buffer ().unwrap ().get_bounds();
            let words = view.get_buffer ().unwrap ().get_text (&start, &end, false).unwrap ().split_whitespace().count();

            type_label.set_text (&format!("Words: {}", &words));
            settings.set_string("track-type", "words").unwrap();
        }));

        lines.connect_toggled(glib::clone!(@strong settings, @weak type_label, @weak view => move |_| {
            let lines = view.get_buffer ().unwrap ().get_line_count();

            type_label.set_text (&format!("Lines: {}", &lines));
            settings.set_string("track-type", "lines").unwrap();
        }));

        reading_time.connect_toggled(glib::clone!(@strong settings, @weak type_label, @weak view => move |_| {
            let (start, end) = view.get_buffer ().unwrap ().get_bounds();
            let rt = (view.get_buffer ().unwrap ().get_text (&start, &end, false).unwrap ().split_whitespace().count()) / 200;
            let rt_min = rt;

            type_label.set_text (&format!("Reading Time: {:.8}min", &rt_min));
            settings.set_string("track-type", "rtc").unwrap();
        }));

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

            view.get_buffer ().unwrap ().set_text(&contents);

            lbr.title.set_label (&crop_letters(&mut last_file.to_string(), 22).as_str());
            lbr.subtitle.set_label ("");

            sidebar.files_list.add(&lbr.container);
            sidebar.files_list.select_row(Some(&lbr.container));
        }

        view.get_buffer ().unwrap ().connect_changed(glib::clone!(@strong settings, @weak view, @weak webview => move |_| {
            reload_func (&view, &webview);

            glib::timeout_add_local(3500, glib::clone!(@strong settings, @weak view => @default-return glib::Continue(false), move || {
                let last_file = settings.get_string("current-file").unwrap();
                let filename = last_file.as_str();
                let (start, end) = view.get_buffer ().unwrap ().get_bounds();
                let contents = view.get_buffer ().unwrap ().get_text(&start, &end, true);
                glib::file_set_contents(filename, contents.unwrap().as_bytes()).expect("Unable to write data");
                glib::Continue(false)
            }));
        }));

        let md_lang = sourceview4::LanguageManager::get_default().and_then(|lm| lm.get_language("markdown"));
        
        if let Some(md_lang) = md_lang {
            buffer.set_highlight_matching_brackets(true);
            buffer.set_language(Some(&md_lang));
            buffer.set_highlight_syntax(true);
        }
        

        let eadj = view.get_vadjustment ().unwrap();
        eadj.connect_property_value_notify(glib::clone!(@weak view, @weak webview  => move |_| {
            let vap: gtk::Adjustment = view.get_vadjustment ().unwrap();
            let upper = vap.get_upper();
            let valued = vap.get_value();
            let scroll_value = valued/upper;
            set_scrvalue(&webview, scroll_value);
        }));

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
        let lstylem = sourceview4::StyleSchemeManager::get_default().and_then(|sm| sm.get_scheme ("quilter"));
        let dstylem = sourceview4::StyleSchemeManager::get_default().and_then(|sm| sm.get_scheme ("quilter-dark"));
        let sstylem = sourceview4::StyleSchemeManager::get_default().and_then(|sm| sm.get_scheme ("quilter-sepia"));
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
                                                @weak statusbar,
                                                @weak focus_bar as fb,
                                                @weak searchbar.container as sbc,
                                                @weak header.container as hc,
                                                @weak header.search_button as hsb,
                                                @weak sidebar.container as sdb,
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
                                                @weak prefs_win.large2 as pwl2,
                                                @weak prefs_win.sb as sb,
                                                @weak prefs_win.sdbs as sdbs,
                                                @weak prefs_win.ftype as ft,
                                                @weak prefs_win.focus_mode as fm,
                                                @weak type_label as tl,
                                                @weak words as w,
                                                @weak lines as l,
                                                @weak reading_time as rtc
                                                => move |settings, _| {
            let vm = settings.get_string("visual-mode").unwrap();
            let lstylem = sourceview4::StyleSchemeManager::get_default().and_then(|sm| sm.get_scheme ("quilter"));
            let dstylem = sourceview4::StyleSchemeManager::get_default().and_then(|sm| sm.get_scheme ("quilter-dark"));
            let sstylem = sourceview4::StyleSchemeManager::get_default().and_then(|sm| sm.get_scheme ("quilter-sepia"));
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

            reload_func(&view, &webview);

            if sb.get_active() {
                statusbar.set_reveal_child(true);
            } else {
                statusbar.set_reveal_child(false);
            }

            if sdbs.get_active() {
                sdb.set_reveal_child(true);
                hc.set_decoration_layout (Some(&":maximize"));
            } else {
                sdb.set_reveal_child(false);
                hc.set_decoration_layout (Some(&"close:maximize"));
            }

            let sm = settings.get_boolean("sidebar");
            let st = settings.get_boolean("statusbar");
            if fm.get_expanded() {
                fb.set_reveal_child(true);
                hc.set_visible (false);
                sdb.set_reveal_child(false);
                statusbar.set_reveal_child(false);
            } else {
                fb.set_reveal_child(false);
                hc.set_visible (true);
                sdb.set_reveal_child(sm);
                statusbar.set_reveal_child(st);
            }

            hsb.connect_toggled(glib::clone!(@weak sbc, @weak hsb => move |_| {
                if hsb.get_active() {
                    sbc.set_search_mode(true);
                } else {
                    sbc.set_search_mode(false);
                }
            }));

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

            let width = settings.get_int("window-width") as f32;
            pws1.connect_toggled(glib::clone!(@weak view => move |_| {
                let m = (width * (1.0 / 100.0)) as i32;
                view.set_left_margin (m);
                view.set_right_margin (m);
            }));

            pwm1.connect_toggled(glib::clone!(@weak view => move |_| {
                let m = (width * (8.0 / 100.0)) as i32;
                view.set_left_margin (m);
                view.set_right_margin (m);
            }));

            pwl1.connect_toggled(glib::clone!(@weak view => move |_| {
                let m = (width * (16.0 / 100.0)) as i32;
                view.set_left_margin (m);
                view.set_right_margin (m);
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

            ft.connect_changed (glib::clone!(@strong settings, @weak ft, @weak view => move |_| {
                if ft.get_active() == Some(0) {
                    view.get_style_context().add_class("mono-font");
                    view.get_style_context().remove_class("zwei-font");
                    view.get_style_context().remove_class("vier-font");
                } else if ft.get_active() == Some(1) {
                    view.get_style_context().add_class("zwei-font");
                    view.get_style_context().remove_class("mono-font");
                    view.get_style_context().remove_class("vier-font");
                } else if ft.get_active() == Some(2) {
                    view.get_style_context().add_class("vier-font");
                    view.get_style_context().remove_class("zwei-font");
                    view.get_style_context().remove_class("mono-font");
                }
            }));

            let tt = settings.get_string("track-type").unwrap();
            if tt.as_str() == "words" {
                let (start, end) = view.get_buffer ().unwrap ().get_bounds();
                let words = view.get_buffer ().unwrap ().get_text (&start, &end, false).unwrap ().split_whitespace().count();

                tl.set_text (&format!("Words: {}", &words));
            } else if tt.as_str() == "lines" {
                let lines = view.get_buffer ().unwrap ().get_line_count();

                tl.set_text (&format!("Lines: {}", &lines));
            } else if tt.as_str() == "rtc" {
                let (start, end) = view.get_buffer ().unwrap ().get_bounds();
                let rt = view.get_buffer ().unwrap ().get_text (&start, &end, false).unwrap ().split_whitespace().count();
                let rt_min = rt / 200;

                type_label.set_text (&format!("Reading Time: {:.8}min", &rt_min));
            }
        }));

        //
        //
        //
        // Preferences Window
        //
        //
        //

        let pft = settings.get_string("preview-font-type").unwrap();
        let fft = settings.get_string("edit-font-type").unwrap();

        settings.bind ("statusbar", &prefs_win.sb, "active", gio::SettingsBindFlags::DEFAULT);
        settings.bind ("sidebar", &prefs_win.sdbs, "active", gio::SettingsBindFlags::DEFAULT);

        settings.bind ("focus-mode", &prefs_win.focus_mode, "enable_expansion", gio::SettingsBindFlags::DEFAULT);
        settings.bind ("focus-mode", &prefs_win.focus_mode, "expanded", gio::SettingsBindFlags::DEFAULT);

        prefs_win.sb.bind_property (
            "active",
            &statusbar,
            "search-mode"
        );

        if vm.as_str() == "light" {
            prefs_win.light.set_active (true);
        } else if vm.as_str() == "dark" {
            prefs_win.dark.set_active (true);
        } else if vm.as_str() == "sepia" {
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
        }

        prefs_win.ptype.connect_changed (glib::clone!(@strong settings, @weak prefs_win.ptype as pw => move |_| {
            if pw.get_active() == Some(1) {
                settings.set_string("preview-font-type", "serif").expect ("Oops!");
            } else if pw.get_active() == Some(0) {
                settings.set_string("preview-font-type", "sans").expect ("Oops!");
            } else if pw.get_active() == Some(2) {
                settings.set_string("preview-font-type", "mono").expect ("Oops!");
            }
        }));

        if fft.as_str() == "vier" {
            prefs_win.ftype.set_active(Some(2));
        } else if fft.as_str() == "mono" {
            prefs_win.ftype.set_active(Some(0));
        } else if fft.as_str() == "zwei" {
            prefs_win.ptype.set_active(Some(1));
        }

        prefs_win.ftype.connect_changed (glib::clone!(@strong settings, @weak prefs_win.ftype as fw => move |_| {
            if fw.get_active() == Some(0) {
                settings.set_string("edit-font-type", "mono").expect ("Oops!");
            } else if fw.get_active() == Some(1) {
                settings.set_string("edit-font-type", "zwei").expect ("Oops!");
            } else if fw.get_active() == Some(2) {
                settings.set_string("edit-font-type", "vier").expect ("Oops!");
            }
        }));

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

        if prefs_win.small.get_active () {
            settings.set_int("spacing", 2).expect ("Oops!");
        } else if prefs_win.medium.get_active () {
            settings.set_int("spacing", 4).expect ("Oops!");
        } else if prefs_win.large.get_active() {
            settings.set_int("spacing", 8).expect ("Oops!");
        } else {
            settings.set_int("spacing", 4).expect ("Oops!");
        }

        let width = settings.get_int("window-width") as f32;
        if settings.get_int("margins") == 1 {
            prefs_win.small1.set_active (true);
        } else if settings.get_int("margins") == 8 {
            prefs_win.medium1.set_active (true);
        } else if settings.get_int("margins") == 16 {
            prefs_win.large1.set_active (true);
        } else {
            prefs_win.medium1.set_active (true);
        }

        if prefs_win.small1.get_active () {
            let m = (width * (1.0 / 100.0)) as i32;
            settings.set_int("margins", m).expect ("Oops!");
            view.set_left_margin (m);
            view.set_right_margin (m);
        } else if prefs_win.medium1.get_active () {
            let m = (width * (8.0 / 100.0)) as i32;
            settings.set_int("margins", m).expect ("Oops!");
            view.set_left_margin (m);
            view.set_right_margin (m);
        } else if prefs_win.large1.get_active() {
            let m = (width * (16.0 / 100.0)) as i32;
            settings.set_int("margins", m).expect ("Oops!");
            view.set_left_margin (m);
            view.set_right_margin (m);
        } else {
            let m = (width * (8.0 / 100.0)) as i32;
            settings.set_int("margins", m).expect ("Oops!");
            view.set_left_margin (m);
            view.set_right_margin (m);
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

        if prefs_win.small2.get_active () {
            settings.set_int("font-sizing", 1).expect ("Oops!");
        } else if prefs_win.medium2.get_active () {
            settings.set_int("font-sizing", 2).expect ("Oops!");
        } else if prefs_win.large2.get_active() {
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

                    view.get_buffer ().unwrap ().set_text(&contents);
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
                    let (start, end) = view.get_buffer ().unwrap ().get_bounds();
                    let contents = view.get_buffer ().unwrap ().get_text(&start, &end, true);
                    
                    glib::file_set_contents(filename, contents.unwrap().as_bytes()).expect("Unable to write data");
                }
                file_chooser.close();
            }));

            file_chooser.show_all();
        }));
        
        header.new_button.connect_clicked(glib::clone!(@weak view => move |_| {
            view.get_buffer ().unwrap ().set_text("");
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

        let sgrid = gtk::Grid::new();
        sgrid.set_orientation(gtk::Orientation::Vertical);
        sgrid.attach (&sidebar.container, 0, 0, 1, 1);
        sgrid.show_all ();

        let grid = gtk::Grid::new();
        grid.set_hexpand(true);
        grid.set_orientation(gtk::Orientation::Vertical);
        grid.attach (&header.container, 0, 0, 1, 1);
        grid.attach (&searchbar.container, 0, 1, 1, 1);
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

        leaflet.connect_property_folded_notify (glib::clone!(@weak leaflet, @weak header.container as hcs, @weak sidebar.sideheader as sbcs => move |_| {
            if leaflet.get_folded() {
                hcs.set_decoration_layout (Some(&":"));
                sbcs.set_decoration_layout (Some(&":"));
            } else {
                hcs.set_decoration_layout (Some(&":maximize"));
                sbcs.set_decoration_layout (Some(&"close:"));
            }
        }));

        let mgrid = gtk::Grid::new ();
        mgrid.set_orientation(gtk::Orientation::Vertical);
        mgrid.attach (&leaflet,0,0,1,1);
        mgrid.show_all ();

        win.add(&mgrid);
        win.set_size_request(600, 350);
        win.set_icon_name(Some(APP_ID));

        let def = gtk::IconTheme::get_default ();
        gtk::IconTheme::add_resource_path(&def.unwrap(), "/com/github/lainsce/quilter/");

        let window_widget = Window {
            app,
            widget: win,
            settings,
            header,
            sidebar,
            searchbar,
            lbr,
            main,
            sc,
            sc1,
            half_stack,
            full_stack,
            view,
            webview,
            prefs_win,
            statusbar,
            focus_bar,
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

    fn setup_actions(&self) {
        action!(
            self.widget,
            "prefs",
            glib::clone!(@weak self.widget as widget, @weak self.prefs_win.prefsw as pw  => move |_, _| {
                pw.set_transient_for(Some(&widget));
                pw.show();
            })
        );

        action!(
            self.widget,
            "toggle_view",
            glib::clone!(@weak self.full_stack as fs, @weak self.view as editor, @weak self.webview as preview, @weak self.sc as a, @weak self.sc1 as b => move |_, _| {
                let key: glib::GString = "editor".into();
                if fs.get_visible_child_name() == Some(key) {
                    fs.set_visible_child(&b);
                } else {
                    fs.set_visible_child(&a);
                    reload_func(&editor, &preview);
                }
            })
        );

        action!(
            self.widget,
            "focus_mode",
            glib::clone!(@strong self.settings as settings => move |_, _| {
                let fm = settings.get_boolean("focus-mode");
                if !fm {
                    settings.set_boolean("focus-mode", true).expect ("Oops!");
                } else {
                    settings.set_boolean("focus-mode", false).expect ("Oops!");
                }
            })
        );

        // Quit
        action!(
            self.widget,
            "quit",
            glib::clone!(@strong self.app as app => move |_, _| {
                app.quit();
            })
        );
        self.app.set_accels_for_action("win.quit", &["<primary>q"]);
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

    pub fn run(&self) {
        let args: Vec<String> = env::args().collect();
        self.app.run(&args);
    }
}

//
//
//
// Misc. Functions Block
//
//
//

fn change_layout (main: &gtk::Stack, full_stack: &gtk::Stack, half_stack: &gtk::Grid, sc: &gtk::Overlay, sc1: &gtk::ScrolledWindow,) {
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
    let render;
    let stringhl;
    let mut cheader;
    cheader = "".to_string();
    let mut highlight = "".to_string();

    let settings = gio::Settings::new(APP_ID);
    let vm = settings.get_string("visual-mode").unwrap();
    if vm.as_str() == "dark" {
        style = &css.dark;
        highlight = glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/highlight.js/styles/dark.min.css";
    } else if vm.as_str() == "sepia" {
        style = &css.sepia;
        highlight = glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/highlight.js/styles/sepia.min.css";
    } else if vm.as_str() == "light" {
        style = &css.light;
        highlight = glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/highlight.js/styles/light.min.css";
    }

    // Highlight.js
    render = glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/highlight.js/lib/highlight.min.js";
    stringhl = format! ("
        <link rel=\"stylesheet\" href=\"{}\">
        <script defer src=\"{}\" onload=\"hljs.initHighlightingOnLoad();\"></script>
    ", highlight, render);

    // LaTeX (Katex)
    let renderl;
    let stringtex;
    let katexmain;
    let katexjs;
    katexmain = glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/katex/katex.css";
    katexjs = glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/katex/katex.js";
    renderl = glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/katex/render.js";
    stringtex = format!( "
                    <link rel=\"stylesheet\" href=\"{}\">
                    <script defer src=\"{}\"></script>
                    <script defer src=\"{}\" onload=\"renderMathInElement(document.body);\"></script>
                ",  katexmain, katexjs, renderl);

    let pft = settings.get_string("preview-font-type").unwrap();
    if pft.as_str() == "serif" {
        font = &css.serif;
    } else if pft.as_str() == "sans" {
        font = &css.sans;
    } else if pft.as_str() == "mono" {
        font = &css.mono;
    }

    if settings.get_boolean("center-headers") {
        cheader = (&css.center).to_string();
    }

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
          <style>{}{}{}</style>
          {}
          {}
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
       stringhl,
       stringtex,
       md);

    webview.load_html(&html, Some("file:///"));
}

fn set_scrvalue (webview: &webkit2gtk::WebView, scroll_value: f64) {
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
            e.scrollTop = ({:?} * e.offsetHeight);
            e.scrollTop;
        ", scroll_value).as_str(),
         Some(&cl),
         move |v| {
            let jsg = webkit2gtk::JavascriptResult::get_global_context(&v.clone ().unwrap());
            webkit2gtk::JavascriptResult::get_value(&v.as_ref ().unwrap()).unwrap().to_number(&jsg.unwrap()).unwrap();
         }
    );
}

fn crop_letters(s: &mut str, pos: usize) -> String {
    let mut z = s.to_string ();
    match z.char_indices().nth(pos) {
        Some((pos, _)) => {
            z.drain(..pos);
        }
        None => {
            z.clear();
        }
    }
    z
}
