//
//  WizardFinalPane.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/7.
//

import SwiftUI

extension WizardView {
    struct WizardFinalPane: View {
        var body: some View {
            VStack {
                Spacer()
                Image(systemName: "checkmark.seal")
                    .resizable().scaledToFit()
                    .foregroundStyle(.accent)
                    .frame(width: 96)
                Text("wizard.final.title")
                    .font(.largeTitle).fontWeight(.black)
                Text("wizard.final.exp")
                Spacer()
                Button(
                    action: { finishAll() },
                    label: {
                        Image(systemName: "arrow.forward.circle")
                            .font(.title).fontWeight(.bold)
                    }
                )
                .buttonStyle(.plain)
                .padding(.top)
                Spacer()
            }
        }
        
        private func finishAll() {
            UserDefaults.standard.set("0.0.4", forKey: "lastUsedVersion")
            UserDefaults.standard.synchronize()
            NSApplication.shared.terminate(self)
        }
    }
}
