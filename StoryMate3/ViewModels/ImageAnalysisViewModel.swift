import SwiftUI
import Combine

/// ViewModel for handling image analysis operations
class ImageAnalysisViewModel: ObservableObject {
    
    private let repository = ImageAnalysisRepository()
    
    // UI State
    @Published var isLoading = false
    @Published var analysisResult: String? = nil
    @Published var error: String? = nil
    
    /// Analyzes an image and updates the UI state
    /// - Parameter image: The UIImage to analyze
    func analyzeImage(_ image: UIImage) async {
        await MainActor.run {
            isLoading = true
            error = nil
            analysisResult = nil
        }
        
        let result = await repository.analyzeImage(image)
        
        switch result {
        case .success(let message):
            await MainActor.run {
                analysisResult = message
                isLoading = false
            }
            
        case .failure(let error):
            await MainActor.run {
                self.error = "Analysis failed: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    /// Clears the current analysis result
    func clearResult() {
        analysisResult = nil
        error = nil
    }
}
