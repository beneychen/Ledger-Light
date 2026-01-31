//
//  LedgerListView.swift
//  LedgerLight
//
//  账本管理视图
//

import SwiftUI
import SwiftData

struct LedgerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var ledgers: [Ledger]
    
    @State private var showAddLedger = false
    @State private var editingLedger: Ledger?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(ledgers, id: \.id) { ledger in
                    LedgerRowView(ledger: ledger)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            setDefaultLedger(ledger)
                        }
                        .swipeActions(edge: .trailing) {
                            if !ledger.isDefault {
                                Button(role: .destructive) {
                                    deleteLedger(ledger)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                            
                            Button {
                                editingLedger = ledger
                            } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("账本")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddLedger = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddLedger) {
                AddLedgerView()
            }
            .sheet(item: $editingLedger) { ledger in
                EditLedgerView(ledger: ledger)
            }
        }
    }
    
    private func setDefaultLedger(_ ledger: Ledger) {
        for l in ledgers {
            l.isDefault = (l.id == ledger.id)
        }
        try? modelContext.save()
        
        // 触感反馈
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func deleteLedger(_ ledger: Ledger) {
        modelContext.delete(ledger)
        try? modelContext.save()
    }
}

// MARK: - 账本行视图
struct LedgerRowView: View {
    let ledger: Ledger
    
    var body: some View {
        HStack(spacing: 16) {
            // 账本图标
            Image(systemName: ledger.icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(ledger.color)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // 账本信息
            VStack(alignment: .leading, spacing: 4) {
                Text(ledger.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("\(ledger.records?.count ?? 0)条记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 默认标记
            if ledger.isDefault {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 添加账本视图
struct AddLedgerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var selectedColorHex = AppColors.palette[0].hex
    @State private var selectedIcon = "book.fill"
    
    let icons = ["book.fill", "creditcard.fill", "cart.fill", "house.fill", "car.fill", "airplane", "gift.fill", "heart.fill"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("账本名称") {
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
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundColor(selectedIcon == icon ? .white : Color(hex: selectedColorHex))
                                .frame(width: 44, height: 44)
                                .background(selectedIcon == icon ? Color(hex: selectedColorHex) : Color(hex: selectedColorHex).opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("新建账本")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        saveLedger()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveLedger() {
        let ledger = Ledger(
            name: name,
            colorHex: selectedColorHex,
            icon: selectedIcon,
            isDefault: false
        )
        modelContext.insert(ledger)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - 编辑账本视图
struct EditLedgerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var ledger: Ledger
    
    let icons = ["book.fill", "creditcard.fill", "cart.fill", "house.fill", "car.fill", "airplane", "gift.fill", "heart.fill"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("账本名称") {
                    TextField("输入名称", text: $ledger.name)
                }
                
                Section("颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(AppColors.palette, id: \.hex) { color in
                            Circle()
                                .fill(Color(hex: color.hex))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.primary, lineWidth: ledger.colorHex == color.hex ? 2 : 0)
                                )
                                .onTapGesture {
                                    ledger.colorHex = color.hex
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundColor(ledger.icon == icon ? .white : ledger.color)
                                .frame(width: 44, height: 44)
                                .background(ledger.icon == icon ? ledger.color : ledger.color.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .onTapGesture {
                                    ledger.icon = icon
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("编辑账本")
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
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Ledger.self, Record.self, Tag.self, configurations: config)
    
    return LedgerListView()
        .modelContainer(container)
}
