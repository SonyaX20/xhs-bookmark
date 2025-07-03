//
//  SettingsView.swift
//  rednote-col
//
//  Created by Siyu Xiao on 2025/7/3.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var dataService: DataService
    @State private var syncFrequency: SyncFrequency = .manual
    @State private var displayMode: DisplayMode = .grid
    @State private var autoCategorizationEnabled = true
    @State private var imageDownloadEnabled = true
    @State private var showingCategoryManager = false
    @State private var showingAbout = false
    @State private var showingDataExport = false
    @State private var showingClearCache = false
    
    var body: some View {
        NavigationStack {
            List {
                // 同步设置
                syncSettingsSection
                
                // 分类设置
                categorySettingsSection
                
                // 界面设置
                interfaceSettingsSection
                
                // 数据管理
                dataManagementSection
                
                // 关于应用
                aboutSection
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingCategoryManager) {
            CategoryManagementView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .alert("清理缓存", isPresented: $showingClearCache) {
            Button("取消", role: .cancel) { }
            Button("清理", role: .destructive) {
                clearCache()
            }
        } message: {
            Text("这将清理所有缓存的图片数据，确定继续吗？")
        }
    }
    
    // MARK: - 同步设置
    private var syncSettingsSection: some View {
        Section {
            HStack {
                Image(systemName: Constants.Icons.sync)
                    .foregroundColor(Constants.Colors.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("自动同步频率")
                        .font(Constants.Fonts.body)
                    Text("设置自动同步的频率")
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.textSecondary)
                }
                
                Spacer()
                
                Picker("", selection: $syncFrequency) {
                    ForEach(SyncFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.displayName).tag(frequency)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            HStack {
                Image(systemName: "icloud.and.arrow.down")
                    .foregroundColor(Constants.Colors.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("下载图片")
                        .font(Constants.Fonts.body)
                    Text("自动下载并缓存图片")
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.textSecondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $imageDownloadEnabled)
            }
            
            NavigationLink {
                SyncHistoryView()
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(Constants.Colors.primary)
                        .frame(width: 24)
                    
                    Text("同步历史")
                        .font(Constants.Fonts.body)
                    
                    Spacer()
                }
            }
        } header: {
            Text("同步设置")
        }
    }
    
    // MARK: - 分类设置
    private var categorySettingsSection: some View {
        Section {
            Button {
                showingCategoryManager = true
            } label: {
                HStack {
                    Image(systemName: Constants.Icons.category)
                        .foregroundColor(Constants.Colors.primary)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("分类管理")
                            .font(Constants.Fonts.body)
                            .foregroundColor(Constants.Colors.textPrimary)
                        Text("管理收藏分类和关键词")
                            .font(Constants.Fonts.caption)
                            .foregroundColor(Constants.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Constants.Colors.textSecondary)
                }
            }
            
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(Constants.Colors.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("智能分类")
                        .font(Constants.Fonts.body)
                    Text("自动为新收藏分类")
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.textSecondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $autoCategorizationEnabled)
            }
        } header: {
            Text("分类设置")
        }
    }
    
    // MARK: - 界面设置
    private var interfaceSettingsSection: some View {
        Section {
            HStack {
                Image(systemName: displayMode.icon)
                    .foregroundColor(Constants.Colors.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("显示方式")
                        .font(Constants.Fonts.body)
                    Text("选择收藏的显示模式")
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.textSecondary)
                }
                
                Spacer()
                
                Picker("", selection: $displayMode) {
                    ForEach(DisplayMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        } header: {
            Text("界面设置")
        }
    }
    
    // MARK: - 数据管理
    private var dataManagementSection: some View {
        Section {
            NavigationLink {
                StorageInfoView()
            } label: {
                HStack {
                    Image(systemName: "internaldrive")
                        .foregroundColor(Constants.Colors.primary)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("存储占用")
                            .font(Constants.Fonts.body)
                        Text("查看存储使用情况")
                            .font(Constants.Fonts.caption)
                            .foregroundColor(Constants.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
            }
            
            Button {
                showingClearCache = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(Constants.Colors.warning)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("清理缓存")
                            .font(Constants.Fonts.body)
                            .foregroundColor(Constants.Colors.textPrimary)
                        Text("清理图片和临时文件")
                            .font(Constants.Fonts.caption)
                            .foregroundColor(Constants.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
            }
            
            Button {
                showingDataExport = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Constants.Colors.primary)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("导出数据")
                            .font(Constants.Fonts.body)
                            .foregroundColor(Constants.Colors.textPrimary)
                        Text("导出收藏数据为JSON文件")
                            .font(Constants.Fonts.caption)
                            .foregroundColor(Constants.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
            }
            
            // 开发调试功能
            #if DEBUG
            Button {
                Task {
                    await SampleDataGenerator.generateSampleData(dataService: dataService)
                }
            } label: {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(Constants.Colors.secondary)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("生成示例数据")
                            .font(Constants.Fonts.body)
                            .foregroundColor(Constants.Colors.textPrimary)
                        Text("仅开发模式可用")
                            .font(Constants.Fonts.caption)
                            .foregroundColor(Constants.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
            }
            #endif
        } header: {
            Text("数据管理")
        }
    }
    
    // MARK: - 关于应用
    private var aboutSection: some View {
        Section {
            Button {
                showingAbout = true
            } label: {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(Constants.Colors.primary)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("关于应用")
                            .font(Constants.Fonts.body)
                            .foregroundColor(Constants.Colors.textPrimary)
                        Text("版本 \(Constants.appVersion)")
                            .font(Constants.Fonts.caption)
                            .foregroundColor(Constants.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Constants.Colors.textSecondary)
                }
            }
        } header: {
            Text("关于")
        }
    }
    
    // MARK: - 私有方法
    private func clearCache() {
        Task {
            // TODO: 实现缓存清理
            print("清理缓存")
        }
    }
}

// MARK: - 存储信息视图
struct StorageInfoView: View {
    @State private var storageInfo: StorageInfo?
    
    var body: some View {
        List {
            if let info = storageInfo {
                Section("存储使用情况") {
                    StorageRowView(title: "收藏数据", size: info.databaseSize)
                    StorageRowView(title: "图片缓存", size: info.imagesCacheSize)
                    StorageRowView(title: "临时文件", size: info.tempFilesSize)
                    StorageRowView(title: "总计", size: info.totalSize, isTotal: true)
                }
            } else {
                Section {
                    HStack {
                        ProgressView()
                        Text("计算中...")
                            .foregroundColor(Constants.Colors.textSecondary)
                    }
                }
            }
        }
        .navigationTitle("存储占用")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            calculateStorageInfo()
        }
    }
    
    private func calculateStorageInfo() {
        Task {
            // TODO: 实际计算存储占用
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 模拟计算
            
            storageInfo = StorageInfo(
                databaseSize: 1024 * 1024 * 5,     // 5MB
                imagesCacheSize: 1024 * 1024 * 25, // 25MB
                tempFilesSize: 1024 * 1024 * 2,    // 2MB
                totalSize: 1024 * 1024 * 32        // 32MB
            )
        }
    }
}

// MARK: - 存储行视图
struct StorageRowView: View {
    let title: String
    let size: Int64
    let isTotal: Bool
    
    init(title: String, size: Int64, isTotal: Bool = false) {
        self.title = title
        self.size = size
        self.isTotal = isTotal
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(isTotal ? Constants.Fonts.headline : Constants.Fonts.body)
                .foregroundColor(Constants.Colors.textPrimary)
            
            Spacer()
            
            Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                .font(isTotal ? Constants.Fonts.headline : Constants.Fonts.caption)
                .foregroundColor(isTotal ? Constants.Colors.primary : Constants.Colors.textSecondary)
        }
    }
}

// MARK: - 数据结构
struct StorageInfo {
    let databaseSize: Int64
    let imagesCacheSize: Int64
    let tempFilesSize: Int64
    let totalSize: Int64
}

// MARK: - 同步历史视图
struct SyncHistoryView: View {
    var body: some View {
        List {
            // TODO: 实现同步历史
            Text("同步历史功能开发中...")
                .foregroundColor(Constants.Colors.textSecondary)
        }
        .navigationTitle("同步历史")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 关于视图
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.UI.largePadding) {
                    // 应用图标和名称
                    VStack(spacing: Constants.UI.padding) {
                        Image(systemName: Constants.Icons.collection)
                            .font(.system(size: 80))
                            .foregroundColor(Constants.Colors.primary)
                        
                        Text(Constants.appName)
                            .font(Constants.Fonts.title)
                            .foregroundColor(Constants.Colors.textPrimary)
                        
                        Text("版本 \(Constants.appVersion)")
                            .font(Constants.Fonts.body)
                            .foregroundColor(Constants.Colors.textSecondary)
                    }
                    
                    // 应用描述
                    VStack(alignment: .leading, spacing: Constants.UI.padding) {
                        Text("应用介绍")
                            .font(Constants.Fonts.headline)
                            .foregroundColor(Constants.Colors.textPrimary)
                        
                        Text("这是一款专为小红书用户设计的收藏管理工具，帮助您更好地整理和管理收藏的笔记内容。")
                            .font(Constants.Fonts.body)
                            .foregroundColor(Constants.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // 功能特点
                    VStack(alignment: .leading, spacing: Constants.UI.padding) {
                        Text("主要功能")
                            .font(Constants.Fonts.headline)
                            .foregroundColor(Constants.Colors.textPrimary)
                        
                        VStack(alignment: .leading, spacing: Constants.UI.smallPadding) {
                            FeatureRowView(icon: "arrow.2.circlepath", title: "智能同步", description: "自动获取您的小红书收藏")
                            FeatureRowView(icon: "folder", title: "智能分类", description: "根据内容自动分类整理")
                            FeatureRowView(icon: "magnifyingglass", title: "快速搜索", description: "快速找到需要的收藏内容")
                            FeatureRowView(icon: "icloud", title: "本地存储", description: "数据安全存储在本地设备")
                        }
                    }
                    
                    Spacer(minLength: Constants.UI.largePadding)
                }
                .padding(Constants.UI.largePadding)
            }
            .navigationTitle("关于应用")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 功能行视图
struct FeatureRowView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: Constants.UI.padding) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Constants.Colors.primary)
                .frame(width: 30, alignment: .center)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Constants.Fonts.body)
                    .foregroundColor(Constants.Colors.textPrimary)
                
                Text(description)
                    .font(Constants.Fonts.caption)
                    .foregroundColor(Constants.Colors.textSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - 示例数据生成器
#if DEBUG
struct SampleDataGenerator {
    static func generateSampleData(dataService: DataService) async {
        let sampleTitles = [
            "夏日清爽护肤攻略｜敏感肌也能用",
            "超简单的家常菜做法分享",
            "日系穿搭 | 温柔又显白的夏日look",
            "旅行必备物品清单 | 女生版",
            "高颜值早餐制作教程",
            "学生党平价化妆品推荐",
            "居家收纳小技巧分享",
            "减肥期间的营养搭配建议",
            "小户型装修设计灵感",
            "手工DIY | 简单又实用的小物件"
        ]
        
        let sampleAuthors = [
            "美妆小达人", "料理新手", "穿搭博主", "旅行日记",
            "早餐时光", "学生党", "收纳师", "健康生活",
            "设计师", "手工爱好者"
        ]
        
        let sampleContents = [
            "分享一些夏日护肤的小心得，特别适合敏感肌的姐妹们",
            "简单易学的家常菜，新手也能轻松掌握",
            "温柔系穿搭分享，让你在夏天也能保持优雅",
            "旅行必备清单，让你的旅程更加完美",
            "颜值超高的早餐制作方法，营养又美味",
            "学生党必看的平价好物推荐",
            "小空间大智慧，让家变得更整洁",
            "科学的营养搭配，健康减肥不反弹",
            "小户型也能装出大空间的感觉",
            "简单的手工制作，让生活更有趣"
        ]
        
        for i in 0..<10 {
            let note = CollectedNote(
                id: "sample_\(i)",
                title: sampleTitles[i],
                content: sampleContents[i],
                imageURL: "https://picsum.photos/300/400?random=\(i)",
                originalURL: "https://www.xiaohongshu.com/explore/sample_\(i)",
                authorName: sampleAuthors[i],
                tags: ["生活", "分享", "推荐"]
            )
            
            await dataService.saveNote(note)
        }
    }
}
#endif

#Preview {
    SettingsView()
        .environmentObject(DataService(modelContext: try! ModelContainer(for: CollectedNote.self).mainContext))
} 