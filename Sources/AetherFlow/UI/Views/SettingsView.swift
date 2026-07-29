import SwiftUI
import EventKit

struct SettingsView: View {
    @EnvironmentObject var store: FlowStore
    @EnvironmentObject var engine: FlowEngine

    @State private var showResetAlert = false

    var body: some View {
        Form {
            Section("数据") {
                HStack {
                    Text("流程数量")
                    Spacer()
                    Text("\(store.flows.count)")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("运行记录")
                    Spacer()
                    Text("\(store.runHistory.count)")
                        .foregroundColor(.secondary)
                }
            }

            Section("权限") {
                NavigationLink {
                    PermissionStatusView()
                } label: {
                    Label("权限状态", systemImage: "lock.shield")
                }
            }

            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0 (Build 1)")
                        .foregroundColor(.secondary)
                }
                Label("支持 iOS 17.0+", systemImage: "iphone")
                    .foregroundColor(.secondary)
            }

            Section {
                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Text("重置所有数据")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("设置")
        .alert("确认重置", isPresented: $showResetAlert) {
            Button("取消", role: .cancel) {}
            Button("重置", role: .destructive) {
                store.flows.removeAll()
                store.runHistory.removeAll()
                store.saveFlows()
                store.saveHistory()
            }
        } message: {
            Text("将删除所有流程和运行记录，此操作不可撤销。")
        }
    }
}

struct PermissionStatusView: View {
    @EnvironmentObject var calendar: CalendarService
    @EnvironmentObject var reminders: ReminderService
    @EnvironmentObject var health: HealthService

    var body: some View {
        List {
            PermissionRow(
                title: "日历",
                icon: "calendar",
                status: calendar.authorizationStatus.description
            ) {
                Task { let _ = try? await calendar.requestAccess() }
            }
            PermissionRow(
                title: "提醒事项",
                icon: "bell",
                status: calendar.authorizationStatus.description
            ) {
                Task { let _ = try? await reminders.requestAccess() }
            }
            PermissionRow(
                title: "健康",
                icon: "heart",
                status: "需在 App 启动时授权"
            ) {
                Task { try? await health.requestDefaultPermissions() }
            }
            PermissionRow(
                title: "通知",
                icon: "bell.badge",
                status: "系统设置"
            ) {}
        }
        .navigationTitle("权限状态")
    }
}

struct PermissionRow: View {
    let title: String
    let icon: String
    let status: String
    let action: () -> Void

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            Text(title)
            Spacer()
            Text(status)
                .font(.caption)
                .foregroundColor(.secondary)
            Button("授权") { action() }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }
}

extension EKAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "未授权"
        case .restricted:    return "受限制"
        case .denied:        return "已拒绝"
        case .fullAccess:    return "已授权"
        case .writeOnly:     return "仅写入"
        @unknown default:    return "未知"
        }
    }
}
