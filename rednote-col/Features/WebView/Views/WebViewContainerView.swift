//
//  WebViewContainerView.swift
//  rednote-col
//
//  Created by Siyu Xiao on 2025/7/3.
//

import SwiftUI
import SwiftData
import WebKit

struct WebViewContainerView: View {
    @EnvironmentObject private var webViewService: WebViewService
    @EnvironmentObject private var dataService: DataService
    @State private var showingPreview = false
    @State private var showingHelp = false
    @State private var showingQuickActions = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 顶部工具栏
                topToolbar
                
                // 登录状态提示
                if !webViewService.isLoggedIn {
                    loginStatusBanner
                }
                
                // 同步进度条
                if webViewService.isLoading || webViewService.syncProgress > 0 {
                    syncProgressView
                }
                
                // WebView区域
                WebViewRepresentable(webViewService: webViewService)
                    .onAppear {
                        webViewService.setDataService(dataService)
                    }
                
                // 底部操作栏
                bottomToolbar
            }
            .navigationTitle("小红书同步")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        quickActionsMenu
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingPreview) {
            SyncPreviewView()
        }
        .sheet(isPresented: $showingHelp) {
            SyncHelpView()
        }
        .alert("同步错误", isPresented: .constant(webViewService.errorMessage != nil)) {
            Button("确定") {
                webViewService.errorMessage = nil
            }
        } message: {
            if let error = webViewService.errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - 顶部工具栏
    private var topToolbar: some View {
        HStack {
            // 导航按钮组
            HStack(spacing: Constants.UI.smallPadding) {
                Button {
                    webViewService.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(!webViewService.canGoBack)
                
                Button {
                    webViewService.goForward()
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(!webViewService.canGoForward)
                
                Button {
                    webViewService.reload()
                } label: {
                    Image(systemName: Constants.Icons.refresh)
                }
            }
            
            Spacer()
            
            // 页面信息
            VStack(alignment: .center, spacing: 2) {
                if !webViewService.pageTitle.isEmpty {
                    Text(webViewService.pageTitle)
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.textPrimary)
                        .lineLimit(1)
                }
                
                if let url = webViewService.currentURL {
                    Text(url.host ?? "")
                        .font(Constants.Fonts.small)
                        .foregroundColor(Constants.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // 功能按钮组
            HStack(spacing: Constants.UI.smallPadding) {
                Button {
                    showingHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                }
                
                Button {
                    showingQuickActions = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .padding(.horizontal, Constants.UI.padding)
        .padding(.vertical, Constants.UI.smallPadding)
        .background(Constants.Colors.background)
        .overlay(
            Divider(), alignment: .bottom
        )
    }
    
    // MARK: - 登录状态横幅
    private var loginStatusBanner: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.orange)
                Text("未登录")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Spacer()
                
                // 手动检测按钮
                Button("检测登录") {
                    webViewService.manualCheckLoginStatus()
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(6)
                
                Button("去登录") {
                    webViewService.loadRedBookLogin()
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
            
            Text("请先登录小红书账号以开始同步收藏")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 调试信息显示
            if !webViewService.debugInfo.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("检测详情:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text(webViewService.debugInfo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 8)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .border(Color.orange.opacity(0.3), width: 1)
    }
    
    // MARK: - 同步进度视图
    private var syncProgressView: some View {
        VStack(spacing: Constants.UI.smallPadding) {
            // 进度条
            ProgressView(value: webViewService.syncProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: Constants.Colors.primary))
            
            // 进度文本
            HStack {
                if let session = webViewService.currentSession {
                    Text(session.syncStatus.displayName)
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.textSecondary)
                    
                    Spacer()
                    
                    if session.totalCount > 0 {
                        Text("\(session.syncedCount)/\(session.totalCount)")
                            .font(Constants.Fonts.caption)
                            .foregroundColor(Constants.Colors.textSecondary)
                    } else {
                        Text("已获取 \(session.syncedCount) 条")
                            .font(Constants.Fonts.caption)
                            .foregroundColor(Constants.Colors.textSecondary)
                    }
                }
            }
        }
        .padding(.horizontal, Constants.UI.padding)
        .padding(.vertical, Constants.UI.smallPadding)
        .background(Constants.Colors.background)
        .overlay(
            Divider(), alignment: .bottom
        )
    }
    
    // MARK: - 底部操作栏
    private var bottomToolbar: some View {
        VStack(spacing: Constants.UI.smallPadding) {
            // 状态提示
            statusMessage
            
            // 操作按钮
            actionButtons
        }
        .padding(Constants.UI.padding)
        .background(Constants.Colors.background)
        .overlay(
            Divider(), alignment: .top
        )
    }
    
    private var statusMessage: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if webViewService.currentSession?.syncStatus.isActive == true {
                    Text("正在同步收藏数据...")
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.primary)
                } else if !webViewService.isLoggedIn {
                    Text("请先登录小红书账号")
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.warning)
                } else {
                    Text("请导航到收藏夹页面后开始同步")
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.textSecondary)
                }
                
                if !webViewService.extractedNotes.isEmpty {
                    Text("已获取 \(webViewService.extractedNotes.count) 条记录")
                        .font(Constants.Fonts.small)
                        .foregroundColor(Constants.Colors.success)
                }
            }
            
            Spacer()
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: Constants.UI.smallPadding) {
            // 快速导航按钮
            if webViewService.isLoggedIn {
                Button {
                    webViewService.loadRedBookCollection()
                } label: {
                    Label("收藏夹", systemImage: "heart")
                        .font(Constants.Fonts.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            // 预览按钮
            if !webViewService.extractedNotes.isEmpty {
                Button {
                    showingPreview = true
                } label: {
                    Label("预览", systemImage: "eye")
                        .font(Constants.Fonts.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Spacer()
            
            // 主要操作按钮
            if webViewService.currentSession?.syncStatus.isActive == true {
                // 暂停/恢复和停止按钮
                HStack(spacing: Constants.UI.smallPadding) {
                    Button {
                        if webViewService.currentSession?.syncStatus == .running {
                            webViewService.pauseSync()
                        } else {
                            webViewService.resumeSync()
                        }
                    } label: {
                        Image(systemName: webViewService.currentSession?.syncStatus == .running ? Constants.Icons.pause : Constants.Icons.play)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button {
                        webViewService.stopSync()
                    } label: {
                        Image(systemName: Constants.Icons.stop)
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                // 开始同步按钮
                Button {
                    webViewService.startSync()
                } label: {
                    Label("开始同步", systemImage: "arrow.2.circlepath")
                        .font(Constants.Fonts.caption)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!webViewService.isLoggedIn)
            }
        }
    }
    
    // MARK: - 快速操作菜单
    private var quickActionsMenu: some View {
        Group {
            Button {
                webViewService.loadRedBookHome()
            } label: {
                Label("小红书首页", systemImage: "house")
            }
            
            if !webViewService.isLoggedIn {
                Button {
                    webViewService.loadRedBookLogin()
                } label: {
                    Label("去登录", systemImage: "person.circle")
                }
            } else {
                Button {
                    webViewService.loadRedBookCollection()
                } label: {
                    Label("我的收藏", systemImage: "heart")
                }
                
                Button {
                    webViewService.navigateToUserProfile()
                } label: {
                    Label("个人资料", systemImage: "person")
                }
            }
            
            Divider()
            
            Button {
                showingHelp = true
            } label: {
                Label("使用帮助", systemImage: "questionmark.circle")
            }
            
            Button {
                webViewService.clearData()
            } label: {
                Label("清除数据", systemImage: "trash")
            }
        }
    }
}

// MARK: - WebView Representable
struct WebViewRepresentable: UIViewRepresentable {
    let webViewService: WebViewService
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = webViewService.setupWebView()
        
        // 默认加载小红书首页
        DispatchQueue.main.async {
            webViewService.loadRedBookHome()
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 更新WebView（如果需要）
    }
}

// MARK: - 同步预览视图
struct SyncPreviewView: View {
    @EnvironmentObject private var webViewService: WebViewService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if webViewService.extractedNotes.isEmpty {
                    ContentUnavailableView(
                        "暂无数据",
                        systemImage: "tray",
                        description: Text("还没有提取到收藏数据")
                    )
                } else {
                    List(webViewService.extractedNotes, id: \.id) { note in
                        NotePreviewRow(note: note)
                    }
                }
            }
            .navigationTitle("同步预览 (\(webViewService.extractedNotes.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !webViewService.extractedNotes.isEmpty {
                        Button("保存全部") {
                            // TODO: 批量保存功能
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 笔记预览行
struct NotePreviewRow: View {
    let note: CollectedNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.title)
                .font(Constants.Fonts.body)
                .foregroundColor(Constants.Colors.textPrimary)
                .lineLimit(2)
            
            if let content = note.content {
                Text(content)
                    .font(Constants.Fonts.caption)
                    .foregroundColor(Constants.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            HStack {
                if let authorName = note.authorName {
                    Label(authorName, systemImage: "person.circle")
                        .font(Constants.Fonts.small)
                        .foregroundColor(Constants.Colors.textSecondary)
                }
                
                Spacer()
                
                Text("刚刚获取")
                    .font(Constants.Fonts.small)
                    .foregroundColor(Constants.Colors.success)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 同步帮助视图
struct SyncHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.UI.padding) {
                    helpSection(
                        title: "使用步骤",
                        content: """
                        1. 点击右上角菜单选择"去登录"
                        2. 在网页中登录您的小红书账号
                        3. 登录成功后点击"我的收藏"
                        4. 在收藏页面点击"开始同步"
                        5. 等待数据提取完成
                        """,
                        icon: "list.number"
                    )
                    
                    helpSection(
                        title: "功能说明",
                        content: """
                        • 自动检测登录状态
                        • 智能识别收藏页面
                        • 支持暂停和恢复同步
                        • 实时显示同步进度
                        • 自动保存到本地数据库
                        """,
                        icon: "star.circle"
                    )
                    
                    helpSection(
                        title: "注意事项",
                        content: """
                        • 请保持网络连接稳定
                        • 同步过程中请勿关闭应用
                        • 首次同步可能需要较长时间
                        • 建议在WiFi环境下进行同步
                        • 数据完全存储在本地设备
                        """,
                        icon: "exclamationmark.triangle"
                    )
                    
                    helpSection(
                        title: "常见问题",
                        content: """
                        Q: 为什么显示未登录？
                        A: 请确保在网页中正确登录小红书账号
                        
                        Q: 同步失败怎么办？
                        A: 检查网络连接，确保在收藏页面
                        
                        Q: 可以中途暂停吗？
                        A: 可以，点击暂停按钮即可暂停同步
                        
                        Q: 数据存储在哪里？
                        A: 所有数据都存储在您的设备本地
                        """,
                        icon: "questionmark.circle"
                    )
                }
                .padding(Constants.UI.padding)
            }
            .navigationTitle("使用帮助")
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
    
    private func helpSection(title: String, content: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: Constants.UI.smallPadding) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Constants.Colors.primary)
                    .frame(width: 24)
                
                Text(title)
                    .font(Constants.Fonts.headline)
                    .foregroundColor(Constants.Colors.textPrimary)
            }
            
            Text(content)
                .font(Constants.Fonts.body)
                .foregroundColor(Constants.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Constants.UI.padding)
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(Constants.Colors.background)
        )
    }
}

#Preview {
    WebViewContainerView()
        .environmentObject(WebViewService())
        .environmentObject(DataService(modelContext: try! ModelContainer(for: CollectedNote.self).mainContext))
} 