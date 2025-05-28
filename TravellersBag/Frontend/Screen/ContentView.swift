//
//  ContentView.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/13.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var lastOpenedAppVersion = ConfigManager.getSettingsValue(key: ConfigKey.APP_LAST_USED_VERSION, value: "0.0.0")
    @State private var showWizardWindow = false
    @Query(filter: #Predicate<HoyoAccount> { $0.activedAccount }) private var defAccount: [HoyoAccount]
    @State private var panePart: StagePart = .announcement
    
    var body: some View {
        NavigationSplitView(sidebar: {
            if lastOpenedAppVersion == "1.0.0-10000" {
                List(selection: $panePart) {
                    AccountCapsule(des: .account, account: defAccount.first)
                    Section("content.side.title.general") {
                        NavigationLink(value: StagePart.announcement, label: { Label("content.side.label.anno", systemImage: "bell.badge") })
                    }
                    Section("content.side.title.feature") {
                        NavigationLink(value: StagePart.gacha, label: { Label("content.side.label.gacha", systemImage: "app.gift") })
                    }
                    Section("content.side.title.web") {
                        NavigationLink(value: StagePart.bbsIndex, label: { Label("content.side.label.home", systemImage: "house") })
                        NavigationLink(value: StagePart.adopt, label: { Label("content.side.label.adopt", systemImage: "figure.child") })
                        NavigationLink(value: StagePart.sign, label: { Label("content.side.label.sign", systemImage: "calendar") })
                    }
                }.frame(minWidth: 180, idealWidth: 210)
            }
        }, detail: {
            if lastOpenedAppVersion != "1.0.0-10000" {
                ContentUnavailableView("wizard.blocked", systemImage: "hand.raised", description: Text("wizard.blocked.exp"))
            } else {
                switch panePart {
                case .account:
                    AccountView()
                case .bbsIndex:
                    WebStaticView(requiredPage: "https://webstatic.mihoyo.com/app/community-game-records/")
                case .adopt:
                    WebStaticView(requiredPage: "https://webstatic.mihoyo.com/ys/event/e20200923adopt_calculator/")
                case .sign:
                    WebStaticView(requiredPage: "https://act.mihoyo.com/bbs/event/signin/hk4e/index.html?act_id=e202311201442471")
                case .announcement:
                    AnnouncementView()
                case .gacha:
                    GachaView().navigationTitle(Text("content.side.label.gacha"))
                }
            }
        })
        .onAppear {
            if lastOpenedAppVersion != "1.0.0-10000" {
                showWizardWindow = true
            }
        }
        .sheet(isPresented: $showWizardWindow) {
            WizardView {
                ConfigManager.setSettingsValue(key: ConfigKey.APP_LAST_USED_VERSION, value: "1.0.0-10000")
                showWizardWindow = false
                lastOpenedAppVersion = ConfigManager.getSettingsValue(key: ConfigKey.APP_LAST_USED_VERSION, value: "0.0.0")
            }
        }
    }
    
    enum StagePart {
        case account
        case bbsIndex
        case adopt
        case sign
        case announcement
        case gacha
    }
}

#Preview {
    ContentView()
}
