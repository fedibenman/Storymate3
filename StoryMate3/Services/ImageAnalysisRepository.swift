import Foundation
import UIKit

/// Repository for handling image analysis operations
/// This class handles sending images to the backend for level detection
class ImageAnalysisRepository {
    
    // TODO: Replace with your actual backend API endpoint
    private let baseUrl = "http://localhost:3001/analyze"
    

    func analyzeImage(_ image: UIImage) async -> Result<String, Error> {
        do {
            print("[ImageAnalysis] Starting image analysis...")
            
            // Convert image to base64
            let base64String = try convertImageToBase64(image)
            print("[ImageAnalysis] Image converted to base64. Size: \(base64String.count) characters")
            
            // Create the request body
            let requestBody = ImageAnalysisRequest(
                image: base64String,
                imageType: "jpeg"
            )
            print("[ImageAnalysis] Request body created")
            
            // Make the API call
            let response = try await makeApiCall(requestBody)
            print("[ImageAnalysis] Response received from API")
            
            // Parse the response
            let message = try parseResponse(response)
            print("[ImageAnalysis] Response parsed successfully")
            print("[ImageAnalysis] Message: \(message)")
            
            return .success(message)
        } catch {
            print("[ImageAnalysis] Error occurred: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    

    private func convertImageToBase64(_ image: UIImage) throws -> String {
        print("[ImageAnalysis] Converting image to base64...")
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            let error = NSError(domain: "ImageConversion", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data"])
            print("[ImageAnalysis] Image conversion failed: \(error.localizedDescription)")
            throw error
        }
        let base64 = imageData.base64EncodedString()
        print("[ImageAnalysis] Image data size: \(imageData.count) bytes")
        return base64
    }
    

    private func makeApiCall(_ requestBody: ImageAnalysisRequest) async throws -> String {
        guard let url = URL(string: baseUrl) else {
            let error = NSError(domain: "InvalidURL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])
            print("[ImageAnalysis] Invalid URL: \(baseUrl)")
            throw error
        }
        
        print("[ImageAnalysis] Preparing API request to: \(baseUrl)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let encoder = JSONEncoder()
        let httpBody = try encoder.encode(requestBody)
        request.httpBody = httpBody
        
        print("[ImageAnalysis] Request body size: \(httpBody.count) bytes")
        print("[ImageAnalysis] Sending POST request...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("[ImageAnalysis] Response received")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = NSError(domain: "InvalidResponse", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
            print("[ImageAnalysis] Invalid HTTP response type")
            throw error
        }
        
        print("[ImageAnalysis] HTTP Status Code: \(httpResponse.statusCode)")
        print("[ImageAnalysis] Response headers: \(httpResponse.allHeaderFields)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "HTTP Error: \(httpResponse.statusCode)"
            print("[ImageAnalysis] HTTP Error - Status: \(httpResponse.statusCode), Message: \(errorMessage)")
            throw NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        guard let responseString = String(data: data, encoding: .utf8) else {
            let error = NSError(domain: "DecodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response"])
            print("[ImageAnalysis] Failed to decode response as UTF-8")
            throw error
        }
        
        print("[ImageAnalysis] Response data size: \(data.count) bytes")
        print("[ImageAnalysis] Response body: \(responseString)")
        
        return responseString
    }
    
    /// Parses the JSON response from the backend
    /// - Parameter response: The response string from the server
    /// - Returns: Message string from the API
    private func parseResponse(_ response: String) throws -> String {
        print("[ImageAnalysis] Parsing JSON response...")
        
        guard let data = response.data(using: .utf8) else {
            let error = NSError(domain: "DecodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode response string"])
            print("[ImageAnalysis] Failed to convert response string to UTF-8 data")
            throw error
        }
        
        let decoder = JSONDecoder()
        do {
            // Decode the API response
            let apiResponse = try decoder.decode(ImageAnalysisResponse.self, from: data)
            print("[ImageAnalysis] JSON parsing successful")
            print("[ImageAnalysis] API Response - Success: \(apiResponse.success), Message: \(apiResponse.message)")
            
            // Return only the message
            return apiResponse.message
        } catch {
            print("[ImageAnalysis] JSON parsing failed: \(error.localizedDescription)")
            print("[ImageAnalysis] Response that failed to parse: \(response)")
            throw error
        }
    }
}
