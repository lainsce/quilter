import SwiftUI

struct CheatsheetEffectView: View {
    let entry: CheatsheetEntry

    var body: some View {
        ZStack(alignment: .leading) {
            switch entry {
            case .heading1:
                Text("Heading 1").font(AppTheme.viewTitle)
            case .heading2:
                Text("Heading 2").font(AppTheme.viewSubtitle)
            case .heading3:
                Text("Heading 3").font(AppTheme.contentBlockTitle)
            case .bold:
                Text("bold").bold()
            case .italic:
                Text("italic").italic()
            case .strikethrough:
                Text("strikethrough").strikethrough()
            case .inlineCode:
                Text("inline code")
                    .font(AppTheme.technicalFont(role: .body))
                    .padding(.horizontal, AppTheme.gridUnit)
                    .padding(.vertical, AppTheme.gridUnit)
                    .background(Color.primary.opacity(0.06), in: .rect(cornerRadius: AppTheme.industrialSmallCornerRadius))
            case .link:
                Text("link")
                    .foregroundStyle(.tint)
                    .underline()
            case .blockquote:
                HStack(spacing: AppTheme.gridSmallGap) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.secondary.opacity(0.4))
                        .frame(width: AppTheme.gridUnit)
                    Text("blockquote")
                        .foregroundStyle(.secondary)
                }
                .fixedSize(horizontal: false, vertical: true)
            case .bullet:
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.gridSmallGap) {
                    Text("•")
                    Text("bullet item")
                }
            case .numbered:
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.gridSmallGap) {
                    Text("1.")
                    Text("numbered item")
                }
            case .codeBlock:
                Text("code block")
                    .font(AppTheme.technicalFont(role: .body))
                    .padding(AppTheme.gridUnit * 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.04), in: .rect(cornerRadius: AppTheme.industrialCornerRadius))
            case .horizontalRule:
                Divider()
            case .image:
                Label("image", systemImage: "photo")
                    .foregroundStyle(.secondary)
            case .tag:
                Text("#tag")
                    .font(AppTheme.caption)
                    .padding(.horizontal, AppTheme.gridUnit * 2)
                    .padding(.vertical, AppTheme.gridUnit)
                    .background(.tint.opacity(0.15), in: .rect(cornerRadius: AppTheme.industrialSmallCornerRadius))
                    .foregroundStyle(.primary)
            case .libraryImage:
                Label("Library image, placed inline and centered", systemImage: "photo.on.rectangle")
                    .foregroundStyle(.secondary)
            case .libraryFile:
                Label("Library document, embedded inline", systemImage: "doc.text")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
