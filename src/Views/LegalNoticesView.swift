import SwiftUI

struct LegalNoticesView: View {
    private enum Notice: String, CaseIterable, Identifiable {
        case thirdParty
        case quilterLicense
        case fontLicense

        var id: Self { self }

        var title: LocalizedStringResource {
            switch self {
            case .thirdParty: return "Third-Party Notices"
            case .quilterLicense: return "Quilter License"
            case .fontLicense: return "Font License"
            }
        }
    }

    @State private var selectedNotice: Notice = .thirdParty
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.gridSectionGap) {
                VStack(alignment: .leading, spacing: AppTheme.gridSmallGap) {
                    Label("Open-source acknowledgements", systemImage: "doc.text.fill")
                        .font(AppTheme.viewTitle)
                    Text("Quilter includes open-source code and bundled fonts. Their license texts are included here for reference.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Rectangle()
                    .fill(AppTheme.industrialControlRule(for: colorScheme))
                    .frame(height: AppTheme.delimiterThickness)

                VStack(alignment: .leading, spacing: AppTheme.gridUnit * 3) {
                    Label("Notice", systemImage: "list.bullet.rectangle")
                    .font(AppTheme.contentBlockTitle)

                    NULSegmentedPicker(
                        selection: $selectedNotice,
                        options: Notice.allCases
                    ) { notice in
                        Text(notice.title)
                    }
                    .accessibilityLabel("Notice")
                }

                Text(noticeText)
                    .font(AppTheme.technicalFont(role: .contentBlockSubtitle))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppTheme.gridGutter)
            }
            .padding(AppTheme.gridContentInset)
            .frame(maxWidth: 760, alignment: .leading)
        }
        .background(AppTheme.industrialSurface)
        .font(AppTheme.body)
    }

    private var noticeText: String {
        switch selectedNotice {
        case .thirdParty:
            return bundledText(
                named: "ThirdPartyNotices.txt",
                subdirectory: "Legal"
            ) ?? "Third-party notices are unavailable in this build."
        case .quilterLicense:
            return bundledText(
                named: "Quilter GPL License.txt",
                subdirectory: "PreviewAssets"
            ) ?? "The Quilter license is unavailable in this build."
        case .fontLicense:
            return bundledText(
                named: "SIL Open Font License.txt",
                subdirectory: "Fonts"
            ) ?? "The font license is unavailable in this build."
        }
    }

    private func bundledText(named name: String, subdirectory: String) -> String? {
        guard let url = Bundle.main.url(
            forResource: name,
            withExtension: nil,
            subdirectory: subdirectory
        ) else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }
}
