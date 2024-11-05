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
        NavigationStack {
            Image(systemName: "globe").resizable().foregroundStyle(.accent).frame(width: 72, height: 72)
            Text("wizard.language.title").font(.title).bold().padding(.bottom, 4)
            Text("wizard.language.subtitle")
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
                    switch UserDefaults.langGetCurrentLanguage() {
                    case "zh-Hans", "zh-Hans-CN":
                        lang = "chs"
                        break
                    default:
                        lang = "en"
                        break
                    }
                }
            }.formStyle(.grouped)
            Text("wizard.language.translation").font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.leading)
            Spacer()
            Button(
                action: {
                    UserDefaults.langWriteNeoLanguage(langType: lang)
                    UserDefaults.configSetValue(key: "configuredLang", data: true)
                    NSApplication.shared.terminate(self)
                },
                label: { Text("wizard.language.confirm").padding(4) }
            )
        }
    }
}
