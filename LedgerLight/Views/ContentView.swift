//
//  ContentView.swift
//  LedgerLight
//
//  主入口视图
//  CloudKit 自动处理同步，无需手动管理认证状态
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query private var ledgers: [Ledger]
    @Query private var tags: [Tag]
    
    @State private var hasInitialized = false
    
    var body: some View {
        ZStack {
            if let defaultLedger = ledgers.first(where: { $0.isDefault }) ?? ledgers.first {
                MainTabView(ledger: defaultLedger)
            } else {
                // 首次启动，显示加载中（等待默认数据创建）
                LoadingView()
            }
        }
        .sheet(isPresented: $appState.showAddRecord) {
            if let defaultLedger = ledgers.first(where: { $0.isDefault }) ?? ledgers.first {
                AddRecordView(ledger: defaultLedger)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            if !hasInitialized {
                initializeDefaultData()
                hasInitialized = true
            }
        }
    }
    
    private func initializeDefaultData() {
        // 如果没有账本，创建默认账本
        if ledgers.isEmpty {
            let defaultLedger = Ledger(name: "日常账本", colorHex: "#007AFF", icon: "book.fill", isDefault: true)
            modelContext.insert(defaultLedger)
        }
        
        // 如果没有标签，创建默认标签
        if tags.isEmpty {
            for tagInfo in DefaultTags.list {
                let tag = Tag(name: tagInfo.name, colorHex: tagInfo.color, icon: tagInfo.icon, isDefault: true)
                modelContext.insert(tag)
            }
        }
        
        try? modelContext.save()
    }
}

// MARK: - 加载视图
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            ProgressView()
            
            Text("正在加载...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 欢迎页面
struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: "book.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 12) {
                Text("秒记")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("极简记账，专注于重要的事")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            
            Text("正在初始化...")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .modelContainer(for: [Ledger.self, Record.self, Tag.self], inMemory: true)
}
