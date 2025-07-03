//
//  Constants.swift
//  rednote-col
//
//  Created by Siyu Xiao on 2025/7/3.
//

import Foundation
import SwiftUI

struct Constants {
    
    // MARK: - 应用信息
    static let appName = "小红书收藏管理"
    static let appVersion = "1.0.0"
    static let appBundleId = "com.siyux.rednote-col"
    
    // MARK: - 网络相关
    struct Network {
        static let redBookBaseURL = "https://www.xiaohongshu.com"
        static let userCollectionPath = "/user/profile/%@/collect"
        static let requestTimeout: TimeInterval = 30.0
        static let maxRetryCount = 3
    }
    
    // MARK: - UI常量
    struct UI {
        // 间距
        static let padding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        
        // 圆角
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let largeCornerRadius: CGFloat = 16
        
        // 卡片
        static let cardHeight: CGFloat = 280
        static let cardWidth: CGFloat = 180
        static let thumbnailHeight: CGFloat = 160
        
        // 网格
        static let gridColumns = 2
        static let gridSpacing: CGFloat = 12
    }
    
    // MARK: - 动画
    struct Animation {
        static let defaultDuration: Double = 0.3
        static let fastDuration: Double = 0.2
        static let slowDuration: Double = 0.5
        
        static let spring = SwiftUI.Animation.spring(
            response: 0.6,
            dampingFraction: 0.8,
            blendDuration: 0.0
        )
    }
    
    // MARK: - 颜色主题
    struct Colors {
        static let primary = Color(hex: "#FF6B35")
        static let secondary = Color(hex: "#4ECDC4")
        static let accent = Color(hex: "#FF6B94")
        static let background = Color(hex: "#F8F9FA")
        static let cardBackground = Color.white
        static let textPrimary = Color(hex: "#2C3E50")
        static let textSecondary = Color(hex: "#7F8C8D")
        static let success = Color(hex: "#27AE60")
        static let warning = Color(hex: "#F39C12")
        static let error = Color(hex: "#E74C3C")
    }
    
    // MARK: - 字体
    struct Fonts {
        static let title = Font.system(size: 24, weight: .bold)
        static let headline = Font.system(size: 18, weight: .semibold)
        static let body = Font.system(size: 16, weight: .regular)
        static let caption = Font.system(size: 14, weight: .regular)
        static let small = Font.system(size: 12, weight: .regular)
    }
    
    // MARK: - 图标
    struct Icons {
        static let home = "house.fill"
        static let collection = "heart.fill"
        static let sync = "arrow.2.circlepath"
        static let settings = "gearshape.fill"
        static let search = "magnifyingglass"
        static let add = "plus"
        static let delete = "trash"
        static let edit = "pencil"
        static let share = "square.and.arrow.up"
        static let bookmark = "bookmark.fill"
        static let category = "folder.fill"
        static let filter = "line.3.horizontal.decrease.circle"
        static let sort = "arrow.up.arrow.down"
        static let grid = "square.grid.2x2"
        static let list = "list.bullet"
        static let refresh = "arrow.clockwise"
        static let play = "play.fill"
        static let pause = "pause.fill"
        static let stop = "stop.fill"
    }
    
    // MARK: - 数据存储
    struct Storage {
        static let maxImageCacheSize = 100 * 1024 * 1024 // 100MB
        static let maxDatabaseSize = 500 * 1024 * 1024 // 500MB
        static let imageCacheDirectory = "ImageCache"
        static let backupDirectory = "Backup"
    }
    
    // MARK: - 功能限制
    struct Limits {
        static let maxNotesPerSync = 1000
        static let maxCategoriesCount = 50
        static let maxTagsPerNote = 20
        static let maxTitleLength = 200
        static let maxContentLength = 2000
        static let maxKeywordsPerCategory = 50
    }
    
    // MARK: - 用户设置键值
    struct UserDefaults {
        static let isFirstLaunch = "isFirstLaunch"
        static let syncFrequency = "syncFrequency"
        static let displayMode = "displayMode"
        static let autoCategorizationEnabled = "autoCategorizationEnabled"
        static let imageDownloadEnabled = "imageDownloadEnabled"
        static let lastSyncDate = "lastSyncDate"
        static let themeMode = "themeMode"
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 枚举定义
enum DisplayMode: String, CaseIterable {
    case grid = "grid"
    case list = "list"
    
    var displayName: String {
        switch self {
        case .grid: return "网格视图"
        case .list: return "列表视图"
        }
    }
    
    var icon: String {
        switch self {
        case .grid: return Constants.Icons.grid
        case .list: return Constants.Icons.list
        }
    }
}

enum SyncFrequency: String, CaseIterable {
    case manual = "manual"
    case daily = "daily"
    case weekly = "weekly"
    
    var displayName: String {
        switch self {
        case .manual: return "手动同步"
        case .daily: return "每日同步"
        case .weekly: return "每周同步"
        }
    }
} 