import Foundation
import AppKit

private struct PreviewThemeCSS {
    let rootDeclarations: String
    let appearanceOverrides: String
}

enum MarkdownHTMLRenderer {
    static func render(
        _ markdown: String,
        preferences: AppPreferences
    ) -> String {
        let body = renderBlocks(
            markdown,
            rendersMermaid: preferences.rendersMermaidGraphs,
            visited: []
        )
        let centeredHeaders = centeredHeaderCSS(preferences)
        let previewTheme = previewThemeCSS()

        // Match the preview's text selection to the app's themed accent.
        let selectionColor = AppTheme.accentCSSColor(alpha: 0.3)

        let codeResources = codeResourceMarkup(enabled: preferences.highlightsPreviewCode)
        let latexResources = latexResourceMarkup(enabled: preferences.rendersLaTeXMath)
        let mermaidResources = mermaidResourceMarkup(enabled: preferences.rendersMermaidGraphs)
        let readyScripts = readyScripts(for: preferences)

        return """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline' quilter-preview:; script-src 'unsafe-inline' quilter-preview:; img-src data: quilter-preview:; font-src data: quilter-preview:; connect-src 'none'; frame-ancestors 'none';">
          <style>
            :root {
              color-scheme: light dark;
              \(previewTheme.rootDeclarations)
              /* Updated in place by MarkdownPreviewWebView from the shared
                 AppKit column metrics whenever the pane is resized. */
              --quilter-preview-max-width: min(820px, calc(\(preferences.columnCharacterCount)ch + 128px));
              --quilter-preview-leading-inset: 64px;
              --quilter-preview-trailing-inset: 64px;
            }
            \(previewTheme.appearanceOverrides)
            html { background: var(--quilter-preview-background); }
            body {
              box-sizing: border-box;
              width: 100%;
              /*
               These variables are calculated from the same column metrics as
               the NSTextView. Keep width: 100% so the surface remains fluid as
               the split divider moves.
               */
              max-width: var(--quilter-preview-max-width);
              margin: 0 auto;
              padding: 56px var(--quilter-preview-trailing-inset) 96px var(--quilter-preview-leading-inset);
              color: var(--quilter-preview-foreground);
              background: var(--quilter-preview-background);
              font-family: \(preferences.previewFont.cssFamily);
              font-size: 16px;
              line-height: 28px;
              letter-spacing: 0.005em;
              overflow-wrap: anywhere;
            }
            h1, h2, h3, h4 {
              margin: 0;
              line-height: 28px;
              font-weight: 700;
              letter-spacing: -0.012em;
            }
            h1 { font-size: 26px; }
            h2 { font-size: 22px; }
            h3 { font-size: 19px; }
            h4 { font-size: 17px; }
            p, ul, ol, blockquote, pre { margin: 0; }
            .quilter-blank-line {
              height: 1.75rem;
              width: 100%;
            }
            .quilter-table-wrap {
              max-width: 100%;
              margin: 1.1em 0;
              overflow-x: auto;
              overscroll-behavior-x: contain;
            }
            table {
              width: max-content;
              min-width: 100%;
              border-collapse: collapse;
              table-layout: auto;
            }
            th, td {
              padding: 0.35em 0.6em;
              border: 1px solid color-mix(in srgb, var(--quilter-preview-foreground) 18%, transparent);
              vertical-align: top;
              text-align: left;
            }
            th {
              white-space: nowrap;
              font-weight: 600;
              background: color-mix(in srgb, var(--quilter-preview-foreground) 6%, var(--quilter-preview-background));
            }
            .task-list {
              list-style: none;
              padding-left: 0;
            }
            .task-list li {
              display: flex;
              align-items: flex-start;
              gap: 0.55em;
            }
            .task-list input {
              flex: 0 0 auto;
              width: 1em;
              height: 1em;
              margin: 0.36em 0 0;
              accent-color: var(--quilter-preview-accent);
            }
            blockquote {
              margin-left: 0;
              padding-left: 1em;
              border-left: 2px solid color-mix(in srgb, var(--quilter-preview-foreground) 28%, transparent);
              color: color-mix(in srgb, var(--quilter-preview-foreground) 68%, transparent);
            }
            pre {
              padding: 0.85em 1em;
              border: 1px solid color-mix(in srgb, var(--quilter-preview-foreground) 18%, transparent);
              border-radius: 4px;
              overflow: auto;
              background: color-mix(in srgb, var(--quilter-preview-foreground) 4%, var(--quilter-preview-background));
            }
            code {
              font-family: 'Lekton', ui-monospace, 'SFMono-Regular', Menlo, monospace;
              font-size: 0.9em;
            }
            :not(pre) > code {
              padding: 0.12em 0.32em;
              border-radius: 3px;
              background: color-mix(in srgb, var(--quilter-preview-foreground) 7%, var(--quilter-preview-background));
            }
            a { color: var(--quilter-preview-accent); }
            .hljs, .hljs * {
              color: var(--quilter-preview-foreground) !important;
              background: transparent !important;
            }
            .hljs-keyword, .hljs-title, .hljs-built_in, .hljs-type,
            .hljs-name, .hljs-attribute, .hljs-selector-tag {
              font-weight: 700;
            }
            ::selection { background: \(selectionColor); }
            hr {
              border: 0;
              border-top: 1px solid color-mix(in srgb, var(--quilter-preview-foreground) 24%, transparent);
              margin: 1.5em 0;
            }
            img, svg { max-width: 100%; height: auto; }
            .mermaid { display: flex; justify-content: center; margin: 1.5em 0; }
            .quilter-image { margin: 1.5em 0; text-align: center; }
            .quilter-image img { display: inline-block; max-width: 100%; border-radius: 4px; }
            .quilter-embed {
              margin: 1.5em 0;
              padding: 0.2em 1em;
              border-left: 2px solid color-mix(in srgb, var(--quilter-preview-foreground) 28%, transparent);
            }
            .quilter-missing {
              margin: 1.5em 0;
              padding: 0.55em 0.85em;
              border-radius: 4px;
              font-style: italic;
              color: color-mix(in srgb, var(--quilter-preview-foreground) 55%, transparent);
              background: color-mix(in srgb, var(--quilter-preview-foreground) 6%, var(--quilter-preview-background));
            }
            \(centeredHeaders)
          </style>
          \(codeResources)
          \(latexResources)
          \(mermaidResources)
        </head>
        <body>
          \(body)
          <script>
            document.addEventListener('DOMContentLoaded', function () {
              \(readyScripts.joined(separator: "\n"))
            });
          </script>
        </body>
        </html>
        """
    }

    private static func centeredHeaderCSS(_ preferences: AppPreferences) -> String {
        preferences.centersPreviewHeaders ? "h1, h2, h3 { text-align: center; }" : ""
    }

    private static func codeResourceMarkup(enabled: Bool) -> String {
        guard enabled else { return "" }
        return """
          <link rel="stylesheet" href="highlight.js/styles/default.min.css" media="(prefers-color-scheme: light)">
          <link rel="stylesheet" href="highlight.js/styles/dark.min.css" media="(prefers-color-scheme: dark)">
          <script src="highlight.js/lib/highlight.min.js"></script>
          """
    }

    private static func latexResourceMarkup(enabled: Bool) -> String {
        guard enabled else { return "" }
        return """
          <link rel="stylesheet" href="katex/katex.css">
          <script src="katex/katex.js"></script>
          <script src="katex/render.js"></script>
          """
    }

    private static func mermaidResourceMarkup(enabled: Bool) -> String {
        enabled ? #"<script src="mermaid/mermaid.js"></script>"# : ""
    }

    private static func readyScripts(for preferences: AppPreferences) -> [String] {
        var scripts: [String] = []
        if preferences.highlightsPreviewCode { scripts.append("hljs.highlightAll();") }
        if preferences.rendersLaTeXMath { scripts.append("renderMathInElement(document.body);") }
        if preferences.rendersMermaidGraphs {
            let mermaidTheme = "window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'default'"
            scripts.append("mermaid.initialize({ startOnLoad: true, theme: \(mermaidTheme) });")
        }
        return scripts
    }

    private static func previewThemeCSS() -> PreviewThemeCSS {
        // Resolve both branches through the same preview tokens used by the
        // native preview surface. WebKit follows the host appearance through
        // the media query below, while the actual RGB values remain owned by
        // AppTheme.
        let lightAppearance = NSAppearance(named: .aqua)!
        let darkAppearance = NSAppearance(named: .darkAqua)!
        let lightBackground = cssColor(
            AppTheme.previewSurfaceColor(for: lightAppearance)
        )
        let lightForeground = cssColor(
            AppTheme.previewTextColor(for: lightAppearance)
        )
        let darkBackground = cssColor(
            AppTheme.previewSurfaceColor(for: darkAppearance)
        )
        let darkForeground = cssColor(
            AppTheme.previewTextColor(for: darkAppearance)
        )
        let accent = AppTheme.accentCSSColor()
        let rootDeclarations = """
          --quilter-preview-background: \(lightBackground);
          --quilter-preview-foreground: \(lightForeground);
          --quilter-preview-accent: \(accent);
        """
        return PreviewThemeCSS(
            rootDeclarations: rootDeclarations,
            appearanceOverrides: """
            @media (prefers-color-scheme: dark) {
              :root {
                --quilter-preview-background: \(darkBackground);
                --quilter-preview-foreground: \(darkForeground);
              }
            }
            """
        )
    }

    private static func cssColor(_ color: NSColor) -> String {
        let srgb = color.usingColorSpace(.sRGB) ?? color
        let red = Int((srgb.redComponent * 255).rounded())
        let green = Int((srgb.greenComponent * 255).rounded())
        let blue = Int((srgb.blueComponent * 255).rounded())
        return "rgb(\(red), \(green), \(blue))"
    }


}
