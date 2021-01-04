use gtk::prelude::BuilderExtManual;

pub struct PreferencesWindow {
    pub prefs: libhandy::PreferencesWindow,
    pub centering: gtk::Switch,
}

impl PreferencesWindow {
    pub fn new() -> PreferencesWindow {
        let builder = gtk::Builder::from_resource("/com/github/lainsce/quilter/prefs_window.ui");
        get_widget!(builder, libhandy::PreferencesWindow, prefs);

        get_widget!(builder, gtk::Switch, centering);

        PreferencesWindow {
            prefs,
            centering,
        }
    }
}
