//
//  GachaScreenViewModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/12/8.
//

import Foundation
import SwiftData
import SwiftyJSON

class GachaScreenViewModel: ObservableObject {
    @Published var currentAccountGachaRecords: [GachaItem] = []
    @Published var showContent: Bool = false
    @Published var alertMate = AlertMate()
    @Published var showWaitingDialog: Bool = false
    
    let beginnerGacha = "100" //初行者推荐
    let residentGacha = "200" //常驻
    let characterGacha = "301" //角色
    let weaponGacha = "302" //武器
    let collectionGacha = "500" //混池
    
    // MARK: INNER USE start
    var errorPart: [String] = []
    var allList: [JSON] = []
    // MARK: INNER USE end
    
    init() {
        print("inited")
        currentAccountGachaRecords.removeAll()
        fetchCurrentGachaRecord()
    }
    
    func fetchCurrentGachaRecord() {
        Task {
            let result = await TBDao.getCurrentAccountGachaRecords()
            DispatchQueue.main.async { [self] in
                currentAccountGachaRecords = result
                if currentAccountGachaRecords.isEmpty {
                    showContent = false
                } else {
                    showContent = true
                }
            }
        }
    }
    
    /// 从官方源更新数据
    func updateDataFromCloud() async {
        let user = await TBDao.getDefaultAccount()
        do {
            let authKeyB = try await TBGachaService.getAuthKeyB(user: user!) //这是验证KeyB
            do { // 初行者推荐池
                let beginnerRecord = try await TBGachaService.getGachaInfo(gachaType: beginnerGacha, authKey: authKeyB)
                allList.append(contentsOf: beginnerRecord)
                do { // 角色活动池 301 400 两个池
                    let characterRecord = try await TBGachaService.getGachaInfo(gachaType: characterGacha, authKey: authKeyB)
                    allList.append(contentsOf: characterRecord)
                    do { // 武器池
                        let weaponRecord = try await TBGachaService.getGachaInfo(gachaType: weaponGacha, authKey: authKeyB)
                        allList.append(contentsOf: weaponRecord)
                        do { // 混池 集录祈愿池
                            let collectionRecord = try await TBGachaService.getGachaInfo(gachaType: collectionGacha, authKey: authKeyB)
                            allList.append(contentsOf: collectionRecord)
                            do { // 常驻池
                                let residentRecord = try await TBGachaService.getGachaInfo(gachaType: residentGacha, authKey: authKeyB)
                                allList.append(contentsOf: residentRecord)
                            } catch { errorPart.append(residentGacha) }
                        } catch { errorPart.append(collectionGacha) }
                    } catch { errorPart.append(weaponGacha) }
                } catch { errorPart.append(characterGacha) }
            } catch { errorPart.append(beginnerGacha) }
            if errorPart.count == 0 || errorPart.count < 5 {
                DispatchQueue.main.async { [self] in
                    showWaitingDialog = false
                    alertMate.showAlert(msg: "成功从云端同步\(processHk4e2CoreData(hk4eList: allList, uid: user!.gameInfo.genshinUID))条记录到本地。")
                }
            } else {
                DispatchQueue.main.async { [self] in
                    showWaitingDialog = false
                    alertMate.showAlert(msg: "同步\(errorPart.description)时出现问题。")
                }
            }
        } catch {
            DispatchQueue.main.async { [self] in
                showWaitingDialog = false
                alertMate.showAlert(msg: "无法从云端同步，\(error.localizedDescription)")
            }
        }
    }
    
    /// 将Hk4e的json转换到CoreData并存储
    private func processHk4e2CoreData(hk4eList: [JSON], uid: String) -> Int {
        var count = 0
        for one in hk4eList {
            if one["item_id"].stringValue == "10008" { continue }
            if !currentAccountGachaRecords.isEmpty {
                if currentAccountGachaRecords.contains(where: { $0.id == one["id"].stringValue }) { continue }
            } // 自动增量更新配置
            if one["uid"].stringValue != uid { continue } //不知道是否会触发
            let neoItem = GachaItem(
                uid: one["uid"].stringValue, id: one["id"].stringValue, name: one["name"].stringValue, time: one["time"].stringValue,
                rankType: one["rank_type"].stringValue, itemType: one["item_type"].stringValue, gachaType: one["gacha_type"].stringValue
            )
            TBDao.writeRow2Db(item: neoItem, sendError: { it in print("无法将\(neoItem)添加到数据库") })
            count += 1
        }
        currentAccountGachaRecords.removeAll()
        allList.removeAll()
        fetchCurrentGachaRecord()
        return count
    }
    
    private func transferTimeToDate(data: String) -> Date {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df.date(from: data)!
    }
}
