//
//  WizardLangPane.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/6.
//

import SwiftUI

extension WizardView {
    struct WizardLangPane: View {
        @State private var selectedLang: WizardLangs = .EN
        let goNext: () -> Void
        
        var body: some View {
            VStack {
                Image(systemName: "globe")
                    .resizable().scaledToFit()
                    .foregroundStyle(.accent)
                    .frame(width: 96)
                    .onAppear {
                        let lang = UserDefaults.getCurrentLangCode()
                        if lang.contains("ch") || lang.contains("zh") {
                            selectedLang = .ZH
                        }
                    }
                Text("wizard.lang.title")
                    .font(.largeTitle).fontWeight(.black)
                Text("wizard.lang.exp")
                    .padding(.top, 2)
                Form {
                    Picker(
                        "wizard.lang.select",
                        selection: $selectedLang
                    ) {
                        Text("wizard.lang.select.zh").tag(WizardLangs.ZH)
                        Text("wizard.lang.select.en").tag(WizardLangs.EN)
                    }
                }
                .formStyle(.grouped).scrollDisabled(true)
                Image(systemName: "info.circle")
                    .font(.title3).symbolRenderingMode(.multicolor)
                Text("wizard.lang.tip").font(.footnote).foregroundStyle(.secondary)
                Divider()
                HStack {
                    StyledButton(
                        text: "wizard.lang.skip",
                        actions: goNext
                    )
                    StyledButton(
                        text: "wizard.lang.set",
                        actions: {
                            UserDefaults.setLanguage(lang: selectedLang)
                            NSApplication.shared.terminate(self)
                        },
                        colored: true
                    )
                }
            }
        }
        
    }
}
