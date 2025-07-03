//
//  NoteCardView.swift
//  rednote-col
//
//  Created by Siyu Xiao on 2025/7/3.
//

import SwiftUI

struct NoteCardView: View {
    let note: CollectedNote
    let displayMode: DisplayMode
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            if displayMode == .grid {
                gridCard
            } else {
                listCard
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture {
            onLongPress()
        }
        .scaleEffect(isSelected ? 0.95 : 1.0)
        .animation(Constants.Animation.spring, value: isSelected)
    }
    
    // MARK: - 网格卡片
    private var gridCard: some View {
        VStack(alignment: .leading, spacing: Constants.UI.smallPadding) {
            // 图片区域
            imageView
                .frame(height: Constants.UI.thumbnailHeight)
                .clipped()
            
            // 内容区域
            VStack(alignment: .leading, spacing: 4) {
                // 标题
                Text(note.title)
                    .font(Constants.Fonts.caption)
                    .foregroundColor(Constants.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // 作者信息
                if let authorName = note.authorName {
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle")
                            .font(.caption)
                            .foregroundColor(Constants.Colors.textSecondary)
                        
                        Text(authorName)
                            .font(Constants.Fonts.small)
                            .foregroundColor(Constants.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                // 分类标签
                if let category = note.category, !category.isDefault {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: category.colorHex))
                            .frame(width: 8, height: 8)
                        
                        Text(category.name)
                            .font(Constants.Fonts.small)
                            .foregroundColor(Constants.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, Constants.UI.smallPadding)
            .padding(.bottom, Constants.UI.smallPadding)
        }
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(Constants.Colors.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .stroke(isSelected ? Constants.Colors.primary : Color.clear, lineWidth: 2)
        )
    }
    
    // MARK: - 列表卡片
    private var listCard: some View {
        HStack(spacing: Constants.UI.padding) {
            // 缩略图
            imageView
                .frame(width: 80, height: 80)
                .clipped()
            
            // 内容区域
            VStack(alignment: .leading, spacing: 4) {
                // 标题
                Text(note.title)
                    .font(Constants.Fonts.body)
                    .foregroundColor(Constants.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // 内容摘要
                if let content = note.content {
                    Text(content)
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // 底部信息
                HStack {
                    // 作者
                    if let authorName = note.authorName {
                        HStack(spacing: 4) {
                            Image(systemName: "person.circle")
                                .font(.caption)
                                .foregroundColor(Constants.Colors.textSecondary)
                            
                            Text(authorName)
                                .font(Constants.Fonts.small)
                                .foregroundColor(Constants.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    // 分类
                    if let category = note.category, !category.isDefault {
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: category.colorHex))
                                .frame(width: 6, height: 6)
                            
                            Text(category.name)
                                .font(Constants.Fonts.small)
                                .foregroundColor(Constants.Colors.textSecondary)
                        }
                    }
                    
                    // 时间
                    Text(DateFormatter.relative.string(for: note.syncDate) ?? "刚刚")
                        .font(Constants.Fonts.small)
                        .foregroundColor(Constants.Colors.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(Constants.UI.padding)
        .background(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .fill(Constants.Colors.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                .stroke(isSelected ? Constants.Colors.primary : Color.clear, lineWidth: 2)
        )
    }
    
    // MARK: - 图片视图
    private var imageView: some View {
        Group {
            if let imageURL = note.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                        .fill(Constants.Colors.background)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                }
            } else {
                RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius)
                    .fill(Constants.Colors.background)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(Constants.Colors.textSecondary)
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.smallCornerRadius))
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
}

#Preview("NoteCardView") {
    let sampleNote = CollectedNote(
        id: "sample",
        title: "这是一个示例笔记标题，可能会很长",
        content: "这是笔记的内容描述，通常会包含更多的详细信息...",
        imageURL: "https://picsum.photos/300/400",
        originalURL: "https://example.com",
        authorName: "示例作者"
    )
    
    return VStack {
        NoteCardView(
            note: sampleNote,
            displayMode: .grid,
            isSelected: false,
            onTap: {},
            onLongPress: {}
        )
        .frame(width: 180)
        
        NoteCardView(
            note: sampleNote,
            displayMode: .list,
            isSelected: true,
            onTap: {},
            onLongPress: {}
        )
    }
    .padding(Constants.UI.padding)
} 