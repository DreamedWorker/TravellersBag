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
    nonisolated(unsafe) private static var instance: ApiEndpoints?
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
    
    /// 获取社区账号的基本信息
    func getSheUserInfo(uid: String) -> String {
        return "\(ApiEndpoints.BbsApi)/user/api/getUserFullInfo?uid=\(uid)"
    }
    
    /// 获取原神的基本信息 （UID，服务器这些）
    func getGameBasic() -> String {
        return "\(ApiEndpoints.ApiTaKumiBindingApi)/getUserGameRolesByStoken"
    }
    
    /// 获取原神的详细信息，默认是国服
    func getGameDetail(game: String = "cn_gf01", roleID: String) -> String {
        return "\(ApiEndpoints.ApiTakumiRecordApi)/index?server=\(game)&role_id=\(roleID)"
    }
    
    /// 从战绩面板获取角色列表
    func getAvatarList() -> String {
        return "\(ApiEndpoints.ApiTakumiRecordApi)/character/list"
    }
    
    /// 从战绩面板获取角色详情
    func getAvatarDetail() -> String {
        return "\(ApiEndpoints.ApiTakumiRecordApi)/character/detail"
    }
    
    /// 获取战绩面板的大纲内容
    func getGameOutline(game: String = "cn_gf01", avatarType: String = "1", roleID: String) -> String {
        return "\(ApiEndpoints.ApiTakumiRecordApi)/index?avatar_list_type=\(avatarType)&server=\(game)&role_id=\(roleID)"
    }
    
    /// 通过Stoken获取Ltoken
    func getLTokenBySToken() -> String {
        return "\(ApiEndpoints.PassportApiAccountAuthApi)/getLTokenBySToken"
    }
    
    /// 通过GameToken获取CookieToken
    func getCookieToken(aid: Int, token: String) -> String {
        return "\(ApiEndpoints.ApiTakumiAuthApi)/getCookieAccountInfoByGameToken?account_id=\(aid)&game_token=\(token)"
    }
    
    /// 通过Stoken获取CookieToken
    func getCookieTokenByStoken(/*stoken: String, uid: Int*/) -> String {
        return "\(ApiEndpoints.PassportApiAccountAuthApi)/getCookieAccountInfoBySToken"
    }
    
    /// 通过Stoken获取GameToken
    func getGameTokenByStoken() -> String {
        return "\(ApiEndpoints.ApiTakumiAuthApi)/getGameToken"
    }
    
    /// 获取游戏启动器上显示的公告？
    func getHk4eAnnouncement() -> String {
        return "\(ApiEndpoints.Hk4eApiAnnouncementApi)/getAnnList?\(ApiEndpoints.AnnouncementQuery)"
    }
    
    /// 获取公告的详情
    func getHk4eAnnounceContext() -> String {
        return "\(ApiEndpoints.Hk4eApiAnnouncementApi)/getAnnContent?\(ApiEndpoints.AnnouncementQuery)"
    }
    
    /// 获取人机验证必要的两个参数
    func getGeetestRequired() -> String {
        return "\(ApiEndpoints.ApiTakumiCardWApi)/createVerification?is_high=true"
    }
    
    /// 提交人机验证结果判断是否通过
    func getGeetestResult() -> String {
        return "\(ApiEndpoints.ApiTakumiCardWApi)/verifyVerification"
    }
    
    /// 从水社原神首页获取所有角色信息
    func getCharactersFromHoyo() -> String {
        return "\(ApiEndpoints.ApiTakumiRecordApi)/character?"
    }
    
    /// 获取AuthKeyB用于祈愿记录提取
    func getAuthKey() -> String {
        return "\(ApiEndpoints.ApiTakumiMiyousheBindingApi)/genAuthKey"
    }
    
    /// 获取祈愿列表
    /// - Parameters:
    ///   - key AuthKeyB
    ///   - type 卡池类型
    ///   - endID 末位ID 决定翻页用途
    func getGachaData(key: String, type: Int, endID: Int) -> String {
        let neoKey = key.replacingOccurrences(of: "+", with: "%2b")
            .replacingOccurrences(of: "/", with: "%2f")
            .replacingOccurrences(of: "=", with: "%3d") //此前没有注意到工具做了自动转换 粘贴到浏览器里才发现的端倪 写个注释记录一下~
        return "\(ApiEndpoints.PublicOperationHk4eGachaInfoApi)/getGachaLog?lang=zh-cn&auth_appid=webview_gacha&authkey=\(neoKey)&authkey_ver=\(1)&sign_type=\(2)&gacha_type=\(type)&size=\(20)&end_id=\(endID)"
    }
    
    /// 获取安卓的桌面小组件的实时便签
    func getWidgetSimple() -> String {
        return "\(ApiEndpoints.ApiTakumiRecord)/game_record/app/genshin/aapi/widget/v2?"
    }
    
    /// 获取完整的实时便签
    func getWidgetFull(uid: String, server: String = "cn_gf01") -> String {
        return "\(ApiEndpoints.ApiTakumiRecordApi)/dailyNote?server=\(server)&role_id=\(uid)"
    }
}
