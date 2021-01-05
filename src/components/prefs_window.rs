use gtk::prelude::BuilderExtManual;
use gtk::*;

pub struct PreferencesWindow {
    pub prefs: libhandy::PreferencesWindow,
    pub ftype: gtk::ComboBoxText,
    pub ptype: gtk::ComboBoxText,
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
}

impl PreferencesWindow {
    pub fn new() -> PreferencesWindow {
        let builder = gtk::Builder::from_resource("/com/github/lainsce/quilter/prefs_window.ui");
        get_widget!(builder, libhandy::PreferencesWindow, prefs);

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

        PreferencesWindow {
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
        }
    }
}
