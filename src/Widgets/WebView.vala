/*
* Copyright (c) 2017 Lains
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
*/
using WebKit;

namespace Quilter {
    public class Widgets.WebView : WebKit.WebView {
        public MainWindow parent_window;

        public WebView (MainWindow window) {
            Object(user_content_manager: new UserContentManager());
            parent_window = window;
            visible = true;
            vexpand = true;
            hexpand = true;
            var settingsweb = get_settings();
            settingsweb.enable_plugins = false;
            settingsweb.enable_page_cache = true;
            settingsweb.enable_developer_extras = false;
            web_context.set_cache_model(WebKit.CacheModel.DOCUMENT_VIEWER);

            update_html_view ();
            var settings = AppSettings.get_default ();
            settings.changed.connect (update_html_view);
            connect_signals ();
        }

        protected override bool context_menu (
            ContextMenu context_menu,
            Gdk.Event event,
            HitTestResult hit_test_result
        ) {
            return true;
        }

        private string set_stylesheet () {
            var settings = AppSettings.get_default ();
            if (!settings.dark_mode) {
                string normal = Styles.quilter.css;
                return normal;
            } else {
                string dark = Styles.quilterdark.css;
                return dark;
            }
        }

        private string set_highlight_stylesheet () {
            var settings = AppSettings.get_default ();
            if (settings.dark_mode) {
                return Build.PKGDATADIR + "/highlight.js/styles/atom-one-dark.min.css";
            } else {
                return Build.PKGDATADIR + "/highlight.js/styles/default.min.css";
            }
        }

        private void connect_signals () {
            create.connect ((navigation_action) => {
                launch_browser (navigation_action.get_request().get_uri ());
                return (Gtk.Widget) null;
            });

            decide_policy.connect ((decision, type) => {
                switch (type) {
                    case WebKit.PolicyDecisionType.NEW_WINDOW_ACTION:
                        if (decision is WebKit.ResponsePolicyDecision) {
                            launch_browser ((decision as WebKit.ResponsePolicyDecision).request.get_uri ());
                        }
                    break;
                    case WebKit.PolicyDecisionType.RESPONSE:
                        if (decision is WebKit.ResponsePolicyDecision) {
                            var policy = (WebKit.ResponsePolicyDecision) decision;
                            launch_browser (policy.request.get_uri ());
                            return false;
                        }
                    break;
                }

                return true;
            });

            load_changed.connect ((event) => {
                if (event == WebKit.LoadEvent.FINISHED) {
                    var rectangle = get_window_properties ().get_geometry ();
                    set_size_request (rectangle.width, rectangle.height);
                }
            });
        }

        private void launch_browser (string url) {
            if (!url.contains ("/embed/")) {
                try {
                    AppInfo.launch_default_for_uri (url, null);
                } catch (Error e) {
                    warning ("No app to handle urls: %s", e.message);
                }
                stop_loading ();
            }
        }

        /**
         * Process the frontmatter of a markdown document, if it exists.
         * Returns the frontmatter data and strips the frontmatter from the markdown doc.
         *
         * @see http://jekyllrb.com/docs/frontmatter/
         */
        private string[] process_frontmatter (string raw_mk, out string processed_mk) {
            string[] map = {};

            processed_mk = null;

            // Parse frontmatter
            if (raw_mk.length > 4 && raw_mk[0:4] == "---\n") {
                int i = 0;
                bool valid_frontmatter = true;
                int last_newline = 3;
                int next_newline;
                string line = "";
                while (true) {
                    next_newline = raw_mk.index_of_char('\n', last_newline + 1);
                    if (next_newline == -1) { // End of file
                        valid_frontmatter = false;
                        break;
                    }
                    line = raw_mk[last_newline+1:next_newline];
                    last_newline = next_newline;

                    if (line == "---") { // End of frontmatter
                        break;
                    }

                    var sep_index = line.index_of_char(':');
                    if (sep_index != -1) {
                        map += line[0:sep_index-1];
                        map += line[sep_index+1:line.length];
                    } else { // No colon, invalid frontmatter
                        valid_frontmatter = false;
                        break;
                    }

                    i++;
                }

                if (valid_frontmatter) { // Strip frontmatter if it's a valid one
                    processed_mk = raw_mk[last_newline:raw_mk.length];
                }
            }

            if (processed_mk == null) {
                processed_mk = raw_mk;
            }

            return map;
        }

        private string process () {
            string text = Widgets.SourceView.buffer.text;
            string processed_mk;
            process_frontmatter (text, out processed_mk);
            // These codes mean, in order: Extra Footnote + Autolink + ``` code + Extra def lists + keep style
            var mkd = new Markdown.Document (processed_mk.data, 0x00200000 + 0x00004000 + 0x02000000 + 0x01000000 + 0x00400000);
            mkd.compile (0x00200000 + 0x00004000 + 0x02000000 + 0x01000000 + 0x00400000);

            string result;
            mkd.get_document (out result);

            return result;
        }

        public void update_html_view () {
            string html = "<!doctype html><meta charset=utf-8><head>";
            html += "<style>" + set_stylesheet () + "</style>";

            // Add highlight.js style and lib to page for code block syntax highlighting.
            html += "<link rel=\"stylesheet\" href=\"" + set_highlight_stylesheet() + "\"/>";
            html += "<script src=\"" + Build.PKGDATADIR + "/highlight.js/lib/highlight.min.js\"></script>";
            html += "<script>hljs.configure({languages: []}); hljs.initHighlightingOnLoad();</script>";

            html += "</head><body><div class=\"markdown-body\">";
            html += process ();
            html += "</div></body></html>";
            this.load_html (html, "file:///");
        }
    }
}
