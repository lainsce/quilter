use gtk::prelude::BuilderExtManual;
use gtk::*;
use gio::{Settings, SettingsExt};
use gtk::WidgetExt;
use glib::ObjectExt;
use gtk::prelude::ComboBoxExtManual;

pub struct PreferencesWindow {
    pub prefs: libhandy::PreferencesWindow,
    pub ftype: gtk::ComboBoxText,
    pub ptype: gtk::ComboBoxText,
    pub typewriter: gtk::Switch,
    pub sb: gtk::Switch,
    pub sdbs: gtk::Switch,
    pub centering: gtk::Switch,
    pub highlight: gtk::Switch,
    pub latex: gtk::Switch,
    pub mermaid: gtk::Switch,
    pub light: gtk::RadioButton,
    pub sepia: gtk::RadioButton,
    pub dark: gtk::RadioButton,
    pub small: gtk::RadioButton,
    pub medium: gtk::RadioButton,
    pub large: gtk::RadioButton,
    pub small1: gtk::RadioButton,
    pub medium1: gtk::RadioButton,
    pub large1: gtk::RadioButton,
    pub small2: gtk::RadioButton,
    pub medium2: gtk::RadioButton,
    pub large2: gtk::RadioButton,
    pub focus_mode: libhandy::ExpanderRow,
    pub autosave: libhandy::ExpanderRow,
    pub delay: gtk::SpinButton,
}

impl PreferencesWindow {
    pub fn new(parent: &libhandy::ApplicationWindow, gschema: &Settings) -> PreferencesWindow {
        let builder = gtk::Builder::from_resource("/com/github/lainsce/quilter/prefs_window.ui");
        get_widget!(builder, libhandy::PreferencesWindow, prefs);
        prefs.set_modal (false);
        prefs.set_transient_for(Some(parent));
        prefs.show_all();

        //
        //
        // General Page
        //
        //

        //
        // Visual Style
        //
        get_widget!(builder, gtk::RadioButton, light);
        get_widget!(builder, gtk::RadioButton, sepia);
        get_widget!(builder, gtk::RadioButton, dark);
        light.set_visible(true);
        sepia.set_visible(true);
        dark.set_visible(true);

        //
        // Interface
        //

        get_widget!(builder, libhandy::ExpanderRow, focus_mode);
        focus_mode.set_visible(true);

        get_widget!(builder, gtk::Switch, typewriter);
        typewriter.set_visible(true);

        get_widget!(builder, gtk::Switch, sb);
        sb.set_visible(true);

        get_widget!(builder, gtk::Switch, sdbs);
        sdbs.set_visible(true);

        //
        //
        // Editor Page
        //
        //

        //
        // Autosave
        //
        get_widget!(builder, libhandy::ExpanderRow, autosave);
        autosave.set_visible(true);
        get_widget!(builder, gtk::SpinButton, delay);
        delay.set_visible(true);

        //
        // Text Spacing
        //
        get_widget!(builder, gtk::RadioButton, small);
        get_widget!(builder, gtk::RadioButton, medium);
        get_widget!(builder, gtk::RadioButton, large);
        small.set_visible(true);
        medium.set_visible(true);
        large.set_visible(true);

        //
        // Text Margins
        //
        get_widget!(builder, gtk::RadioButton, small1);
        get_widget!(builder, gtk::RadioButton, medium1);
        get_widget!(builder, gtk::RadioButton, large1);
        small1.set_visible(true);
        medium1.set_visible(true);
        large1.set_visible(true);

        //
        // Font Type
        //

        get_widget!(builder, gtk::ComboBoxText, ftype);
        ftype.set_visible(true);

        //
        // Font Size
        //
        get_widget!(builder, gtk::RadioButton, small2);
        get_widget!(builder, gtk::RadioButton, medium2);
        get_widget!(builder, gtk::RadioButton, large2);
        small2.set_visible(true);
        medium2.set_visible(true);
        large2.set_visible(true);

        //
        //
        // Preview Page
        //
        //

        get_widget!(builder, gtk::ComboBoxText, ptype);
        ptype.set_visible(true);
        get_widget!(builder, gtk::Switch, centering);
        centering.set_visible(true);

        get_widget!(builder, gtk::Switch, highlight);
        highlight.set_visible(true);
        get_widget!(builder, gtk::Switch, latex);
        latex.set_visible(true);
        get_widget!(builder, gtk::Switch, mermaid);
        mermaid.set_visible(true);

        //
        //
        // gschema Binds
        //
        //

        let vm = gschema.get_string("visual-mode").unwrap();
        let ts = gschema.get_int("spacing");
        let tm = gschema.get_int("margins");
        let tx = gschema.get_int("font-sizing");

        gschema.bind ("statusbar", &sb, "active", gio::SettingsBindFlags::DEFAULT);
        gschema.bind ("sidebar", &sdbs, "active", gio::SettingsBindFlags::DEFAULT);
        gschema.bind ("focus-mode", &focus_mode, "enable_expansion", gio::SettingsBindFlags::DEFAULT);
        gschema.bind ("focus-mode", &focus_mode, "expanded", gio::SettingsBindFlags::DEFAULT);
        gschema.bind ("autosave", &autosave, "enable_expansion", gio::SettingsBindFlags::DEFAULT);
        gschema.bind ("autosave", &autosave, "expanded", gio::SettingsBindFlags::DEFAULT);
        gschema.bind ("autosave-delay", &delay, "value", gio::SettingsBindFlags::DEFAULT);
        gschema.bind ("typewriter-scrolling", &typewriter, "active", gio::SettingsBindFlags::DEFAULT);

        if vm.as_str() == "light" {
            light.set_active (true);
        } else if vm.as_str() == "dark" {
            dark.set_active (true);
        } else if vm.as_str() == "sepia" {
            sepia.set_active (true);
        }

        if ts == 1 {
            small.set_active (true);
        } else if ts == 4 {
            medium.set_active (true);
        } else if ts == 8 {
            large.set_active (true);
        } else {
            medium.set_active (true);
        }

        if small.get_active () {
            gschema.set_int("spacing", 1).expect ("Oops!");
        } else if medium.get_active () {
            gschema.set_int("spacing", 4).expect ("Oops!");
        } else if large.get_active() {
            gschema.set_int("spacing", 8).expect ("Oops!");
        } else {
            gschema.set_int("spacing", 4).expect ("Oops!");
        }

        if tm == 1 {
            small1.set_active (true);
        } else if tm == 8 {
            medium1.set_active (true);
        } else if tm == 16 {
            large1.set_active (true);
        } else {
            medium1.set_active (true);
        }

        if small1.get_active () {
            gschema.set_int("margins", 1).expect ("Oops!");
        } else if medium1.get_active () {
            gschema.set_int("margins", 8).expect ("Oops!");
        } else if large1.get_active() {
            gschema.set_int("margins", 16).expect ("Oops!");
        } else {
            gschema.set_int("margins", 8).expect ("Oops!");
        }

        if tx == 1 {
            small2.set_active (true);
        } else if tx == 2 {
            medium2.set_active (true);
        } else if tx == 3 {
            large2.set_active (true);
        } else {
            medium2.set_active (true);
        }

        if small2.get_active () {
            gschema.set_int("font-sizing", 1).expect ("Oops!");
        } else if medium2.get_active () {
            gschema.set_int("font-sizing", 2).expect ("Oops!");
        } else if large2.get_active() {
            gschema.set_int("font-sizing", 3).expect ("Oops!");
        } else {
            gschema.set_int("font-sizing", 2).expect ("Oops!");
        }

        light.connect_toggled(glib::clone!(@weak gschema as g => move |_| {
            g.set_string("visual-mode", "light").unwrap();
        }));

        dark.connect_toggled(glib::clone!(@weak gschema as g => move |_| {
            g.set_string("visual-mode", "dark").unwrap();
        }));

        sepia.connect_toggled(glib::clone!(@weak gschema as g => move |_| {
            g.set_string("visual-mode", "sepia").unwrap();
        }));

        let pft = gschema.get_string("preview-font-type").unwrap();
        let fft = gschema.get_string("edit-font-type").unwrap();

        if pft.as_str() == "mono" {
            ptype.set_active(Some(2));
        } else if pft.as_str() == "sans" {
            ptype.set_active(Some(0));
        } else if pft.as_str() == "serif" {
            ptype.set_active(Some(1));
        }

        ptype.connect_changed (glib::clone!(@strong gschema, @weak ptype as pw => move |_| {
            if pw.get_active() == Some(1) {
                gschema.set_string("preview-font-type", "serif").expect ("Oops!");
            } else if pw.get_active() == Some(0) {
                gschema.set_string("preview-font-type", "sans").expect ("Oops!");
            } else if pw.get_active() == Some(2) {
                gschema.set_string("preview-font-type", "mono").expect ("Oops!");
            }
        }));

        if fft.as_str() == "vier" {
            ftype.set_active(Some(2));
        } else if fft.as_str() == "mono" {
            ftype.set_active(Some(0));
        } else if fft.as_str() == "zwei" {
            ptype.set_active(Some(1));
        }

        ftype.connect_changed (glib::clone!(@strong gschema, @weak ftype as fw => move |_| {
            if fw.get_active() == Some(0) {
                gschema.set_string("edit-font-type", "mono").expect ("Oops!");
            } else if fw.get_active() == Some(1) {
                gschema.set_string("edit-font-type", "zwei").expect ("Oops!");
            } else if fw.get_active() == Some(2) {
                gschema.set_string("edit-font-type", "vier").expect ("Oops!");
            }
        }));

        gschema.bind ("center-headers", &centering, "active", gio::SettingsBindFlags::DEFAULT);
        gschema.bind ("highlight", &highlight, "active", gio::SettingsBindFlags::DEFAULT);
        gschema.bind ("latex", &latex, "active", gio::SettingsBindFlags::DEFAULT);
        gschema.bind ("mermaid", &mermaid, "active", gio::SettingsBindFlags::DEFAULT);

        mermaid.bind_property (
            "active",
            &highlight,
            "active"
        );

        let prefswin = PreferencesWindow {
            prefs,
            ftype,
            ptype,
            sb,
            sdbs,
            centering,
            highlight,
            latex,
            mermaid,
            light,
            sepia,
            dark,
            small,
            medium,
            large,
            small1,
            medium1,
            large1,
            small2,
            medium2,
            large2,
            focus_mode,
            autosave,
            delay,
            typewriter
        };

        prefswin
    }
}
