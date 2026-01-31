//
//  LedgerLightApp.swift
//  LedgerLight - 秒记
//
//  极简记账软件
//

import SwiftUI
import SwiftData

@main
struct LedgerLightApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .modelContainer(for: [Ledger.self, Record.self, Tag.self])
        }
    }
}
