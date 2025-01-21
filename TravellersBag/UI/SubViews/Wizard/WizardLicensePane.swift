//
//  WizardLicensePane.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/6.
//

import SwiftUI

extension WizardView {
    struct WizardLicensePane: View {
        let goNext: () -> Void
        
        var body: some View {
            VStack {
                Image(systemName: "doc")
                    .font(.largeTitle)
                    .foregroundStyle(.accent)
                    .padding(.bottom, 4)
                Text("wizard.license.title").font(.title).bold()
                Text("wizard.license.description")
                    .padding(.top, 4)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom)
                Form {
                    PolicyTile(name: "wizard.license.typeUser", url: "https://bluedream.icu/TravellersBag/zh/normative/user_service_agreement.html")
                    PolicyTile(name: "wizard.license.typeInfoCollection", url: "https://bluedream.icu/TravellersBag/zh/normative/privacy.html")
                    PolicyTile(name: "wizard.license.typeOpenSource", url: "https://bluedream.icu/TravellersBag/zh/normative/gnu.html")
                    PolicyTile(name: "wizard.license.typeIssue", url: "https://bluedream.icu/TravellersBag/zh/normative/how_to_make_an_issue.html")
                }.formStyle(.grouped)
                Spacer()
                Image(systemName: "info.circle")
                    .font(.title2).foregroundStyle(.accent)
                    .padding(.bottom, 2)
                Text("wizard.license.tip").foregroundStyle(.secondary).font(.callout)
                Divider()
                Button(action: { goNext() }, label: { Text("wizard.lang.next").padding(8) })
                    .buttonStyle(BorderedProminentButtonStyle())
            }
        }
        
        private struct PolicyTile : View {
            let name: String
            let url: String
            
            var body: some View {
                HStack(spacing: 8) {
                    Label("wizard.license.read", systemImage: "doc.append.fill")
                    Link(NSLocalizedString(name, comment: ""), destination: URL(string: url)!)
                }
            }
        }
    }
}

#Preview(body: { WizardView.WizardLicensePane(goNext: {}).padding() })
