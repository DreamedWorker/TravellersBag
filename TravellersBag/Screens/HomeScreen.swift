//
//  HomeScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/9.
//

import SwiftUI
import AlertToast

struct HomeScreen: View {
    @Environment(\.managedObjectContext) private var dm
    @ObservedObject private var viewModel = GlobalUIModel.exported
    @State private var part: ScreenPart = .Notice
    
    var body: some View {
        if viewModel.showUI {
            NavigationSplitView(
                sidebar: {
                    List(selection: $part) {
                        NavigationLink(value: ScreenPart.Accounts, label: { Label("home.sider.account", systemImage: "person.fill") })
                        Text("home.side.title.basic").font(.callout).bold().padding(4)
                        NavigationLink(value: ScreenPart.Notice, label: { Label("home.sider.notice", systemImage: "newspaper") })
                        NavigationLink(
                            value: ScreenPart.Dashboard, label: { Label("home.sider.dashboard", systemImage: "list.bullet.clipboard") })
                        NavigationLink(value: ScreenPart.Gacha, label: { Label("home.sider.gacha", systemImage: "giftcard") })
                        NavigationLink(value: ScreenPart.Achievement, label: { Label("home.sider.achieve", systemImage: "flag.checkered.2.crossed") })
                        Text("home.side.title.game").font(.callout).bold().padding(4)
                        NavigationLink(value: ScreenPart.DialyNote, label: { Label("home.sider.daily", systemImage: "macbook.and.ipad")})
                        NavigationLink(value: ScreenPart.Avatar, label: { Label("home.sider.avatar", systemImage: "figure.wave")})
                        NavigationLink(value: ScreenPart.Index, label: { Label("home.sider.index", systemImage: "info.bubble")})
                        NavigationLink(
                            value: ScreenPart.Adopt,
                            label: { Label("home.sider.adopt", systemImage: "person.crop.circle.badge.checkmark")}
                        )
                    }
                },
                detail: {
                    switch part {
                    case .Accounts:
                        AccountManager()
                    case .Notice:
                        NoticeScreen()
                    case .Dashboard:
                        DashboardScreen().navigationTitle(Text("home.sider.dashboard"))
                    case .Gacha:
                        GachaOverview().navigationTitle(Text("home.sider.gacha"))
                    case .Achievement:
                        AchievementScreen().navigationTitle(Text("home.sider.achieve"))
                    case .DialyNote:
                        DailyNotePane().navigationTitle(Text("home.sider.daily"))
                    case .Avatar:
                        AvatarScreen().navigationTitle(Text("home.sider.avatar"))
                    case .Index:
                        ShequIndexView().navigationTitle(Text("home.sider.index"))
                    case .Adopt:
                        AdoptCalculator().navigationTitle(Text("home.sider.adopt"))
                    }
                }
            )
            .toast(isPresenting: $viewModel.showAlert.showIt, alert: {
                AlertToast(
                    type: (2 - viewModel.showAlert.type > 0) ? .complete(.green) : .error(.red),
                    title: viewModel.showAlert.msg
                )
            })
            .toast(isPresenting: $viewModel.showLoading.showIt, alert: {
                AlertToast(type: .loading, title: viewModel.showLoading.msg)
            })
            .onAppear { // 自动刷新胡桃通行证状态（如有必要）
                let lastTime = Int(UserDefaultHelper.shared.getValue(forKey: "hutaoLastLogin", def: "0"))!
                let current = Int(Date.now.timeIntervalSince1970)
                if current - lastTime > 7200 { // 每隔两个小时登录一次
                    Task {
                        do {
                            try await HutaoService.default.loginWithKeychain(dm: dm)
                        } catch {} // 让用户手动删除账号重新登录即可
                    }
                }
            }
        } else {
            VStack {
                Image(systemName: "timer").font(.system(size: 32))
                    .padding(.bottom, 8)
                Text("home.before.fp").font(.headline)
            }
            .padding()
            .onAppear {
                viewModel.initSomething()
                Task { await viewModel.generateDeviceFp() }
            }
        }
    }
}

private enum ScreenPart {
    case Accounts
    case Notice
    case Dashboard
    case Gacha
    case Achievement
    case DialyNote
    case Avatar
    case Index
    case Adopt
}
