//
//  WizardScreen.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/10.
//

import SwiftUI
import AlertToast

struct WizardScreen: View {
    @State private var uiMode: WizardPart = .First
    @State var agreed = UserDefaultHelper.shared.getValue(forKey: "license_agree", def: "no") == "yes"
    
    var body: some View {
        TabView(selection: $uiMode) {
            FirstPart.tabItem { Text("wizard.tab.splash") }.tag(WizardPart.First)
            Wizard(goNext: { uiMode = .Third }).tabItem { Text("wizard.tab.data") }.tag(WizardPart.Second)
            ThirdPart.tabItem { Text("wizard.tab.images") }.tag(WizardPart.Third)
        }
    }
    
    var ThirdPart: some View {
        return ScrollView {
            CardView {
                VStack {
                    if agreed {
                        Image("expecting_new_world").resizable().scaledToFit().frame(width: 72, height: 72)
                        Text("wizard.finally.title").font(.title2).bold()
                        Button("wizard.go", action: {
                            UserDefaultHelper.shared.setValue(forKey: "currentAppVersion", value: "0.0.1")
                            exit(0)
                        }).buttonStyle(BorderedProminentButtonStyle())
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.tint).font(.title2)
                        Text("wizard.data.not_agree")
                        Button("wizard.neo.refresh_license", action: {
                            agreed = UserDefaultHelper.shared.getValue(forKey: "license_agree", def: "no") == "yes"
                        }).buttonStyle(BorderedProminentButtonStyle())
                    }
                }.padding()
            }.frame(minWidth: 500)
        }
    }
    
    var FirstPart: some View {
        ScrollView {
            CardView {
                VStack {
                    Image("app_logo")
                        .resizable().scaledToFit()
                        .frame(width: 64, height: 64)
                    Text("app.name").font(.title2).bold()
                    Text("wizard.splash.p1")
                    HStack {Spacer()}
                }.padding(8)
            }
            VStack {
                Link(destination: URL(string: "https://www.gnu.org/licenses/gpl-3.0.html")!, label: {
                    Label("wizard.splash.look_gpl", systemImage: "licenseplate")
                })
                ZStack {}.frame(height: 4)
                Link(destination: URL(string: "https://github.com/DreamedWorker/TravellersBag")!, label: {
                    Label("wizard.splash.look_repo", systemImage: "opticaldiscdrive")
                })
                ZStack {}.frame(height: 4)
                Link(destination: URL(string: "https://buledream.icu/TravellersBag")!, label: {
                    Label("wizard.splash.license", systemImage: "shield.lefthalf.filled")
                })
            }.padding(.bottom, 16)
            Text("wizard.splash.p2")
                .font(.footnote).foregroundStyle(.secondary)
                .padding(.horizontal, 16)
            Divider().padding(.horizontal, 16)
            HStack {
                Button(action: {
                    UserDefaultHelper.shared.setValue(forKey: "license_agree", value: "no")
                    exit(0) //不同意者直接退出
                }, label: {
                    Text("wizard.splash.disagree")
                }).padding(.trailing, 8)
                    .buttonStyle(BorderedProminentButtonStyle())
                Button(action: {
                    UserDefaultHelper.shared.setValue(forKey: "license_agree", value: "yes")
                    uiMode = .Second
                }, label: {
                    Text("wizard.splash.agree")
                })
            }.padding(.bottom, 8)
        }
        .frame(maxWidth: 650)
    }
    
    enum WizardPart {
        case First
        case Second
        case Third
    }
}
