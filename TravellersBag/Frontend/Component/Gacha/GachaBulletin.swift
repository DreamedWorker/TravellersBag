//
//  GachaBulletin.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/6/1.
//

import SwiftUI

struct GachaBulletin: View {
    let specificData: [GachaItem] // 数据总表
    let goldenCharacter: [GachaItem] // 5星物品表
    let gachaTitle: String
    let gachaHistory: GachaEvent
    let showUp: Bool
    
    @State private var showDetail: Bool = true
    @State private var fiveStars: [FiveStarAnalysis] = []
    
    init(specificData: [GachaItem], gachaTitle: String, event: GachaEvent, showUp: Bool = false) {
        self.specificData = specificData
        self.gachaHistory = event
        self.showUp = showUp
        self.goldenCharacter = specificData.filter { $0.rankType == "5" }.sorted(by: { Int($0.id)! < Int($1.id)! })
        self.gachaTitle = gachaTitle
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(NSLocalizedString(gachaTitle, comment: "")).font(.title2).bold()
                Spacer()
                Button(action: {
                    withAnimation(.smooth, { showDetail.toggle() })
                }, label: {
                    Image(systemName: showDetail ? "arrow.up" : "arrow.down").font(.callout)
                })
            }
            DisplayEntry(icon: "tray.full.fill", title: "gacha.overview.total", count: String(specificData.count))
            DisplayEntry(
                icon: "5.circle", title: "gacha.overview.last_five",
                count: (!goldenCharacter.isEmpty) ? String(specificData.count - lastWantedItem(rank: 5)): "\(0)"
            )
            DisplayEntry(
                icon: "4.circle", title: "gacha.overview.last_four",
                count: (!goldenCharacter.isEmpty) ? String(specificData.count - lastWantedItem(rank: 4)): "\(0)"
            )
            ScrollView(showsIndicators: false) {
                LazyVStack {
                    ForEach(fiveStars) { single in
                        Text("\(single.itemName)在\(single.pullsSinceLastFiveStar)抽时出现，歪：\(!single.isUpItem)")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
        .frame(minWidth: 230, idealWidth: 250)
        .onAppear {
            Task {
                let result = analyzeFiveStars()
                DispatchQueue.main.async {
                    self.fiveStars = result
                }
            }
        }
    }
    
    func extractFiveStars() -> [(record: GachaItem, pullsSinceLast: Int)] {
        var result: [(GachaItem, Int)] = []
        var countSinceLastFiveStar = 0
        for record in specificData {
            countSinceLastFiveStar += 1
            if record.rankType == "5" {
                result.append((record, countSinceLastFiveStar))
                countSinceLastFiveStar = 0
            }
        }
        return result
    }
    
    func matchEvent(for record: GachaItem, from events: GachaEvent) -> GachaEventElement? {
        let result = events.first(where: { event in
            record.gachaType == String(event.type) &&
            record.time.dateFromFormattedString() >= event.from.dateFromISOFormattedString()
            && record.time.dateFromFormattedString() <= event.to.dateFromISOFormattedString()
        })
        return result
    }
    
    func analyzeFiveStars() -> [FiveStarAnalysis] {
        return extractFiveStars().map { (record: GachaItem, pullsSinceLast: Int) in
            let matchedEvent = matchEvent(for: record, from: gachaHistory)
            // 如果找不到匹配活动，则认为没有歪
            let upItemId = matchedEvent?.upOrangeList.first ?? 10008
            let isUp = String(upItemId) == StaticHelper.getIdByName(name: record.name)
            return FiveStarAnalysis(id: record.id, itemName: record.name, pullsSinceLastFiveStar: pullsSinceLast, isUpItem: isUp)
        }
    }
    
    /// 获取目标对象的相对位置
    func lastWantedItem(rank: Int) -> Int {
        if specificData.contains(where: { $0.rankType == "\(rank)" }){
            // 这里使用包含测试是为了下面这个返回值使用的「!」不会报错
            return (Int(exactly: specificData.lastIndex(where: { $0.rankType == "\(rank)" })!)! + 1)
        } else {
            return 0
        }
    }
}

extension GachaBulletin {
    struct DisplayEntry: View {
        let icon: String
        let title: String
        let count: String
        
        var body: some View {
            HStack {
                Label(NSLocalizedString(title, comment: ""), systemImage: icon)
                Spacer()
                Text(String.localizedStringWithFormat(NSLocalizedString("gacha.overview.count", comment: ""), count))
                    .foregroundStyle(.secondary)
            }.font(.callout).padding(.horizontal, 4).padding(.bottom, 2)
        }
    }
}

extension GachaBulletin {
    struct FiveStarAnalysis: Identifiable {
        let id: String
        let itemName: String
        let pullsSinceLastFiveStar: Int
        let isUpItem: Bool
    }
}
