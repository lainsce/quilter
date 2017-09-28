[CCode(cheader_filename = "mkdio.h")]
namespace Markdown {
    [Compact]
    [CCode(cname = "MMIOT", cprefix = "mkd_", free_function = "mkd_cleanup")]
    public class Document {
        internal bool compile(int flags);
        private int document(out unowned string text);
        private int toc(out unowned string? text);

        [CCode(cname = "mkd_string")]
        public Document.from_string(uint8[] bfr, int flags);

        public unowned string render_html() {
            unowned string html;
            int size = this.document(out html);
            return html;
        }

        public unowned string? render_html_toc() {
            unowned string? html = null;
            int size = this.toc(out html);
            return html;
        }
    }

    public Document parse(uint8[] text, int flags = 0x02001000) {
        var document = new Document.from_string(text, flags);
        document.compile(flags);
        return document;
    }
}
