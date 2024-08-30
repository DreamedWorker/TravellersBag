//
//  HomeContainer.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/15.
//

import SwiftUI
import AlertToast

struct HomeContainer: View {
    @AppStorage("currentAppVersion") var currentVersion: String = "0.0.0"
    @StateObject private var controller = HomeController.shared
    @Environment(\.managedObjectContext) private var dataManager
    @Environment(\.colorScheme) private var appColor
    
    var body: some View {
        if currentVersion != "0.0.1" {
            WizardPart(changeVersion: { currentVersion = "0.0.1" })
        } else {
            HomePart()
                .onAppear {
                    controller.initSomething(inContext: dataManager)
                    GlobalHutao.shared.initSomething(dm: dataManager)
                }
                .toast(
                    isPresenting: $controller.showErrDialog,
                    alert: { AlertToast(type: .error(.red), title: controller.errDialogMessage) })
                .toast(
                    isPresenting: $controller.showInfoDialog,
                    alert: { AlertToast(type: .complete(.green), title: controller.infoDialogMessage) })
                .toast(
                    isPresenting: $controller.showLoadingDialog,
                    alert: {
                        AlertToast(
                            type: .loading,
                            title: controller.loadingMessage,
                            style: .style(backgroundColor: (appColor == .dark) ? .black : .white)
                        )
                    })
        }
    }
}

/// 容器的功能分区
private enum Functions {
    case Notice //主页
    case Launcher //启动项
    case Account //账号管理
    case Character //游戏角色
    case Gacha //祈愿记录
}

private struct HomePart: View {
    @State private var selectedFeat: Functions = .Notice
    @State private var showUI: Bool = false
    
    var body: some View {
        if showUI {
            NavigationSplitView {
                List(selection: $selectedFeat) { // 这里会有一个奇怪的报错，但我们忽视它，因为苹果自己的示例项目也报了相同的错误。
                    NavigationLink(value: Functions.Notice, label: { Label("home.sider.notice", systemImage: "house")} )
                    Spacer()
                    NavigationLink(value: Functions.Launcher, label: { Label("home.sider.launcher", systemImage: "play")} )
                    NavigationLink(value: Functions.Gacha, label: { Label("home.sider.gacha", systemImage: "menucard")})
                    NavigationLink(value: Functions.Character, label: { Label("home.sider.characters", systemImage: "figure.walk")} )
                    Spacer()
                    NavigationLink(value: Functions.Account, label: { Label("home.sider.account", systemImage: "person.circle")} )
                }
            } detail: {
                switch selectedFeat {
                case .Account:
                    AccountScreen()
                case .Launcher: LaunchOptionScreen()
                case .Character: CharacterScreen()
                case .Notice: NoticeScreen()
                case .Gacha: GachaScreen()
                }
            }
        } else {
            VStack {
                Image(systemName: "timer").font(.system(size: 32))
                    .padding(.bottom, 8)
                Text("home.container").font(.headline)
            }
            .padding()
            .onAppear {
                Task {
                    await LocalEnvironment.shared.checkFigurePointer()
                    DispatchQueue.main.async { self.showUI.toggle() }
                }
            }
        }
    }
}

private struct WizardPart: View {
    let changeVersion: () -> Void
    
    var body: some View {
        VStack {
            Image("app_logo")
                .resizable()
                .frame(width: 48, height: 48)
                .scaledToFit()
                .padding(.vertical, 8)
            Text("app.name").font(.title2).padding(.bottom, 8)
            Text("app.description").multilineTextAlignment(.leading).padding(4)
            VStack {
                Link(destination: URL(string: "https://www.gnu.org/licenses/gpl-3.0.html")!, label: {
                    Label("wizard.look_gpl", systemImage: "licenseplate")
                })
                ZStack {}.frame(height: 4)
                Link(destination: URL(string: "https://github.com/DreamedWorker/TravellersBag")!, label: {
                    Label("wizard.look_repo", systemImage: "opticaldiscdrive")
                })
                ZStack {}.frame(height: 4)
                Link(destination: URL(string: "https://buledream.icu/TravellersBag")!, label: {
                    Label("wizard.license", systemImage: "shield.lefthalf.filled")
                })
            }.padding(.bottom, 4)
            Spacer()
            Text("app.description_2").font(.footnote).multilineTextAlignment(.leading).padding(4)
            Text("wizard.look_gpl.tip").font(.footnote).multilineTextAlignment(.leading)
            Divider()
            HStack {
                Button(action: {
                    exit(0) //不同意者直接退出
                }, label: {
                    Text("wizard.cancel")
                }).padding(.trailing, 8)
                    .buttonStyle(BorderedProminentButtonStyle())
                Button(action: {
                    changeVersion()
                }, label: {
                    Text("wizard.ok")
                })
            }.padding(.bottom, 8)
        }.frame(maxWidth: 450)
    }
}
