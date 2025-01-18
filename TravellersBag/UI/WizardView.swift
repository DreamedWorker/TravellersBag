//
//  WizardView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/6.
//

import SwiftUI

struct WizardView: View {
    private enum WizardViewParts {
        case WavePane; case LanugagePane;
        case LicensePane; case ResourcePane;
        case FinalPane
    }
    
    @State private var panePart: WizardViewParts = .WavePane
    
    var body: some View {
        switch panePart {
        case .WavePane:
            WavePaneView.padding()
        case .LanugagePane:
            WizardLanguagePane(
                goNext: { panePart = .LicensePane }
            ).padding()
        case .LicensePane:
            WizardLicensePane(goNext: { panePart = .ResourcePane })
                .padding()
        case .ResourcePane:
            WizardResourcePane(goNext: { panePart = .FinalPane })
                .padding()
        case .FinalPane:
            WizardFinalPane().padding()
        }
    }
    
    private var WavePaneView: some View {
        return VStack {
            Image("app_logo")
                .resizable()
                .frame(width: 128, height: 128)
                .padding(.bottom, 8)
            Text("wizard.wave.title")
                .font(.largeTitle).bold()
            Spacer()
            Image(systemName: "info.circle")
                .font(.title2).foregroundStyle(.accent)
                .padding(.bottom, 2)
            Text("wizard.wave.description")
            Divider()
            Button(action: { panePart = .LanugagePane }, label: { Text("wizard.wave.go").padding(8) })
                .buttonStyle(BorderedProminentButtonStyle())
        }
    }
}

#Preview {
    WizardView()
}
