//
//  Category.swift
//  rednote-col
//
//  Created by Siyu Xiao on 2025/7/3.
//

import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: String
    var name: String
    var colorHex: String
    var keywords: String // JSON数组字符串
    var isDefault: Bool
    var sortOrder: Int
    
    // 关联的笔记
    @Relationship var notes: [CollectedNote] = []
    
    init(name: String, colorHex: String = "#FF6B35", isDefault: Bool = false, sortOrder: Int = 0) {
        self.id = UUID().uuidString
        self.name = name
        self.colorHex = colorHex
        self.keywords = "[]"
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }
    
    convenience init(name: String, keywords: [String], colorHex: String = "#FF6B35") {
        self.init(name: name, colorHex: colorHex)
        self.setKeywords(keywords)
    }
    
    var keywordsArray: [String] {
        guard let data = keywords.data(using: .utf8),
              let array = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return array
    }
    
    func setKeywords(_ keywords: [String]) {
        if let data = try? JSONEncoder().encode(keywords),
           let string = String(data: data, encoding: .utf8) {
            self.keywords = string
        }
    }
    
    var notesCount: Int {
        return notes.count
    }
}

// 预定义分类
extension Category {
    static func defaultCategories() -> [Category] {
        return [
            Category(name: "美妆护肤", keywords: ["护肤", "化妆", "口红", "面膜", "精华", "防晒"], colorHex: "#FF6B94"),
            Category(name: "穿搭时尚", keywords: ["穿搭", "时尚", "搭配", "服装", "鞋子", "包包"], colorHex: "#6B73FF"),
            Category(name: "美食料理", keywords: ["美食", "料理", "菜谱", "烘焙", "甜品", "餐厅"], colorHex: "#FF9F40"),
            Category(name: "旅行出游", keywords: ["旅行", "景点", "攻略", "酒店", "机票", "自由行"], colorHex: "#4ECDC4"),
            Category(name: "生活日常", keywords: ["生活", "日常", "家居", "收纳", "清洁", "健康"], colorHex: "#95E1D3"),
            Category(name: "学习工作", keywords: ["学习", "工作", "效率", "技能", "读书", "职场"], colorHex: "#A8E6CF"),
            Category(name: "未分类", colorHex: "#D3D3D3", isDefault: true)
        ]
    }
} 