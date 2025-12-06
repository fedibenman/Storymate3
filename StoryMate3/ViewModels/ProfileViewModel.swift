import SwiftUI
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var showingEditProfile = false
    
    private var authManager = AuthManager.shared
    
    func logout() {
        authManager.logout()
    }
}
