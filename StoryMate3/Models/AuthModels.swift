//
//  AuthModels.swift
//  StoryMates
//
//  Created by mac on 11/19/25.
//

import Foundation

struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
}

struct AuthResponse: Codable {
    let userId: String      // was optional; make it non-optional for successful login
    let token: TokenResponse
}

struct ErrorResponse: Codable {
    let message: String
    let statusCode: Int?
    let error: String?
}
