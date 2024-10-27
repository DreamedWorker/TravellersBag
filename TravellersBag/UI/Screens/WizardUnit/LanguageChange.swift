//
//  LanguageChange.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2024/10/27.
//

import SwiftUI

struct LanguageChange : View {
    @State private var lang: String = "def"
    
    var body: some View {
        VStack {
            Image(systemName: "globe").resizable().foregroundStyle(.accent).frame(width: 72, height: 72)
            Text("wizard.language.title").font(.title).bold().padding(.bottom, 4)
            Text("wizard.language.subtitle").font(.title3)
            Form {
                Picker(
                    selection: $lang,
                    content: {
                        Text("wizard.language.typeDef").tag("def")
                        Text("wizard.language.typeEN").tag("en")
                        Text("wizard.language.typeCHS").tag("chs")
                    },
                    label: { Label("wizard.language.label", systemImage: "globe") }
                )
                .onAppear {
                    switch TBCore.shared.langGetCurrentLanguage() {
                    case "zh-Hans", "zh-Hans-CN":
                        lang = "chs"
                        break
                    default:
                        lang = "en"
                        break
                    }
                }
            }.formStyle(.grouped)
            Spacer()
            Button("wizard.language.confirm", action: {
                TBCore.shared.langWriteNeoLanguage(langType: lang)
                TBCore.shared.configSetValue(key: "configuredLang", data: true)
                NSApplication.shared.terminate(self)
            })
        }
    }
}
