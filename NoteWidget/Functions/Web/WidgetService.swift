//
//  WidgetService.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/21.
//

import Foundation
import SwiftyJSON

final class WidgetService: Sendable {
    static let `default` = WidgetService()
    private init() {}
    
    func fetchWidget(account: AccountInfo) async throws -> Data {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getWidgetSimple())!)
        req.setHost(host: "api-takumi-record.mihoyo.com")
        req.setUser(uid: account.stuid, stoken: account.stoken, mid: account.mid)
        req.setIosUA()
        req.setValue("https://webstatic.mihoyo.com", forHTTPHeaderField: "Origin")
        req.setDS(version: .V2, type: .X4, include: false)
        req.setDeviceInfoHeaders()
        req.setXRPCAppInfo(client: "5")
        return try await req.receiveOrThrow().rawData()
    }
}
