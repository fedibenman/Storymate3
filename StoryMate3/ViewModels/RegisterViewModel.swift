import SwiftUI
import Combine

@MainActor
class RegisterViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccessAlert = false
    
    private var networkManager = NetworkManager()
    
    func handleSignup() async {
        // Reset error message
        errorMessage = nil
        
        // Validate inputs
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        isLoading = true
        
        do {
            try await networkManager.signup(name: name, email: email, password: password)
            isLoading = false
            showSuccessAlert = true
        } catch let error as NetworkError {
            isLoading = false
            errorMessage = error.errorDescription ?? "An error occurred"
        } catch {
            isLoading = false
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}
