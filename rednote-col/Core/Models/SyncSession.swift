//
//  SyncSession.swift
//  rednote-col
//
//  Created by Siyu Xiao on 2025/7/3.
//

import Foundation
import SwiftData

@Model
final class SyncSession {
    @Attribute(.unique) var id: String
    var startTime: Date
    var endTime: Date?
    var totalCount: Int
    var syncedCount: Int
    var status: String
    var errorMessage: String?
    
    init() {
        self.id = UUID().uuidString
        self.startTime = Date()
        self.totalCount = 0
        self.syncedCount = 0
        self.status = SyncStatus.preparing.rawValue
    }
    
    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: status) ?? .preparing }
        set { status = newValue.rawValue }
    }
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    var progress: Double {
        guard totalCount > 0 else { return 0.0 }
        return Double(syncedCount) / Double(totalCount)
    }
    
    func complete() {
        self.endTime = Date()
        self.syncStatus = .completed
    }
    
    func fail(with error: String) {
        self.endTime = Date()
        self.syncStatus = .failed
        self.errorMessage = error
    }
}

enum SyncStatus: String, CaseIterable {
    case preparing = "preparing"
    case running = "running"
    case paused = "paused"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .preparing: return "准备中"
        case .running: return "同步中"
        case .paused: return "已暂停"
        case .completed: return "已完成"
        case .failed: return "同步失败"
        case .cancelled: return "已取消"
        }
    }
    
    var isActive: Bool {
        return self == .preparing || self == .running
    }
} 