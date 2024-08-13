//
//  ContentView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/5.
//

import SwiftUI
import AlertToast

/// 容器的功能分区
private enum Functions {
    case Notice //主页
    case Launcher //启动项
    case Account //账号管理
    case Character //游戏角色
}

/// 全局消息弹出管理
class ContentMessager : ObservableObject { // 这个类必须是单例类
    static let shared = ContentMessager()
    
    @Published var showErrDialog: Bool = false // 显示错误弹窗
    @Published var errDialogMessage: String = ""
    
    @Published var showInfoDialog: Bool = false // 显示基本消息弹窗
    @Published var infoDialogMessage: String = ""
    
    /// 呼出一个错误弹窗 【必须在UI线程执行】
    func showErrorDialog(msg: String) {
        showErrDialog = true; errDialogMessage = msg
    }
    
    /// 呼出一个基本信息弹窗 【必须在UI线程执行】
    func showInfomationDialog(msg: String) {
        showInfoDialog = true; infoDialogMessage = msg
    }
}

struct ContentView: View {
    @State private var showUI = false
    @State private var selectedFeat: Functions = .Notice
    @StateObject private var msgHelper = ContentMessager.shared
    
    var body: some View {
        if showUI {
            NavigationSplitView {
                List(selection: $selectedFeat) {
                    NavigationLink(value: Functions.Notice, label: { Label("home.sider.notice", systemImage: "house")} )
                    Spacer()
                    NavigationLink(value: Functions.Launcher, label: { Label("home.sider.launcher", systemImage: "play")} )
                    NavigationLink(value: Functions.Character, label: { Label("home.sider.characters", systemImage: "figure.walk")} )
                    Spacer()
                    NavigationLink(value: Functions.Account, label: { Label("home.sider.account", systemImage: "person.circle")} )
                }
            } detail: {
                switch selectedFeat {
                case .Notice: NoticeScreen()
                case .Account: AccountManagerScreen()
                case .Launcher: LauncherScreen()
                case .Character: CharacterScreen()
                }
            }
            // 注册上述两个全局信息弹窗
            .toast(isPresenting: $msgHelper.showErrDialog, alert: { AlertToast(type: .error(.red), title: msgHelper.errDialogMessage) })
            .toast(isPresenting: $msgHelper.showInfoDialog, alert: { AlertToast(type: .complete(.green), title: msgHelper.infoDialogMessage) })
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
