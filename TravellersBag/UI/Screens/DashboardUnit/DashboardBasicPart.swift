//
//  DashboardBasicPart.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/11/12.
//

import SwiftUI
import SwiftyJSON
import Kingfisher

struct DashboardBasicPart: View {
    let content: JSON?
    let checkFileExist: () -> Void
    
    var body: some View {
        if let content = content {
            ScrollView {
                LazyVStack {
                    HStack {
                        KFImage(URL(string: content["role"]["game_head_icon"].stringValue))
                            .loadDiskFileSynchronously(true)
                            .placeholder({ ProgressView() })
                            .resizable()
                            .frame(width: 72, height: 72)
                        VStack(alignment: .leading) {
                            Text(content["role"]["nickname"].stringValue).font(.title2).bold()
                            Text(
                                String.localizedStringWithFormat(
                                    NSLocalizedString("dashboard.and", comment: ""),
                                    String(content["role"]["level"].intValue),
                                    content["role"]["region"].stringValue
                                )
                            )
                            Text(getDefaultAccount()!.gameInfo.genshinUID)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()).shadow(radius: 4, y: 4))
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "tray.full").font(.title2).bold()
                            Text("dashboard.info.baseTitle").font(.title2).bold()
                            Spacer()
                        }
                        LazyVGrid(
                            columns: [.init(), .init(), .init(), .init(), .init()],
                            content: {
                                //第一行
                                InfoCell(count: content["stats"]["avatar_number"].intValue, name: "获得角色数")
                                InfoCell(count: content["stats"]["full_fetter_avatar_num"].intValue, name: "满好感角色")
                                InfoCell(count: content["stats"]["achievement_number"].intValue, name: "获得成就数")
                                InfoCell(count: content["stats"]["way_point_number"].intValue, name: "解锁传送点")
                                InfoCell(count: content["stats"]["domain_number"].intValue, name: "解锁秘境数")
                                //第二行
                                InfoCell(count: content["stats"]["anemoculus_number"].intValue, name: "风神瞳")
                                InfoCell(count: content["stats"]["geoculus_number"].intValue, name: "岩神瞳")
                                InfoCell(count: content["stats"]["electroculus_number"].intValue, name: "雷神瞳")
                                InfoCell(count: content["stats"]["dendroculus_number"].intValue, name: "草神瞳")
                                InfoCell(count: content["stats"]["hydroculus_number"].intValue, name: "水神瞳")
                                //第三行
                                InfoCell(count: content["stats"]["pyroculus_number"].intValue, name: "火神瞳")
                                InfoCell(count: content["stats"]["luxurious_chest_number"].intValue, name: "华丽宝箱数")
                                InfoCell(count: content["stats"]["active_day_number"].intValue, name: "活跃天数")
                                if content["stats"]["role_combat"]["has_data"].boolValue {
                                    InfoCell(count: content["stats"]["role_combat"]["max_round_id"].intValue, name: "幻想真境剧诗演出幕")
                                }
                                VStack {
                                    Text(content["stats"]["spiral_abyss"].stringValue).bold()
                                    Text("dashboard.info.baseSpiralAbyss").font(.callout)
                                }.padding(.bottom, 2)
                            }
                        )
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()).shadow(radius: 4, y: 4))
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "house.fill").font(.title2).bold()
                            Text("dashboard.info.houseTitle").font(.title2).bold()
                            Spacer()
                        }
                        HouseCells(cells: processHouseCells(houses: content["homes"]))
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()).shadow(radius: 4, y: 4))
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "globe.desk").font(.title2).bold()
                            Text("dashboard.info.worldTitle").font(.title2).bold()
                            Spacer()
                        }
                        WorldCells(localRegions: processWorldCells(worlds: content["world_explorations"]))
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()).shadow(radius: 4, y: 4))
                }.padding()
            }
        } else {
            VStack {
                Image("dashboard_empty").resizable().frame(width: 72, height: 72)
                Text("dashboard.empty").font(.title2).bold().padding(.bottom, 8)
                Button("dashboard.fetch", action: checkFileExist).buttonStyle(BorderedProminentButtonStyle())
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(BackgroundStyle()).shadow(radius: 4, y: 4))
        }
    }
    
    private func processHouseCells(houses: JSON) -> [HouseCell] {
        var houseList: [HouseCell] = []
        for single in houses.arrayValue {
            houseList.append(
                HouseCell(
                    id: single["name"].stringValue, name: single["name"].stringValue, visit_num: single["visit_num"].intValue,
                    level: single["level"].intValue, comfort_level_icon: single["comfort_level_icon"].stringValue,
                    comfort_level_name: single["comfort_level_name"].stringValue, icon: single["icon"].stringValue,
                    comfort_num: single["comfort_num"].intValue, item_num: single["item_num"].intValue
                )
            )
        }
        return houseList
    }
    
    private func processWorldCells(worlds: JSON) -> [RegionDetail] {
        var worldList: [RegionDetail] = []
        for i in worlds.arrayValue {
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
            
            worldList.append(
                RegionDetail(
                    id: i["id"].intValue, offerings: tempOfferings, boss_list: bosses,
                    name: i["name"].stringValue, area_exploration_list: subArea,
                    exploration_percentage: i["exploration_percentage"].intValue, level: i["level"].intValue,
                    cover: i["cover"].stringValue.replacingOccurrences(of: "\\", with: ""),
                    icon: (i["id"].intValue == 15)
                    ? "https://webstatic.mihoyo.com/app/community-game-records/images/world-logo-15.fd274778.png"
                    : i["icon"].stringValue.replacingOccurrences(of: "\\", with: ""),
                    inner_icon: i["inner_icon"].stringValue.replacingOccurrences(of: "\\", with: ""),
                    background_image: i["background_image"].stringValue.replacingOccurrences(of: "\\", with: ""),
                    type: i["type"].stringValue,
                    parent: i["parent_id"].intValue, seven_statue_level: i["seven_statue_level"].intValue
                )
            )
        }
        
        worldList = worldList.sorted(by: { $0.id > $1.id })
        return worldList
    }
}

private struct InfoCell: View {
    let count: Int
    let name: String
    
    var body: some View {
        VStack {
            Text(String(count)).bold()
            Text(name).font(.callout)
        }.padding(.bottom, 2)
    }
}

private struct HouseCells: View {
    let cells: [HouseCell]
    
    var body: some View {
        ForEach(cells) { cell in
            ZStack {
                KFImage(URL(string: cell.icon))
                    .loadDiskFileSynchronously(true)
                    .placeholder({ ProgressView() })
                    .resizable()
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .frame(height: 78)
                VStack {
                    HStack {
                        KFImage(URL(string: cell.comfort_level_icon))
                            .loadDiskFileSynchronously(true)
                            .placeholder({ ProgressView() })
                            .resizable()
                            .frame(width: 32, height: 32)
                        Text(cell.comfort_level_name).font(.title2)
                        Spacer()
                        Text(cell.name).font(.callout)
                    }.padding(4)
                    Spacer()
                    LazyVGrid(
                        columns: [.init(), .init(), .init(), .init()],
                        content: {
                            InfoCell(count: cell.level, name: "信任等阶")
                            InfoCell(count: cell.comfort_num, name: "最高洞天仙力")
                            InfoCell(count: cell.item_num, name: "获得摆设数")
                            InfoCell(count: cell.visit_num, name: "历史访客数")
                        }
                    )
                    .background(.gray.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.bottom, 4)
                }
            }
            .colorScheme(.dark)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .frame(height: 78)
        }
    }
}

private struct WorldCells: View {
    let localRegions: [RegionDetail]
    
    var body: some View {
        LazyVGrid(
            columns: [.init(), .init(), .init(), .init(), .init()],
            content: {
                ForEach(localRegions) { regionInfo in
                    if regionInfo.parent == 0 {
                        WorldCell(regionInfo: regionInfo, localRegions: localRegions)
                    }
                }
            }
        )
    }
}

private struct WorldCell: View {
    @Environment(\.colorScheme) private var currentColor
    let regionInfo: RegionDetail
    let localRegions: [RegionDetail]
    @State private var showDetail = false
    
    var body: some View {
        ZStack(alignment: .center, content: {
            KFImage(URL(string: regionInfo.cover))
                .loadDiskFileSynchronously(true)
                .resizable()
                .frame(/*width: 90,*/ height: 120)
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
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onTapGesture {
            showDetail = true
        }
        .sheet(isPresented: $showDetail, content: {
            NavigationStack {
                ScrollView {
                    LazyVStack {
                        ZStack(
                            alignment: .leading,
                            content: {
                                KFImage(URL(string: regionInfo.background_image))
                                    .loadDiskFileSynchronously(true)
                                    .resizable()
                                HStack(alignment: .top) {
                                    KFImage(URL(string: (currentColor == .light) ? regionInfo.inner_icon : regionInfo.icon))
                                        .loadDiskFileSynchronously(true)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 64, height: 64)
                                    VStack(alignment: .leading) {
                                        Text(regionInfo.name).font(.title2).bold()
                                        HStack {
                                            Text("dashboard.unit.world.ee")
                                            Spacer()
                                            Text(
                                                String.localizedStringWithFormat(
                                                    NSLocalizedString("dashboard.unit.world.per", comment: ""),
                                                    String(format: "%.1f", ((Float(regionInfo.exploration_percentage) / 1000) * 100))
                                                )
                                            )
                                        }
                                        ProgressView(value: Float(regionInfo.exploration_percentage), total: 1000).padding(.bottom, 4)
                                        if regionInfo.seven_statue_level != 0 {
                                            Label(
                                                String.localizedStringWithFormat(
                                                    NSLocalizedString("dashboard.unit.world.statue", comment: ""),
                                                    String(regionInfo.seven_statue_level)),
                                                systemImage: "flag.checkered")
                                        }
                                        if regionInfo.offerings.count > 0 {
                                            ForEach(regionInfo.offerings, id: \.name) { offering in
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
                                        if regionInfo.level > 0 {
                                            Label(String.localizedStringWithFormat(NSLocalizedString("dashboard.unit.world.level", comment: ""), String(regionInfo.level)), systemImage: "house")
                                        }
                                    }
                                }.padding()
                            })
                        .frame(maxHeight: 165)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        if regionInfo.area_exploration_list.count > 0 {
                            GroupBox("dashboard.unit.world.ee.sub", content: {
                                ForEach(regionInfo.area_exploration_list){ area in
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
                        if localRegions.filter({ $0.parent == regionInfo.id }).count > 0 {
                            GroupBox("dashboard.unit.world.ee.sub", content: {
                                ForEach(localRegions.filter({ $0.parent == regionInfo.id })){ area in
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
                        if regionInfo.boss_list.count > 0 {
                            GroupBox("dashboard.unit.world.boss", content: {
                                ForEach(regionInfo.boss_list, id: \.name) { boss in
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
                    }.padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction, content: {
                    Button("app.confirm", action: { showDetail = false })
                })
            }
        })
    }
}
