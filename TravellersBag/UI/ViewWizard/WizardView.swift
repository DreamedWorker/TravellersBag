//
//  WizardView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/24.
//

import SwiftUI

struct WizardView: View {
    
    @State private var part: WizardViewPanes = .Hello
    
    @ViewBuilder
    var body: some View {
        NavigationStack {
            switch part {
            case .Hello:
                WizardHelloPane(
                    goNext: { part = .Lang }
                )
            case .Lang:
                WizardLangPane(
                    goNext: { part = .Doc }
                )
            case .Doc:
                WizardLicensePane(
                    goNext: { part = .Res }
                )
            case .Res:
                WizardResPane(
                    goNext: { part = .Final }
                )
            case .Final:
                WizardFinalPane()
            }
        }
        .padding(.all, 20)
    }
}

enum WizardViewPanes {
    case Hello
    case Lang
    case Doc
    case Res
    case Final
}

#Preview {
    WizardView()
}
