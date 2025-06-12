//
//  HoyoAccountHelper.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/18.
//

import Foundation
import AppKit
import SwiftyJSON

class HoyoAccountHelper {
    nonisolated(unsafe) private static var currentCodeURL: String = ""
    
    static func generateQRCode() async throws -> NSImage? {
        let qrcodeRequest = RequestBuilder.buildRequest(
            method: .POST, host: Endpoints.Hk4eSdk, path: "/hk4e_cn/combo/panda/qrcode/fetch", queryItems: [],
            body: try JSONSerialization.data(
                withJSONObject: ["app_id": "2", "device": ConfigManager.getSettingsValue(key: ConfigKey.DEVICE_ID, value: "")]
            )
        )
        let qrcode = try await NetworkClient.simpleDataClient(request: qrcodeRequest, type: QRCode.self)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(qrcode.data.url.data(using: .utf8)!, forKey: "inputMessage")
        filter?.setValue("H", forKey: "inputCorrectionLevel")
        guard let output = filter?.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = output.transformed(by: transform)
        let rep = NSCIImageRep(ciImage: scaledImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        currentCodeURL = qrcode.data.url
        return nsImage
    }
    
    static func login(
        checkHasSame: @escaping @Sendable (String) async -> Bool,
        completion: @escaping @Sendable (HoyoAccount) -> Void
    ) async throws {
        let qrcodeScanResult = try await checkCodeScanState()
        if await checkHasSame(qrcodeScanResult.uid) { // 需要判断本地是否存在相同社区ID的账号
            throw NSError(domain: "AccountLogin", code: -5, userInfo: [NSLocalizedDescriptionKey: "Ilegal operation: account already existed."])
        } else {
            let stokenResult = try await fetchUserSToken(uid: qrcodeScanResult.uid, token: qrcodeScanResult.token)
            let cookieTokenResult = try await fetchCookieToken(uid: qrcodeScanResult.uid, token: qrcodeScanResult.token)
            let bbsInfo = try await fetchBBSInfo(uid: qrcodeScanResult.uid)
            let genshinInfo = try await fetchGenshinInfo(uid: qrcodeScanResult.uid, stoken: stokenResult.data.token.token, mid: stokenResult.data.userInfo.mid)
            let ltokenResult = try await fetchLtoken(uid: qrcodeScanResult.uid, stoken: stokenResult.data.token.token, mid: stokenResult.data.userInfo.mid)
            completion(
                .init(
                    activedAccount: false, bbsHeadImg: bbsInfo.bbsHeadImg, bbsNicname: bbsInfo.bbsNick,
                    cookie: .init(
                        cookieToken: cookieTokenResult.data.cookieToken, gameToken: qrcodeScanResult.token, ltoken: ltokenResult.data.ltoken,
                        mid: stokenResult.data.userInfo.mid, stoken: stokenResult.data.token.token, stuid: qrcodeScanResult.uid
                    ),
                    game: .init(
                        genshinNicname: genshinInfo.nickname, genshinPicID: "other", genshinUID: genshinInfo.gameUid,
                        level: String(genshinInfo.level), serverName: genshinInfo.regionName, serverRegion: genshinInfo.region
                    )
                )
            )
        }
    }
    
    // 检查二维码扫描状态 如果成功则返回一个含GameToken和社区ID的结构体
    private static func checkCodeScanState() async throws -> ScanResultRaw {
        let urlComponent = URLComponents(string: currentCodeURL)
        guard let urlComponent = urlComponent else {
            throw NSError(domain: "AccountLogin", code: -2, userInfo: [NSLocalizedDescriptionKey: "Ilegal code url: empty"])
        }
        guard let codeTicket = urlComponent.queryItems?.filter({ $0.name == "ticket" }).first?.value else {
            throw NSError(domain: "AccountLogin", code: -3, userInfo: [NSLocalizedDescriptionKey: "Ilegal code url: no ticket"])
        }
        let codeStateRequest = RequestBuilder.buildRequest(
            method: .POST, host: Endpoints.Hk4eSdk, path: "/hk4e_cn/combo/panda/qrcode/query", queryItems: [],
            body: try JSONSerialization.data(withJSONObject: [
                "app_id": "2", "device": ConfigManager.getSettingsValue(key: ConfigKey.DEVICE_ID, value: ""), "ticket": codeTicket
            ])
        )
        let scanResult = try await NetworkClient.simpleDataClient(request: codeStateRequest, type: QRCodeScanResult.self)
        if scanResult.retcode == 0 {
            if scanResult.data.stat != "Confirmed" {
                throw NSError(domain: "AccountLogin", code: -4, userInfo: [NSLocalizedDescriptionKey: "Ilegal code state: \(scanResult.data.stat)"])
            } else {
                let payload = try JSONDecoder().decode(ScanResultRaw.self, from: scanResult.data.payload.raw.data(using: .utf8)!)
                return payload
            }
        } else {
            throw NSError(domain: "AccountLogin", code: -4, userInfo: [NSLocalizedDescriptionKey: "Ilegal code state: \(scanResult.message)"])
        }
    }
    
    // 返回账号的stoken 同时还包含了mid
    static func fetchUserSToken(uid: String, token: String) async throws -> STokenRelated {
        let stokenRequest = RequestBuilder.buildRequest(
            method: .POST, host: Endpoints.ApiTakumi, path: "/account/ma-cn-session/app/getTokenByGameToken", queryItems: [],
            body: try JSONSerialization.data(withJSONObject: ["account_id": Int(uid)!, "game_token": token]),
            needAppId: true
        )
        let result = try await NetworkClient.simpleDataClient(request: stokenRequest, type: STokenRelated.self)
        if result.retcode == 0 {
            return result
        } else {
            throw NSError(domain: "AccountLogin", code: -10, userInfo: [NSLocalizedDescriptionKey: "Ilegal stoken state: \(result.message)"])
        }
    }
    
    // 返回账号的cookie token
    static func fetchCookieToken(uid: String, token: String) async throws -> CookieTokenRelated {
        let cookieTokenRequest = RequestBuilder.buildRequest(
            method: .GET, host: Endpoints.ApiTakumi, path: "/auth/api/getCookieAccountInfoByGameToken",
            queryItems: [.init(name: "account_id", value: uid), .init(name: "game_token", value: token)]
        )
        let result = try await NetworkClient.simpleDataClient(request: cookieTokenRequest, type: CookieTokenRelated.self)
        if result.retcode == 0 {
            return result
        } else {
            throw NSError(domain: "AccountLogin", code: -11, userInfo: [NSLocalizedDescriptionKey: "Ilegal cookieToken state: \(result.message)"])
        }
    }
    
    // 返回社区头像和昵称
    private static func fetchBBSInfo(uid: String) async throws -> BBSBerifInfo {
        let bbsInfoRequest = RequestBuilder.buildRequest(
            method: .GET, host: Endpoints.BbsApi, path: "/user/api/getUserFullInfo", queryItems: [
                .init(name: "uid", value: uid)
            ]
        )
        let (a, _) = try await URLSession.shared.data(for: bbsInfoRequest)
        let result = try JSON(data: a)
        let origin = result["retcode"].intValue
        if origin == 0 {
            let formatted = result["data"]
            return BBSBerifInfo(
                bbsNick: formatted["user_info"]["nickname"].stringValue,
                bbsHeadImg: formatted["user_info"]["avatar_url"].stringValue.replacingOccurrences(of: "\\", with: "")
            )
        } else {
            throw NSError(domain: "AccountLogin", code: -12, userInfo: [NSLocalizedDescriptionKey: "Ilegal BBS state!"])
        }
    }
    
    // 获取游戏的基本情况 如果没有关联的游戏则会报错终止登录
    private static func fetchGenshinInfo(uid: String, stoken: String, mid: String) async throws -> GameBasic {
        let genshinInfoRequest = RequestBuilder.buildRequest(
            method: .GET, host: Endpoints.ApiTakumi, path: "/binding/api/getUserGameRolesByStoken", queryItems: [],
            needAppId: true, optHost: "api-takumi.miyoushe.com",
            referer: "https://app.mihoyo.com", origin: "https://api-takumi.miyoushe.com",
            user: .init(uid: uid, stoken: stoken, mid: mid),
            needRequestWith: true,
            ds: DynamicSecret.getDynamicSecret(version: .V1, saltType: .K2)
        )
        let gameList = try await NetworkClient.simpleDataClient(request: genshinInfoRequest, type: GameBasicInfo.self)
        if gameList.retcode == 0 {
            guard let genshin = gameList.data.list.filter({ $0.gameBiz == "hk4e_cn" }).first else {
                throw NSError(domain: "AccountLogin", code: -6, userInfo: [NSLocalizedDescriptionKey: "Ilegal account info: no Genshin info."])
            }
            return genshin
        } else {
            throw NSError(domain: "AccountLogin", code: -12, userInfo: [NSLocalizedDescriptionKey: "Ilegal game state: \(gameList.message)"])
        }
    }
    
    // 获取账号的ltoken
    static func fetchLtoken(uid: String, stoken: String, mid: String) async throws -> LtokenInfo {
        let ltokenRequest = RequestBuilder.buildRequest(
            method: .GET, host: Endpoints.PassportApi, path: "/account/auth/api/getLTokenBySToken", queryItems: [],
            user: .init(uid: uid, stoken: stoken, mid: mid)
        )
        let result = try await NetworkClient.simpleDataClient(request: ltokenRequest, type: LtokenInfo.self)
        if result.retcode == 0 {
            return result
        } else {
            throw NSError(domain: "AccountLogin", code: -14, userInfo: [NSLocalizedDescriptionKey: "Ilegal ltoken state: \(result.message)"])
        }
    }
}

extension HoyoAccountHelper {
    private struct QRCode: Codable {
        let retcode: Int
        let message: String
        let data: QRCodeData
    }
    
    private struct QRCodeData: Codable {
        let url: String
    }
}

extension HoyoAccountHelper {
    private struct QRCodeScanResult: Codable {
        let retcode: Int
        let message: String
        let data: QRCodeScanResultData
    }
    
    private struct ScanResultRaw: Codable {
        let uid, token: String
    }
    
    private struct QRCodeScanResultData: Codable {
        let stat: String
        let payload: ScanResultPayload

        enum CodingKeys: String, CodingKey {
            case stat, payload
        }
    }
    
    private struct ScanResultPayload: Codable {
        let proto, raw, ext: String
    }
}

extension HoyoAccountHelper {
    struct STokenRelated: Codable {
        let retcode: Int
        let message: String
        let data: STokenData
    }
    
    struct STokenData: Codable {
        let token: SToken
        let userInfo: UserInfo
        let needRealperson: Bool

        enum CodingKeys: String, CodingKey {
            case token
            case userInfo = "user_info"
            case needRealperson = "need_realperson"
        }
    }
    
    struct SToken: Codable {
        let tokenType: Int
        let token: String

        enum CodingKeys: String, CodingKey {
            case tokenType = "token_type"
            case token
        }
    }
    
    struct UserInfo: Codable {
        let aid, mid, accountName, email: String
        let isEmailVerify: Int
        let areaCode, mobile, safeAreaCode, safeMobile: String
        let realname, identityCode, rebindAreaCode, rebindMobile: String
        let rebindMobileTime: String
        let country, passwordTime: String
        let isAdult: Int
        let unmaskedEmail: String
        let unmaskedEmailType: Int

        enum CodingKeys: String, CodingKey {
            case aid, mid
            case accountName = "account_name"
            case email
            case isEmailVerify = "is_email_verify"
            case areaCode = "area_code"
            case mobile
            case safeAreaCode = "safe_area_code"
            case safeMobile = "safe_mobile"
            case realname
            case identityCode = "identity_code"
            case rebindAreaCode = "rebind_area_code"
            case rebindMobile = "rebind_mobile"
            case rebindMobileTime = "rebind_mobile_time"
            case country
            case passwordTime = "password_time"
            case isAdult = "is_adult"
            case unmaskedEmail = "unmasked_email"
            case unmaskedEmailType = "unmasked_email_type"
        }
    }
}

extension HoyoAccountHelper {
    struct CookieTokenRelated: Codable {
        let retcode: Int
        let message: String
        let data: CookieTokenData
    }

    struct CookieTokenData: Codable {
        let uid, cookieToken: String

        enum CodingKeys: String, CodingKey {
            case uid
            case cookieToken = "cookie_token"
        }
    }
}

extension HoyoAccountHelper {
    private struct BBSBerifInfo: Codable {
        let bbsNick: String
        let bbsHeadImg: String
    }
}

extension HoyoAccountHelper {
    private struct GameBasicInfo: Codable {
        let retcode: Int
        let message: String
        let data: GameBasicInfoClass
    }

    private struct GameBasicInfoClass: Codable {
        let list: [GameBasic]
    }

    private struct GameBasic: Codable {
        let gameBiz, region, gameUid, nickname: String
        let level: Int
        let isChosen: Bool
        let regionName: String
        let isOfficial: Bool

        enum CodingKeys: String, CodingKey {
            case gameBiz = "game_biz"
            case region
            case gameUid = "game_uid"
            case nickname, level
            case isChosen = "is_chosen"
            case regionName = "region_name"
            case isOfficial = "is_official"
        }
    }
}

extension HoyoAccountHelper {
    struct LtokenInfo: Codable {
        let retcode: Int
        let message: String
        let data: LtokenData
    }

    struct LtokenData: Codable {
        let ltoken: String
    }
}
