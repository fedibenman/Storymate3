import Foundation
import OSLog

class APIClient {
    static let shared = APIClient()
    static let baseURL = "https://your-api-url.com/api" // Replace with actual URL
    
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
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Story History

struct StoryStep: Identifiable {
    let id = UUID()
    let nodeId: String
    let nodeType: NodeType
    let text: String
    let imageData: String?
    let choice: String?
    let timestamp: Date
}

// MARK: - Publish State

enum PublishState: Equatable {
    case idle
    case loading
    case success
    case error(String)
}
