//ffuck
//  AuthManager.swift
//  StoryMates
//
//  Created by mac on 11/19/25.
//

import Foundation
import Combine

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var userId: String?
    
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let userIdKey = "userId"
    
    private init() {
        loadAuthState()
    }
    
    var accessToken: String? {
        return UserDefaults.standard.string(forKey: accessTokenKey)
    }
    
    var refreshToken: String? {
        return UserDefaults.standard.string(forKey: refreshTokenKey)
    }
    
    func saveTokens(userId: String, accessToken: String, refreshToken: String) {
        UserDefaults.standard.set(accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
        UserDefaults.standard.set(userId, forKey: userIdKey)
        self.userId = userId
        self.isAuthenticated = true
    }
    
    func clearAuth() {
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        self.userId = nil
        self.isAuthenticated = false
    }
    
    // Public API for signing out from the app.
    func logout() {
        clearAuth()
    }
    
    private func loadAuthState() {
        if let userId = UserDefaults.standard.string(forKey: userIdKey),
           let _ = UserDefaults.standard.string(forKey: accessTokenKey) {
            self.userId = userId
            self.isAuthenticated = true
        }
    }
}
