use gtk::prelude::BuilderExtManual;
use gtk::*;
use gtk::WidgetExt;
use gtk::prelude::ComboBoxExtManual;
use crate::settings::{Key, SettingsManager};

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
    pub stype: gtk::ComboBoxText,
    pub mtype: gtk::ComboBoxText,
    pub ztype: gtk::ComboBoxText,
    pub focus_mode: libhandy::ExpanderRow,
    pub focus_scope: gtk::Switch,
    pub autosave: libhandy::ExpanderRow,
    pub delay: gtk::SpinButton,
}

impl PreferencesWindow {
    pub fn new(parent: &libhandy::ApplicationWindow) -> PreferencesWindow {
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

        get_widget!(builder, gtk::Switch, focus_scope);
        focus_scope.set_visible(true);

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

        get_widget!(builder, gtk::Switch, pos);
        pos.set_visible(true);

        //
        // Text Spacing
        //
        get_widget!(builder, gtk::ComboBoxText, stype);
        stype.set_visible(true);

        //
        // Text Margins
        //
        get_widget!(builder, gtk::ComboBoxText, mtype);
        mtype.set_visible(true);

        //
        // Font Type
        //

        get_widget!(builder, gtk::ComboBoxText, ftype);
        ftype.set_visible(true);

        //
        // Font Size
        //
        get_widget!(builder, gtk::ComboBoxText, ztype);
        ztype.set_visible(true);

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
        let ts = SettingsManager::get_integer(Key::Spacing);
        let tm = SettingsManager::get_integer(Key::Margins);
        let tx = SettingsManager::get_integer(Key::FontSizing);
        let vm = SettingsManager::get_string(Key::VisualMode);
        let fft = SettingsManager::get_string(Key::EditFontType);
        let pft = SettingsManager::get_string(Key::PreviewFontType);

        SettingsManager::bind_property(Key::Statusbar, &sb, "active");
        SettingsManager::bind_property(Key::Sidebar, &sdbs, "active");
        SettingsManager::bind_property(Key::FocusMode, &focus_mode, "enable_expansion");
        SettingsManager::bind_property(Key::FocusMode, &focus_mode, "expanded");
        SettingsManager::bind_property(Key::Autosave, &focus_mode, "enable_expansion");
        SettingsManager::bind_property(Key::Autosave, &focus_mode, "expanded");
        SettingsManager::bind_property(Key::AutosaveDelay, &delay, "value");
        SettingsManager::bind_property(Key::FocusModeType, &focus_scope, "active");
        SettingsManager::bind_property(Key::TypewriterScrolling, &typewriter, "active");
        SettingsManager::bind_property(Key::Pos, &pos, "active");
        SettingsManager::bind_property(Key::CenterHeaders, &centering, "active");
        SettingsManager::bind_property(Key::Highlight, &highlight, "active");
        SettingsManager::bind_property(Key::Latex, &latex, "active");
        SettingsManager::bind_property(Key::Mermaid, &mermaid, "active");


        if vm.as_str() == "light" {
            light.set_active (true);
        } else if vm.as_str() == "dark" {
            dark.set_active (true);
        } else if vm.as_str() == "sepia" {
            sepia.set_active (true);
        }

        if ts == 1 {
            stype.set_active(Some(0));
        } else if ts == 4 {
            stype.set_active(Some(1));
        } else if ts == 8 {
            stype.set_active(Some(2));
        }

        stype.connect_changed (glib::clone!(@weak stype as sw => move |_| {
            if sw.get_active() == Some(0) {
                SettingsManager::set_integer(Key::Spacing, 1);
            } else if sw.get_active() == Some(1) {
                SettingsManager::set_integer(Key::Spacing, 4);
            } else if sw.get_active() == Some(2) {
                SettingsManager::set_integer(Key::Spacing, 8);
            }
        }));

        if tm == 1 {
            mtype.set_active(Some(0));
        } else if tm == 8 {
            mtype.set_active(Some(1));
        } else if tm == 16 {
            mtype.set_active(Some(2));
        }

        mtype.connect_changed (glib::clone!(@weak mtype as mw => move |_| {
            if mw.get_active() == Some(0) {
                SettingsManager::set_integer(Key::Margins, 1);
            } else if mw.get_active() == Some(1) {
                SettingsManager::set_integer(Key::Margins, 8);
            } else if mw.get_active() == Some(2) {
                SettingsManager::set_integer(Key::Margins, 16);
            }
        }));

        if tx == 0 {
            ztype.set_active(Some(0));
        } else if tx == 1 {
            ztype.set_active(Some(1));
        } else if tx == 2 {
            ztype.set_active(Some(2))
        }

        ztype.connect_changed (glib::clone!(@weak ztype as zw => move |_| {
            if zw.get_active() == Some(0) {
                SettingsManager::set_integer(Key::FontSizing, 0);
            } else if zw.get_active() == Some(1) {
                SettingsManager::set_integer(Key::FontSizing, 1);
            } else if zw.get_active() == Some(2) {
                SettingsManager::set_integer(Key::FontSizing, 2);
            }
        }));

        light.connect_toggled(glib::clone!(@weak ztype as zw => move |_| {
            SettingsManager::set_string(Key::VisualMode, "light".to_string());
        }));

        dark.connect_toggled(glib::clone!(@weak ztype as zw => move |_| {
            SettingsManager::set_string(Key::VisualMode, "dark".to_string());
        }));

        sepia.connect_toggled(glib::clone!(@weak ztype as zw => move |_| {
            SettingsManager::set_string(Key::VisualMode, "sepia".to_string());
        }));

        if pft.as_str() == "mono" {
            ptype.set_active(Some(2));
        } else if pft.as_str() == "sans" {
            ptype.set_active(Some(0));
        } else if pft.as_str() == "serif" {
            ptype.set_active(Some(1));
        }

        ptype.connect_changed (glib::clone!(@weak ptype as pw => move |_| {
            if pw.get_active() == Some(1) {
                SettingsManager::set_string(Key::PreviewFontType, "serif".to_string());
            } else if pw.get_active() == Some(0) {
                SettingsManager::set_string(Key::PreviewFontType, "sans".to_string());
            } else if pw.get_active() == Some(2) {
                SettingsManager::set_string(Key::PreviewFontType, "mono".to_string());
            }
        }));

        if fft.as_str() == "vier" {
            ftype.set_active(Some(2));
        } else if fft.as_str() == "mono" {
            ftype.set_active(Some(0));
        } else if fft.as_str() == "zwei" {
            ptype.set_active(Some(1));
        }

        ftype.connect_changed (glib::clone!(@weak ftype as fw => move |_| {
            if fw.get_active() == Some(0) {
                SettingsManager::set_string(Key::EditFontType, "mono".to_string());
            } else if fw.get_active() == Some(1) {
                SettingsManager::set_string(Key::EditFontType, "zwei".to_string());
            } else if fw.get_active() == Some(2) {
                SettingsManager::set_string(Key::EditFontType, "vier".to_string());
            }
        }));

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
            stype,
            mtype,
            ztype,
            focus_mode,
            focus_scope,
            autosave,
            delay,
            typewriter
        };

        prefswin
    }
}
