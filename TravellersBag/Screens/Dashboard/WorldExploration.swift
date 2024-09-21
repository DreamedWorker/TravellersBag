//
//  WorldExploration.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/21.
//

import SwiftUI
import SwiftyJSON
import Kingfisher

struct WorldExploration: View {
    @Environment(\.colorScheme) private var currentColor
    let regions: [JSON]?
    @State private var localRegions: [RegionDetail] = []
    @State private var regId = -1
    @State private var showDetail = false
    @State private var detailInfo: RegionDetail? = nil
    
    var body: some View {
        if let region = regions {
            VStack(alignment: .leading) {
                Text("dashboard.unit.world.title").padding(.leading, 16)
                Text(String(regId)).font(.system(size: 1))
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(localRegions){ regionInfo in
                            if regionInfo.parent == 0 {
                                ZStack(alignment: .center, content: {
                                    KFImage(URL(string: regionInfo.cover))
                                        .loadDiskFileSynchronously(true)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 90, height: 110)
                                    VStack {
                                        KFImage(URL(string: regionInfo.icon))
                                            .loadDiskFileSynchronously(true)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 48, height: 40)
                                        Text(regionInfo.name).foregroundStyle(Color.white)
                                        HStack {
                                            Text("dashboard.unit.world.ee").foregroundStyle(Color.white)
                                            Spacer()
                                            Text(
                                                String.localizedStringWithFormat(
                                                    NSLocalizedString("dashboard.unit.world.per", comment: ""),
                                                    String(format: "%.1f", ((Float(regionInfo.exploration_percentage) / 1000) * 100))
                                                )
                                            ).foregroundStyle(Color.white)
                                        }.font(.system(size: 12))
                                        ProgressView(value: Float(regionInfo.exploration_percentage), total: 1000).padding(.bottom, 4)
                                    }.padding(4)
                                })
                                .frame(width: 90, height: 110).clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture {
                                    detailInfo = regionInfo
                                    regId = regionInfo.id
                                    showDetail = true
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    for i in region {
                        var tempOfferings: [Offerings] = []
                        var bosses: [BossInfo] = []
                        var subArea: [Areas] = []
                        for j in i["offerings"].arrayValue {
                            tempOfferings.append(Offerings(name: j["name"].stringValue, icon: j["icon"].stringValue, level: j["level"].intValue))
                        }
                        for j in i["boss_list"].arrayValue {
                            bosses.append(BossInfo(kill_num: j["kill_num"].intValue, name: j["name"].stringValue))
                        }
                        for j in i["area_exploration_list"].arrayValue {
                            subArea.append(
                                Areas(
                                    id: j["name"].stringValue, name: j["name"].stringValue,
                                    exploration_percentage: j["exploration_percentage"].intValue)
                            )
                        }
                        localRegions.append(
                            RegionDetail(
                                id: i["id"].intValue, offerings: tempOfferings, boss_list: bosses,
                                name: i["name"].stringValue, area_exploration_list: subArea,
                                exploration_percentage: i["exploration_percentage"].intValue, level: i["level"].intValue,
                                cover: i["cover"].stringValue.replacingOccurrences(of: "\\", with: ""),
                                icon: i["icon"].stringValue.replacingOccurrences(of: "\\", with: ""),
                                inner_icon: i["inner_icon"].stringValue.replacingOccurrences(of: "\\", with: ""),
                                background_image: i["background_image"].stringValue.replacingOccurrences(of: "\\", with: ""),
                                type: i["type"].stringValue,
                                parent: i["parent_id"].intValue, seven_statue_level: i["seven_statue_level"].intValue
                            )
                        )
                    }
                    localRegions = localRegions.sorted(by: { $0.id > $1.id })
                }
                Text("dashboard.unit.world.see").font(.footnote).foregroundStyle(.secondary)
                    .padding(.leading, 16)
            }
            .sheet(isPresented: $showDetail, content: {
                if let region = detailInfo {
                    NavigationStack {
                        ScrollView {
                            ZStack(alignment: .leading, content: {
                                KFImage(URL(string: region.background_image))
                                    .loadDiskFileSynchronously(true)
                                    .resizable()
                                HStack(alignment: .top) {
                                    KFImage(URL(string: (currentColor == .light) ? region.inner_icon : region.icon))
                                        .loadDiskFileSynchronously(true)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 64, height: 64)
                                    VStack(alignment: .leading) {
                                        Text(region.name).font(.title2).bold()
                                        HStack {
                                            Text("dashboard.unit.world.ee")
                                            Spacer()
                                            Text(
                                                String.localizedStringWithFormat(
                                                    NSLocalizedString("dashboard.unit.world.per", comment: ""),
                                                    String(format: "%.1f", ((Float(region.exploration_percentage) / 1000) * 100))
                                                )
                                            )
                                        }
                                        ProgressView(value: Float(region.exploration_percentage), total: 1000).padding(.bottom, 4)
                                        if region.seven_statue_level != 0 {
                                            Label(
                                                String.localizedStringWithFormat(
                                                    NSLocalizedString("dashboard.unit.world.statue", comment: ""), String(region.seven_statue_level)),
                                                systemImage: "flag.checkered")
                                        }
                                        if region.offerings.count > 0 {
                                            ForEach(region.offerings, id: \.name) { offering in
                                                Label(
                                                    title: {
                                                        Text(
                                                            String.localizedStringWithFormat(
                                                                NSLocalizedString("dashboard.unit.world.offering", comment: ""), offering.name,
                                                                String(offering.level)))
                                                    },
                                                    icon: {
                                                        KFImage(URL(string: offering.icon))
                                                            .loadDiskFileSynchronously(true)
                                                            .placeholder({ Image(systemName: "fuelpump") })
                                                            .resizable()
                                                            .frame(width: 16, height: 16)
                                                    }
                                                )
                                            }
                                        }
                                        if region.level > 0 {
                                            Label(String.localizedStringWithFormat(NSLocalizedString("dashboard.unit.world.level", comment: ""), String(region.level)), systemImage: "house")
                                        }
                                    }
                                }.padding()
                            })
                            .frame(maxHeight: 165)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            if region.area_exploration_list.count > 0 {
                                GroupBox("dashboard.unit.world.ee.sub", content: {
                                    ForEach(region.area_exploration_list){ area in
                                        VStack {
                                            HStack {
                                                Image(systemName: "location.fill")
                                                Text(area.name)
                                                Spacer()
                                                Text(
                                                    String.localizedStringWithFormat(
                                                        NSLocalizedString("dashboard.unit.world.per", comment: ""),
                                                        String(format: "%.1f", ((Float(area.exploration_percentage) / 1000) * 100)))
                                                ).foregroundStyle(.secondary)
                                            }
                                            ProgressView(value: Float(area.exploration_percentage), total: 1000)
                                        }
                                    }.font(.callout)
                                })
                            }
                            if localRegions.filter({ $0.parent == region.id }).count > 0 {
                                GroupBox("dashboard.unit.world.ee.sub", content: {
                                    ForEach(localRegions.filter({ $0.parent == region.id })){ area in
                                        VStack {
                                            HStack {
                                                Image(systemName: "location.fill")
                                                Text(area.name)
                                                Spacer()
                                                Text(
                                                    String.localizedStringWithFormat(
                                                        NSLocalizedString("dashboard.unit.world.per", comment: ""),
                                                        String(format: "%.1f", ((Float(area.exploration_percentage) / 1000) * 100)))
                                                ).foregroundStyle(.secondary)
                                            }
                                            ProgressView(value: Float(area.exploration_percentage), total: 1000)
                                        }
                                    }.font(.callout)
                                })
                            }
                            if region.boss_list.count > 0 {
                                GroupBox("dashboard.unit.world.boss", content: {
                                    ForEach(region.boss_list, id: \.name) { boss in
                                        HStack {
                                            Text(boss.name)
                                            Spacer()
                                            Text(
                                                String.localizedStringWithFormat(
                                                    NSLocalizedString("dashboard.unit.world.boss_kill", comment: ""), String(boss.kill_num))
                                            ).foregroundStyle(.secondary)
                                        }.padding(2)
                                    }
                                })
                            }
                        }.padding(4)
                    }
                    .padding()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction, content: {
                            Button("app.cancel", action: { showDetail = false })
                        })
                    }
                } else { Text(String(regId))}
            })
        }
    }
    
    private struct RegionDetail: Identifiable {
        var id: Int
        var offerings: [Offerings] // 除「七天神像」之外提供等级和奖励的地区可供奉交互
        var boss_list: [BossInfo] // 主要魔物
        var name: String // 地区名
        var area_exploration_list: [Areas] // 子区域的探索情况
        var exploration_percentage: Int // 整体区域探索度 (X ÷ 1000 x 100%)
        var level: Int // 地区声望等级
        var cover: String // 外部查看时的背景图
        var icon: String // 地区图
        var inner_icon: String // 详情页面的地区图
        var background_image: String // 详情页面的背景图
        var type: String // 世界类型
        var parent: Int // 父地区ID
        var seven_statue_level: Int //七天神像供奉等级
    }
    
    private struct BossInfo {
        var kill_num: Int
        var name: String
    }
    
    private struct Offerings {
        var name: String
        var icon: String
        var level: Int
    }
    
    private struct Areas: Identifiable {
        var id: String
        var name: String
        var exploration_percentage: Int
    }
}
