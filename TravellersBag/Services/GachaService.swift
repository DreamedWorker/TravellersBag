//
//  GachaService.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/23.
//

import Foundation
import AppKit

/// 抽卡分析页服务
class GachaService {
    private init() {}
    static let shared = GachaService()
    
    /// 返回 AuthKeyB 字符串（抽卡分析用途）
    func getAuthKeyB(user: ShequAccount) async throws -> String {
        let reqBody = try! JSONSerialization.data(withJSONObject: [
            "auth_appid": "webview_gacha", "game_biz": "hk4e_cn", "game_uid": Int(user.genshinUID!)!, "region": user.serverRegion!
        ])
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getAuthKey())!)
        req.setHost(host: "api-takumi.mihoyo.com")
        req.setUser(singleUser: user)
        req.setDeviceInfoHeaders()
        req.setReferer(referer: "https://app.mihoyo.com/")
        req.setDS(version: SaltVersion.V1, type: SaltType.LK2)
        req.setXRPCAppInfo(client: "5")
        req.setIosUA()
        let result = try await req.receiveOrThrow(isPost: true, reqBody: reqBody)
        return result["authkey"].stringValue
    }
    
    /// 查询指定卡池的数据
    func getGachaInfo(gachaType: String, authKey: String, endID: String = "0") async throws -> [JSON] {
        var partData: [JSON] = [] // 用于存储累计的数据
        
        func fetchData(gachaType: String, authKey: String, endID: String = "0") async throws {
            var req = URLRequest(url: URL(string: ApiEndpoints.shared.getGachaData(key: authKey, type: Int(gachaType)!, endID: Int(endID)!))!)
            req.setValue("okhttp/4.9.3", forHTTPHeaderField: "user-agent")
            let result = try await req.receiveOrThrow()
            let partList = result["list"].arrayValue
            partData.append(contentsOf: partList)
            if partList.count == 20 {
                try await Task.sleep(for: .seconds(1.5))
                try await fetchData(gachaType: gachaType, authKey: authKey, endID: partList.last!["id"].stringValue)
            }
        }
        
        try await fetchData(gachaType: gachaType, authKey: authKey, endID: endID)
        return partData
    }
    
    /// 从游戏服务器增量或全量更新数据
    func updateGachaInfo(gachaType: String, authKey: String, list: [GachaItem]) async throws -> [JSON] {
        var specificList = (gachaType == "301")
        ? list.filter({ $0.gachaType == "301" || $0.gachaType == "400" }) : list.filter({ $0.gachaType == gachaType })
        specificList = specificList.sorted(by: { Int($0.id!)! < Int($1.id!)! })
        var jsons: [JSON] = []
        jsons.append(contentsOf: try await getGachaInfo(gachaType: gachaType, authKey: authKey))
        if !jsons.isEmpty {
            jsons = jsons.sorted(by: { CLong($0["id"].stringValue)! < CLong($1["id"].stringValue)! })
            let newLast = Int(jsons.last!["id"].stringValue)!
            let oldLast = Int(specificList.last!.id!)!
            if oldLast < newLast {
                let a = jsons.split(separator: jsons[jsons.firstIndex(where: { $0["id"].stringValue == specificList.last!.id! })!])
                return a[1].sorted()
            } else {
                return []
            }
        } else {
            return []
        }
    }
    
    /// 以UIGFv4.0标准导出记录到文件（此方法系同步方法，不需要切换线程）
    @objc func exportRecords2UIGFv4(record: [GachaItem], uid: String) {
        func timeTransfer(d: Date, detail: Bool = true) -> String {
            let df = DateFormatter()
            df.dateFormat = (detail) ? "yyyy-MM-dd HH:mm:ss" : "yyMMdd"
            return df.string(from: d)
        }
        let time = Date().timeIntervalSince1970
        let target = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let targetFile = target.appending(component: "Gacha-\(timeTransfer(d: Date.now, detail: false)).UIGFv4.json")
        do {
            let info = Info(export_timestamp: Int(time)) // 文件头部信息
            var records: [SingleGachaItem] = []
            for i in record {
                let name = i.name!
                let name_id = (HomeController.shared.idTable.contains(where: { $0.0 == name })) 
                ? HomeController.shared.idTable[name].intValue : 10008
                records.append(
                    SingleGachaItem(
                        uigf_gacha_type: (i.gachaType! == "400") ? "301" : i.gachaType!,
                        gacha_type: i.gachaType!, item_id: String(name_id),
                        time: timeTransfer(d: i.time!), id: i.id!)
                )
            }
            let hk4e = HK4E(uid: uid, list: records)
            let uigf = UIGFFile(info: info, hk4e: [hk4e])
            let encoder = try JSONEncoder().encode(uigf)
            FileHandler.shared.writeUtf8String(
                path: targetFile.path().removingPercentEncoding!, 
                context: String(data: encoder, encoding: .utf8)!)
            NSWorkspace.shared.open(target)
        } catch {
            HomeController.shared.showErrorDialog(
                msg: String.localizedStringWithFormat(
                    NSLocalizedString("gacha.export.error", comment: ""), error.localizedDescription)
            )
        }
    }
}
