//
//  WizardPane.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/24.
//

import SwiftUI

struct WizardPane: View {
    @State private var pane: PresetParts = .Language
    
    var body: some View {
        NavigationStack {
            switch pane {
            case .Language:
                LanguageChange().padding()
            case .Policy:
                PolicyReading(
                    navigator: { what in
                        if what == 0 {
                            pane = .Language
                        } else {
                            TBCore.shared.configSetValue(key: "licenseAgreed", data: true)
                            pane = .Resources
                        }
                    }
                )
                .padding()
                .onAppear {
                    if TBCore.shared.configGetConfig(forKey: "licenseAgreed", def: false) { pane = .Resources }
                }
            case .Resources:
                ResourceDownload(
                    navigator: { what in
                        if what == 3 {
                            TBCore.shared.configSetValue(key: "useBundledItems", data: true)
                        } else if what == 1 {
                            TBCore.shared.configSetValue(key: "useBundledItems", data: false)
                        }
                        pane = .DeviceInfo
                    }
                ).padding()
            case .DeviceInfo:
                DeviceInfo()
            case .Finished:
                FinshSettings()
                    .onTapGesture {
                        print("ok yes")
                    }
            }
        }
        .navigationTitle(Text("wizard.windowTitle"))
        .onAppear {
            let needLanguage = TBCore.shared.configGetConfig(forKey: "configuredLang", def: false)
            if !needLanguage { pane = .Language } else { pane = .Policy }
        }
    }
    
    enum PresetParts {
        case Language; case Policy; case Resources; case Finished; case DeviceInfo
    }
}

#Preview {
    WizardPane()
}
