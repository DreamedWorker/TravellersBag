//
//  AchieveImportSheet.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/6/10.
//

import SwiftUI

struct AchieveImportSheet: View {
    let con: UIAFStandard.UIAF11Inner
    let arches: [AchieveArchive]
    
    var body: some View {
        NavigationStack {
            let appInfo = con.context.info
            Text("achieve.action.import").font(.title.bold()).padding(.bottom, 8)
            HStack {
                Label("gacha.uigf.app", systemImage: "apple.terminal")
                Spacer()
                Text(appInfo.export_app).foregroundStyle(.secondary)
            }
            .padding(.bottom, 2)
            HStack {
                Label("gacha.uigf.version", systemImage: "textformat.123")
                Spacer()
                Text(appInfo.export_app_version).foregroundStyle(.secondary)
            }
            .padding(.bottom, 2)
            HStack {
                Label("achieve.uiaf.count", systemImage: "list.number.rtl")
                Spacer()
                Text(String(con.context.list.count)).foregroundStyle(.secondary)
            }
            .padding(.bottom, 2)
            HStack {
                Label("gacha.uigf.time", systemImage: "clock.arrow.circlepath")
                Spacer()
                Text(appInfo.export_timestamp.formatTimestamp()).foregroundStyle(.secondary)
            }
            .padding(.bottom)
        }
        .padding()
    }
}
