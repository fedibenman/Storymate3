//
//  CoversationModels.swift
//  StoryMates
//
//  Created by Mac Mini 10 on 23/11/2025.
//

import Foundation

// MARK: - Image Data Model
struct ImageData: Codable, Identifiable {
    let id: String = UUID().uuidString
    let base64: String?
    let mimeType: String?
    let fileName: String?
}

// MARK: - AI Conversation DTOs (mirror Android models)
struct Conversation: Codable, Identifiable {
    let id: String
    let title: String
    let userId: String
    let messages: [String]?
    let createdAt: String?
    let updatedAt: String?
    let v: Int?
    
    enum CodingKeys: String, CodingKey {
        case id       = "_id"
        case title, userId, messages, createdAt, updatedAt
        case v        = "__v"
    }
}

struct CreateConversationDto: Codable {
    let title: String
    let userId: String
}

struct Message: Codable, Identifiable {
    let id: String
    let conversationId: String
    let sender: String
    let content: String
    let timestamp: String?
    let images: [ImageData]?
    let status: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, conversationId, sender, content, timestamp, images, status, createdAt, updatedAt
    }
}

struct CreateMessageDto: Codable {
    var conversationId: String = ""
    let userId: String
    let content: String
    var sender: String = "user"
    let images: [ImageData]?
    
    init(userId: String, content: String, images: [ImageData]? = nil) {
        self.userId = userId
        self.content = content
        self.sender = "user"
        self.images = images
    }
}

struct EditMessageDto: Codable {
    let content: String
    let images: [ImageData]?
}
