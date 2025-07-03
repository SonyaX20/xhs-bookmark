//
//  DataService.swift
//  rednote-col
//
//  Created by Siyu Xiao on 2025/7/3.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class DataService: ObservableObject {
    private var modelContext: ModelContext
    
    @Published var categories: [Category] = []
    @Published var notes: [CollectedNote] = []
    @Published var isLoading = false
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadInitialData()
    }
    
    // 更新模型上下文
    func updateModelContext(_ newContext: ModelContext) {
        self.modelContext = newContext
        loadInitialData()
    }
    
    // MARK: - 初始化
    private func loadInitialData() {
        Task {
            await loadCategories()
            await loadNotes()
            await createDefaultCategoriesIfNeeded()
        }
    }
    
    private func createDefaultCategoriesIfNeeded() async {
        if categories.isEmpty {
            let defaultCategories = Category.defaultCategories()
            for category in defaultCategories {
                modelContext.insert(category)
            }
            try? modelContext.save()
            await loadCategories()
            
            // 在调试模式下添加示例数据
            #if DEBUG
            await createSampleDataIfNeeded()
            #endif
        }
    }
    
    #if DEBUG
    private func createSampleDataIfNeeded() async {
        if notes.isEmpty {
            let sampleNotes = createSampleNotes()
            for note in sampleNotes {
                await saveNote(note)
            }
        }
    }
    
    private func createSampleNotes() -> [CollectedNote] {
        let beautyCategory = categories.first { $0.name == "美妆护肤" }
        let fashionCategory = categories.first { $0.name == "穿搭时尚" }
        let foodCategory = categories.first { $0.name == "美食料理" }
        
        return [
            CollectedNote(
                id: "sample1",
                title: "春日护肤新品测评",
                content: "这款新出的维C精华真的太好用了，质地清爽不粘腻，坚持用了一个月皮肤明显变亮了～",
                imageURL: "https://sns-avatar-qc.xhscdn.com/avatar/1040g2jo30qb4ie6jb40g5n2ff3bnqf4lheh7hr0",
                originalURL: "https://www.xiaohongshu.com/explore/sample1",
                authorName: "护肤达人小美",
                authorAvatar: "https://sns-avatar-qc.xhscdn.com/avatar/user1",
                tags: ["护肤", "精华", "维C", "美白"],
                category: beautyCategory
            ),
            CollectedNote(
                id: "sample2",
                title: "今日穿搭分享｜法式复古风",
                content: "今天走的是法式复古路线，高腰阔腿裤配简约白衬衫，再加一个小丝巾点缀，简单又优雅～",
                imageURL: "https://sns-avatar-qc.xhscdn.com/avatar/1040g2jo30qb4ie6jb40g5n2ff3bnqf4lheh7hr0",
                originalURL: "https://www.xiaohongshu.com/explore/sample2",
                authorName: "时尚博主Anna",
                authorAvatar: "https://sns-avatar-qc.xhscdn.com/avatar/user2",
                tags: ["穿搭", "法式", "复古", "搭配"],
                category: fashionCategory
            ),
            CollectedNote(
                id: "sample3",
                title: "超简单的草莓司康饼做法",
                content: "周末在家做的草莓司康饼，松软香甜，配茶或咖啡都很棒。制作过程超简单，新手也能轻松搞定！",
                imageURL: "https://sns-avatar-qc.xhscdn.com/avatar/1040g2jo30qb4ie6jb40g5n2ff3bnqf4lheh7hr0",
                originalURL: "https://www.xiaohongshu.com/explore/sample3",
                authorName: "烘焙小能手",
                authorAvatar: "https://sns-avatar-qc.xhscdn.com/avatar/user3",
                tags: ["烘焙", "司康饼", "草莓", "甜品"],
                category: foodCategory
            )
        ]
    }
    #endif
    
    // MARK: - 分类管理
    func loadCategories() async {
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.name)]
        )
        
        do {
            categories = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load categories: \(error)")
        }
    }
    
    func saveCategory(_ category: Category) async {
        modelContext.insert(category)
        try? modelContext.save()
        await loadCategories()
    }
    
    func updateCategory(_ category: Category) async {
        try? modelContext.save()
        await loadCategories()
    }
    
    func deleteCategory(_ category: Category) async {
        // 将该分类下的笔记移动到默认分类
        let defaultCategory = categories.first { $0.isDefault }
        for note in category.notes {
            note.category = defaultCategory
        }
        
        modelContext.delete(category)
        try? modelContext.save()
        await loadCategories()
        await loadNotes()
    }
    
    // MARK: - 笔记管理
    func loadNotes(category: Category? = nil, searchQuery: String? = nil) async {
        var descriptor = FetchDescriptor<CollectedNote>(
            sortBy: [SortDescriptor(\.syncDate, order: .reverse)]
        )
        
        // 构建过滤条件
        if let category = category, !category.isDefault {
            // 有分类条件
            let categoryId = category.id
            if let query = searchQuery, !query.isEmpty {
                // 同时有分类和搜索条件
                descriptor.predicate = #Predicate<CollectedNote> { note in
                    note.category?.id == categoryId && note.title.contains(query)
                }
            } else {
                // 只有分类条件
                descriptor.predicate = #Predicate<CollectedNote> { note in
                    note.category?.id == categoryId
                }
            }
        } else if let query = searchQuery, !query.isEmpty {
            // 只有搜索条件
            descriptor.predicate = #Predicate<CollectedNote> { note in
                note.title.contains(query)
            }
        }
        
        do {
            notes = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load notes: \(error)")
        }
    }
    
    func saveNote(_ note: CollectedNote) async {
        // 自动分类
        if note.category == nil {
            note.category = await categorizeNote(note)
        }
        
        modelContext.insert(note)
        try? modelContext.save()
        await loadNotes()
    }
    
    func updateNote(_ note: CollectedNote) async {
        try? modelContext.save()
        await loadNotes()
    }
    
    func deleteNote(_ note: CollectedNote) async {
        modelContext.delete(note)
        try? modelContext.save()
        await loadNotes()
    }
    
    func deleteNotes(_ notes: [CollectedNote]) async {
        for note in notes {
            modelContext.delete(note)
        }
        try? modelContext.save()
        await loadNotes()
    }
    
    // MARK: - 智能分类
    private func categorizeNote(_ note: CollectedNote) async -> Category? {
        let content = [note.title, note.content, note.authorName].compactMap { $0 }.joined(separator: " ")
        let tags = note.tagsArray
        let allText = (content + " " + tags.joined(separator: " ")).lowercased()
        
        for category in categories where !category.isDefault {
            let keywords = category.keywordsArray
            for keyword in keywords {
                if allText.contains(keyword.lowercased()) {
                    return category
                }
            }
        }
        
        return categories.first { $0.isDefault }
    }
    
    func recategorizeAllNotes() async {
        isLoading = true
        
        for note in notes {
            if let newCategory = await categorizeNote(note) {
                note.category = newCategory
            }
        }
        
        try? modelContext.save()
        await loadNotes()
        isLoading = false
    }
    
    // MARK: - 搜索功能
    func searchNotes(query: String) async -> [CollectedNote] {
        let descriptor = FetchDescriptor<CollectedNote>(
            predicate: #Predicate { note in
                note.title.contains(query)
            },
            sortBy: [SortDescriptor(\.syncDate, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to search notes: \(error)")
            return []
        }
    }
    
    // MARK: - 统计信息
    func getStatistics() async -> (totalNotes: Int, categoriesCount: Int, todayNotes: Int) {
        let totalNotes = notes.count
        let categoriesCount = categories.filter { !$0.isDefault }.count
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let todayNotes = notes.filter { note in
            note.syncDate >= today && note.syncDate < tomorrow
        }.count
        
        return (totalNotes, categoriesCount, todayNotes)
    }
} 