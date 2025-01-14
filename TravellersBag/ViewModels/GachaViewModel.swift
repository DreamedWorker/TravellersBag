//
//  GachaViewModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/13.
//

import Foundation
@preconcurrency import SwiftyJSON

extension GachaView {
    
    class GachaViewModel: ObservableObject, @unchecked Sendable {
        @Published var alertMate = AlertMate()
        
        var errorPart: [String] = []
        
        let beginnerGacha = "100" //初行者推荐
        let residentGacha = "200" //常驻
        let characterGacha = "301" //角色
        let weaponGacha = "302" //武器
        let collectionGacha = "500" //混池
        
        /// 从官方源更新数据
        @MainActor func updateDataFromCloud(user: MihoyoAccount) async -> [JSON] {
            var allList: [JSON] = []
            do {
                let authKeyB = try await TBGachaService.getAuthKeyB(user: user) //这是验证KeyB
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
                    return allList
                } else {
                    alertMate.showAlert(msg: "同步\(errorPart.description)时出现问题。")
                    return []
                }
            } catch {
                alertMate.showAlert(msg: "无法从云端同步，\(error.localizedDescription)")
                return []
            }
        }
    }
}
