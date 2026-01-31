//
//  AppState.swift
//  LedgerLight
//
//  应用状态管理
//

import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var showAddRecord: Bool = true  // 默认打开APP进入记账流
    @Published var selectedLedgerId: UUID?
    @Published var currentDate: Date = Date()
    
    // 时间窗口选项
    enum TimeWindow: String, CaseIterable {
        case week = "周"
        case month = "月"
        case year = "年"
    }
    
    @Published var selectedTimeWindow: TimeWindow = .month
    
    // 获取时间窗口的起始和结束日期
    func getDateRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = currentDate
        
        switch selectedTimeWindow {
        case .week:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
            return (startOfWeek, endOfWeek)
        case .month:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
            return (startOfMonth, endOfMonth)
        case .year:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
            let endOfYear = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startOfYear)!
            return (startOfYear, endOfYear)
        }
    }
    
    // 当前月份显示
    var currentMonthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: currentDate)
    }
}
