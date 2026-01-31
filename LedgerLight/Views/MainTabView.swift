//
//  MainTabView.swift
//  LedgerLight
//
//  主页Tab视图
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    let ledger: Ledger
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 主页 - 记录列表
            HomeView(ledger: ledger)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("记录")
                }
                .tag(0)
            
            // 图表分析
            ChartView(ledger: ledger)
                .tabItem {
                    Image(systemName: "chart.pie")
                    Text("分析")
                }
                .tag(1)
            
            // 账本管理
            LedgerListView()
                .tabItem {
                    Image(systemName: "book")
                    Text("账本")
                }
                .tag(2)
            
            // 设置
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("设置")
                }
                .tag(3)
        }
        .tint(ledger.color)
    }
}

// MARK: - 主页视图
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Bindable var ledger: Ledger
    
    var monthlyRecords: [Record] {
        ledger.monthlyRecords(for: appState.currentDate)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 月度概览卡片
                MonthSummaryCard(
                    expense: ledger.monthlyExpense(for: appState.currentDate),
                    income: ledger.monthlyIncome(for: appState.currentDate)
                )
                .padding()
                
                // 记录列表
                if monthlyRecords.isEmpty {
                    Spacer()
                    EmptyStateView()
                    Spacer()
                } else {
                    RecordListView(records: monthlyRecords)
                }
            }
            .navigationTitle(appState.currentMonthString)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appState.showAddRecord = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 4) {
                        Button {
                            withAnimation {
                                appState.currentDate = Calendar.current.date(byAdding: .month, value: -1, to: appState.currentDate) ?? appState.currentDate
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        
                        Button {
                            withAnimation {
                                appState.currentDate = Calendar.current.date(byAdding: .month, value: 1, to: appState.currentDate) ?? appState.currentDate
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 月度概览卡片
struct MonthSummaryCard: View {
    let expense: Double
    let income: Double
    
    var balance: Double {
        income - expense
    }
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("支出")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("¥\(String(format: "%.2f", expense))")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("收入")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("¥\(String(format: "%.2f", income))")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("结余")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("¥\(String(format: "%.2f", balance))")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(balance >= 0 ? .primary : .red)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - 空状态视图
struct EmptyStateView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("暂无记录")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("点击下方按钮开始记账")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
            
            Button {
                appState.showAddRecord = true
            } label: {
                Label("记一笔", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - 记录列表
struct RecordListView: View {
    @Environment(\.modelContext) private var modelContext
    let records: [Record]
    
    var groupedRecords: [(String, [Record])] {
        let grouped = Dictionary(grouping: records) { record -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd"
            return formatter.string(from: record.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        List {
            ForEach(groupedRecords, id: \.0) { dateString, dayRecords in
                Section {
                    ForEach(dayRecords, id: \.id) { record in
                        RecordRowView(record: record)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        modelContext.delete(record)
                                    }
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    HStack {
                        Text(dateString)
                        Text(getWeekday(from: dateString))
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func getWeekday(from dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        guard let date = formatter.date(from: dateString) else { return "" }
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

// MARK: - 记录行视图
struct RecordRowView: View {
    let record: Record
    
    var body: some View {
        HStack(spacing: 12) {
            // 标签图标
            if let tag = record.tag {
                Image(systemName: tag.icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(tag.color)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "questionmark.circle")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // 标签名和备注
            VStack(alignment: .leading, spacing: 2) {
                Text(record.tag?.name ?? "未分类")
                    .font(.body)
                    .fontWeight(.medium)
                
                if !record.note.isEmpty {
                    Text(record.note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // 金额
            Text(record.formattedAmount)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(record.type == .expense ? .red : .green)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Ledger.self, Record.self, Tag.self, configurations: config)
    
    let ledger = Ledger(name: "测试账本", isDefault: true)
    container.mainContext.insert(ledger)
    
    return MainTabView(ledger: ledger)
        .environmentObject(AppState())
        .modelContainer(container)
}
