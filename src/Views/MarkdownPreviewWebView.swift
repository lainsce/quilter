import AppKit
import SwiftUI
import WebKit

private final class PreviewURLSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "quilter-preview"

    private let previewAssetsURL: URL?

    init(previewAssetsURL: URL?) {
        self.previewAssetsURL = previewAssetsURL
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url, let previewAssetsURL else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        var relativePath = url.path
        if relativePath.hasPrefix("/") {
            relativePath = String(relativePath.dropFirst())
        }
        guard !relativePath.isEmpty else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        let fileURL = previewAssetsURL.appendingPathComponent(relativePath)
        let rootPath = previewAssetsURL.standardizedFileURL.path
        let candidatePath = fileURL.standardizedFileURL.path
        guard candidatePath == rootPath || candidatePath.hasPrefix(rootPath + "/"),
              let data = try? Data(contentsOf: fileURL) else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        let response = URLResponse(
            url: url,
            mimeType: mimeType(for: fileURL.pathExtension),
            expectedContentLength: data.count,
            textEncodingName: "utf-8"
        )
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {}

    private func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "css": return "text/css"
        case "js": return "application/javascript"
        case "svg": return "image/svg+xml"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "woff2": return "font/woff2"
        case "woff": return "font/woff"
        case "ttf": return "font/ttf"
        case "otf": return "font/otf"
        default: return "application/octet-stream"
        }
    }
}

private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: (AnyObject & WKScriptMessageHandler)?
    init(_ delegate: AnyObject & WKScriptMessageHandler) { self.delegate = delegate }
    func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(ucc, didReceive: message)
    }
}

struct MarkdownPreviewWebView: NSViewRepresentable {
    let markdown: String
    @Bindable var preferences: AppPreferences
    let columnLayout: MarkdownColumnLayout
    var syncScrollRatio: Binding<CGFloat>? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let previewAssetsURL = Bundle.main.resourceURL?
            .appendingPathComponent("PreviewAssets", isDirectory: true)
        config.setURLSchemeHandler(
            PreviewURLSchemeHandler(previewAssetsURL: previewAssetsURL),
            forURLScheme: PreviewURLSchemeHandler.scheme
        )

        config.userContentController.add(
            WeakScriptMessageHandler(context.coordinator),
            name: "scrollSync"
        )
        let scrollJS = """
        (function() {
            var ticking = false;
            function report() {
                var h = document.documentElement.scrollHeight - window.innerHeight;
                if (h > 0) window.webkit.messageHandlers.scrollSync.postMessage(window.scrollY / h);
                ticking = false;
            }
            window.addEventListener('scroll', function() {
                if (!ticking) { requestAnimationFrame(report); ticking = true; }
            }, { passive: true });
        })();
        """
        config.userContentController.addUserScript(
            WKUserScript(source: scrollJS, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        )

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.underPageBackgroundColor = previewUnderPageColor
        webView.setAccessibilityLabel(String(localized: "Markdown Preview"))
        context.coordinator.columnLayout = columnLayout
#if DEBUG
        webView.isInspectable = true
#endif
        loadContent(in: webView, coordinator: context.coordinator)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.underPageBackgroundColor = previewUnderPageColor
        context.coordinator.syncScrollRatio = syncScrollRatio
        context.coordinator.columnLayout = columnLayout
        let reloaded = loadContent(in: webView, coordinator: context.coordinator)
        if !reloaded {
            context.coordinator.applyColumnLayout(to: webView)

            if let ratio = syncScrollRatio?.wrappedValue,
               abs(ratio - context.coordinator.ownedScrollRatio) > 0.005 {
                context.coordinator.ownedScrollRatio = ratio
                webView.evaluateJavaScript(
                    "(function(){var h=document.documentElement.scrollHeight-window.innerHeight;if(h>0)window.scrollTo(0,\(ratio)*h);})()",
                    completionHandler: nil
                )
            }
        }
    }

    private var previewUnderPageColor: NSColor {
        AppTheme.configuredPreviewSurfaceColor()
    }

    @discardableResult
    private func loadContent(in webView: WKWebView, coordinator: Coordinator) -> Bool {
        let html = MarkdownHTMLRenderer.render(markdown, preferences: preferences)
        guard coordinator.lastHTML != html else { return false }
        coordinator.lastHTML = html
        let baseURL = URL(string: "\(PreviewURLSchemeHandler.scheme):///")
        webView.loadHTMLString(html, baseURL: baseURL)
        return true
    }

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        var lastHTML = ""
        var columnLayout: MarkdownColumnLayout?
        var syncScrollRatio: Binding<CGFloat>?
        var ownedScrollRatio: CGFloat = -1

        func applyColumnLayout(to webView: WKWebView) {
            guard let columnLayout, columnLayout.availableWidth > 0 else { return }

            let script = """
            (function() {
              var root = document.documentElement;
              root.style.setProperty('--quilter-preview-max-width', '\(max(1.0, columnLayout.availableWidth))px');
              root.style.setProperty('--quilter-preview-leading-inset', '\(columnLayout.leadingInset)px');
              root.style.setProperty('--quilter-preview-trailing-inset', '\(columnLayout.trailingInset)px');
            })();
            """
            webView.evaluateJavaScript(script, completionHandler: nil)
        }

        func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "scrollSync", let ratio = message.body as? Double else { return }
            let r = CGFloat(ratio)
            ownedScrollRatio = r
            syncScrollRatio?.wrappedValue = r
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            applyColumnLayout(to: webView)

            guard let ratio = syncScrollRatio?.wrappedValue, ratio > 0.005 else { return }
            ownedScrollRatio = ratio
            webView.evaluateJavaScript(
                "(function(){var h=document.documentElement.scrollHeight-window.innerHeight;if(h>0)window.scrollTo(0,\(ratio)*h);})()",
                completionHandler: nil
            )
        }

        @MainActor
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            switch url.scheme?.lowercased() {
            case "http", "https":
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
            case PreviewURLSchemeHandler.scheme:
                decisionHandler(.allow)
            default:
                decisionHandler(.cancel)
            }
        }
    }
}
