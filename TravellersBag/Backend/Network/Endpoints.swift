//
//  Endpoints.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/15.
//

import Foundation

class Endpoints {
    static let annoQuery: [URLQueryItem] = [
        .init(name: "game", value: "hk4e"), .init(name: "game_biz", value: "hk4e_cn"), .init(name: "lang", value: "zh-cn"),
        .init(name: "bundle_id", value: "hk4e_cn"), .init(name: "platform", value: "pc"), .init(name: "region", value: "cn_gf01"),
        .init(name: "level", value: "55"), .init(name: "uid", value: "100000000")
    ]
    // MARK: - MiHoYo Apis
    static let ApiSDK = "api-sdk.mihoyo.com"
    static let ApiTakumi = "api-takumi.mihoyo.com"
    static let PublicDataApi = "public-data-api.mihoyo.com"
    static let Hk4eSdk = "hk4e-sdk.mihoyo.com"
    static let BbsApi = "bbs-api.mihoyo.com"
    static let PassportApi = "passport-api.mihoyo.com"
    static let Hk4eAnnApi = "hk4e-ann-api.mihoyo.com"
    static let ActApiTakumi = "act-api-takumi.mihoyo.com"
    static let TakumiMiyousheApi = "api-takumi.miyoushe.com"
    static let PublicOperationApi = "public-operation-hk4e.mihoyo.com"
    
    // MARK: - Snap.Hutao Apis
    static let HutaoMetadataApi = "hutao-metadata-pages.snapgenshin.cn"
    static let HomaSnapGenshin = "homa.snapgenshin.com"
}

extension Endpoints {
    enum HttpMethod: String {
        case GET = "GET"
        case POST = "POST"
    }
}
