//
//  SettingsView.swift
//  LedgerLight
//
//  设置视图 - 包含数据导出功能
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var ledgers: [Ledger]
    @Query private var tags: [Tag]
    @Query private var records: [Record]
    
    @State private var showExportSheet = false
    @State private var showTagManagement = false
    @State private var exportedFileURL: URL?
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                // 数据统计
                Section {
                    HStack {
                        Label("账本数量", systemImage: "book")
                        Spacer()
                        Text("\(ledgers.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("记录数量", systemImage: "doc.text")
                        Spacer()
                        Text("\(records.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("标签数量", systemImage: "tag")
                        Spacer()
                        Text("\(tags.count)")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("数据概览")
                }
                
                // 标签管理
                Section {
                    NavigationLink {
                        TagManagementView()
                    } label: {
                        Label("管理标签", systemImage: "tag.fill")
                    }
                } header: {
                    Text("标签")
                }
                
                // 数据导出
                Section {
                    Button {
                        exportToCSV()
                    } label: {
                        Label("导出为CSV", systemImage: "square.and.arrow.up")
                    }
                } header: {
                    Text("数据导出")
                } footer: {
                    Text("导出所有记录为CSV格式，可在Excel或Numbers中打开")
                }
                
                // 关于
                Section {
                    HStack {
                        Label("版本", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("关于")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    private func exportToCSV() {
        let csvContent = generateCSV()
        
        // 保存到临时文件
        let fileName = "秒记_\(formattedExportDate()).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            // 添加BOM以确保Excel正确识别UTF-8
            let bom = "\u{FEFF}"
            try (bom + csvContent).write(to: tempURL, atomically: true, encoding: .utf8)
            exportedFileURL = tempURL
            showShareSheet = true
        } catch {
            print("导出失败: \(error)")
        }
    }
    
    private func generateCSV() -> String {
        var csv = "日期,时间,类型,标签,金额,备注,账本\n"
        
        let sortedRecords = records.sorted { $0.date > $1.date }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        
        for record in sortedRecords {
            let date = dateFormatter.string(from: record.date)
            let time = timeFormatter.string(from: record.createdAt)
            let type = record.type == .expense ? "支出" : "收入"
            let tag = record.tag?.name ?? "未分类"
            let amount = String(format: "%.2f", record.amount)
            let note = record.note.replacingOccurrences(of: ",", with: "，")  // 替换英文逗号
            let ledgerName = record.ledger?.name ?? "未知账本"
            
            csv += "\(date),\(time),\(type),\(tag),\(amount),\(note),\(ledgerName)\n"
        }
        
        return csv
    }
    
    private func formattedExportDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
}

// MARK: - 分享Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 标签管理视图
struct TagManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tags: [Tag]
    
    @State private var showAddTag = false
    @State private var editingTag: Tag?
    
    var body: some View {
        List {
            ForEach(tags, id: \.id) { tag in
                HStack(spacing: 12) {
                    Image(systemName: tag.icon)
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(tag.color)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    Text(tag.name)
                        .font(.body)
                    
                    Spacer()
                    
                    if tag.isDefault {
                        Text("默认")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    editingTag = tag
                }
                .swipeActions(edge: .trailing) {
                    if !tag.isDefault {
                        Button(role: .destructive) {
                            modelContext.delete(tag)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("标签管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddTag = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddTag) {
            AddTagView()
        }
        .sheet(item: $editingTag) { tag in
            EditTagView(tag: tag)
        }
    }
}

// MARK: - 添加标签视图
struct AddTagView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var selectedColorHex = AppColors.palette[0].hex
    @State private var selectedIcon = "tag.fill"
    
    let icons = ["tag.fill", "fork.knife", "car.fill", "bag.fill", "gamecontroller.fill", "house.fill", "cross.case.fill", "book.fill", "briefcase.fill", "gift.fill", "heart.fill", "star.fill", "ellipsis.circle.fill"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("标签名称") {
                    TextField("输入名称", text: $name)
                }
                
                Section("颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(AppColors.palette, id: \.hex) { color in
                            Circle()
                                .fill(Color(hex: color.hex))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.primary, lineWidth: selectedColorHex == color.hex ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColorHex = color.hex
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .foregroundColor(selectedIcon == icon ? .white : Color(hex: selectedColorHex))
                                .frame(width: 40, height: 40)
                                .background(selectedIcon == icon ? Color(hex: selectedColorHex) : Color(hex: selectedColorHex).opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("新建标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        let tag = Tag(name: name, colorHex: selectedColorHex, icon: selectedIcon)
                        modelContext.insert(tag)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - 编辑标签视图
struct EditTagView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var tag: Tag
    
    let icons = ["tag.fill", "fork.knife", "car.fill", "bag.fill", "gamecontroller.fill", "house.fill", "cross.case.fill", "book.fill", "briefcase.fill", "gift.fill", "heart.fill", "star.fill", "ellipsis.circle.fill"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("标签名称") {
                    TextField("输入名称", text: $tag.name)
                }
                
                Section("颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(AppColors.palette, id: \.hex) { color in
                            Circle()
                                .fill(Color(hex: color.hex))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.primary, lineWidth: tag.colorHex == color.hex ? 2 : 0)
                                )
                                .onTapGesture {
                                    tag.colorHex = color.hex
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .foregroundColor(tag.icon == icon ? .white : tag.color)
                                .frame(width: 40, height: 40)
                                .background(tag.icon == icon ? tag.color : tag.color.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture {
                                    tag.icon = icon
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("编辑标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Ledger.self, Record.self, Tag.self], inMemory: true)
}
