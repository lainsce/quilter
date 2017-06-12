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
*/
using WebKit;

class Quilter.Widgets.WebView: WebKit.WebView {
    const UserContentInjectedFrames FTOP = UserContentInjectedFrames.TOP_FRAME;
    const UserStyleLevel USER = UserStyleLevel.USER;
    public Quilter.Widgets.WindowView window;

    public WebView(Quilter.Widgets.WindowView window) {
        Object(user_content_manager: new UserContentManager());
        this.window = window;
        visible = true;
        vexpand = true;
        hexpand = true;
        var settings = get_settings();
        settings.enable_javascript = false;
        settings.enable_plugins = false;
        settings.enable_page_cache = false;
        web_context.set_cache_model(WebKit.CacheModel.DOCUMENT_VIEWER);
    }

    protected override bool context_menu (
        ContextMenu context_menu,
        Gdk.Event event,
        HitTestResult hit_test_result
    ) {
        return true; // Prevent context menu being shown
    }
}