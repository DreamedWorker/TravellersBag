//
//  WizardLicensePane.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/25.
//

import SwiftUI

struct WizardLicensePane: View {
    let goNext: () -> Void
    
    var body: some View {
        VStack {
            Image(systemName: "doc.richtext.zh")
                .symbolRenderingMode(.multicolor)
                .resizable().scaledToFit()
                .foregroundStyle(.accent)
                .frame(width: 72)
            Text("wizard.doc.title")
                .font(.largeTitle).fontWeight(.black)
            WebBrowser(initialWeb: "https://bluedream.icu/TravellersBag/normative/user_service_agreement.html")
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(minHeight: CGFloat(300))
            Spacer()
            Image(systemName: "info.circle")
                .font(.title3).symbolRenderingMode(.multicolor)
            HStack(spacing: 0) {
                Text("wizard.doc.exp").foregroundStyle(.secondary)
                Link(
                    "wizard.doc.exp.f1",
                    destination: URL(string: "https://bluedream.icu/TravellersBag/normative/privacy.html")!
                )
                Text("wizard.doc.exp.and").foregroundStyle(.secondary)
                Link(
                    "wizard.doc.exp.f2",
                    destination: URL(string: "https://bluedream.icu/TravellersBag/normative/gnu.html")!
                )
                Text("wizard.doc.exp2").foregroundStyle(.secondary)
            }.font(.footnote)
            Divider()
            HStack {
                StyledButton(
                    text: "wizard.doc.disagree",
                    actions: {
                        NSApplication.shared.terminate(self)
                    }
                )
                StyledButton(
                    text: "wizard.doc.agree",
                    actions: goNext,
                    colored: true
                )
            }
        }
    }
}

#Preview {
    WizardLicensePane(goNext: {})
}
