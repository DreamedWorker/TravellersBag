//
//  ContentView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/5.
//

import SwiftUI

/// 容器的功能分区
private enum Functions {
    case Notice //主页
    case Launcher //启动项
    case Account //账号管理
}

struct ContentView: View {
    @State private var showUI = false
    @State private var selectedFeat: Functions = .Notice
    
    var body: some View {
        if showUI {
            NavigationSplitView {
                List(selection: $selectedFeat) {
                    NavigationLink(value: Functions.Notice, label: { Label("home.sider.notice", systemImage: "house")} )
                    Spacer()
                    NavigationLink(value: Functions.Launcher, label: { Label("home.sider.launcher", systemImage: "play")} )
                    NavigationLink(value: Functions.Account, label: { Label("home.sider.account", systemImage: "person.circle")} )
                }
            } detail: {
                switch selectedFeat {
                case .Notice: NoticeScreen()
                case .Account: AccountManagerScreen()
                case .Launcher: LauncherScreen()
                }
            }
        } else {
            VStack {
                Image(systemName: "timer").font(.system(size: 32))
                    .padding(.bottom, 8)
                Text("home.container").font(.headline)
            }.padding()
                .onAppear {
                    Task {
                        await LocalEnvironment.shared.checkFigurePointer()
                        DispatchQueue.main.async {
                            showUI.toggle()
                        }
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
