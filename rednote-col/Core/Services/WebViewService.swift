//
//  WebViewService.swift
//  rednote-col
//
//  Created by Siyu Xiao on 2025/7/3.
//

import Foundation
import WebKit
import SwiftUI

@MainActor
class WebViewService: NSObject, ObservableObject {
    @Published var isLoading = false
    @Published var syncProgress: Double = 0.0
    @Published var currentSession: SyncSession?
    @Published var extractedNotes: [CollectedNote] = []
    @Published var errorMessage: String?
    @Published var isLoggedIn = false
    @Published var currentURL: URL?
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var pageTitle = ""
    @Published var lastSyncDate: Date?
    @Published var debugInfo: String = ""
    
    private var webView: WKWebView?
    private var dataService: DataService?
    private var loginCheckTimer: Timer?
    
    // MARK: - WebView 配置
    func setupWebView() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()
        
        // 添加消息处理器
        configuration.userContentController.add(self, name: "dataExtractor")
        
        // 注入数据提取脚本
        if let scriptPath = Bundle.main.path(forResource: "DataExtractor", ofType: "js"),
           let scriptContent = try? String(contentsOfFile: scriptPath) {
            let userScript = WKUserScript(
                source: scriptContent,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: false
            )
            configuration.userContentController.addUserScript(userScript)
        }
        
        // 设置更真实的用户代理，确保小红书识别为正常浏览器
        configuration.applicationNameForUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        
        // 启用媒体播放和其他功能
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // 设置网站数据存储
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        
        // 设置首选项
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        
        // 设置自定义 User-Agent（备用方案）
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        
        self.webView = webView
        
        // 开始监控登录状态
        startLoginStatusMonitoring()
        
        return webView
    }
    
    func setDataService(_ dataService: DataService) {
        self.dataService = dataService
    }
    
    // MARK: - 登录状态管理
    private func startLoginStatusMonitoring() {
        loginCheckTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            // 在主线程上异步执行
            DispatchQueue.main.async { [weak self] in
                self?.checkLoginStatus()
            }
        }
    }
    
    private func checkLoginStatus() {
        guard webView != nil else { return }
        
        let script = """
        (function() {
            try {
                console.log('开始检测小红书登录状态...');
                
                // 方法1: 检测小红书号（最可靠的方式）
                const pageText = document.body.innerText || '';
                const hasRedBookId = /小红书号[：:]\\s*\\d+/.test(pageText);
                console.log('小红书号检测:', hasRedBookId);
                
                // 方法2: 检测用户统计数据（关注、粉丝、获赞）
                let hasUserStats = false;
                if (pageText.includes('关注') && pageText.includes('粉丝')) {
                    hasUserStats = true;
                }
                console.log('用户统计数据检测:', hasUserStats);
                
                // 方法3: 检测收藏相关元素（简化版）
                const hasCollectionText = pageText.includes('收藏') || pageText.includes('获赞与收藏');
                console.log('收藏文本检测:', hasCollectionText);
                
                // 方法4: 检测用户头像（简化版）
                const avatarElements = document.querySelectorAll('img');
                let hasUserAvatar = false;
                for (let img of avatarElements) {
                    const src = img.src || '';
                    const alt = img.alt || '';
                    if (src.includes('avatar') || alt.includes('头像') || alt.includes('用户')) {
                        hasUserAvatar = true;
                        break;
                    }
                }
                console.log('用户头像检测:', hasUserAvatar);
                
                // 方法5: 检测URL路径
                const url = window.location.href;
                const hasUserInUrl = url.includes('/user/') || url.includes('/profile/');
                console.log('URL路径检测:', hasUserInUrl, 'URL:', url);
                
                // 方法6: 检测localStorage和cookies
                let hasUserInStorage = false;
                try {
                    const localStorageKeys = Object.keys(localStorage);
                    hasUserInStorage = localStorageKeys.some(key => 
                        key.includes('user') || key.includes('auth') || key.includes('token')
                    );
                } catch(e) {
                    console.log('localStorage检测出错:', e);
                }
                
                const hasUserInCookies = document.cookie.includes('user') || 
                                       document.cookie.includes('token') || 
                                       document.cookie.includes('session');
                console.log('存储检测:', hasUserInStorage, 'Cookie检测:', hasUserInCookies);
                
                // 方法7: 检测登录按钮的反向逻辑
                let hasLoginButton = false;
                if (pageText.includes('登录') || pageText.includes('去登录')) {
                    // 进一步检查是否是登录按钮而不是其他含有"登录"的文本
                    const buttons = document.querySelectorAll('button, a');
                    for (let btn of buttons) {
                        const text = btn.textContent || btn.innerText || '';
                        if (text.trim() === '登录' || text.trim() === '去登录') {
                            hasLoginButton = true;
                            break;
                        }
                    }
                }
                console.log('登录按钮检测:', hasLoginButton);
                
                // 综合判断：多种方法中任何一种检测到登录状态就认为已登录
                const isLoggedIn = hasRedBookId || hasUserStats || hasCollectionText || 
                                 (hasUserAvatar && !hasLoginButton) || hasUserInUrl || 
                                 hasUserInStorage || hasUserInCookies;
                
                console.log('最终登录状态判断:', isLoggedIn);
                
                // 返回详细信息供调试
                return {
                    isLoggedIn: isLoggedIn,
                    hasRedBookId: hasRedBookId,
                    hasUserStats: hasUserStats,
                    hasCollectionText: hasCollectionText,
                    hasUserAvatar: hasUserAvatar,
                    hasUserInUrl: hasUserInUrl,
                    hasUserInStorage: hasUserInStorage,
                    hasUserInCookies: hasUserInCookies,
                    hasLoginButton: hasLoginButton,
                    currentUrl: url,
                    pageTitle: document.title,
                    bodyText: pageText.substring(0, 200) // 前200字符
                };
                
            } catch(error) {
                console.log('检测过程中出错:', error);
                return {
                    isLoggedIn: false,
                    error: error.toString(),
                    currentUrl: window.location.href,
                    pageTitle: document.title
                };
            }
        })();
        """
        
        webView!.evaluateJavaScript(script) { [weak self] result, error in
            Task { @MainActor in
                if let error = error {
                    print("登录状态检测出错: \(error)")
                    self?.debugInfo = "❌ 检测出错: \(error.localizedDescription)"
                    return
                }
                
                if let result = result as? [String: Any] {
                    let isLoggedIn = result["isLoggedIn"] as? Bool ?? false
                    
                    // 输出详细的调试信息
                    print("=== 小红书登录状态检测结果 ===")
                    print("最终判断: \(isLoggedIn ? "已登录" : "未登录")")
                    print("小红书号检测: \(result["hasRedBookId"] ?? false)")
                    print("用户统计检测: \(result["hasUserStats"] ?? false)")
                    print("收藏文本检测: \(result["hasCollectionText"] ?? false)")
                    print("用户头像检测: \(result["hasUserAvatar"] ?? false)")
                    print("URL路径检测: \(result["hasUserInUrl"] ?? false)")
                    print("存储检测: \(result["hasUserInStorage"] ?? false)")
                    print("Cookie检测: \(result["hasUserInCookies"] ?? false)")
                    print("登录按钮检测: \(result["hasLoginButton"] ?? false)")
                    print("当前URL: \(result["currentUrl"] ?? "未知")")
                    print("页面标题: \(result["pageTitle"] ?? "未知")")
                    print("页面内容: \(result["bodyText"] ?? "未知")")
                    if let errorMsg = result["error"] as? String {
                        print("JavaScript错误: \(errorMsg)")
                    }
                    print("=============================")
                    
                    // 更新调试信息到UI
                    let debugText = """
                    登录状态: \(isLoggedIn ? "✅ 已登录" : "❌ 未登录")
                    小红书号: \(result["hasRedBookId"] as? Bool == true ? "✅" : "❌")
                    用户统计: \(result["hasUserStats"] as? Bool == true ? "✅" : "❌") 
                    收藏文本: \(result["hasCollectionText"] as? Bool == true ? "✅" : "❌")
                    用户头像: \(result["hasUserAvatar"] as? Bool == true ? "✅" : "❌")
                    URL检测: \(result["hasUserInUrl"] as? Bool == true ? "✅" : "❌")
                    存储检测: \(result["hasUserInStorage"] as? Bool == true ? "✅" : "❌")
                    页面: \(result["pageTitle"] as? String ?? "未知")
                    """
                    self?.debugInfo = debugText
                    
                    self?.isLoggedIn = isLoggedIn
                    
                    // 如果检测到登录状态，清除错误信息
                    if isLoggedIn {
                        self?.errorMessage = nil
                    }
                }
            }
        }
    }
    
    // MARK: - 手动检测方法
    func manualCheckLoginStatus() {
        checkLoginStatus()
    }
    
    // MARK: - 导航功能
    func loadRedBookHome() {
        guard webView != nil else { return }
        let url = URL(string: "https://www.xiaohongshu.com")!
        let request = URLRequest(url: url)
        
        // 添加自定义请求头
        var mutableRequest = request
        mutableRequest.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        mutableRequest.setValue("zh-CN,zh;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        
        print("正在加载小红书首页: \(url)")
        webView!.load(mutableRequest)
    }
    
    func loadRedBookLogin() {
        guard webView != nil else { return }
        let url = URL(string: "https://www.xiaohongshu.com/login")!
        let request = URLRequest(url: url)
        
        var mutableRequest = request
        mutableRequest.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        mutableRequest.setValue("zh-CN,zh;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        
        print("正在加载小红书登录页: \(url)")
        webView!.load(mutableRequest)
    }
    
    func loadRedBookCollection() {
        guard webView != nil else { return }
        
        if !isLoggedIn {
            errorMessage = "请先登录小红书账号"
            return
        }
        
        // 先尝试通用的收藏页面路径
        let url = URL(string: "https://www.xiaohongshu.com/user/profile/me/collect")!
        let request = URLRequest(url: url)
        
        var mutableRequest = request
        mutableRequest.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        mutableRequest.setValue("zh-CN,zh;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        
        print("正在加载收藏页面: \(url)")
        webView!.load(mutableRequest)
    }
    
    func navigateToUserProfile() {
        guard webView != nil else { return }
        
        let script = """
        (function() {
            const profileLinks = document.querySelectorAll('a[href*="/user/profile"], a[href*="/profile"]');
            if (profileLinks.length > 0) {
                profileLinks[0].click();
                return true;
            }
            
            const userInfo = document.querySelector('.user-info, .avatar, [class*="user"]');
            if (userInfo) {
                userInfo.click();
                return true;
            }
            
            return false;
        })();
        """
        
        webView!.evaluateJavaScript(script) { [weak self] result, error in
            if let success = result as? Bool, !success {
                Task { @MainActor in
                    self?.errorMessage = "无法找到用户资料页面，请手动导航"
                }
            }
        }
    }
    
    // MARK: - 同步控制
    func startSync() {
        guard webView != nil else { return }
        
        if !isLoggedIn {
            errorMessage = "请先登录小红书账号"
            return
        }
        
        // 检查是否在收藏页面
        checkIfOnCollectionPage { [weak self] isOnCollectionPage in
            Task { @MainActor in
                if !isOnCollectionPage {
                    self?.errorMessage = "请先导航到收藏夹页面"
                    return
                }
                
                self?.startActualSync()
            }
        }
    }
    
    private func checkIfOnCollectionPage(completion: @escaping (Bool) -> Void) {
        guard webView != nil else {
            completion(false)
            return
        }
        
        let script = """
        (function() {
            const url = window.location.href;
            const hasCollectionInUrl = url.includes('/collect') || url.includes('/collection');
            const hasCollectionElements = document.querySelector('.collection-container, [data-testid="collection"], .note-item') !== null;
            
            return hasCollectionInUrl || hasCollectionElements;
        })();
        """
        
        webView!.evaluateJavaScript(script) { result, error in
            completion(result as? Bool ?? false)
        }
    }
    
    private func startActualSync() {
        guard webView != nil else { return }
        
        currentSession = SyncSession()
        currentSession?.syncStatus = .running
        isLoading = true
        syncProgress = 0.0
        extractedNotes = []
        errorMessage = nil
        
        // 发送开始提取命令到JavaScript
        let script = """
            if (window.RedBookDataExtractor) {
                window.RedBookDataExtractor.startExtraction();
            } else {
                // 如果提取器未加载，尝试重新初始化
                setTimeout(function() {
                    if (window.RedBookDataExtractor) {
                        window.RedBookDataExtractor.startExtraction();
                    }
                }, 1000);
            }
        """
        
        webView!.evaluateJavaScript(script) { [weak self] result, error in
            if let error = error {
                Task { @MainActor in
                    self?.handleError("启动同步失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func pauseSync() {
        guard webView != nil else { return }
        
        currentSession?.syncStatus = .paused
        
        let script = """
            if (window.RedBookDataExtractor) {
                window.RedBookDataExtractor.pauseExtraction();
            }
        """
        
        webView!.evaluateJavaScript(script, completionHandler: nil)
    }
    
    func resumeSync() {
        guard webView != nil else { return }
        
        currentSession?.syncStatus = .running
        
        let script = """
            if (window.RedBookDataExtractor) {
                window.RedBookDataExtractor.resumeExtraction();
            }
        """
        
        webView!.evaluateJavaScript(script, completionHandler: nil)
    }
    
    func stopSync() {
        guard webView != nil else { return }
        
        currentSession?.syncStatus = .cancelled
        currentSession?.endTime = Date()
        isLoading = false
        
        let script = """
            if (window.RedBookDataExtractor) {
                window.RedBookDataExtractor.stopExtraction();
            }
        """
        
        webView!.evaluateJavaScript(script, completionHandler: nil)
    }
    
    // MARK: - 数据处理
    private func handleExtractedData(_ data: [String: Any]) {
        Task {
            do {
                let note = try parseNoteData(data)
                extractedNotes.append(note)
                
                // 保存到数据库
                await dataService?.saveNote(note)
                
                // 更新同步进度
                currentSession?.syncedCount += 1
                updateProgress()
                
            } catch {
                print("Failed to parse note data: \(error)")
            }
        }
    }
    
    private func parseNoteData(_ data: [String: Any]) throws -> CollectedNote {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let originalURL = data["url"] as? String else {
            throw WebViewError.invalidData
        }
        
        let note = CollectedNote(
            id: id,
            title: title,
            content: data["content"] as? String,
            imageURL: data["imageURL"] as? String,
            originalURL: originalURL,
            authorName: data["authorName"] as? String,
            authorAvatar: data["authorAvatar"] as? String,
            tags: data["tags"] as? [String] ?? []
        )
        
        return note
    }
    
    private func updateProgress() {
        guard let session = currentSession else { return }
        syncProgress = session.progress
        
        if session.syncedCount >= session.totalCount && session.totalCount > 0 {
            completeSync()
        }
    }
    
    private func completeSync() {
        currentSession?.complete()
        isLoading = false
        syncProgress = 1.0
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        currentSession?.fail(with: message)
        isLoading = false
    }
    
    // MARK: - WebView 控制
    func goBack() {
        webView?.goBack()
    }
    
    func goForward() {
        webView?.goForward()
    }
    
    func reload() {
        webView?.reload()
    }
    
    func clearData() {
        guard webView != nil else { return }
        
        let websiteDataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let date = Date(timeIntervalSince1970: 0)
        
        webView!.configuration.websiteDataStore.removeData(ofTypes: websiteDataTypes, modifiedSince: date) { [weak self] in
            Task { @MainActor in
                self?.isLoggedIn = false
            }
        }
    }
    
    deinit {
        loginCheckTimer?.invalidate()
    }
}

// MARK: - WKScriptMessageHandler
extension WebViewService: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "dataExtractor",
              let body = message.body as? [String: Any],
              let type = body["type"] as? String else {
            return
        }
        
        switch type {
        case "initialized":
            print("数据提取器已初始化")
            
        case "progress":
            if let total = body["total"] as? Int,
               let current = body["current"] as? Int {
                currentSession?.totalCount = total
                currentSession?.syncedCount = current
                updateProgress()
            }
            
        case "data":
            if let noteData = body["data"] as? [String: Any] {
                handleExtractedData(noteData)
            }
            
        case "complete":
            completeSync()
            
        case "error":
            if let error = body["message"] as? String {
                handleError(error)
            }
            
        case "paused":
            currentSession?.syncStatus = .paused
            
        case "resumed":
            currentSession?.syncStatus = .running
            
        case "stopped":
            currentSession?.syncStatus = .cancelled
            isLoading = false
            
        default:
            break
        }
    }
}

// MARK: - WKNavigationDelegate
extension WebViewService: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
        currentURL = webView.url
        print("开始加载页面: \(webView.url?.absoluteString ?? "未知")")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        currentURL = webView.url
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        pageTitle = webView.title ?? ""
        
        print("页面加载完成: \(webView.url?.absoluteString ?? "未知")")
        print("页面标题: \(pageTitle)")
        
        // 页面加载完成后检查登录状态
        checkLoginStatus()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        let errorMsg = "页面加载失败: \(error.localizedDescription)"
        print("❌ \(errorMsg)")
        
        // 检查是否是网络连接问题
        if let nsError = error as NSError? {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                handleError("网络连接不可用，请检查网络设置")
            case NSURLErrorTimedOut:
                handleError("网络连接超时，请重试")
            case NSURLErrorCannotFindHost:
                handleError("无法找到服务器，请检查网络连接")
            case NSURLErrorCannotConnectToHost:
                handleError("无法连接到服务器")
            default:
                handleError(errorMsg)
            }
        } else {
            handleError(errorMsg)
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        let errorMsg = "页面请求失败: \(error.localizedDescription)"
        print("❌ \(errorMsg)")
        
        if let nsError = error as NSError? {
            print("错误代码: \(nsError.code)")
            print("错误域: \(nsError.domain)")
            print("错误详情: \(nsError.userInfo)")
            
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                handleError("网络连接不可用，请检查网络设置")
            case NSURLErrorTimedOut:
                handleError("请求超时，请重试")
            case NSURLErrorCannotFindHost:
                handleError("无法找到小红书服务器，请检查网络连接")
            case NSURLErrorAppTransportSecurityRequiresSecureConnection:
                handleError("网络安全设置限制，请检查应用配置")
            default:
                handleError("网络请求失败: \(nsError.localizedDescription)")
            }
        } else {
            handleError(errorMsg)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            print("导航请求: \(url.absoluteString)")
            
            // 允许小红书相关域名
            if url.host?.contains("xiaohongshu.com") == true ||
               url.host?.contains("xhscdn.com") == true ||
               url.scheme == "https" {
                decisionHandler(.allow)
            } else {
                print("⚠️ 阻止非 HTTPS 请求: \(url)")
                decisionHandler(.cancel)
            }
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let httpResponse = navigationResponse.response as? HTTPURLResponse {
            print("HTTP 响应码: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                decisionHandler(.allow)
            } else {
                print("❌ HTTP 错误响应: \(httpResponse.statusCode)")
                handleError("服务器响应错误 (\(httpResponse.statusCode))")
                decisionHandler(.cancel)
            }
        } else {
            decisionHandler(.allow)
        }
    }
}

// MARK: - WKUIDelegate
extension WebViewService: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // 在当前WebView中打开新窗口链接
        if let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        // 处理JavaScript alert
        DispatchQueue.main.async {
            self.errorMessage = message
        }
        completionHandler()
    }
}

// MARK: - Error Types
enum WebViewError: Error {
    case invalidData
    case networkError(String)
    case parseError(String)
    case notLoggedIn
    case notOnCollectionPage
    
    var localizedDescription: String {
        switch self {
        case .invalidData:
            return "数据格式不正确"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .parseError(let message):
            return "解析错误: \(message)"
        case .notLoggedIn:
            return "请先登录小红书账号"
        case .notOnCollectionPage:
            return "请导航到收藏夹页面"
        }
    }
} 