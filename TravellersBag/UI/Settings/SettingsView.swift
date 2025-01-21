//
//  SettingsView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/20.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("settings.back").font(.title2).bold().foregroundStyle(.red)
                    Text("settings.back.des").foregroundStyle(.secondary).multilineTextAlignment(.leading).padding(.bottom, 4).font(.callout)
                    HStack {
                        Spacer()
                        Button(
                            action: {
                                UserDefaults.standard.set("0.0.0", forKey: "lastUsedVersion")
                                UserDefaults.standard.synchronize()
                                NSApplication.shared.terminate(self)
                            },
                            label: { Text("def.confirm").foregroundStyle(.red) }
                        )
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.background))
                .frame(maxWidth: 500)
            }.tabItem({ Label("settings.normal", systemImage: "gearshape")})
            ScrollView {
                WizardView.WizardResourcePane(goNext: {}, usedInSettings: true).frame(maxWidth: 500)
            }.tabItem({ Label("settings.resource", systemImage: "photo")})
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}
