// Useful macros
macro_rules! action {
    ($actions_group:expr, $name:expr, $callback:expr) => {
        let simple_action = gio::SimpleAction::new($name, None);
        simple_action.connect_activate($callback);
        $actions_group.add_action(&simple_action);
    };
}

