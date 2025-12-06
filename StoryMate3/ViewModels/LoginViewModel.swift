import SwiftUI
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccessAlert = false
    @Published var showRegisterScreen = false
    @Published var showHomeView = false
    @Published var showForgotPasswordScreen = false
    
    private var networkManager = NetworkManager()
    private var authManager = AuthManager.shared
    
    func handleLogin() async {
        errorMessage = nil
        
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        
        do {
            let authResponse = try await networkManager.login(email: email, password: password)
            let userId = authResponse.userId
            authManager.saveTokens(
                userId: userId,
                accessToken: authResponse.token.accessToken,
                refreshToken: authResponse.token.refreshToken
            )
            isLoading = false
            showSuccessAlert = true
        } catch let error as NetworkError {
            isLoading = false
            errorMessage = error.errorDescription
        } catch {
            isLoading = false
            errorMessage = "An unexpected error occurred"
        }
    }
}
