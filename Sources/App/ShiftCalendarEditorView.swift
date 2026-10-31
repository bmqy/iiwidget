import SwiftUI

struct ShiftCalendarEditorView: View {
    @State private var config = SharedStore.loadShiftCalendar()
    @State private var previewDate = Date()
    @State private var selectedPreview: PreviewSize = .medium
    @State private var saved = false

    private enum PreviewSize: String, CaseIterable, Identifiable {
        case small = "周视图"
        case medium = "月视图"
        var id: String { rawValue }
        var family: WidgetFamily {
            switch self {
            case .small: return .systemSmall
            case .medium: return .systemMedium
            }
        }
    }

    private var weekLabel: String {
        let week = Calendar.current.component(.weekday, from: previewDate)
        return ["", "周日", "周一", "周二", "周三", "周四", "周五", "周六"][week]
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Picker("預览", selection: $selectedPreview) {
                        ForEach(PreviewSize.allCases) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                    HStack {
                        Button {
                            previewDate = Calendar.current.date(byAdding: .month, value: -1, to: previewDate) ?? previewDate
                        } label: { Image(systemName: "chevron.left") }
                        .buttonStyle(.plain)
                        Spacer()
                        Text("预览：\(weekLabel)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            previewDate = Calendar.current.date(byAdding: .month, value: 1, to: previewDate) ?? previewDate
                        } label: { Image(systemName: "chevron.right") }
                        .buttonStyle(.plain)
                    }
                    ShiftCalendarView(config: config, date: previewDate, familyOverride: selectedPreview.family)
                        .frame(height: selectedPreview == .small ? 195 : 260)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
                }
                .padding(.vertical, 5)
                .listRowInsets(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
            } header: {
                Text("实时预览")
            }

            Section {
                ForEach(config.cycle.indices, id: \.self) { index in
                    HStack(spacing: 12) {
                        Text(String(format: "%02d", index + 1))
                            .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 27, height: 27)
                            .background(Circle().fill(Color.secondary.opacity(0.1)))
                        TextField("班次名称", text: Binding(
                            get: { config.cycle.indices.contains(index) ? config.cycle[index] : "" },
                            set: { newValue in
                                guard config.cycle.indices.contains(index) else { return }
                                config.cycle[index] = String(newValue.prefix(8))
                            }
                        ))
                        .submitLabel(.done)
                        if index < config.cycle.count - 1 {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .onDelete { offsets in
                    guard config.cycle.count - offsets.count >= 1 else { return }
                    config.cycle.remove(atOffsets: offsets)
                }
                .onMove { source, destination in
                    config.cycle.move(fromOffsets: source, toOffset: destination)
                }

                if config.cycle.count < 14 {
                    Button {
                        config.cycle.append("白班")
                    } label: {
                        Label("添加一个班次", systemImage: "plus.circle.fill")
                            .fontWeight(.medium)
                    }
                }

                DatePicker("循环从哪天开始", selection: $config.anchorDate, displayedComponents: .date)
                    .datePickerStyle(.compact)

                LabeledContent("锚点当天班次", value: config.cycle.first ?? "白班")
                    .foregroundStyle(.secondary)
            } header: {
                Text("排班循环 · \(config.cycle.count) 天")
            } footer: {
                Text("从上往下依次循环。例：白班 → 夜班 → 休息 → 休息。第一天日期代表循环中的第一个班次。长按或左滑可调整顺序与删除。")
            }

            Section {
                Picker("日历风格", selection: Binding(
                    get: { config.style },
                    set: { config.style = $0 }
                )) {
                    ForEach(ShiftCalendarStyle.allCases) { style in
                        Text(style.label).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                HStack(spacing: 8) {
                    styleSwatch(.aurora, title: "极光", gradient: [Color(hex: "#1B2B49"), Color(hex: "#183B4B")])
                    styleSwatch(.editorial, title: "简约", gradient: [Color(hex: "#F3F0E9"), Color(hex: "#D6CBB8")])
                    styleSwatch(.soft, title: "柔和", gradient: [Color(hex: "#F7F0FF"), Color(hex: "#EEF6FF")])
                }
                .padding(.vertical, 4)
            } header: {
                Text("视觉风格")
            } footer: {
                Text("极光：深色渐变，夜间也清晰。简约：暖调纸感。柔和：浅色渐变，轻盈明亮。")
            }

            Section {
                Button {
                    save()
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                        Text("保存排班并刷新小组件")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.vertical, 5)
                }
                .disabled(config.cycle.isEmpty || config.cycle.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }))
            } footer: {
                Text("保存后回到桌面，长按小组件 → 编辑小组件可选尺寸；若桌面暂未更新，稍等片刻。")
            }
        }
        .navigationTitle("倒班日历")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .alert("排班已保存", isPresented: $saved) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("小组件已刷新。班次会按循环规律自动排到过去和未来。")
        }
    }

    private func styleSwatch(_ style: ShiftCalendarStyle, title: String, gradient: [Color]) -> some View {
        Button {
            config.style = style
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 48)
                    .overlay(alignment: .topLeading) {
                        HStack(spacing: 4) {
                            Circle().fill(Color(hex: "#5EDBC5")).frame(width: 8, height: 8)
                            Circle().fill(Color(hex: "#FF8B7B")).frame(width: 8, height: 8)
                            Circle().fill(Color(hex: "#739BFF")).frame(width: 8, height: 8)
                        }
                        .padding(8)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if config.style == style {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(.white)
                                .padding(6)
                        }
                    }
                Text(title)
                    .font(.caption.weight(config.style == style ? .bold : .medium))
                    .foregroundStyle(config.style == style ? Color.accentColor : Color.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private func save() {
        var normalized = config
        normalized.cycle = config.cycle.map { String($0.trimmingCharacters(in: .whitespacesAndNewlines).prefix(8)) }
        SharedStore.saveShiftCalendar(normalized)
        config = normalized
        saved = true
    }
}
