/* libmarkdown Vala Bindings
 * Copyright 2016 Guillaume Poirier-Morency <guillaumepoiriermorency@gmail.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of works must retain the original copyright notice,
 *     this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the original copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither my name (David L Parsons) nor the names of contributors to
 *     this code may be used to endorse or promote products derived
 *     from this work without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

[CCode (cheader_filename = "vapi/mkdio.h")]
namespace Markdown {
    [CCode (cname = "mkd_callback_t", has_target = false)]
    public delegate string Callback<T> (string str, int size, T user_data);

    [CCode (cname = "mkd_free_t", has_target = false)]
    public delegate void FreeCallback<T> (string str, int size, T user_data);

    [CCode (cname = "mkd_sta_t", has_target = false)]
    public delegate int StringToAnchorCallback<T> (int outchar, T @out);

    public void initialize ();
    public void with_html5_tags ();
    public void shlib_destructor ();

    [Compact]
    [CCode (cname = "mkd_flag_t", free_function = "mkd_free_flags")]
    public class Flags {
        [CCode (cname = "mkd_flags")]
        public Flags ();

        [CCode (cname = "mkd_copy_flags")]
        public Flags.copy (Flags other);

        [CCode (cname = "mkd_set_flag_string")]
        public unowned string set_flag_string (string names);

        [CCode (cname = "mkd_set_flag_num")]
        public void set_flag_num (ulong num);

        [CCode (cname = "mkd_clr_flag_num")]
        public void clr_flag_num (ulong num);

        [CCode (cname = "mkd_set_flag_bitmap")]
        public void set_flag_bitmap (long bitmap);

        [CCode (cname = "mkd_flag_isset")]
        public int isset (int index);
    }

    public char markdown_version[256];

    [Compact]
    [CCode (cname = "MMIOT", cprefix = "mkd_", free_function = "mkd_cleanup")]
    public class Document {
        [CCode (cname = "mkd_in")]
        public Document.from_in (GLib.FileStream file, Flags flags);
        [CCode (cname = "mkd_string")]
        public Document.from_string (uint8[] doc, Flags flags);

        [CCode (cname = "gfm_in")]
        public Document.from_gfm_in (GLib.FileStream file, Flags flags);
        [CCode (cname = "gfm_string")]
        public Document.from_gfm_string (uint8[] doc, Flags flags);
        [CCode (cname = "mkd_document")]
        public int get_document (out unowned string result);

        public void basename (string @base);

        public bool compile (Flags flags);
        public void cleanup ();

        public int dump (GLib.FileStream file, Flags flags, string title);

        [CCode (cname = "markdown")]
        public int markdown (GLib.FileStream file, Flags flags);
        public static int line (uint8[] buffer, out string @out, Flags flags);
        public static void string_to_anchor<T> (uint8[] buffer, StringToAnchorCallback<T> sta, T @out, int flags);
        public int xhtmlpage (Flags flags, GLib.FileStream file);

        public unowned string doc_title ();
        public unowned string doc_author ();
        public unowned string doc_date ();

        public int document (out unowned string text);
        public int toc (out unowned string @out);
        public int css (out unowned string @out);
        public static int xml (uint8[] buffer, out string @out);

        public int generatehtml (GLib.FileStream file);
        public int generatetoc (GLib.FileStream file);
        public static int generatexml (uint8[] buffer, GLib.FileStream file);
        public int generatecss (GLib.FileStream file);
        public static int generateline (uint8[] buffer, GLib.FileStream file, Flags flags);

        public void e_url (Callback callback);
        public void e_flags (Callback callback);
        public void e_free (FreeCallback callback);
        public void e_data<T> (T user_data);

        public static void mmiot_flags (GLib.FileStream file, Document document, bool htmlplease);
        public static void flags_are (GLib.FileStream file, Flags flags, bool htmlplease);

        public void ref_prefix (string prefix);
    }
}
