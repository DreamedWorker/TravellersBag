//
//  AnnouncementPart.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/12.
//

import SwiftUI
import WaterfallGrid

struct AnnouncementPart: View {
    var specificList: [Announcement]
    
    var body: some View {
        ScrollView {
            WaterfallGrid(specificList, content: {single in
                AnnouncementCardView(
                    title: single.subtitle,
                    banner: single.banner ?? "none",
                    annID: String(single.annId),
                    subtitle: single.title
                )
            }).gridStyle(columns: 3)
        }.frame(maxHeight: 310)
    }
}

#Preview {
    AnnouncementPart(specificList: [])
}
