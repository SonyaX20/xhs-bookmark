//
//  MainTabView.swift
//  rednote-col
//
//  Created by Siyu Xiao on 2025/7/3.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dataService: DataService
    @StateObject private var webViewService = WebViewService()
    
    init() {
        // 临时初始化，在body中会重新设置
        let tempContext = try! ModelContainer(for: CollectedNote.self, Category.self, SyncSession.self).mainContext
        _dataService = StateObject(wrappedValue: DataService(modelContext: tempContext))
    }
    
    var body: some View {
        TabView {
            CollectionListView()
                .tabItem {
                    Image(systemName: Constants.Icons.collection)
                    Text("收藏")
                }
            
            WebViewContainerView()
                .tabItem {
                    Image(systemName: Constants.Icons.sync)
                    Text("同步")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: Constants.Icons.settings)
                    Text("设置")
                }
        }
        .accentColor(Constants.Colors.primary)
        .environmentObject(dataService)
        .environmentObject(webViewService)
        .onAppear {
            // 重新设置正确的modelContext
            dataService.updateModelContext(modelContext)
            webViewService.setDataService(dataService)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [CollectedNote.self, Category.self, SyncSession.self], inMemory: true)
} 