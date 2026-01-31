//
//  LedgerLightApp.swift
//  LedgerLight - 秒记
//
//  极简记账软件
//  使用 SwiftData + CloudKit 自动同步
//

import SwiftUI
import SwiftData

@main
struct LedgerLightApp: App {
    @StateObject private var appState = AppState()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Ledger.self,
            Record.self,
            Tag.self
        ])
        
        // 使用 CloudKit 自动同步
        // 需要在 Xcode 中配置:
        // 1. Signing & Capabilities → + Capability → iCloud
        // 2. 勾选 CloudKit
        // 3. 创建或选择 CloudKit Container
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic  // 自动同步到 iCloud
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .modelContainer(sharedModelContainer)
        }
    }
}
