extern crate sourceview4;

use gtk::WidgetExt;
use gtk::*;
use sourceview4::LanguageManagerExt;
use sourceview4::BufferExt;
use gio::SettingsExt;
use std::{
    fs::File,
    io::{prelude::*, BufReader},
    path::Path,
};
use crate::settings::{Key, SettingsManager};

pub struct EditorView {
    pub view: sourceview4::View,
    pub buffer: sourceview4::Buffer,
    pub focus_mode_turnkey: Option<glib::signal::SignalHandlerId>,
}

impl EditorView {
    pub fn init(webview: &webkit2gtk::WebView, buffer: sourceview4::Buffer, view: sourceview4::View, header: &libhandy::HeaderBar) -> EditorView {
        let asv = SettingsManager::get_boolean(Key::Autosave);
        let tw = SettingsManager::get_boolean(Key::TypewriterScrolling);
        let pos = SettingsManager::get_boolean(Key::Pos);
        let ts = SettingsManager::get_integer(Key::Spacing);
        let tm = SettingsManager::get_integer(Key::Margins);
        let fs = SettingsManager::get_boolean(Key::FocusMode);
        let tx = SettingsManager::get_integer(Key::FontSizing);
        let last_file = SettingsManager::get_string(Key::CurrentFile);
        let fft = SettingsManager::get_string(Key::EditFontType);
        let width = SettingsManager::get_integer(Key::WindowWidth) as f32;
        let height = SettingsManager::get_integer(Key::WindowHeight) as f32;
        let mut focus_mode_turnkey = None;

        if last_file.as_str() != "" {
        // TODO: Implement loading the files from last-files gschema instead of just one.
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

        if pos {
            start_pos (&buffer);
        } else {
            let (start, end) = buffer.get_bounds();
            buffer.remove_tag_by_name("conjfont", &start, &end);
            buffer.remove_tag_by_name("advfont", &start, &end);
            buffer.remove_tag_by_name("adjfont", &start, &end);
            buffer.remove_tag_by_name("verbfont", &start, &end);
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

        buffer.connect_changed(glib::clone!(@weak view, @weak webview, @weak buffer => move |_| {
            if tw && fs {
                glib::timeout_add_local(
                    500, glib::clone!(@weak view, @weak buffer => @default-return glib::Continue(true), move || {
                    let cursor = buffer.get_insert ().unwrap();
                    view.scroll_to_mark(&cursor, 0.0, true, 0.0, 0.55);
                    glib::Continue(true)
                }));
            }

            if asv {
                let delay = SettingsManager::get_integer(Key::AutosaveDelay) as u32;
                glib::timeout_add_seconds_local(delay, glib::clone!(@weak view => @default-return glib::Continue(false), move || {
                    let last_file = SettingsManager::get_string(Key::CurrentFile);
                    let filename = last_file.as_str();
                    let (start, end) = buffer.get_bounds();
                    let contents = buffer.get_text(&start, &end, true);
                    glib::file_set_contents(filename, contents.unwrap().as_bytes()).expect("Unable to write data");
                    glib::Continue(false)
                }));
            }
        }));

        // FIXME: Fix this so it unloads the Focus Scope connection properly.
        if fs {
            focus_mode_turnkey = Some(buffer.connect_property_cursor_position_notify(glib::clone!(@weak buffer => move |_| {
                focus_scope (&buffer);
            })));
        } else {
            if let Some(sig) = None {
                glib::object::ObjectExt::disconnect(&buffer, sig);
            } else {
                focus_mode_turnkey = None;
            }
        }

        SettingsManager::get_settings().connect_changed (glib::clone!(@weak webview,
                                                                      @weak view,
                                                                      @weak buffer,
                                                                      @weak header
                                                => move |_, _| {
            let tw = SettingsManager::get_boolean(Key::TypewriterScrolling);
            let pos = SettingsManager::get_boolean(Key::Pos);
            let ts = SettingsManager::get_integer(Key::Spacing);
            let tm = SettingsManager::get_integer(Key::Margins);
            let fs = SettingsManager::get_boolean(Key::FocusMode);
            let tx = SettingsManager::get_integer(Key::FontSizing);
            let fft = SettingsManager::get_string(Key::EditFontType);
            let width = SettingsManager::get_integer(Key::WindowWidth) as f32;
            let height = SettingsManager::get_integer(Key::WindowHeight) as f32;

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

            if pos {
                start_pos (&buffer);
            } else {
                let (start, end) = buffer.get_bounds();
                buffer.remove_tag_by_name("conjfont", &start, &end);
                buffer.remove_tag_by_name("advfont", &start, &end);
                buffer.remove_tag_by_name("adjfont", &start, &end);
                buffer.remove_tag_by_name("verbfont", &start, &end);
            }
        }));

        EditorView {
            view,
            buffer,
            focus_mode_turnkey,
        }
    }
}

fn focus_scope (buffer: &sourceview4::Buffer) {
    let (start, end) = buffer.get_bounds();
    let vm = SettingsManager::get_string(Key::VisualMode);
    let cursor = buffer.get_insert ().unwrap();
    let cursor_iter = buffer.get_iter_at_mark (&cursor);

    if vm.as_str() == "dark" {
        buffer.remove_tag_by_name("lightsepiafont", &start, &end);
        buffer.remove_tag_by_name("lightgrayfont", &start, &end);
        buffer.remove_tag_by_name("whitefont", &start, &end);
        buffer.apply_tag_by_name("darkgrayfont", &start, &end);
    } else if vm.as_str() == "sepia" {
        buffer.remove_tag_by_name("darkgrayfont", &start, &end);
        buffer.remove_tag_by_name("lightsepiafont", &start, &end);
        buffer.remove_tag_by_name("lightgrayfont", &start, &end);
        buffer.apply_tag_by_name("sepiafont", &start, &end);
    } else {
        buffer.remove_tag_by_name("darkgrayfont", &start, &end);
        buffer.remove_tag_by_name("lightsepiafont", &start, &end);
        buffer.remove_tag_by_name("blackfont", &start, &end);
        buffer.apply_tag_by_name("lightgrayfont", &start, &end);
    }

    // Symbolic "if cursor != null" block {
        let mut start_sentence = cursor_iter.clone();
        let mut end_sentence = start_sentence.clone();

        let focus_type = SettingsManager::get_boolean(Key::FocusModeType);
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

fn start_pos(buffer: &sourceview4::Buffer) {
    let (start, end) = buffer.get_bounds();
    let vbuf_list = lines_from_file(glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/wordlist/verb.txt");
    let abuf_list = lines_from_file(glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/wordlist/adjective.txt");
    let adbuf_list = lines_from_file(glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/wordlist/adverb.txt");
    let cnbuf_list = lines_from_file(glib::get_user_data_dir().unwrap().into_os_string().into_string().unwrap() + "/com.github.lainsce.quilter/wordlist/conjunction.txt");
    let normal_buf = buffer.get_text (&start, &end, false).unwrap().to_string().replace("1234567890@$%^&*+=.,/!?<>;:\"{}[]()<>|\\’”“——…-# ", " ");
    let words: Vec<String> = normal_buf.split(' ').map(|s| s.to_string()).collect();
    let mut p = 0;

    let nounifier = ["the".to_string(), "an".to_string(), "a".to_string(), "and".to_string(), "or".to_string(), "this".to_string()];
    let verbifier = ["be".to_string(), "to".to_string(), "and".to_string()];

    for word in words {
        if word.chars().count() == 0 {
            p += word.chars().count() + 1;
            continue;
        }

        if vbuf_list.contains(&word) || (!word.starts_with("ing") && word.ends_with("ing")) || (!word.starts_with("ed") && word.ends_with("ed")) {
            let match_start = buffer.get_iter_at_offset(p as i32);
            let match_end = buffer.get_iter_at_offset((p as i32) + (word.chars().count() as i32));

            buffer.apply_tag_by_name("verbfont", &match_start, &match_end);
            buffer.remove_tag_by_name("advfont", &match_start, &match_end);
            buffer.remove_tag_by_name("adjfont", &match_start, &match_end);
            buffer.remove_tag_by_name("conjfont", &match_start, &match_end);

            if nounifier.contains(&word) || (word.ends_with ("ction") && !word.starts_with ("ction")) {
               buffer.remove_tag_by_name("verbfont", &match_start, &match_end);
            }

            if verbifier.contains(&word) {
               buffer.apply_tag_by_name("verbfont", &match_start, &match_end);
            }
        }
        if abuf_list.contains(&word) {
            let match_start = buffer.get_iter_at_offset(p as i32);
            let match_end = buffer.get_iter_at_offset((p as i32) + (word.chars().count() as i32));

            buffer.apply_tag_by_name("adjfont", &match_start, &match_end);
            buffer.remove_tag_by_name("verbfont", &match_start, &match_end);
            buffer.remove_tag_by_name("conjfont", &match_start, &match_end);
            buffer.remove_tag_by_name("advfont", &match_start, &match_end);

            if nounifier.contains(&word) {
               buffer.remove_tag_by_name("adjfont", &match_start, &match_end);
            }
        }
        if adbuf_list.contains(&word) {
            let match_start = buffer.get_iter_at_offset(p as i32);
            let match_end = buffer.get_iter_at_offset((p as i32) + (word.chars().count() as i32));

            buffer.apply_tag_by_name("advfont", &match_start, &match_end);
            buffer.remove_tag_by_name("adjfont", &match_start, &match_end);
            buffer.remove_tag_by_name("verbfont", &match_start, &match_end);
            buffer.remove_tag_by_name("conjfont", &match_start, &match_end);

            if nounifier.contains(&word) {
               buffer.remove_tag_by_name("advfont", &match_start, &match_end);
            }
        }
        if cnbuf_list.contains(&word) {
            let match_start = buffer.get_iter_at_offset(p as i32);
            let match_end = buffer.get_iter_at_offset((p as i32) + (word.chars().count() as i32));

            buffer.apply_tag_by_name("conjfont", &match_start, &match_end);
            buffer.remove_tag_by_name("advfont", &match_start, &match_end);
            buffer.remove_tag_by_name("adjfont", &match_start, &match_end);
            buffer.remove_tag_by_name("verbfont", &match_start, &match_end);
        }

        p += word.chars().count() + 1;
    }
}

fn lines_from_file(filename: impl AsRef<Path>) -> Vec<String> {
    let file = File::open(filename).expect("no such file");
    let buf = BufReader::new(file);
    buf.lines()
        .map(|l| l.expect("Could not parse line"))
        .collect()
}
