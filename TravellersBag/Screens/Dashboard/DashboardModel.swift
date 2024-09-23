//
//  DashboardModel.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/9/20.
//

import Foundation
import SwiftyJSON

class DashboardModel: ObservableObject {
    @Published var showUI = GlobalUIModel.exported.hasDefAccount()
    @Published var basicData: JSON?
    @Published var widgetData: JSON?
    @Published var showWidget = false
    
    let dashboardFile = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(component: "shequ_index.json")
    let widgetFile = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appending(component: "widget_v2.json")
    
    init() {
        if !FileManager.default.fileExists(atPath: dashboardFile.toStringPath()) {
            FileManager.default.createFile(atPath: dashboardFile.toStringPath(), contents: nil)
        } else {
            let context = FileHandler.shared.readUtf8String(path: dashboardFile.toStringPath())
            if !context.isEmpty {
                basicData = try? JSON(data: context.data(using: .utf8)!)
            }
        }
        if !FileManager.default.fileExists(atPath: widgetFile.toStringPath()) {
            FileManager.default.createFile(atPath: widgetFile.toStringPath(), contents: nil)
        } else {
            let context = FileHandler.shared.readUtf8String(path: widgetFile.toStringPath())
            if !context.isEmpty {
                widgetData = try? JSON(data: context.data(using: .utf8)!)
                showWidget = true
            }
        }
    }
    
    func refreshState() {
        showUI = GlobalUIModel.exported.hasDefAccount()
    }
    
    /// 获取战绩面板的内容并写入本地保存
    func fetchContextAndSave(account: ShequAccount) async throws {
        let result = try await fetchOutline(user: account)
        FileHandler.shared.writeUtf8String(path: dashboardFile.toStringPath(), context: result.rawString()!)
        DispatchQueue.main.async { [self] in
            GlobalUIModel.exported.makeAnAlert(type: 1, msg: NSLocalizedString("dashboard.info.fetch_ok", comment: ""))
            basicData = try? JSON(data: FileHandler.shared.readUtf8String(path: dashboardFile.toStringPath()).data(using: .utf8)!)
            showUI = true
        }
    }
    
    /// 获取小组件【实时便签】的内容并写入本地保存
    func fetchWidgetAndSace(user: ShequAccount) async throws {
        let result = try await fetchWidget(user: user)
        FileHandler.shared.writeUtf8String(path: widgetFile.toStringPath(), context: result.rawString()!)
        DispatchQueue.main.async { [self] in
            GlobalUIModel.exported.makeAnAlert(type: 1, msg: NSLocalizedString("dashboard.info.fetch_widget_ok", comment: ""))
            widgetData = try? JSON(data: FileHandler.shared.readUtf8String(path: widgetFile.toStringPath()).data(using: .utf8)!)
            showWidget = true
        }
    }
    
    private func fetchOutline(user: ShequAccount) async throws -> JSON {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getGameOutline(roleID: user.genshinUID!))!)
        req.setHost(host: "api-takumi-record.mihoyo.com")
        req.setValue(
            "stuid=\(user.stuid!);stoken=\(user.stoken!);ltuid=\(user.stuid!);ltoken=\(user.ltoken!);mid=\(user.mid!)",
            forHTTPHeaderField: "Cookie")
        req.setValue("zh-cn", forHTTPHeaderField: "x-rpc-language")
        req.setUA()
        req.setDS(
            version: SaltVersion.V2, type: SaltType.X4,
            body: "avatar_list_type=1&role_id=\(user.genshinUID!)&server=cn_gf01", include: false)
        req.setReferer(referer: "https://webstatic.mihoyo.com")
        req.setValue("v4.1.5-ys_#/ys/daily", forHTTPHeaderField: "x-rpc-page")
        req.setValue("https://webstatic.mihoyo.com", forHTTPHeaderField: "Origin")
        req.setXRPCAppInfo(client: "5")
        req.setDeviceInfoHeaders()
        return try await req.receiveOrThrow()
    }
    
    private func fetchWidget(user: ShequAccount) async throws -> JSON {
        var req = URLRequest(url: URL(string: ApiEndpoints.shared.getWidgetSimple())!)
        req.setHost(host: "api-takumi-record.mihoyo.com")
        req.setUser(singleUser: user)
        req.setIosUA()
        req.setValue("https://webstatic.mihoyo.com", forHTTPHeaderField: "Origin")
        req.setDS(version: .V2, type: .X4, include: false)
        req.setDeviceInfoHeaders()
        req.setXRPCAppInfo(client: "5")
        return try await req.receiveOrThrow()
    }
}
