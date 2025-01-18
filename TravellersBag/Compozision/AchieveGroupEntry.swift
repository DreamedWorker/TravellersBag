//
//  AchieveGroupEntry.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/15.
//

import SwiftUI
import Kingfisher

struct AchieveGroupEntry: View {
    let entry: AchieveList
    let detail: ResHandler.TBResource
    
    init(entry: AchieveList) {
        self.entry = entry
        self.detail = ResHandler.default.getImageWithNameAndType(type: "AchievementIcon", name: entry.icon)
    }
    var body: some View {
        HStack(spacing: 8) {
            if detail.useLocal {
                Image(nsImage: NSImage(contentsOfFile: detail.resPath) ?? NSImage())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            } else {
                KFImage(URL(string: String(detail.resPath)))
                    .loadDiskFileSynchronously(true)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
            }
            Text(entry.name).font(.headline)
        }.padding(2)
    }
}
