//
//  ApiEndpoints.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/8/5.
//

import Foundation

// 我们约定：链接尽量不对外开放
// TODO: 本类随项目的完善而不断补充
/// 本类存储了米哈游所有已经由社区提供使用方法的API。 本类是单例类
class ApiEndpoints {
    // 单例类申明
    private static var instance: ApiEndpoints?
    private init (){}
    static var shared: ApiEndpoints {
        if instance == nil { instance = ApiEndpoints() }
        return instance!
    }
    
    // URL定义部分
    private static let ApiSDK = "https://api-sdk.mihoyo.com"
    
    private static let ApiTakumi = "https://api-takumi.mihoyo.com"
    private static let ApiTakumiCommon = "\(ApiTakumi)/common"
    private static let ApiTakumiAuthApi = "\(ApiTakumi)/auth/api"
    private static let ApiTaKumiBindingApi = "\(ApiTakumi)/binding/api"
    
    private static let ApiTakumiMiyoushe = "https://api-takumi.miyoushe.com"
    private static let ApiTakumiMiyousheBindingApi = "\(ApiTakumiMiyoushe)/binding/api"
    
    private static let ApiTakumiMiyousheAuthApi = "\(ApiTakumiMiyoushe)/auth/api"
    
    private static let ApiTakumiRecord = "https://api-takumi-record.mihoyo.com"
    private static let ApiTakumiRecordApi = "\(ApiTakumiRecord)/game_record/app/genshin/api"
    
    private static let ApiTakumiCardApi = "\(ApiTakumiRecord)/game_record/app/card/api"
    private static let ApiTakumiCardWApi = "\(ApiTakumiRecord)/game_record/app/card/wapi"
    
    private static let ApiTakumiEvent = "\(ApiTakumi)/event"
    private static let ApiTakumiEventCalculate = "\(ApiTakumiEvent)/e20200928calculate"
    
    private static let HoyoApp = "https://app.mihoyo.com"
    private static let AppAuthApi = "\(HoyoApp)/account/auth/api"
    
    private static let BbsApi = "https://bbs-api.mihoyo.com"
    private static let BbsApiUserApi = "\(BbsApi)/user/wapi"
    
    private static let BbsApiMiYouShe = "https://bbs-api.miyoushe.com"
    private static let BbsApiMiYouSheApiHub = "https://bbs-api.miyoushe.com/apihub"
    private static let BbsApiMiYouSheTopicApi = "https://bbs-api.miyoushe.com/topic/api"
    private static let BbsApiMiYouShePainterApiTopic = "https://bbs-api.miyoushe.com/painter/api/topic"
    
    
    private static let Hk4eApi = "https://hk4e-api.mihoyo.com"
    private static let Hk4eApiAnnouncementApi = "\(Hk4eApi)/common/hk4e_cn/announcement/api"
    private static let Hk4eApiGachaInfoApi = "\(Hk4eApi)/event/gacha_info/api"
    
    private static let Hk4eSdk = "https://hk4e-sdk.mihoyo.com"
    
    private static let PassportApi = "https://passport-api.mihoyo.com"
    private static let PassportApiAccountAuthApi = "\(PassportApi)/account/auth/api"
    private static let PassportApiV4 = "https://passport-api-v4.mihoyo.com"
    
    private static let PassportApiAccountMaCnSession = "\(PassportApi)/account/ma-cn-session"
    
    
    private static let PassportApiStatic = "https://passport-api-static.mihoyo.com"
    
    private static let PassportApiStaticAccountMaCnPassport = "\(PassportApiStatic)/account/ma-cn-passport/passport"
    
    private static let PublicOperationHk4e = "https://public-operation-hk4e.mihoyo.com";
    private static let PublicOperationHk4eGachaInfoApi = "\(PublicOperationHk4e)/gacha_info/api";
    
    private static let SdkStatic = "https://sdk-static.mihoyo.com"
    private static let SdkStaticLauncherApi = "\(SdkStatic)/hk4e_cn/mdk/launcher/api"
    
    private static let AnnouncementQuery = "game=hk4e&game_biz=hk4e_cn&lang=zh-cn&bundle_id=hk4e_cn&platform=pc&region=cn_gf01&level=55&uid=100000000"
    
    private static let ApiStatic = "https://api-static.mihoyo.com"
    private static let ApiStaticCommon = "\(ApiStatic)/common"
    private static let BbsApiStatic = "https://bbs-api-static.mihoyo.com"
    
    private static let PublicDataApi = "https://public-data-api.mihoyo.com"
    
    private static let WebStaticMiHoYo = "https://webstatic.mihoyo.com"
    private static let WebStaticMiHoYoBBSEvent = "https://webstatic.mihoyo.com/bbs/event"

    static let getFp = "\(PublicDataApi)/device-fp/api/getFp"
    
    /// 获取额外拓展信息
    /// - Parameters:
    ///   - platform 平台编号：WEB：4 MWEB：5 米游社：2（默认）
    func getExtList(platform: Int = 2) -> String {
        return "\(ApiEndpoints.PublicDataApi)/device-fp/api/getExtList?platform=${platform}"
    }
    
    /// 获取登录二维码
    func getFetchQRCode() -> String {
        return "\(ApiEndpoints.Hk4eSdk)/hk4e_cn/combo/panda/qrcode/fetch"
    }
    
    /// 查询登录二维码状态
    func getQueryQRState() -> String {
        return "\(ApiEndpoints.Hk4eSdk)/hk4e_cn/combo/panda/qrcode/query"
    }
    
    /// 获取SToken(V2?)通过GameToken
    func getSTokenByGameToken() -> String {
        return "\(ApiEndpoints.ApiTakumi)/account/ma-cn-session/app/getTokenByGameToken"
    }
}
