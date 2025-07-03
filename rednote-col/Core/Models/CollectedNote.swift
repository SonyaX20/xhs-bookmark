//
//  CollectedNote.swift
//  rednote-col
//
//  Created by Siyu Xiao on 2025/7/3.
//

import Foundation
import SwiftData

@Model
final class CollectedNote {
    @Attribute(.unique) var id: String
    var title: String
    var content: String?
    var imageURL: String?
    var originalURL: String
    var authorName: String?
    var authorAvatar: String?
    var tags: String? // JSON数组字符串
    var createdDate: Date
    var syncDate: Date
    var isBookmarked: Bool
    var localImagePath: String?
    
    // 关联分类
    @Relationship(inverse: \Category.notes) var category: Category?
    
    init(id: String, title: String, originalURL: String) {
        self.id = id
        self.title = title
        self.originalURL = originalURL
        self.createdDate = Date()
        self.syncDate = Date()
        self.isBookmarked = false
    }
    
    convenience init(
        id: String,
        title: String,
        content: String? = nil,
        imageURL: String? = nil,
        originalURL: String,
        authorName: String? = nil,
        authorAvatar: String? = nil,
        tags: [String] = [],
        category: Category? = nil
    ) {
        self.init(id: id, title: title, originalURL: originalURL)
        self.content = content
        self.imageURL = imageURL
        self.authorName = authorName
        self.authorAvatar = authorAvatar
        self.tags = try? JSONEncoder().encode(tags).base64EncodedString()
        self.category = category
    }
    
    var tagsArray: [String] {
        guard let tags = tags,
              let data = Data(base64Encoded: tags),
              let array = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return array
    }
    
    func setTags(_ tags: [String]) {
        self.tags = try? JSONEncoder().encode(tags).base64EncodedString()
    }
} 