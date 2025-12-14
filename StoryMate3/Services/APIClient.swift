import Foundation
import OSLog

class APIClient {
    static let shared = APIClient()
    static let baseURL = "http://localhost:3001" // Replace with actual URL
    
    private let session: URLSession
    private static let logger = Logger(subsystem: "com.storymate", category: "APIClient")
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    func request<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(Self.baseURL)\(endpoint)") else {
            Self.logger.error("❌ Invalid URL: \(Self.baseURL)\(endpoint)")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Get token from AuthManager
        if let token = AuthManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            Self.logger.info("🔑 Token added to request")
        } else {
            Self.logger.warning("⚠️ No token available")
        }
        
        // Encode and log request body
        if let body = body {
            let encoded = try JSONEncoder().encode(body)
            request.httpBody = encoded
            
            if let bodyString = String(data: encoded, encoding: .utf8) {
                Self.logger.info("📤 REQUEST: \(method) \(endpoint)")
                Self.logger.info("📤 REQUEST BODY: \(bodyString)")
            }
        } else {
            Self.logger.info("📤 REQUEST: \(method) \(endpoint)")
        }
        
        // Make request
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            Self.logger.error("❌ Invalid response type")
            throw URLError(.badServerResponse)
        }
        
        Self.logger.info("📥 RESPONSE STATUS: \(httpResponse.statusCode)")
        
        // Log raw response body BEFORE decoding
        if let responseString = String(data: data, encoding: .utf8) {
            Self.logger.info("📥 RESPONSE BODY (RAW): \(responseString)")
        } else {
            Self.logger.warning("⚠️ Could not convert response data to string")
        }
        
        // Check status code
        guard (200...299).contains(httpResponse.statusCode) else {
            Self.logger.error("❌ HTTP Error: Status \(httpResponse.statusCode)")
            
            // Handle 401 Unauthorized - invalid or expired token
            if httpResponse.statusCode == 401 {
                Self.logger.warning("⚠️ Token is invalid or expired - clearing auth")
                AuthManager.shared.clearAuth()
                throw NSError(domain: "APIClient", code: 401, userInfo: [
                    NSLocalizedDescriptionKey: "Your session has expired. Please log in again."
                ])
            }
            
            // Try to decode error message
            if let errorResponse = try? JSONDecoder().decode(ErrorResponseDto.self, from: data) {
                Self.logger.error("❌ Error message: \(errorResponse.message)")
                throw NSError(domain: "APIClient", code: httpResponse.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: errorResponse.message
                ])
            }
            
            throw URLError(.badServerResponse)
        }
        
        // Decode response
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            Self.logger.info("✅ Successfully decoded response to \(String(describing: T.self))")
            return decoded
        } catch let decodingError {
            Self.logger.error("❌ DECODING ERROR: \(decodingError)")
            if let decodingError = decodingError as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    Self.logger.error("❌ Missing key '\(key.stringValue)' at: \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    Self.logger.error("❌ Type mismatch for type '\(type)' at: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    Self.logger.error("❌ Value not found for type '\(type)' at: \(context.codingPath)")
                case .dataCorrupted(let context):
                    Self.logger.error("❌ Data corrupted at: \(context.codingPath)")
                @unknown default:
                    Self.logger.error("❌ Unknown decoding error")
                }
            }
            throw decodingError
        }
    }
}

// MARK: - Error Response DTO
struct ErrorResponseDto: Codable {
    let success: Bool
    let message: String
    let error: String?
}


// MARK: - Publish State
enum PublishState: Equatable {
    case idle
    case loading
    case success
    case error(String)
}

