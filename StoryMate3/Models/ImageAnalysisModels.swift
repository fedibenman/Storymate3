import Foundation

/// Wrapper for the API response
struct ImageAnalysisResponse: Codable {
    let success: Bool
    let message: String
}

/// Request body for image analysis API
struct ImageAnalysisRequest: Codable {
    let image: String
    let imageType: String
}
