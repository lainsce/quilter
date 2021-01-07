extern crate sourceview4;

use gtk::WidgetExt;
use gtk::*;
use sourceview4::LanguageManagerExt;
use sourceview4::BufferExt;
use gio::SettingsExt;
use glib::ObjectExt;

pub struct EditorView {
    pub view: sourceview4::View,
    pub buffer: sourceview4::Buffer,
}

impl EditorView {
    pub fn init(gschema: &gio::Settings, webview: &webkit2gtk::WebView, buffer: sourceview4::Buffer, view: sourceview4::View, header: &libhandy::HeaderBar) -> EditorView {
        let asv = gschema.get_boolean("autosave");
        let tw = gschema.get_boolean("typewriter-scrolling");
        let ts = gschema.get_int("spacing");
        let tm = gschema.get_int("margins");
        let fs = gschema.get_boolean("focus-mode");
        let tx = gschema.get_int("font-sizing");
        let last_file = gschema.get_string("current-file").unwrap();
        let fft = gschema.get_string("edit-font-type").unwrap();
        let width = gschema.get_int("window-width") as f32;
        let height = gschema.get_int("window-height") as f32;

        if last_file.as_str() != "" {
            let filename = last_file.as_str();
            let buf = glib::file_get_contents(filename).expect("Unable to get data");
            let contents = String::from_utf8_lossy(&buf);

            buffer.set_text(&contents);

            // lbr.title.set_label (&last_file.to_string());
            // lbr.subtitle.set_label ("");

            // sidebar.files_list.add(&lbr.container);
            // sidebar.files_list.select_row(Some(&lbr.container));
        }

        let md_lang = sourceview4::LanguageManager::get_default().and_then(|lm| lm.get_language("markdown"));

        if let Some(md_lang) = md_lang {
            buffer.set_highlight_matching_brackets(true);
            buffer.set_language(Some(&md_lang));
            buffer.set_highlight_syntax(true);
        }

        if tw && fs {
            glib::timeout_add_local(
                500, glib::clone!(@weak buffer, @weak view => @default-return glib::Continue(true), move || {
                let cursor = buffer.get_insert ().unwrap();
                view.scroll_to_mark(&cursor, 0.0, true, 0.0, 0.55);
                glib::Continue(true)
            }));
        }

        if tw && fs {
            let titlebar_h = header.get_allocated_height() as f32;
            let typewriterposition1 = ((height * (1.0 - 0.55)) - titlebar_h) as i32;
            let typewriterposition2 = ((height * 0.55) - titlebar_h) as i32;
            view.set_top_margin (typewriterposition1);
            view.set_bottom_margin (typewriterposition2);
        } else {
            view.set_top_margin (40);
            view.set_bottom_margin (40);
        }

        if ts == 1 {
            view.set_pixels_above_lines (1);
            view.set_pixels_inside_wrap (1);
        } else if ts == 4 {
            view.set_pixels_above_lines (4);
            view.set_pixels_inside_wrap (4);
        } else if ts == 8 {
            view.set_pixels_above_lines (8);
            view.set_pixels_inside_wrap (8);
        }

        if tx == 0 {
            view.get_style_context().add_class("small-font");
            view.get_style_context().remove_class("medium-font");
            view.get_style_context().remove_class("large-font");
        } else if tx == 1 {
            view.get_style_context().add_class("medium-font");
            view.get_style_context().remove_class("small-font");
            view.get_style_context().remove_class("large-font");
        } else if tx == 2 {
            view.get_style_context().add_class("large-font");
            view.get_style_context().remove_class("medium-font");
            view.get_style_context().remove_class("small-font");
        }

        if fft.as_str() == "mono" {
            view.get_style_context().add_class("mono-font");
            view.get_style_context().remove_class("zwei-font");
            view.get_style_context().remove_class("vier-font");
        } else if fft.as_str() == "zwei" {
            view.get_style_context().add_class("zwei-font");
            view.get_style_context().remove_class("mono-font");
            view.get_style_context().remove_class("vier-font");
        } else if fft.as_str() == "vier" {
            view.get_style_context().add_class("vier-font");
            view.get_style_context().remove_class("zwei-font");
            view.get_style_context().remove_class("mono-font");
        }

        if tm == 1 {
            let m = (width * (1.0 / 100.0)) as i32;
            view.set_left_margin (m);
            view.set_right_margin (m);
        } else if tm == 8 {
            let m = (width * (8.0 / 100.0)) as i32;
            view.set_left_margin (m);
            view.set_right_margin (m);
        } else if tm == 16 {
            let m = (width * (16.0 / 100.0)) as i32;
            view.set_left_margin (m);
            view.set_right_margin (m);
        }

        buffer.connect_changed(glib::clone!(@strong gschema, @weak view, @weak webview, @weak buffer => move |_| {
            if tw && fs {
                glib::timeout_add_local(
                    500, glib::clone!(@weak view, @weak buffer => @default-return glib::Continue(true), move || {
                    let cursor = buffer.get_insert ().unwrap();
                    view.scroll_to_mark(&cursor, 0.0, true, 0.0, 0.55);
                    glib::Continue(true)
                }));
            }

            if asv {
                let delay = gschema.get_int("autosave-delay") as u32;
                glib::timeout_add_seconds_local(delay, glib::clone!(@strong gschema, @weak view => @default-return glib::Continue(false), move || {
                    let last_file = gschema.get_string("current-file").unwrap();
                    let filename = last_file.as_str();
                    let (start, end) = buffer.get_bounds();
                    let contents = buffer.get_text(&start, &end, true);
                    glib::file_set_contents(filename, contents.unwrap().as_bytes()).expect("Unable to write data");
                    glib::Continue(false)
                }));
            }
        }));

        gschema.connect_changed (glib::clone!( @strong gschema,
                                                @weak webview,
                                                @weak view,
                                                @weak buffer,
                                                @weak header
                                                => move |gschema, _| {
            let tw = gschema.get_boolean("typewriter-scrolling");
            let ts = gschema.get_int("spacing");
            let tm = gschema.get_int("margins");
            let fs = gschema.get_boolean("focus-mode");
            let tx = gschema.get_int("font-sizing");
            let fft = gschema.get_string("edit-font-type").unwrap();
            let width = gschema.get_int("window-width") as f32;
            let height = gschema.get_int("window-height") as f32;

            if ts == 1 {
                view.set_pixels_above_lines (1);
                view.set_pixels_inside_wrap (1);
            } else if ts == 4 {
                view.set_pixels_above_lines (4);
                view.set_pixels_inside_wrap (4);
            } else if ts == 8 {
                view.set_pixels_above_lines (8);
                view.set_pixels_inside_wrap (8);
            }

            if tm == 1 {
                let m = (width * (1.0 / 100.0)) as i32;
                view.set_left_margin (m);
                view.set_right_margin (m);
            } else if tm == 8 {
                let m = (width * (8.0 / 100.0)) as i32;
                view.set_left_margin (m);
                view.set_right_margin (m);
            } else if tm == 16 {
                let m = (width * (16.0 / 100.0)) as i32;
                view.set_left_margin (m);
                view.set_right_margin (m);
            }

            if tw && fs {
                let titlebar_h = header.get_allocated_height() as f32;
                let typewriterposition1 = ((height * (1.0 - 0.55)) - titlebar_h) as i32;
                let typewriterposition2 = ((height * 0.55) - titlebar_h) as i32;
                view.set_top_margin (typewriterposition1);
                view.set_bottom_margin (typewriterposition2);
            } else {
                view.set_top_margin (40);
                view.set_bottom_margin (40);
            }

            if tx == 0 {
                view.get_style_context().add_class("small-font");
                view.get_style_context().remove_class("medium-font");
                view.get_style_context().remove_class("large-font");
            } else if tx == 1 {
                view.get_style_context().add_class("medium-font");
                view.get_style_context().remove_class("small-font");
                view.get_style_context().remove_class("large-font");
            } else if tx == 2 {
                view.get_style_context().add_class("large-font");
                view.get_style_context().remove_class("medium-font");
                view.get_style_context().remove_class("small-font");
            }

            if fft.as_str() == "mono" {
                view.get_style_context().add_class("mono-font");
                view.get_style_context().remove_class("zwei-font");
                view.get_style_context().remove_class("vier-font");
            } else if fft.as_str() == "zwei" {
                view.get_style_context().add_class("zwei-font");
                view.get_style_context().remove_class("mono-font");
                view.get_style_context().remove_class("vier-font");
            } else if fft.as_str() == "vier" {
                view.get_style_context().add_class("vier-font");
                view.get_style_context().remove_class("zwei-font");
                view.get_style_context().remove_class("mono-font");
            }

            if fs != false {
                buffer.connect_property_cursor_position_notify(glib::clone!(@weak gschema, @weak buffer => move |_| {
                    focus_scope (&gschema, &buffer);
                }));
            } else {

            }
        }));

        EditorView {
            view,
            buffer,
        }
    }
}

fn focus_scope (gschema: &gio::Settings, buffer: &sourceview4::Buffer) {
    let (start, end) = buffer.get_bounds();
    let vm = gschema.get_string("visual-mode").unwrap();
    let cursor = buffer.get_insert ().unwrap();
    let cursor_iter = buffer.get_iter_at_mark (&cursor);

    if vm.as_str() == "dark" {
        buffer.apply_tag_by_name("darkgrayfont", &start, &end);
        buffer.remove_tag_by_name("lightsepiafont", &start, &end);
        buffer.remove_tag_by_name("lightgrayfont", &start, &end);
        buffer.remove_tag_by_name("whitefont", &start, &end);
    } else if vm.as_str() == "sepia" {
        buffer.remove_tag_by_name("darkgrayfont", &start, &end);
        buffer.apply_tag_by_name("lightsepiafont", &start, &end);
        buffer.remove_tag_by_name("lightgrayfont", &start, &end);
        buffer.remove_tag_by_name("sepiafont", &start, &end);
    } else {
        buffer.remove_tag_by_name("darkgrayfont", &start, &end);
        buffer.remove_tag_by_name("lightsepiafont", &start, &end);
        buffer.apply_tag_by_name("lightgrayfont", &start, &end);
        buffer.remove_tag_by_name("blackfont", &start, &end);
    }

    // Symbolic "if cursor != null" block {
        let mut start_sentence = cursor_iter.clone();
        let mut end_sentence = start_sentence.clone();

        let focus_type = gschema.get_boolean ("focus-mode-type");
        if cursor_iter != start &&
            cursor_iter != end {
            if focus_type {
                start_sentence.backward_sentence_start ();
                end_sentence.forward_sentence_end ();
            } else {
                start_sentence.backward_lines (1);
                end_sentence.forward_lines (2);
            }
        }

        if vm.as_str() == "dark" {
            buffer.remove_tag_by_name("sepiafont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("lightsepiafont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("blackfont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("lightgrayfont", &start_sentence, &end_sentence);
            buffer.apply_tag_by_name("whitefont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("lightgrayfont", &start_sentence, &end_sentence);
        } else if vm.as_str() == "sepia" {
            buffer.apply_tag_by_name("sepiafont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("lightsepiafont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("blackfont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("lightgrayfont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("whitefont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("lightgrayfont", &start_sentence, &end_sentence);
        } else {
            buffer.remove_tag_by_name("sepiafont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("lightsepiafont", &start_sentence, &end_sentence);
            buffer.apply_tag_by_name("blackfont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("lightgrayfont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("whitefont", &start_sentence, &end_sentence);
            buffer.remove_tag_by_name("lightgrayfont", &start_sentence, &end_sentence);
        }
    //}
}
