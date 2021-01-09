use gio::prelude::*;

use crate::config;
use crate::settings::Key;
use log::error;

pub struct SettingsManager {}

impl SettingsManager {
    pub fn get_settings() -> gio::Settings {
        let app_id = config::APP_ID;
        gio::Settings::new(app_id)
    }

    pub fn bind_property<P: IsA<glib::Object>>(key: Key, object: &P, property: &str) {
        let settings = Self::get_settings();
        settings.bind(key.to_string().as_str(), object, property, gio::SettingsBindFlags::DEFAULT);
    }

    pub fn get_string(key: Key) -> String {
        let settings = Self::get_settings();
        settings.get_string(&key.to_string()).unwrap().to_string()
    }

    pub fn set_string(key: Key, value: String) {
        let settings = Self::get_settings();
        if let Err(err) = settings.set_string(&key.to_string(), &value) {
            error!("Failed to save {} setting due to {}", key.to_string(), err);
        }
    }

    pub fn get_boolean(key: Key) -> bool {
        let settings = Self::get_settings();
        settings.get_boolean(&key.to_string())
    }

    pub fn set_boolean(key: Key, value: bool) {
        let settings = Self::get_settings();
        if let Err(err) = settings.set_boolean(&key.to_string(), value) {
            error!("Failed to save {} setting due to {}", key.to_string(), err);
        }
    }

    pub fn get_integer(key: Key) -> i32 {
        let settings = Self::get_settings();
        settings.get_int(&key.to_string())
    }

    pub fn set_integer(key: Key, value: i32) {
        let settings = Self::get_settings();
        if let Err(err) = settings.set_int(&key.to_string(), value) {
            error!("Failed to save {} setting due to {}", key.to_string(), err);
        }
    }
}

