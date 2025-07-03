//
//  rednote_colApp.swift
//  rednote-col
//
//  Created by Siyu Xiao on 2025/7/3.
//

import SwiftUI
import SwiftData

@main
struct rednote_colApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CollectedNote.self,
            Category.self,
            SyncSession.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
