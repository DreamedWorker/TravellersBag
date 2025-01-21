//
//  AboutSheet.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/20.
//

import SwiftUI

struct AboutSheet: View {
    let dismiss: () -> Void
    var body: some View {
        NavigationStack {
            Image("app_logo").resizable().frame(width: 96, height: 96)
            Text("app.name").font(.largeTitle).bold()
            Text("about.subtitle").font(.title2).bold()
            Text("about.version").font(.title3).foregroundStyle(.secondary).fontWeight(.light)
            Spacer()
            Text("about.copyright").font(.callout).foregroundStyle(.secondary)
            Spacer()
            HStack(alignment: .firstTextBaseline) {
                Button("about.normative", action: {
                    openPage(url: URL(string: "https://bluedream.icu/TravellersBag/zh/normative")!)
                })
                Button("about.openSource", action: {
                    openPage(url: URL(string: "https://bluedream.icu/TravellersBag/zh/open_source.html")!)
                })
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction, content: {
                Button("def.confirm", action: dismiss)
            })
        }
    }
    
    private func openPage(url: URL) {
        NSWorkspace.shared.open(url)
    }
}

#Preview {
    AboutSheet(dismiss: {})
}
