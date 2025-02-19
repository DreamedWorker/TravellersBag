//
//  WizardHelloPane.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/25.
//

import SwiftUI

struct WizardHelloPane: View {
    
    let goNext: () -> Void
    
    var body: some View {
        VStack {
            Image("app_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 128)
            Text("wizard.hello.title")
                .font(.largeTitle).fontWeight(.black)
            Text("wizard.hello.exp")
                .padding(.top, 2)
            Spacer()
            Image(systemName: "hand.raised")
                .font(.title3)
                .symbolRenderingMode(.multicolor)
                .padding(.bottom, 2)
            Text("wizard.hello.privacy")
            Text("wizard.hello.privacy.sec")
                .font(.footnote).foregroundStyle(.secondary)
            Divider()
            StyledButton(text: "def.next", actions: goNext, colored: true)
        }
    }
}

#Preview {
    WizardHelloPane(goNext: {})
}
