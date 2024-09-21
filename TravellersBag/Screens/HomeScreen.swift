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
                    }
                }
            )
            .toast(isPresenting: $viewModel.showAlert.showIt, alert: {
                AlertToast(
                    type: (2 - viewModel.showAlert.type > 0) ? .complete(.green) : .error(.red),
                    title: viewModel.showAlert.msg
                )
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
}
