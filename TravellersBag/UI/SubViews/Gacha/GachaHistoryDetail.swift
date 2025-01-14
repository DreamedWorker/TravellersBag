//
//  GachaHistoryDetail.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/14.
//

import SwiftUI
import Kingfisher

extension GachaHistoryActivity {
    struct GachaHistoryDetail: View {
        let entry: ActivityEntry
        let getCount: (Int) -> Int
        let processed: [String: Int]
        
        func addThisOne(name: String) -> Bool {
            let itemId = Int(ResHandler.default.getIdByName(name: name))!
            if itemId == 0 { return false }
            if entry.oragon.contains(itemId) || entry.purple.contains(itemId) {
                return false
            } else {
                return true
            }
        }
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading) {
                    KFImage(URL(string: entry.banner))
                        .loadDiskFileSynchronously(true)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .padding(.bottom, 16)
                    Text("gacha.history.five").bold()
                    ScrollView(.horizontal) {
                        LazyHStack {
                            ForEach(entry.oragon, id: \.self){ it in
                                ItemCell(
                                    msg: ResHandler.default.getGachaItemIcon(key: String(it)),
                                    count: getCount(it),
                                    rank: "5",
                                    name: ResHandler.default.getGachaItemName(key: String(it))
                                )
                            }
                        }.padding(.horizontal, 4)
                    }
                    Text("gacha.history.four").bold()
                    ScrollView(.horizontal) {
                        LazyHStack {
                            ForEach(entry.purple, id: \.self){ it in
                                ItemCell(
                                    msg: ResHandler.default.getGachaItemIcon(key: String(it)),
                                    count: getCount(it),
                                    rank: "4",
                                    name: ResHandler.default.getGachaItemName(key: String(it))
                                )
                            }
                        }.padding(.horizontal, 4)
                    }
                    Text("gacha.history.other").bold()
                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible()), .init(.flexible()), .init(.flexible()), .init(.flexible())]) {
                        ForEach(processed.keys.sorted(), id: \.self) { single in
                            ItemCell(
                                msg: ResHandler.default.getGachaItemIcon(key: ResHandler.default.getIdByName(name: single)),
                                count: processed[single] ?? 0,
                                rank: ResHandler.default.getItemRank(key: ResHandler.default.getIdByName(name: single)),
                                name: single
                            )
                        }
                    }
                }
            }
        }
    }
    
    private struct ItemCell: View {
        let msg: ResHandler.TBResource
        let count: Int
        let rank: String
        let name: String
        
        var body: some View {
            VStack {
                ZStack {
                    switch rank {
                    case "5":
                        Image("UI_QUALITY_ORANGE")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                    case "4":
                        Image("UI_QUALITY_PURPLE")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                    default:
                        Image("UI_QUALITY_BLUE")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                    }
                    if !msg.useLocal {
                        KFImage(URL(string: String(msg.resPath)))
                            .loadDiskFileSynchronously(true)
                            .resizable()
                            .frame(width: 48, height: 48)
                    } else {
                        Image(nsImage: NSImage(contentsOfFile: String(msg.resPath)) ?? NSImage())
                            .resizable()
                            .frame(width: 48, height: 48)
                    }
                }
                Text(String(count))
            }
            .help(name)
            .padding(4)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
        }
    }
}
