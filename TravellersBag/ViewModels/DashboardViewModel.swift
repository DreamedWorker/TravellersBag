//
//  DashboardViewModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/10.
//

import Foundation
@preconcurrency import SwiftyJSON

class DashboardViewModel: ObservableObject, @unchecked Sendable {
    let storageRoot = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(component: "Dashboard")
    
    @Published var shouldShowContent: Bool = false
    @Published var alertMate = AlertMate()
    @Published var basicData: JSON?
    
    init() {
        if !FileManager.default.fileExists(atPath: storageRoot.toStringPath()) {
            try! FileManager.default.createDirectory(at: storageRoot, withIntermediateDirectories: true)
        }
    }
    
    @MainActor func getSomething(account: MihoyoAccount, useNetwork: Bool = false) async {
        //这是页面加载时调用的函数，故只加载默认账号的信息
        let pageFile = storageRoot.appending(component: "\(account.stuidForTest).json")
        func getFromNetwork() async {
            do {
                let result = try await fetchOutline(user: account)
                if !FileManager.default.fileExists(atPath: pageFile.toStringPath()) {
                    FileManager.default.createFile(atPath: pageFile.toStringPath(), contents: nil)
                }
                try result.write(to: pageFile)
                basicData = try JSON(data: result)
                shouldShowContent = true
            } catch {
                shouldShowContent = false
                alertMate.showAlert(
                    msg: String.localizedStringWithFormat(
                        NSLocalizedString("dashboard.error.fetch", comment: ""),
                        error.localizedDescription)
                )
            }
        }
        
        if useNetwork {
            await getFromNetwork()
        } else {
            do {
                if FileManager.default.fileExists(atPath: pageFile.toStringPath()) {
                    basicData = try JSON(data: Data(contentsOf: pageFile))
                    shouldShowContent = true
                } else {
                    await getFromNetwork()
                }
            } catch {
                shouldShowContent = false
                await getFromNetwork()
            }
        }
    }
    
    @MainActor private func fetchOutline(user: MihoyoAccount) async throws -> Data {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getGameOutline(roleID: user.gameInfo.genshinUID))!)
        req.setHost(host: "api-takumi-record.mihoyo.com")
        req.setValue(
            "stuid=\(user.cookies.stuid);stoken=\(user.cookies.stoken);ltuid=\(user.cookies.stuid);ltoken=\(user.cookies.ltoken);mid=\(user.cookies.mid)",
            forHTTPHeaderField: "Cookie")
        req.setValue("zh-cn", forHTTPHeaderField: "x-rpc-language")
        req.setUA()
        req.setDS(
            version: SaltVersion.V2, type: SaltType.X4,
            body: "avatar_list_type=1&role_id=\(user.gameInfo.genshinUID)&server=cn_gf01", include: false)
        req.setReferer(referer: "https://webstatic.mihoyo.com")
        req.setValue("v4.2.2-ys_#/ys/daily", forHTTPHeaderField: "x-rpc-page") //4.1.5
        req.setValue("https://webstatic.mihoyo.com", forHTTPHeaderField: "Origin")
        req.setXRPCAppInfo(client: "5")
        req.setDeviceInfoHeaders()
        return try await req.receiveOrThrow().rawData()
    }
}
