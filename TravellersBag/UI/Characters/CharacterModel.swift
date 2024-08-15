//
//  CharacterModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/13.
//

import Foundation
import CoreData
import MMKV

class CharacterModel : ObservableObject {
    @Published var context: NSManagedObjectContext? = nil
    @Published var showWeb: Bool = false
    @Published var gt = ""
    @Published var challenge = ""
    var currentUser: HoyoAccounts? = nil
    @Published var characters: [SingleCharacter] = []
    
    let hoyoCharacters = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(component: "hoyo_characters.json").path().removingPercentEncoding!
    
    /// 获取默认用户
    func fetchDefaultUser() {
        currentUser = nil
        do {
            let result = try context?.fetch(HoyoAccounts.fetchRequest())
            if let surelyResult = result {
                currentUser = surelyResult.filter({$0.stuid! == MMKV.default()!.string(forKey: "default_account_stuid")!}).first!
            } else {
                print("没有默认用户")
            }
        } catch {
            ContentMessager.shared.showErrorDialog(msg: NSLocalizedString("character.error.cannot_found_user", comment: ""))
        }
    }
    
    /// 在点按「人机验证」按钮后判断是否要打开sheet，打开之前需要已经加载好了验证所需的两个参数
    func showWebOrNot() async {
        if let user = currentUser {
            do {
                let data = try await createVerificationCode(user: user)
                DispatchQueue.main.async {
                    self.gt = data["gt"].stringValue
                    self.challenge = data["challenge"].stringValue
                    self.showWeb = true
                }
            } catch {
                await showErrorAsync(err: "showWebErr:\(error.localizedDescription)")
            }
        }
    }
    
    func verifyGeetestCode(validate: String) async {
        // 这里就不需要判断默认账号是否存在了 因为如果不存在的话根本不会呼出验证sheet
        do {
            let result = try await tryGeetestCode(user: currentUser!, validate: validate, challenge: challenge)
            DispatchQueue.main.async {
                ContentMessager.shared.showInfomationDialog(msg: NSLocalizedString("character.verify.pass_it", comment: ""))
            }
            print("验证结果：\(result.rawString() as Any)")
        } catch {
            await showErrorAsync(err: "showWebErr:\(error.localizedDescription)")
        }
        DispatchQueue.main.async { //无论如何都先关闭这个sheet
            self.challenge = ""
            self.gt = ""
            self.showWeb = false
        }
    }
    
    /// 从镜像站获取角色橱窗信息
    func handleEnkaCharacters(uid: String) async throws {
        let json = try await JSON(data: CharacterService.shared.pullCharactersFromEnka(gameUID: uid))
        let avatarList = json["avatarInfoList"].arrayValue // 提炼出角色对象数组
        for single in avatarList {
            DispatchQueue.main.async {
                // 写入角色数据
                let newData = SingleCharacter(context: self.context!)
                newData.avatarID = Int64(single["avatarId"].intValue)
                newData.flats = try? single["equipList"].rawData()
                newData.expLevel = Int64(single["fetterInfo"]["expLevel"].intValue)
                newData.fightPropMap = try? single["fightPropMap"].rawData()
                newData.inherentProudSkillList = try? single["inherentProudSkillList"].rawData()
                newData.genshinUID = uid
                newData.propMap = try? single["propMap"].rawData()
                newData.skillDepotId = Int64(single["skillDepotId"].intValue)
                newData.skillLevelMap = try? single["skillLevelMap"].rawData()
                let _ = AppPersistence.shared.save()
            }
        }
        DispatchQueue.main.async {
            self.currentUser!.genshinHeadID = String(json["playerInfo"]["profilePicture"]["id"].intValue)
            let _ = AppPersistence.shared.save()
            self.fetchCharacter()
        }
    }
    
    func fetchCharacter() {
        characters.removeAll()
        do {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SingleCharacter")
            request.predicate = NSPredicate(format: "genshinUID == %@", /*currentUser!.genshinUID!*/ "1000000")
            let result = try context!.fetch(request)
            for i in result {
                if let j = i as? SingleCharacter {
                    characters.append(j)
                }
            }
        } catch {
            ContentMessager.shared.showErrorDialog(msg: error.localizedDescription)
        }
    }
    
    private func showErrorAsync(err: String) async {
        DispatchQueue.main.async {
            ContentMessager.shared.showErrorDialog(msg: err)
        }
    }
}
