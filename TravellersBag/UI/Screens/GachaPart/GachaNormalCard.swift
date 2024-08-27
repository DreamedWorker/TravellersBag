//
//  GachaNormalCard.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/26.
//

import SwiftUI

struct GachaNormalCard: View {
    let rootList: [GachaItem] // 数据总表
    let goldenCharacter: [GachaItem] // 5星物品表
    let gachaIcon: String
    let gachaName: String
    @State private var showDetail: Bool = true
    
    init(rootList: [GachaItem], gachaIcon: String, gachaName: String) {
        self.rootList = rootList
        self.goldenCharacter = rootList.filter { $0.rankType == "5" }.sorted(by: { Int($0.id!)! < Int($1.id!)! })
        self.gachaName = gachaName
        self.gachaIcon = gachaIcon
    }
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: gachaIcon).font(.title2)
                Text(NSLocalizedString(gachaName, comment: "")).font(.title2).bold()
                Spacer()
                Button(action: {
                    withAnimation(.linear, { showDetail.toggle() }) // 使用这个 看起来流程顺畅一些
                }, label: {
                    Image(systemName: showDetail ? "arrow.up" : "arrow.down").font(.callout)
                })
            }
            GroupBox(
                content: {
                    HStack {
                        Image(systemName: "list.bullet.clipboard")
                        Text("gacha.all.character_times")
                        Spacer()
                        Text(String(rootList.count)).font(.title3).bold()
                        Text("gacha.all.unit")
                    }.padding(4)
                    HStack {
                        Image(systemName: "5.circle")
                        Text("gacha.all.character_last_five_spacing")
                        Spacer()
                        Text( (!goldenCharacter.isEmpty) ? String(rootList.count - lastWantedItem(rank: 5)): "\(0)").bold()
                        Text("gacha.all.unit")
                    }.padding(.horizontal, 4)
                    VStack {
                        HStack {
                            Image(systemName: "4.circle")
                            Text("gacha.all.character_last_four_spacing")
                            Spacer()
                            Text( (rootList.contains(where: { $0.rankType == "4" })) ?
                                  String(rootList.count - lastWantedItem(rank: 4)) : "\(0)"
                            ).bold()
                            Text("gacha.all.unit")
                        }
                        ProgressView(value: Float(exactly: rootList.count - lastWantedItem(rank: 4))!, total: 10)
                    }.padding(.horizontal, 4).padding(.top, 2)
                    Divider().padding(.horizontal, 4)
                    if showDetail {
                        ForEach(goldenCharacter.sorted(by: { Int($0.id!)! > Int($1.id!)! })){ single in
                            // 显示的时候还是按照时间顺序倒序显示
                            HStack {
                                Image(systemName: "figure.stand")
                                Text(single.name!)
                                Spacer()
                                Text(String.localizedStringWithFormat(
                                    NSLocalizedString("gacha.all.character_spacing", comment: ""),
                                    getPosition(item: single)
                                ))
                            }.padding(4)
                        }
                    }
                },
                label: {
                    if rootList.count > 0 {
                        Text(
                            String.localizedStringWithFormat(
                                NSLocalizedString("gacha.all.chatacter_date_1", comment: ""),
                                dateTransfer(date: rootList.first!.time!), dateTransfer(date: rootList.last!.time!))
                        )
                    } else {
                        Text("gacha.all.chatacter_date_2")
                    }
                }
            )
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()))
        .frame(minWidth: 260)
    }
    
    /// 日期对象转换人类可读字符串
    private func dateTransfer(date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }
    
    /// 获取5星物品的相对位置
    private func getPosition(item: GachaItem) -> String {
        if let pos = rootList.firstIndex(where: { $0.id == item.id }) {
            let originPos = Int(pos) + 1
            if goldenCharacter.count > 0 {
                if goldenCharacter.firstIndex(of: item)! == 0 {
                    return String((Int(pos) + 1))
                } else {
                    let perviousOne = goldenCharacter[(Int(goldenCharacter.firstIndex(of: item)!) - 1)]
                    let perviousPos = Int(rootList.firstIndex(of: perviousOne)!) + 1
                    return String((originPos - perviousPos))
                }
            } else {
                return "NONE"
            }
        } else {
            return "NONE"
        }
    }
    
    /// 获取目标对象的相对位置
    private func lastWantedItem(rank: Int) -> Int {
        if rootList.contains(where: { $0.rankType == "\(rank)" }){
            // 这里使用包含测试是为了下面这个返回值使用的「!」不会报错
            return (Int(exactly: rootList.lastIndex(where: { $0.rankType == "\(rank)" })!)! + 1)
        } else {
            return 0
        }
    }
}
