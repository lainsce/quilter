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
        public signal void updated ();

        public WebView (MainWindow window) {
            Object(user_content_manager: new UserContentManager());
            visible = true;
            vexpand = true;
            hexpand = true;
            var settings = get_settings();
            settings.enable_plugins = false;
            settings.enable_page_cache = false;
            web_context.set_cache_model(WebKit.CacheModel.DOCUMENT_VIEWER);
        }
    
        protected override bool context_menu (
            ContextMenu context_menu,
            Gdk.Event event,
            HitTestResult hit_test_result
        ) {
            return true;
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

        private string process (string raw_mk) {
            string processed_mk;
            process_frontmatter (raw_mk, out processed_mk);

            var mkd = new Markdown.Document (processed_mk.data);
            mkd.compile ();

            string result;
            mkd.get_document (out result);

            return result;
        }

        public void update_html_view () {
            var settings = AppSettings.get_default ();
            var file = File.new_for_path (settings.last_file);
            string text;
      
            string filename = file.get_path ();
            GLib.FileUtils.get_contents (filename, out text);
            
            string html = "";
            html += "<html><head>";
            //html += "<style>"+render_stylesheet+"</style>";
            html += "</head><body><div class=\"markdown-body\">";
            html += process (text);
            html += "</div></body></html>";
            this.load_html (html, "file://");
            updated ();
        }
    }
}