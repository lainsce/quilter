// Useful macros
macro_rules! get_widget {
    ($builder:expr, $wtype:ty, $name:ident) => {
        let $name: $wtype = $builder
            .get_object(stringify!($name))
            .expect(&format!("Could not find widget \"{}\"", stringify!($name)));
    };
}

macro_rules! action {
    ($actions_group:expr, $name:expr, $callback:expr) => {
        let simple_action = gio::SimpleAction::new($name, None);
        simple_action.connect_activate($callback);
        $actions_group.add_action(&simple_action);
    };
}

