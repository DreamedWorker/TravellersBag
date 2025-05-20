//
//  Endpoints.swift
//  TravellersBag
//
//  Created by Yuan Shine on 2025/5/15.
//

import Foundation

class Endpoints {
    // MARK: - MiHoYo Apis
    static let ApiSDK = "api-sdk.mihoyo.com"
    static let ApiTakumi = "api-takumi.mihoyo.com"
    static let PublicDataApi = "public-data-api.mihoyo.com"
    static let Hk4eSdk = "hk4e-sdk.mihoyo.com"
    static let BbsApi = "bbs-api.mihoyo.com"
    static let PassportApi = "passport-api.mihoyo.com"
    
    // MARK: - Snap.Hutao Apis
    static let HutaoMetadataApi = "hutao-metadata-pages.snapgenshin.cn"
}

extension Endpoints {
    enum HttpMethod: String {
        case GET = "GET"
        case POST = "POST"
    }
}
