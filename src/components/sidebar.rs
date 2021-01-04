use gtk::*;

use libhandy::HeaderBarExt;
use libhandy::ViewSwitcherExt;

pub struct Sidebar {
    pub container: gtk::Grid,
    pub sideheader: libhandy::HeaderBar,
    pub stack: gtk::Stack,
    pub files_list: gtk::ListBox,
}

impl Sidebar {
    pub fn new() -> Sidebar {
        let sideheader = libhandy::HeaderBar::new();
        sideheader.set_show_close_button(true);
        sideheader.set_title(Some(""));
        sideheader.set_has_subtitle(false);
        sideheader.set_decoration_layout(Some("close:"));
        sideheader.set_size_request(200, 38);
        sideheader.get_style_context().add_class("quilter-toolbar");
        sideheader.get_style_context().add_class("quilter-toolbar-side");
        sideheader.get_style_context().add_class("flat");

        let placeholder = gtk::Label::new(Some("No Files"));
        placeholder.get_style_context().add_class("h2");
        placeholder.get_style_context().add_class("dim-label");
        placeholder.show_all ();

        let files_list = gtk::ListBox::new();
        files_list.set_size_request(200, -1);
        files_list.set_margin_top(6);
        files_list.set_margin_bottom(6);
        files_list.set_margin_start(12);
        files_list.set_margin_end(12);
        files_list.set_placeholder(Some(&placeholder));
        files_list.show_all ();

        let outline = gtk::TreeView::new();
        outline.show_all ();

        let stack = gtk::Stack::new();
        stack.set_vexpand(true);
        stack.add_named(&files_list, "files");
        stack.add_named(&outline, "outline");
        stack.set_visible_child(&files_list);
        stack.set_child_icon_name(&files_list, Some(&"text-x-generic-symbolic"));
        stack.set_child_title(&files_list, Some("Files"));
        stack.set_child_icon_name(&outline, Some(&"outline-symbolic"));
        stack.set_child_title(&outline, Some("Outline"));
        stack.show_all();

        let viewswitcher = libhandy::ViewSwitcher::new();
        viewswitcher.get_style_context().add_class("quilter-sidebar-switcher");
        viewswitcher.set_stack(Some(&stack));

        sideheader.set_custom_title(Some(&viewswitcher));

        let container = gtk::Grid::new();
        container.get_style_context().add_class("quilter-sidebar");
        container.attach (&sideheader, 0, 0, 1, 1);
        container.attach (&stack, 0, 1, 1, 1);
        container.show_all();

        Sidebar {
            container,
            sideheader,
            stack,
            files_list,
        }
    }
}
