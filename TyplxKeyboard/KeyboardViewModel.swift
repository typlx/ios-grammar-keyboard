import Combine
import Foundation

final class KeyboardViewModel: ObservableObject {
    @Published var isFixing = false
    @Published var errorMessage: String? = nil
}
