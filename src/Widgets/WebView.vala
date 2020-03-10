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

namespace Quilter.Widgets {
    public class Preview : WebKit.WebView {
        private static Preview? instance = null;
        public string html;
        public Gtk.SourceBuffer buf;

        public static Preview get_instance () {
            if (instance == null) {
                instance = new Widgets.Preview (Application.win, Application.win.edit_view_content.buffer);
            }

            return instance;
        }

        public Preview (MainWindow window, Gtk.SourceBuffer buf) {
            Object(user_content_manager: new UserContentManager());
            visible = true;
            vexpand = true;
            hexpand = true;
            this.margin = 2;
            this.buf = buf;
            var settingsweb = get_settings ();
            settingsweb.enable_plugins = false;
            settingsweb.enable_page_cache = false;
            settingsweb.enable_developer_extras = false;
            settingsweb.javascript_can_open_windows_automatically = false;

            update_html_view ();
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

            if (Quilter.Application.gsettings.get_string("visual-mode") == "dark") {
                string dark = Styles.quilterdark.css;
                return dark;
            } else if (Quilter.Application.gsettings.get_string("visual-mode") == "sepia") {
                string sepia = Styles.quiltersepia.css;
                return sepia;
            } else {
                string normal = Styles.quilter.css;
                return normal;
            }
        }

        private string set_font_stylesheet () {
            if (Quilter.Application.gsettings.get_string("preview-font") == "serif") {
                return Build.PKGDATADIR + "/font/serif.css";
            } else if (Quilter.Application.gsettings.get_string("preview-font") == "sans") {
                return Build.PKGDATADIR + "/font/sans.css";
            } else if (Quilter.Application.gsettings.get_string("preview-font") == "mono") {
                return Build.PKGDATADIR + "/font/mono.css";
            }

            return Build.PKGDATADIR + "/font/serif.css";
        }

        private string set_highlight_stylesheet () {
            if (Quilter.Application.gsettings.get_string("visual-mode") == "dark") {
                return Build.PKGDATADIR + "/highlight.js/styles/dark.min.css";
            } else if (Quilter.Application.gsettings.get_string("visual-mode") == "sepia") {
                return Build.PKGDATADIR + "/highlight.js/styles/sepia.min.css";
            } else {
                return Build.PKGDATADIR + "/highlight.js/styles/default.min.css";
            }
        }

        private string set_highlight () {
            if (Quilter.Application.gsettings.get_boolean("highlight")) {
                return Build.PKGDATADIR + "/highlight.js/lib/highlight.min.js";
            } else {
                return "";
            }
        }

        private string set_latex () {
            if (Quilter.Application.gsettings.get_boolean("latex")) {
                string katex_main = Build.PKGDATADIR + "/katex/katex.css";
                string katex_js = Build.PKGDATADIR + "/katex/katex.js";
                string render = Build.PKGDATADIR + "/katex/render.js";
                string latex = """
                    <link rel="stylesheet" href="%s">
                    <script defer src="%s"></script>
                    <script defer src="%s" onload="renderMathInElement(document.body);"></script>
                """.printf (katex_main, katex_js, render);
                return latex;
            } else {
                return "";
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

            if (raw_mk.length > 4 && raw_mk[0:4] == "---\n") {
                int i = 0;
                bool valid_frontmatter = true;
                int last_newline = 3;
                int next_newline;
                string line = "";
                while (true) {
                    next_newline = raw_mk.index_of_char('\n', last_newline + 1);
                    if (next_newline == -1) {
                        valid_frontmatter = false;
                        break;
                    }
                    line = raw_mk[last_newline+1:next_newline];
                    last_newline = next_newline;

                    if (line == "---") {
                        break;
                    }

                    var sep_index = line.index_of_char(':');
                    if (sep_index != -1) {
                        map += line[0:sep_index-1];
                        map += line[sep_index+1:line.length];
                    } else {
                        valid_frontmatter = false;
                        break;
                    }

                    i++;
                }

                if (valid_frontmatter) {
                    processed_mk = raw_mk[last_newline:raw_mk.length];
                }
            }

            if (processed_mk == null) {
                processed_mk = raw_mk;
            }

            return map;
        }

        private string process () {
            string processed_mk;
            process_frontmatter (buf.text, out processed_mk);
            var mkd = new Markdown.Document.gfm_format (processed_mk.data,
                                                        0x00001000 +
                                                        0x00002000 +
                                                        0x00004000 +
                                                        0x00200000 +
                                                        0x00400000 +
                                                        0x01000000 +
                                                        0x02000000 +
                                                        0x04000000 +
                                                        0x10000000 +
                                                        0x40000000);
            mkd.compile (0x00001000 +
                         0x00002000 +
                         0x00004000 +
                         0x00200000 +
                         0x00400000 +
                         0x01000000 +
                         0x02000000 +
                         0x04000000 +
                         0x10000000 +
                         0x40000000);

            string result;
            mkd.get_document (out result);
            string html = make_html (result);
            return html;
        }

        public string make_html (string result) {
            string highlight_stylesheet = set_highlight_stylesheet();
            string highlight = set_highlight();
            string latex = set_latex();
            string font_stylesheet = set_font_stylesheet ();
            string stylesheet = set_stylesheet ();
            string markdown = process_plugins (result);
            html = """
            <!doctype html>
            <html>
                <head>
                    <meta charset="utf-8">
                    <link rel="stylesheet" href="%s" />
                    <script src="%s"></script>
                    <script>hljs.initHighlightingOnLoad();</script>
                    %s
                    <link rel="stylesheet" href="%s" />
                    <style>"%s"</style>
                </head>
                <body>
                    <div class="markdown-body">
                        %s
                    </div>
                </body>
            </html>""".printf(highlight_stylesheet, highlight, latex, font_stylesheet, stylesheet, markdown);
            return html;
        }
        public void update_html_view () {
            process ();
            this.load_html (html, "file:///");
        }

        private string process_plugins (string raw_mk) {
            var lines = raw_mk.split ("\n");
            string build = "";
            foreach (var line in lines) {
                bool found = false;
                foreach (var plugin in Plugins.PluginManager.get_instance ().get_plugs ()) {
                    if (plugin.has_match (line)) {
                        build = build + plugin.convert (line) + "\n";
                        found = true;
                        break;
                    }
                }

                if (!found) {
                    build = build + line + "\n";
                }
            }

            return build;
}
    }
}
