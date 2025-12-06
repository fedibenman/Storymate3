import SwiftUI
import Combine

@MainActor
class ForgotPasswordViewModel: ObservableObject {
    @Published var email = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccessAlert = false
    @Published var showResetPasswordScreen = false
    
    private var networkManager = NetworkManager()
    
    func handleForgotPassword() async {
        // Reset error message
        errorMessage = nil
        
        // Validate input
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }
        
        // Basic email validation
        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Please enter a valid email"
            return
        }
        
        isLoading = true
        
        do {
            try await networkManager.forgotPassword(email: email)
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
