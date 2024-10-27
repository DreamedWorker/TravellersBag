//
//  PolicyReading.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2024/10/27.
//

import SwiftUI

struct PolicyReading : View {
    let navigator: (Int) -> Void
    
    var body: some View {
        VStack {
            Image(systemName: "doc.richtext").resizable().foregroundStyle(.accent).frame(width: 72, height: 72)
            Text("wizard.policy.title").font(.title).bold().padding(.bottom, 4)
            Text("wizard.policy.subtitle").font(.title3).multilineTextAlignment(.leading).padding(.bottom, 32)
            HStack(spacing: 16) {
                Image("app_logo").resizable().scaledToFit().frame(width: 98, height: 98)
                VStack(alignment: .leading, spacing: 16) {
                    PolicyTile(name: "wizard.policy.typeLicense", url: "https://www.gnu.org/licenses/gpl-3.0.html")
                    PolicyTile(name: "wizard.policy.typeUser", url: "https://bluedream.icu/TravellersBag")
                    PolicyTile(name: "wizard.policy.typePrivate", url: "https://bluedream.icu/TravellersBag")
                }
            }.padding(.bottom, 8)
            Text("wizard.policy.hutao").font(.callout).foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 16) {
                Button("wizard.policy.previous", action: { navigator(0) })
                Button("wizard.policy.confirm", action: { navigator(1) })
                    .buttonStyle(BorderedProminentButtonStyle())
            }
        }
    }
}

private struct PolicyTile : View {
    let name: String
    let url: String
    
    var body: some View {
        HStack(spacing: 8) {
            Label("wizard.policy.read", systemImage: "doc.append.fill")
            Link(NSLocalizedString(name, comment: ""), destination: URL(string: url)!)
        }
    }
}
