//
//  Models.swift
//  LedgerLight
//
//  数据模型定义
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - 记录类型
enum RecordType: String, Codable, CaseIterable {
    case expense = "支出"
    case income = "收入"
    
    var color: Color {
        switch self {
        case .expense: return .red
        case .income: return .green
        }
    }
}

// MARK: - 标签模型
@Model
final class Tag {
    var id: UUID
    var name: String
    var colorHex: String
    var icon: String
    var isDefault: Bool
    var createdAt: Date
    
    @Relationship(inverse: \Record.tag)
    var records: [Record]?
    
    init(name: String, colorHex: String, icon: String, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.isDefault = isDefault
        self.createdAt = Date()
    }
    
    var color: Color {
        Color(hex: colorHex)
    }
}

// MARK: - 记录模型
@Model
final class Record {
    var id: UUID
    var amount: Double
    var type: RecordType
    var note: String
    var date: Date
    var createdAt: Date
    
    var tag: Tag?
    var ledger: Ledger?
    
    init(amount: Double, type: RecordType, note: String = "", date: Date = Date(), tag: Tag? = nil, ledger: Ledger? = nil) {
        self.id = UUID()
        self.amount = amount
        self.type = type
        self.note = note
        self.date = date
        self.createdAt = Date()
        self.tag = tag
        self.ledger = ledger
    }
    
    var formattedAmount: String {
        let prefix = type == .expense ? "-" : "+"
        return "\(prefix)¥\(String(format: "%.2f", amount))"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
    
    var weekdayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

// MARK: - 账本模型
@Model
final class Ledger {
    var id: UUID
    var name: String
    var colorHex: String
    var icon: String
    var isDefault: Bool
    var createdAt: Date
    
    @Relationship(inverse: \Record.ledger)
    var records: [Record]?
    
    init(name: String, colorHex: String = "#007AFF", icon: String = "book.fill", isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.isDefault = isDefault
        self.createdAt = Date()
    }
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    // 当月总支出
    func monthlyExpense(for date: Date = Date()) -> Double {
        guard let records = records else { return 0 }
        let calendar = Calendar.current
        return records
            .filter { calendar.isDate($0.date, equalTo: date, toGranularity: .month) && $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    // 当月总收入
    func monthlyIncome(for date: Date = Date()) -> Double {
        guard let records = records else { return 0 }
        let calendar = Calendar.current
        return records
            .filter { calendar.isDate($0.date, equalTo: date, toGranularity: .month) && $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    // 当月记录
    func monthlyRecords(for date: Date = Date()) -> [Record] {
        guard let records = records else { return [] }
        let calendar = Calendar.current
        return records
            .filter { calendar.isDate($0.date, equalTo: date, toGranularity: .month) }
            .sorted { $0.date > $1.date }
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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "#000000" }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - 预设颜色
struct AppColors {
    static let palette: [(name: String, hex: String)] = [
        ("天蓝", "#007AFF"),
        ("薄荷", "#34C759"),
        ("珊瑚", "#FF6B6B"),
        ("琥珀", "#FF9500"),
        ("紫罗兰", "#AF52DE"),
        ("粉红", "#FF2D55"),
        ("青色", "#5AC8FA"),
        ("灰色", "#8E8E93")
    ]
}

// MARK: - 预设标签
struct DefaultTags {
    static let list: [(name: String, icon: String, color: String)] = [
        ("餐饮", "fork.knife", "#FF6B6B"),
        ("交通", "car.fill", "#007AFF"),
        ("购物", "bag.fill", "#FF9500"),
        ("娱乐", "gamecontroller.fill", "#AF52DE"),
        ("居住", "house.fill", "#34C759"),
        ("医疗", "cross.case.fill", "#FF2D55"),
        ("教育", "book.fill", "#5AC8FA"),
        ("工资", "briefcase.fill", "#34C759"),
        ("其他", "ellipsis.circle.fill", "#8E8E93")
    ]
}
