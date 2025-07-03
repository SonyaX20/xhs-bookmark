//
//  CollectionListView.swift
//  rednote-col
//
//  Created by Siyu Xiao on 2025/7/3.
//

import SwiftUI
import SwiftData

struct CollectionListView: View {
    @EnvironmentObject private var dataService: DataService
    @State private var searchText = ""
    @State private var selectedCategory: Category?
    @State private var displayMode: DisplayMode = .grid
    @State private var showingSearch = false
    @State private var showingCategoryManager = false
    @State private var selectedNotes: Set<CollectedNote> = []
    @State private var showingDeleteAlert = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: Constants.UI.gridSpacing), count: Constants.UI.gridColumns)
    
    var filteredNotes: [CollectedNote] {
        var notes = dataService.notes
        
        // 分类筛选
        if let category = selectedCategory, !category.isDefault {
            notes = notes.filter { $0.category?.id == category.id }
        }
        
        // 搜索筛选
        if !searchText.isEmpty {
            notes = notes.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                (note.content?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (note.authorName?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return notes
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 顶部工具栏
                topToolbar
                
                // 分类筛选栏
                if !dataService.categories.isEmpty {
                    CategoryFilterBar(
                        categories: dataService.categories,
                        selectedCategory: $selectedCategory
                    )
                }
                
                // 同步状态栏
                syncStatusBar
                
                // 主内容区域
                mainContent
            }
            .navigationTitle("收藏管理")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, isPresented: $showingSearch)
            .refreshable {
                await refreshData()
            }
        }
        .sheet(isPresented: $showingCategoryManager) {
            CategoryManagementView()
        }
        .alert("删除收藏", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteSelectedNotes()
            }
        } message: {
            Text("确定要删除选中的 \(selectedNotes.count) 条收藏吗？此操作不可撤销。")
        }
    }
    
    // MARK: - 顶部工具栏
    private var topToolbar: some View {
        HStack {
            // 搜索按钮
            Button {
                showingSearch.toggle()
            } label: {
                Image(systemName: Constants.Icons.search)
                    .foregroundColor(Constants.Colors.primary)
            }
            
            Spacer()
            
            // 视图模式切换
            Button {
                withAnimation(Constants.Animation.spring) {
                    displayMode = displayMode == .grid ? .list : .grid
                }
            } label: {
                Image(systemName: displayMode == .grid ? Constants.Icons.list : Constants.Icons.grid)
                    .foregroundColor(Constants.Colors.primary)
            }
            
            // 分类管理
            Button {
                showingCategoryManager = true
            } label: {
                Image(systemName: Constants.Icons.category)
                    .foregroundColor(Constants.Colors.primary)
            }
            
            // 删除按钮（多选模式）
            if !selectedNotes.isEmpty {
                Button {
                    showingDeleteAlert = true
                } label: {
                    Image(systemName: Constants.Icons.delete)
                        .foregroundColor(Constants.Colors.error)
                }
            }
        }
        .padding(.horizontal, Constants.UI.padding)
        .padding(.vertical, Constants.UI.smallPadding)
    }
    
    // MARK: - 同步状态栏
    private var syncStatusBar: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(Constants.Colors.textSecondary)
            
            Text("最后同步: 2小时前")
                .font(Constants.Fonts.caption)
                .foregroundColor(Constants.Colors.textSecondary)
            
            Spacer()
            
            Text("共 \(dataService.notes.count) 条收藏")
                .font(Constants.Fonts.caption)
                .foregroundColor(Constants.Colors.textSecondary)
        }
        .padding(.horizontal, Constants.UI.padding)
        .padding(.vertical, Constants.UI.smallPadding)
        .background(Constants.Colors.background)
    }
    
    // MARK: - 主内容
    private var mainContent: some View {
        Group {
            if dataService.isLoading {
                LoadingView()
            } else if filteredNotes.isEmpty {
                EmptyStateView()
            } else {
                notesList
            }
        }
    }
    
    // MARK: - 笔记列表
    private var notesList: some View {
        ScrollView {
            LazyVGrid(columns: displayMode == .grid ? columns : [GridItem(.flexible())], spacing: Constants.UI.gridSpacing) {
                ForEach(filteredNotes, id: \.id) { note in
                    NoteCardView(
                        note: note,
                        displayMode: displayMode,
                        isSelected: selectedNotes.contains(note),
                        onTap: {
                            handleNoteTap(note)
                        },
                        onLongPress: {
                            handleNoteLongPress(note)
                        }
                    )
                }
            }
            .padding(.horizontal, Constants.UI.padding)
        }
    }
    
    // MARK: - 事件处理
    private func handleNoteTap(_ note: CollectedNote) {
        if selectedNotes.isEmpty {
            // 普通点击 - 导航到详情页
            // TODO: 实现详情页导航
        } else {
            // 多选模式 - 切换选中状态
            toggleNoteSelection(note)
        }
    }
    
    private func handleNoteLongPress(_ note: CollectedNote) {
        // 长按开始多选模式
        withAnimation(Constants.Animation.spring) {
            toggleNoteSelection(note)
        }
    }
    
    private func toggleNoteSelection(_ note: CollectedNote) {
        if selectedNotes.contains(note) {
            selectedNotes.remove(note)
        } else {
            selectedNotes.insert(note)
        }
    }
    
    private func deleteSelectedNotes() {
        Task {
            await dataService.deleteNotes(Array(selectedNotes))
            selectedNotes.removeAll()
        }
    }
    
    private func refreshData() async {
        await dataService.loadNotes()
        await dataService.loadCategories()
    }
}

// MARK: - 分类筛选栏
struct CategoryFilterBar: View {
    let categories: [Category]
    @Binding var selectedCategory: Category?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Constants.UI.smallPadding) {
                // 全部分类
                CategoryFilterChip(
                    title: "全部",
                    isSelected: selectedCategory == nil,
                    color: Constants.Colors.textSecondary
                ) {
                    selectedCategory = nil
                }
                
                // 各个分类
                ForEach(categories.filter { !$0.isDefault }, id: \.id) { category in
                    CategoryFilterChip(
                        title: category.name,
                        count: category.notesCount,
                        isSelected: selectedCategory?.id == category.id,
                        color: Color(hex: category.colorHex)
                    ) {
                        selectedCategory = selectedCategory?.id == category.id ? nil : category
                    }
                }
            }
            .padding(.horizontal, Constants.UI.padding)
        }
        .padding(.vertical, Constants.UI.smallPadding)
    }
}

// MARK: - 分类筛选芯片
struct CategoryFilterChip: View {
    let title: String
    var count: Int?
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(Constants.Fonts.caption)
                
                if let count = count, count > 0 {
                    Text("(\(count))")
                        .font(Constants.Fonts.small)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                    .fill(isSelected ? color : Constants.Colors.background)
            )
            .foregroundColor(isSelected ? .white : Constants.Colors.textPrimary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 空状态视图
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: Constants.UI.padding) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(Constants.Colors.textSecondary)
            
            Text("暂无收藏")
                .font(Constants.Fonts.headline)
                .foregroundColor(Constants.Colors.textPrimary)
            
            Text("前往同步页面获取您的小红书收藏")
                .font(Constants.Fonts.body)
                .foregroundColor(Constants.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Constants.UI.largePadding)
    }
}

// MARK: - 加载视图
struct LoadingView: View {
    var body: some View {
        VStack(spacing: Constants.UI.padding) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("加载中...")
                .font(Constants.Fonts.body)
                .foregroundColor(Constants.Colors.textSecondary)
        }
        .padding(Constants.UI.largePadding)
    }
}

#Preview {
    CollectionListView()
        .environmentObject(DataService(modelContext: try! ModelContainer(for: CollectedNote.self, Category.self).mainContext))
        .modelContainer(for: [CollectedNote.self, Category.self], inMemory: true)
} 