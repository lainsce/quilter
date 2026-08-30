import SwiftUI

struct PrivacyPolicySection: View {
    let title: LocalizedStringResource
    let systemImage: String
    let text: LocalizedStringResource

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.gridUnit * 2) {
            Label(title, systemImage: systemImage)
                .font(AppTheme.contentBlockTitle)
            Text(text)
                .font(AppTheme.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
