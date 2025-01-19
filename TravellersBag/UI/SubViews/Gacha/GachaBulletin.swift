//
//  GachaBulletin.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2032/9/32.
//

import SwiftUI
import Kingfisher

/// 总览页面的抽卡数据看板
struct GachaBulletin: View {
    let specificData: [GachaItem] // 数据总表
    let goldenCharacter: [GachaItem] // 5星物品表
    let gachaTitle: String
    
    @State private var showDetail: Bool = true
    
    init(specificData: [GachaItem], gachaTitle: String) {
        self.specificData = specificData
        self.goldenCharacter = specificData.filter { $0.rankType == "5" }.sorted(by: { Int($0.id)! < Int($1.id)! })
        self.gachaTitle = gachaTitle
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(NSLocalizedString(gachaTitle, comment: "")).font(.title2).bold()
                Spacer()
                Button(action: {
                    withAnimation(.linear, { showDetail.toggle() }) // 使用这个 看起来流程顺畅一些
                }, label: {
                    Image(systemName: showDetail ? "arrow.up" : "arrow.down").font(.callout)
                })
            }
            GroupBox(
                content: {
                    DisplayEntry(title: "gacha.overview.total", count: String(specificData.count))
                    DisplayEntry(
                        title: "gacha.overview.last_five",
                        count: (!goldenCharacter.isEmpty) ? String(specificData.count - lastWantedItem(rank: 5)): "\(0)")
                    DisplayEntry(
                        title: "gacha.overview.last_four",
                        count: (specificData.contains(where: { $0.rankType == "4" }))
                        ? String(specificData.count - lastWantedItem(rank: 4)): "\(0)"
                    )
                    ProgressView(value: Float(exactly: specificData.count - lastWantedItem(rank: 4))!, total: 10.0).padding(.bottom, 4)
                    if showDetail {
                        ScrollView {
                            LazyVStack {
                                ForEach(goldenCharacter.sorted(by: { Int($0.id)! > Int($1.id)! })){ single in
                                    FiveStarAvatarTile(avatar: single, count: getPosition(item: single))
                                }
                            }
                        }
                    }
                },
                label: {
                    if specificData.count > 0 {
                        Text(
                            String.localizedStringWithFormat(
                                NSLocalizedString("gacha.overview.time", comment: ""),
                                specificData.first!.time, specificData.last!.time)
                        )
                    } else {
                        Text("gacha.overview.no_record")
                    }
                }
            )
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
        .frame(minWidth: 230)
    }
    
    struct DisplayEntry: View {
        let title: String
        let count: String
        
        var body: some View {
            HStack {
                Text(NSLocalizedString(title, comment: ""))
                Spacer()
                Text(String.localizedStringWithFormat(NSLocalizedString("gacha.overview.count", comment: ""), count))
                    .foregroundStyle(.secondary)
            }.font(.callout).padding(.horizontal, 4).padding(.bottom, 2)
        }
    }
    
    /// 五星角色显示条
    struct FiveStarAvatarTile: View {
        let avatar: GachaItem
        let result: ResHandler.TBResource
        let count: String
        
        init(avatar: GachaItem, count: String) {
            self.avatar = avatar
            let itemId = ResHandler.default.getIdByName(name: avatar.name)
            result = ResHandler.default.getGachaItemIcon(key: itemId)
            self.count = count
        }
        
        var body: some View {
            HStack {
                ZStack {
                    Image("UI_QUALITY_ORANGE")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                    if !result.useLocal {
                        KFImage(URL(string: result.resPath))
                            .loadDiskFileSynchronously(true)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                    } else {
                        Image(nsImage: NSImage(contentsOfFile: result.resPath) ?? NSImage())
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(width: 36, height: 36)
                Text(avatar.name)
                Spacer()
                Text(String.localizedStringWithFormat(NSLocalizedString("gacha.overview.count", comment: ""), count))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    /// 日期对象转换人类可读字符串
    private func dateTransfer(date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }
    
    /// 获取5星物品的相对位置
    func getPosition(item: GachaItem) -> String {
        if let pos = specificData.firstIndex(where: { $0.id == item.id }) {
            let originPos = Int(pos) + 1
            if goldenCharacter.count > 0 {
                if goldenCharacter.firstIndex(of: item)! == 0 {
                    return String((Int(pos) + 1))
                } else {
                    let perviousOne = goldenCharacter[(Int(goldenCharacter.firstIndex(of: item)!) - 1)]
                    let perviousPos = Int(specificData.firstIndex(of: perviousOne)!) + 1
                    return String((originPos - perviousPos))
                }
            } else {
                return "-1"
            }
        } else {
            return "-1"
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
