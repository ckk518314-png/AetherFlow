# AetherFlow - iOS System Automation

AetherFlow 是一款面向 iOS 的系统级自动化 App，支持日历、提醒事项、健康数据、HomeKit 等系统能力的一站式编排。

## 技术栈

| 层级 | 选型 |
|------|------|
| UI | SwiftUI (iOS 17+) |
| 架构 | MVVM + Service Layer |
| 持久化 | UserDefaults (JSON) |
| 系统框架 | EventKit / HealthKit / HomeKit / UserNotifications / WidgetKit |
| 项目生成 | XcodeGen |
| CI | GitHub Actions (macOS 14) |
| 最低版本 | iOS 17.0 |

## 功能特性

- 流程引擎：多步骤顺序执行，失败自动中断
- 触发器：手动 / 定时 / 日历事件 / 提醒到期 / 健康数据 / HomeKit 状态 / 地理位置
- 步骤类型：日历、提醒、健康、HomeKit、通知、URL、HTTP 请求、延迟、条件判断
- Widget：桌面小组件一键触发
- 条件分支：>= != > < contains is_empty 等运算符
- 运行历史：最多 500 条

## 快速开始

```bash
brew install xcodegen
xcodegen generate
open AetherFlow.xcodeproj
```

## 项目结构

```
AetherFlow/
├── Sources/AetherFlow/
│   ├── App/AetherFlowApp.swift
│   ├── Core/Models/          # FlowDefinition / Trigger / Step / Condition
│   ├── Core/Services/        # CalendarService / Reminder / Health / HomeKit
│   ├── Core/Engine/          # FlowEngine 流程执行引擎
│   ├── Core/FlowStore.swift  # UserDefaults 持久化
│   ├── UI/Views/             # ContentView / Flows / Editor / History / Settings
│   └── Extensions/Widget/    # 桌面小组件
├── Tests/AetherFlowTests/
├── Resources/Info.plist
├── project.yml               # XcodeGen 配置
└── .github/workflows/ci.yml
```

## 要求

- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+
