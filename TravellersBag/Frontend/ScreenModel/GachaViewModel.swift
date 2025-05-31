//
//  GachaViewModel.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/28.
//

import Foundation
import SwiftData

class GachaViewModel: ObservableObject, @unchecked Sendable {
    @Published var uiState: GachaViewUiState = .init()
    
    let beginnerGacha = "100" //初行者推荐
    let residentGacha = "200" //常驻
    let characterGacha = "301" //角色
    let weaponGacha = "302" //武器
    let collectionGacha = "500" //混池
    
    let downloader = PicResource.SequentialDownloader()
    
    func checkImageResources() {
        uiState.showImageSheet = !PicResource.hasLocalImgs()
        uiState.showLogic = uiState.showImageSheet
    }
    
    func queryRecords(_ user: HoyoAccount, context: ModelContext) {
        do {
            let requiredUid = user.game.genshinUID
            let result = try context.fetch(FetchDescriptor(predicate: #Predicate<GachaItem> { $0.uid == requiredUid } ))
            uiState.gachaRecords = result
        } catch {
            uiState.alertMate.showAlert(msg: "Failed to load gacha records, \(error.localizedDescription)", type: .Error)
        }
    }
    
    func updateDataFromCloud(
        _ user: HoyoAccount,
        originalList: [GachaItem],
        onWrite: @escaping @MainActor @Sendable (GachaItem) async -> Void,
        onFailed: @escaping @Sendable () -> Void,
        onFinished: @escaping @MainActor @Sendable (String, HoyoAccount) async -> Void
    ) async {
        var errorPart: [String] = []
        var allList: [GachaHelper.GachaList.GachaListData.GachaItems] = []
        let emptyLocal = originalList.isEmpty
        do {
            let authKeyB = try await GachaHelper.getAuthKeyB(user) //这是验证KeyB
            do { // 初行者推荐池
                let beginnerRecord = try await GachaHelper.getGachaInfo(gachaType: beginnerGacha, authKey: authKeyB)
                allList.append(contentsOf: beginnerRecord)
                do { // 角色活动池 301 400 两个池
                    let characterRecord = try await GachaHelper.getGachaInfo(gachaType: characterGacha, authKey: authKeyB)
                    allList.append(contentsOf: characterRecord)
                    do { // 武器池
                        let weaponRecord = try await GachaHelper.getGachaInfo(gachaType: weaponGacha, authKey: authKeyB)
                        allList.append(contentsOf: weaponRecord)
                        do { // 混池 集录祈愿池
                            let collectionRecord = try await GachaHelper.getGachaInfo(gachaType: collectionGacha, authKey: authKeyB)
                            allList.append(contentsOf: collectionRecord)
                            do { // 常驻池
                                let residentRecord = try await GachaHelper.getGachaInfo(gachaType: residentGacha, authKey: authKeyB)
                                allList.append(contentsOf: residentRecord)
                            } catch { errorPart.append(residentGacha) }
                        } catch { errorPart.append(collectionGacha) }
                    } catch { errorPart.append(weaponGacha) }
                } catch { errorPart.append(characterGacha) }
            } catch { errorPart.append(beginnerGacha) }
            if errorPart.count < 5 {
                var count = 0
                for one in allList {
                    if one.itemID == "10008" { continue }
                    if !emptyLocal {
                        if originalList.contains(where: { $0.id == one.id }) { continue }
                    }
                    if one.uid != user.game.genshinUID { continue }
                    let neoItem = GachaItem(
                        uid: one.uid, id: one.id, name: one.name, time: one.time, rankType: one.rankType,
                        itemType: one.itemType.rawValue, gachaType: one.gachaType
                    )
                    await onWrite(neoItem)
                    count += 1
                }
                await onFinished(
                    String.localizedStringWithFormat(
                        NSLocalizedString("gacha.info.finishedSync", comment: ""),
                        String(count), String(errorPart.count), errorPart.description
                    ),
                    user
                )
            } else {
                DispatchQueue.main.async { [self] in
                    onFailed()
                    uiState.alertMate.showAlert(
                        msg: String.localizedStringWithFormat(
                            NSLocalizedString("gacha.error.syncPool", comment: ""),
                            errorPart.description
                        ),
                        type: .Error
                    )
                }
            }
        } catch {
            DispatchQueue.main.async { [self] in
                onFailed()
                uiState.alertMate.showAlert(
                    msg: String.localizedStringWithFormat(
                        NSLocalizedString("gacha.error.sync", comment: ""),
                        error.localizedDescription)
                )
            }
        }
    }
}

extension GachaViewModel {
    struct GachaViewUiState {
        var alertMate: AlertMate = .init()
        var gachaRecords: [GachaItem] = []
        var showImageSheet: Bool = false
        var showLogic: Bool = false
    }
}
