//
//  WizardFinalPane.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/7.
//

import SwiftUI
@preconcurrency import UserNotifications

extension WizardView {
    struct WizardFinalPane: View {
        var body: some View {
            VStack {
                Image(systemName: "checkmark.seal")
                    .font(.largeTitle)
                    .foregroundStyle(.accent)
                    .padding(.bottom, 4)
                Text("wizard.final.title").font(.title).bold()
                Text("wizard.final.description")
                    .padding(.top, 2)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom)
                VStack(alignment: .leading) {
                    Text("wizard.final.notification").font(.title3).bold()
                    Text("wizard.final.notificationTip").font(.callout).foregroundStyle(.secondary)
                    HStack {
                        Spacer()
                        Button("wizard.final.noticeCheck", action: { Task { await needNotification() } })
                    }.padding(.top, 4)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(BackgroundStyle()))
                Spacer()
                Image(systemName: "info.circle")
                    .font(.title2).foregroundStyle(.accent)
                    .padding(.bottom, 2)
                Text("wizard.final.tip")
                    .foregroundStyle(.secondary).font(.callout)
                Divider()
                Button(
                    action: { finishAll() },
                    label: { Text("wizard.final.finish").padding(8) }
                ).buttonStyle(BorderedProminentButtonStyle())
            }
        }
        
        private func needNotification() async {
            let center = UNUserNotificationCenter.current()
            do {
                try await center.requestAuthorization(options: [.alert, .sound, .badge, .provisional])
            } catch {
                print(error.localizedDescription)
            }
        }
        
        private func finishAll() {
            UserDefaults.standard.set("0.0.3", forKey: "lastUsedVersion")
            UserDefaults.standard.synchronize()
            NSApplication.shared.terminate(self)
        }
    }
}

#Preview(body: { WizardView.WizardFinalPane().padding() })
