//
//  WizardLanguagePane.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/6.
//

import SwiftUI

extension WizardView {
    struct WizardLanguagePane: View {
        @State private var selectedLang: String = "cn"
        let goNext: () -> Void

        var body: some View {
            VStack {
                Image(systemName: "globe")
                    .font(.largeTitle)
                    .foregroundStyle(.accent)
                    .padding(.bottom, 4)
                Text("wizard.lang.title").font(.title).bold()
                Text("wizard.lang.description")
                    .padding(.top, 4)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom)
                Picker(
                    selection: $selectedLang,
                    content: {
                        Text("wizard.lang.typeCN").tag("cn")
                        Text("wizard.lang.typeEN").tag("en")
                    },
                    label: {
                        Text("wizard.lang.choose")
                    }
                ).onAppear { getCrtLang() }
                Spacer()
                Image(systemName: "info.circle")
                    .font(.title2).foregroundStyle(.accent)
                    .padding(.bottom, 2)
                Text("wizard.lang.tip")
                    .foregroundStyle(.secondary).font(.callout)
                Divider()
                HStack(spacing: 16) {
                    Button(
                        action: { changeLang() },
                        label: { Text("wizard.lang.apply").padding(8) }
                    )
                    Button(
                        action: { goNext() },
                        label: { Text("wizard.lang.next").padding(8) }
                    ).buttonStyle(BorderedProminentButtonStyle())
                }
            }
        }
        
        private func changeLang() {
            let lang = UserDefaults.standard
            if selectedLang == "cn" {
                lang.set(["zh-Hans"], forKey: "AppleLanguages")
            } else if selectedLang == "en" {
                lang.set(["en"], forKey: "AppleLanguages")
            } else {
                lang.set(["zh-Hans"], forKey: "AppleLanguages")
            }
            exit(0)
        }
        
        private func getCrtLang() {
            let str = (UserDefaults.standard.object(forKey: "AppleLanguages") as? NSArray)?.firstObject as? String
            
            if str == "zh-Hans" && str == nil {
                selectedLang = "cn"
            } else if str == "en" {
                selectedLang = "en"
            } else {
                selectedLang = "cn"
            }
        }
    }
}

#Preview(body: { WizardView.WizardLanguagePane(goNext: {}).padding() })
