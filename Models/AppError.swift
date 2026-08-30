import Foundation

struct AppError: Identifiable {
    let id = UUID()
    let title: LocalizedStringResource
    let message: String
}
