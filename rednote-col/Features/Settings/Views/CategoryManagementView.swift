//
//  CategoryManagementView.swift
//  rednote-col
//
//  Created by Siyu Xiao on 2025/7/3.
//

import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @EnvironmentObject private var dataService: DataService
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddCategory = false
    @State private var showingEditCategory: Category?
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: Category?
    @State private var autoCategorizationEnabled = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 智能分类设置
                smartCategorizationSection
                
                // 分类列表
                categoriesListSection
                
                // 操作按钮区域
                actionButtonsSection
            }
            .navigationTitle("分类管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCategory = true
                    } label: {
                        Image(systemName: Constants.Icons.add)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            CategoryEditView()
        }
        .sheet(item: $showingEditCategory) { category in
            CategoryEditView(category: category)
        }
        .alert("删除分类", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {
                categoryToDelete = nil
            }
            Button("删除", role: .destructive) {
                if let category = categoryToDelete {
                    deleteCategory(category)
                }
            }
        } message: {
            if let category = categoryToDelete {
                Text("确定要删除分类「\(category.name)」吗？该分类下的所有收藏将移动到「未分类」。")
            }
        }
    }
    
    // MARK: - 智能分类设置
    private var smartCategorizationSection: some View {
        VStack(alignment: .leading, spacing: Constants.UI.padding) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(Constants.Colors.primary)
                
                Text("智能分类设置")
                    .font(Constants.Fonts.headline)
                    .foregroundColor(Constants.Colors.textPrimary)
            }
            
            VStack(spacing: Constants.UI.smallPadding) {
                Toggle("自动分类新收藏", isOn: $autoCategorizationEnabled)
                    .font(Constants.Fonts.body)
                
                if autoCategorizationEnabled {
                    Text("新同步的收藏将根据关键词自动分类")
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.textSecondary)
                }
            }
            
            // 重新分类按钮
            Button {
                Task {
                    await dataService.recategorizeAllNotes()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("重新分类所有收藏")
                }
                .font(Constants.Fonts.body)
                .foregroundColor(Constants.Colors.primary)
            }
            .disabled(dataService.isLoading)
        }
        .padding(Constants.UI.padding)
        .background(Constants.Colors.background)
    }
    
    // MARK: - 分类列表
    private var categoriesListSection: some View {
        List {
            ForEach(dataService.categories.filter { !$0.isDefault }, id: \.id) { category in
                CategoryRowView(
                    category: category,
                    onEdit: {
                        showingEditCategory = category
                    },
                    onDelete: {
                        categoryToDelete = category
                        showingDeleteAlert = true
                    }
                )
            }
            .onMove(perform: moveCategories)
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - 操作按钮
    private var actionButtonsSection: some View {
        HStack(spacing: Constants.UI.padding) {
            Button("导入规则") {
                // TODO: 实现导入功能
            }
            .buttonStyle(.bordered)
            
            Button("导出设置") {
                // TODO: 实现导出功能
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("完成") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(Constants.UI.padding)
        .background(Constants.Colors.background)
    }
    
    // MARK: - 私有方法
    private func deleteCategory(_ category: Category) {
        Task {
            await dataService.deleteCategory(category)
            categoryToDelete = nil
        }
    }
    
    private func moveCategories(from source: IndexSet, to destination: Int) {
        // TODO: 实现分类排序
    }
}

// MARK: - 分类行视图
struct CategoryRowView: View {
    let category: Category
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: Constants.UI.padding) {
            // 分类颜色指示器
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: category.colorHex))
                .frame(width: 12, height: 40)
            
            // 分类信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(category.name)
                        .font(Constants.Fonts.body)
                        .foregroundColor(Constants.Colors.textPrimary)
                    
                    Spacer()
                    
                    Text("(\(category.notesCount)条)")
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.textSecondary)
                }
                
                // 关键词
                if !category.keywordsArray.isEmpty {
                    Text("关键词: \(category.keywordsArray.prefix(5).joined(separator: ", "))")
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            // 操作按钮
            HStack(spacing: Constants.UI.smallPadding) {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: Constants.Icons.edit)
                        .foregroundColor(Constants.Colors.primary)
                }
                
                Button {
                    onDelete()
                } label: {
                    Image(systemName: Constants.Icons.delete)
                        .foregroundColor(Constants.Colors.error)
                }
            }
        }
        .padding(.vertical, Constants.UI.smallPadding)
    }
}

// MARK: - 分类编辑视图
struct CategoryEditView: View {
    @EnvironmentObject private var dataService: DataService
    @Environment(\.dismiss) private var dismiss
    
    let category: Category?
    
    @State private var name: String
    @State private var colorHex: String
    @State private var keywords: String
    @State private var keywordInput: String = ""
    
    private let predefinedColors = [
        "#FF6B94", "#6B73FF", "#FF9F40", "#4ECDC4",
        "#95E1D3", "#A8E6CF", "#FFB6C1", "#DDA0DD",
        "#87CEEB", "#F0E68C", "#FFA07A", "#98FB98"
    ]
    
    init(category: Category? = nil) {
        self.category = category
        _name = State(initialValue: category?.name ?? "")
        _colorHex = State(initialValue: category?.colorHex ?? "#FF6B35")
        _keywords = State(initialValue: category?.keywordsArray.joined(separator: ", ") ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("分类信息") {
                    TextField("分类名称", text: $name)
                    
                    VStack(alignment: .leading, spacing: Constants.UI.smallPadding) {
                        Text("分类颜色")
                            .font(Constants.Fonts.caption)
                            .foregroundColor(Constants.Colors.textSecondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                            ForEach(predefinedColors, id: \.self) { color in
                                Button {
                                    colorHex = color
                                } label: {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(colorHex == color ? Constants.Colors.textPrimary : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }
                }
                
                Section("关键词设置") {
                    VStack(alignment: .leading, spacing: Constants.UI.smallPadding) {
                        HStack {
                            TextField("添加关键词", text: $keywordInput)
                                .onSubmit {
                                    addKeyword()
                                }
                            
                            Button("添加") {
                                addKeyword()
                            }
                            .disabled(keywordInput.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        
                        Text("关键词 (用逗号分隔)")
                            .font(Constants.Fonts.caption)
                            .foregroundColor(Constants.Colors.textSecondary)
                        
                        TextEditor(text: $keywords)
                            .frame(minHeight: 80)
                    }
                }
                
                Section("预览") {
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: colorHex))
                            .frame(width: 12, height: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(name.isEmpty ? "分类名称" : name)
                                .font(Constants.Fonts.body)
                                .foregroundColor(Constants.Colors.textPrimary)
                            
                            if !keywords.isEmpty {
                                Text("关键词: \(keywords)")
                                    .font(Constants.Fonts.caption)
                                    .foregroundColor(Constants.Colors.textSecondary)
                                    .lineLimit(2)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, Constants.UI.smallPadding)
                }
            }
            .navigationTitle(category == nil ? "新建分类" : "编辑分类")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveCategory()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func addKeyword() {
        let trimmed = keywordInput.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            if keywords.isEmpty {
                keywords = trimmed
            } else {
                keywords += ", " + trimmed
            }
            keywordInput = ""
        }
    }
    
    private func saveCategory() {
        Task {
            let keywordsArray = keywords.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            
            if let category = category {
                // 编辑现有分类
                category.name = name.trimmingCharacters(in: .whitespaces)
                category.colorHex = colorHex
                category.setKeywords(keywordsArray)
                
                await dataService.updateCategory(category)
            } else {
                // 创建新分类
                let newCategory = Category(
                    name: name.trimmingCharacters(in: .whitespaces),
                    keywords: keywordsArray,
                    colorHex: colorHex
                )
                
                await dataService.saveCategory(newCategory)
            }
            
            dismiss()
        }
    }
}

#Preview {
    CategoryManagementView()
        .environmentObject(DataService(modelContext: try! ModelContainer(for: Category.self).mainContext))
} 