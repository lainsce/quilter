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
namespace Quilter {
    public class Widgets.Preview : WebKit.WebView {
        private static Preview? instance = null;
        public string html;
        public Widgets.EditView buf;
        public double scroll_value;
        private uint id1 = 0;

        public static Preview get_instance () {
            if (instance == null) {
                instance = new Widgets.Preview (Application.win, Application.win.edit_view_content);
            }

            return instance;
        }

        public Preview (MainWindow window, Widgets.EditView buf) {
            Object(user_content_manager: new WebKit.UserContentManager());
            visible = true;
            this.buf = buf;
            var settingsweb = get_settings ();
            settingsweb.enable_page_cache = false;
            settingsweb.javascript_can_open_windows_automatically = false;

            this.scroll_value = -1;
            idle_update_events ();

            update_html_view ();

            Quilter.Application.grsettings.notify["prefers-color-scheme"].connect (() => {
                update_html_view ();
            });

            connect_signals ();
        }

        protected override bool context_menu (
            WebKit.ContextMenu context_menu,
            Gdk.Event event,
            WebKit.HitTestResult hit_test_result
        ) {
            return true;
        }

        private string set_stylesheet () {
            if (Quilter.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK) {
                string dark = Styles.quilterdark.css;
                return dark;
            } else if (Quilter.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.NO_PREFERENCE) {
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
            } else {
                string normal = Styles.quilter.css;
                return normal;
            }
        }

        private string set_font_stylesheet () {
            if (Quilter.Application.gsettings.get_string("preview-font") == "serif") {
                return "/usr/share/com.github.lainsce.quilter/font/serif.css";
            } else if (Quilter.Application.gsettings.get_string("preview-font") == "sans") {
                return "/usr/share/com.github.lainsce.quilter/font/sans.css";
            } else if (Quilter.Application.gsettings.get_string("preview-font") == "mono") {
                return "/usr/share/com.github.lainsce.quilter/font/mono.css";
            }

            return "/usr/share/com.github.lainsce.quilter/font/serif.css";
        }

        private string set_highlight_stylesheet () {
            if (Quilter.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK) {
                return "/usr/share/com.github.lainsce.quilter/highlight.js/styles/dark.min.css";
            } else if (Quilter.Application.grsettings.prefers_color_scheme == Granite.Settings.ColorScheme.NO_PREFERENCE) {
                if (Quilter.Application.gsettings.get_string("visual-mode") == "dark") {
                    return "/usr/share/com.github.lainsce.quilter/highlight.js/styles/dark.min.css";
                } else if (Quilter.Application.gsettings.get_string("visual-mode") == "sepia") {
                    return "/usr/share/com.github.lainsce.quilter/highlight.js/styles/sepia.min.css";
                } else {
                    return "/usr/share/com.github.lainsce.quilter/highlight.js/styles/default.min.css";
                }
            } else {
                return "/usr/share/com.github.lainsce.quilter/highlight.js/styles/default.min.css";
            }
        }


        private string set_highlight () {
            if (Quilter.Application.gsettings.get_boolean("highlight")) {
                string render = "/usr/share/com.github.lainsce.quilter/highlight.js/lib/highlight.min.js";
                string hl = """
                    <link rel="stylesheet" href="%s">
                    <script defer src="%s" onload="hljs.initHighlightingOnLoad();"></script>
                """.printf (set_highlight_stylesheet (), render);
                return hl;
            } else {
                return "";
            }
        }

        private string set_center_headers () {
            if (Quilter.Application.gsettings.get_boolean("center-headers")) {
                return "/usr/share/com.github.lainsce.quilter/center_headers/cheaders.css";
            } else {
                return "";
            }
        }

        private string set_latex () {
            if (Quilter.Application.gsettings.get_boolean("latex")) {
                string katex_main = "/usr/share/com.github.lainsce.quilter/katex/katex.css";
                string katex_js = "/usr/share/com.github.lainsce.quilter/katex/katex.js";
                string render = "/usr/share/com.github.lainsce.quilter/katex/render.js";
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

        private string set_mermaid () {
            if (Quilter.Application.gsettings.get_boolean("mermaid")) {
                string render = "/usr/share/com.github.lainsce.quilter/mermaid/mermaid.js";
                string mermaid = """
                    <script defer src="%s" onload="mermaid.initialize({startOnLoad:true;});"></script>
                """.printf (render);
                return mermaid;
            } else {
                return "";
            }
        }

        public string get_javascript () {
            string script;
            script = """
                e = document.documentElement;
                canScroll = e.scrollHeight > e.clientHeight;
                if (canScroll) {
                    e.scrollTop = (%.13f * e.scrollHeight);
                    e.scrollTop;
                }
                
            """.printf(scroll_value);

            return script;
        }

        private void idle_update_events () {
            if (id1 > 0) {
                GLib.Source.remove (id1);
            }
    
            id1 = GLib.Idle.add (() => {
                state_loop ();
                return true;
            });
        }

        public void state_loop () {
            this.run_javascript (get_javascript (), null);
        }

        private void connect_signals () {
            decide_policy.connect ((decision, type) => {
                switch (type) {
                    case WebKit.PolicyDecisionType.NEW_WINDOW_ACTION:
                        if (decision is WebKit.ResponsePolicyDecision) {
                            var policy = (WebKit.ResponsePolicyDecision) decision;
                            launch_browser (policy.request.get_uri ());
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
                idle_update_events ();
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

        public void update_html_view () {
            string processed_mk;
            process_frontmatter (buf.text, out processed_mk);
            var mkd = new Markdown.Document.from_gfm_string (processed_mk.data,
                                                         0x00000100 +
                                                         0x00001000 +
                                                         0x00040000 +
                                                         0x00200000 );
            mkd.compile (0x00001000 +
                         0x00000100 +
                         0x00040000 +
                         0x00200000 );

            string result;
            mkd.document (out result);
            string highlight = set_highlight();
            string cheaders = set_center_headers();
            string latex = set_latex();
            string mermaid = set_mermaid();
            string font = set_font_stylesheet ();
            string style = set_stylesheet ();
            string md = process_plugins (result);

            bool focus_active = Quilter.Application.gsettings.get_boolean("focus-mode");
            bool typewriter_active = Quilter.Application.gsettings.get_boolean("typewriter-scrolling");
            if (focus_active && typewriter_active) {
                style += """
                html {
                    padding-top: 50%;
                    padding-bottom: 50%;
                }
                """;
            } else {
                style += """
                html {
                    padding-bottom: 10%;
                }
                """;
            }

            html = """
            <!doctype html>
            <html>
                <head>
                    <meta charset="utf-8">
                    <style>%s</style>
                    %s
                    %s
                    <link rel="stylesheet" href="%s"/>
                    <link rel="stylesheet" href="%s"/>
                </head>
                <body>
                    %s
                    <div class="markdown-body">
                        %s
                    </div>
                    
                </body>
            </html>""".printf(style, highlight, latex, font, cheaders, mermaid, md);
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
