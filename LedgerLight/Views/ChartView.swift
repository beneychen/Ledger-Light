//
//  ChartView.swift
//  LedgerLight
//
//  图表分析视图 - 甜甜圈图和柱状图
//

import SwiftUI
import SwiftData
import Charts

struct ChartView: View {
    @EnvironmentObject var appState: AppState
    @Bindable var ledger: Ledger
    
    @State private var selectedChartType: ChartType = .donut
    
    enum ChartType: String, CaseIterable {
        case donut = "分类"
        case bar = "趋势"
    }
    
    var filteredRecords: [Record] {
        guard let records = ledger.records else { return [] }
        let calendar = Calendar.current
        let (start, end) = appState.getDateRange()
        
        return records.filter { record in
            record.date >= start && record.date <= end && record.type == .expense
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 时间窗口选择器
                TimeWindowPicker(selectedWindow: $appState.selectedTimeWindow)
                    .padding()
                
                // 图表类型选择
                Picker("图表类型", selection: $selectedChartType) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // 图表内容
                if filteredRecords.isEmpty {
                    Spacer()
                    EmptyChartView()
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            if selectedChartType == .donut {
                                DonutChartSection(records: filteredRecords)
                            } else {
                                BarChartSection(records: filteredRecords, timeWindow: appState.selectedTimeWindow)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("分析")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - 时间窗口选择器
struct TimeWindowPicker: View {
    @Binding var selectedWindow: AppState.TimeWindow
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppState.TimeWindow.allCases, id: \.self) { window in
                Button {
                    withAnimation {
                        selectedWindow = window
                    }
                } label: {
                    Text(window.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedWindow == window ? .semibold : .regular)
                        .foregroundColor(selectedWindow == window ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedWindow == window ? Color.blue : Color.clear)
                }
            }
        }
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
}

// MARK: - 空图表视图
struct EmptyChartView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("暂无数据")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("该时间段内没有记录")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
        }
    }
}

// MARK: - 甜甜圈图部分
struct DonutChartSection: View {
    let records: [Record]
    
    var categoryData: [(tag: Tag, amount: Double, percentage: Double)] {
        var grouped: [UUID: (tag: Tag, amount: Double)] = [:]
        
        for record in records {
            guard let tag = record.tag else { continue }
            if let existing = grouped[tag.id] {
                grouped[tag.id] = (tag: tag, amount: existing.amount + record.amount)
            } else {
                grouped[tag.id] = (tag: tag, amount: record.amount)
            }
        }
        
        let total = grouped.values.reduce(0) { $0 + $1.amount }
        
        return grouped.values
            .map { (tag: $0.tag, amount: $0.amount, percentage: total > 0 ? $0.amount / total * 100 : 0) }
            .sorted { $0.amount > $1.amount }
    }
    
    var totalExpense: Double {
        records.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 甜甜圈图
            ZStack {
                Chart(categoryData, id: \.tag.id) { item in
                    SectorMark(
                        angle: .value("金额", item.amount),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(item.tag.color)
                    .cornerRadius(4)
                }
                .frame(height: 220)
                
                // 中心显示总金额
                VStack(spacing: 4) {
                    Text("总支出")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("¥\(String(format: "%.0f", totalExpense))")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            .padding()
            
            // 分类列表
            VStack(spacing: 12) {
                ForEach(categoryData, id: \.tag.id) { item in
                    CategoryRow(
                        tag: item.tag,
                        amount: item.amount,
                        percentage: item.percentage
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
            )
        }
    }
}

// MARK: - 分类行
struct CategoryRow: View {
    let tag: Tag
    let amount: Double
    let percentage: Double
    
    var body: some View {
        HStack(spacing: 12) {
            // 颜色指示器
            Circle()
                .fill(tag.color)
                .frame(width: 12, height: 12)
            
            // 图标
            Image(systemName: tag.icon)
                .font(.body)
                .foregroundColor(tag.color)
                .frame(width: 24)
            
            // 标签名
            Text(tag.name)
                .font(.body)
            
            Spacer()
            
            // 金额和占比
            VStack(alignment: .trailing, spacing: 2) {
                Text("¥\(String(format: "%.2f", amount))")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("\(String(format: "%.1f", percentage))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 柱状图部分
struct BarChartSection: View {
    let records: [Record]
    let timeWindow: AppState.TimeWindow
    
    var barData: [(label: String, expense: Double, income: Double)] {
        let calendar = Calendar.current
        var grouped: [String: (expense: Double, income: Double)] = [:]
        
        for record in records {
            let label: String
            switch timeWindow {
            case .week:
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "zh_CN")
                formatter.dateFormat = "E"
                label = formatter.string(from: record.date)
            case .month:
                let day = calendar.component(.day, from: record.date)
                label = "\(day)日"
            case .year:
                let month = calendar.component(.month, from: record.date)
                label = "\(month)月"
            }
            
            var current = grouped[label] ?? (expense: 0, income: 0)
            if record.type == .expense {
                current.expense += record.amount
            } else {
                current.income += record.amount
            }
            grouped[label] = current
        }
        
        return grouped.map { (label: $0.key, expense: $0.value.expense, income: $0.value.income) }
            .sorted { lhs, rhs in
                // 按日期排序
                let lhsNum = Int(lhs.label.filter { $0.isNumber }) ?? 0
                let rhsNum = Int(rhs.label.filter { $0.isNumber }) ?? 0
                return lhsNum < rhsNum
            }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("收支趋势")
                .font(.headline)
            
            Chart {
                ForEach(barData, id: \.label) { item in
                    BarMark(
                        x: .value("日期", item.label),
                        y: .value("支出", item.expense)
                    )
                    .foregroundStyle(Color.red.gradient)
                    .cornerRadius(4)
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            
            // 图例
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("支出")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Ledger.self, Record.self, Tag.self, configurations: config)
    
    let ledger = Ledger(name: "测试账本", isDefault: true)
    container.mainContext.insert(ledger)
    
    return ChartView(ledger: ledger)
        .environmentObject(AppState())
        .modelContainer(container)
}
