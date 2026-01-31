//
//  AddRecordView.swift
//  LedgerLight
//
//  记账流视图 - 极简记账的核心页面
//

import SwiftUI
import SwiftData

struct AddRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var tags: [Tag]
    
    let ledger: Ledger
    
    // 记录数据
    @State private var amount: String = ""
    @State private var recordType: RecordType = .expense
    @State private var selectedTag: Tag?
    @State private var note: String = ""
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker = false
    
    // 计算器状态
    @State private var isCalculating = false
    @State private var expression: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 金额显示区
                AmountDisplayView(
                    amount: amount,
                    recordType: recordType,
                    expression: expression
                )
                
                // 类型切换
                RecordTypePicker(selectedType: $recordType)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                
                // 标签选择
                TagSelectionView(
                    tags: tags.filter { tag in
                        // 支出时显示非工资标签，收入时显示工资等收入相关标签
                        if recordType == .income {
                            return tag.name == "工资" || tag.name == "其他"
                        }
                        return tag.name != "工资"
                    },
                    selectedTag: $selectedTag
                )
                .padding(.bottom, 12)
                
                // 日期和备注
                HStack {
                    // 日期选择
                    Button {
                        showDatePicker.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(formattedDate)
                            Text(weekdayString)
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // 备注输入
                    TextField("备注（选填）", text: $note)
                        .font(.subheadline)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 150)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                Spacer()
                
                // 数字键盘
                NumberPadView(
                    amount: $amount,
                    expression: $expression,
                    isCalculating: $isCalculating,
                    onConfirm: saveRecord,
                    onCancel: { dismiss() }
                )
            }
            .navigationTitle("记一笔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerSheet(selectedDate: $selectedDate)
                    .presentationDetents([.height(350)])
            }
            .onAppear {
                // 默认选择第一个标签
                if selectedTag == nil {
                    selectedTag = tags.first
                }
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: selectedDate)
    }
    
    private var weekdayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEE"
        return formatter.string(from: selectedDate)
    }
    
    private func saveRecord() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }
        
        let record = Record(
            amount: amountValue,
            type: recordType,
            note: note,
            date: selectedDate,
            tag: selectedTag,
            ledger: ledger
        )
        
        modelContext.insert(record)
        try? modelContext.save()
        
        // 触感反馈
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        dismiss()
    }
}

// MARK: - 金额显示视图
struct AmountDisplayView: View {
    let amount: String
    let recordType: RecordType
    let expression: String
    
    var displayAmount: String {
        if amount.isEmpty {
            return "0"
        }
        return amount
    }
    
    var body: some View {
        VStack(spacing: 4) {
            if !expression.isEmpty {
                Text(expression)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("¥")
                    .font(.title)
                    .foregroundColor(recordType == .expense ? .red : .green)
                
                Text(displayAmount)
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .foregroundColor(recordType == .expense ? .red : .green)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .frame(height: 100)
        .padding()
    }
}

// MARK: - 类型选择器
struct RecordTypePicker: View {
    @Binding var selectedType: RecordType
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(RecordType.allCases, id: \.self) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedType = type
                    }
                } label: {
                    Text(type.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedType == type ? .semibold : .regular)
                        .foregroundColor(selectedType == type ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selectedType == type ? type.color : Color.clear
                        )
                }
            }
        }
        .background(Color(.systemGray6))
        .clipShape(Capsule())
        .frame(width: 160)
    }
}

// MARK: - 标签选择视图
struct TagSelectionView: View {
    let tags: [Tag]
    @Binding var selectedTag: Tag?
    
    let columns = [
        GridItem(.adaptive(minimum: 70), spacing: 12)
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(tags, id: \.id) { tag in
                    TagButton(
                        tag: tag,
                        isSelected: selectedTag?.id == tag.id,
                        action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedTag = tag
                            }
                            // 触感反馈
                            let generator = UISelectionFeedbackGenerator()
                            generator.selectionChanged()
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - 标签按钮
struct TagButton: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: tag.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : tag.color)
                    .frame(width: 48, height: 48)
                    .background(isSelected ? tag.color : tag.color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(tag.name)
                    .font(.caption)
                    .foregroundColor(isSelected ? tag.color : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 日期选择器
struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    
    var body: some View {
        NavigationStack {
            DatePicker(
                "选择日期",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            .navigationTitle("选择日期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 数字键盘
struct NumberPadView: View {
    @Binding var amount: String
    @Binding var expression: String
    @Binding var isCalculating: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    let buttons: [[String]] = [
        ["7", "8", "9", "+"],
        ["4", "5", "6", "-"],
        ["1", "2", "3", "⌫"],
        [".", "0", "完成", "="]
    ]
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(row, id: \.self) { button in
                        NumberButton(
                            title: button,
                            action: { handleButtonTap(button) }
                        )
                    }
                }
            }
        }
        .background(Color(.systemGray5))
    }
    
    private func handleButtonTap(_ button: String) {
        // 触感反馈
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        switch button {
        case "完成":
            if !amount.isEmpty, Double(amount) != nil, Double(amount)! > 0 {
                onConfirm()
            }
        case "⌫":
            if !amount.isEmpty {
                amount.removeLast()
            }
            if isCalculating && !expression.isEmpty {
                expression.removeLast()
            }
        case "=":
            calculateExpression()
        case "+", "-":
            if !amount.isEmpty {
                isCalculating = true
                expression = amount + button
                amount = ""
            }
        case ".":
            if !amount.contains(".") {
                if amount.isEmpty {
                    amount = "0."
                } else {
                    amount += "."
                }
            }
        default:
            // 限制小数点后两位
            if let dotIndex = amount.firstIndex(of: ".") {
                let decimals = amount.distance(from: dotIndex, to: amount.endIndex) - 1
                if decimals >= 2 {
                    return
                }
            }
            // 限制整数部分长度
            if amount.count >= 10 && !amount.contains(".") {
                return
            }
            amount += button
        }
    }
    
    private func calculateExpression() {
        guard isCalculating, !expression.isEmpty, !amount.isEmpty else { return }
        
        let fullExpression = expression + amount
        
        // 简单计算
        if expression.contains("+") {
            let parts = expression.dropLast()
            if let first = Double(parts), let second = Double(amount) {
                amount = String(format: "%.2f", first + second)
                // 移除末尾多余的0
                while amount.contains(".") && (amount.hasSuffix("0") || amount.hasSuffix(".")) {
                    amount.removeLast()
                }
            }
        } else if expression.contains("-") {
            let parts = expression.dropLast()
            if let first = Double(parts), let second = Double(amount) {
                let result = first - second
                amount = String(format: "%.2f", max(0, result))
                while amount.contains(".") && (amount.hasSuffix("0") || amount.hasSuffix(".")) {
                    amount.removeLast()
                }
            }
        }
        
        expression = ""
        isCalculating = false
    }
}

// MARK: - 数字按钮
struct NumberButton: View {
    let title: String
    let action: () -> Void
    
    var backgroundColor: Color {
        switch title {
        case "完成":
            return .blue
        case "+", "-", "=":
            return Color(.systemGray4)
        case "⌫":
            return Color(.systemGray4)
        default:
            return Color(.systemBackground)
        }
    }
    
    var foregroundColor: Color {
        switch title {
        case "完成":
            return .white
        default:
            return .primary
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(backgroundColor)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Ledger.self, Record.self, Tag.self, configurations: config)
    
    let ledger = Ledger(name: "测试账本", isDefault: true)
    container.mainContext.insert(ledger)
    
    // 添加测试标签
    for tagInfo in DefaultTags.list {
        let tag = Tag(name: tagInfo.name, colorHex: tagInfo.color, icon: tagInfo.icon, isDefault: true)
        container.mainContext.insert(tag)
    }
    
    return AddRecordView(ledger: ledger)
        .modelContainer(container)
}
