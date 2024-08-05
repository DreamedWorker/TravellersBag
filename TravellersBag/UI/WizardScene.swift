//
//  WizardScene.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/5.
//

import SwiftUI
import AlertToast
import MMKV

struct WizardScene: View {
    @State private var finishToast = false
    
    var body: some View {
        VStack {
            Image("app_logo")
                .resizable()
                .frame(width: 48, height: 48)
                .scaledToFit()
            Text("app.name").font(.title2)
                .padding(.bottom, 8)
            Text("app.description").multilineTextAlignment(.leading)
                .padding(.bottom, 4)
            Form {
                Link(destination: URL(string: "https://www.gnu.org/licenses/gpl-3.0.html")!, label: {
                    Label("wizard.look_gpl", systemImage: "licenseplate")
                })
                Link(destination: URL(string: "https://www.apple.com")!, label: {
                    Label("wizard.look_repo", systemImage: "opticaldiscdrive")
                })
            }.formStyle(.grouped)
            Spacer()
            Text("app.description.2").font(.footnote).multilineTextAlignment(.leading)
            Text("wizard.look_gpl.tip").font(.footnote)
            Divider()
            HStack {
                Button(action: {
                    exit(0) //不同意者直接退出
                }, label: {
                    Text("wizard.cancel")
                }).padding(.trailing, 8)
                Button(action: {
                    MMKV.default()!.set("0.0.1", forKey: "appVersion") // 完成初始化
                    finishToast.toggle()
                    exit(0)
                }, label: {
                    Text("wizard.ok")
                })
            }
        }
        .padding()
        .onAppear {
            LocalNotification.shared.requestPermission() //发起通知权限请求
        }
        .toast(isPresenting: $finishToast, alert: { AlertToast(type: .regular, title: "wizard.toask.finished")} )
    }
}

#Preview {
    WizardScene()
}
