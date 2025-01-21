//
//  CultivationView.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/21.
//

import SwiftUI
import SwiftData

struct CultivationView: View {
    @State private var test: String = "test"
    @Query var accounts: [MihoyoAccount]
    
    let testObject = """
{
    "items": [{
        "avatar_id": 10000073,
        "avatar_level_current": 70,
        "avatar_level_target": 90,
        "element_attr_id": 4,
        "skill_list": [{
            "id": 7331,
            "level_current": 1,
            "level_target": 10
        }, {
            "id": 7332,
            "level_current": 6,
            "level_target": 10
        }, {
            "id": 7339,
            "level_current": 1,
            "level_target": 10
        }, {
            "id": 7321,
            "level_current": 1,
            "level_target": 1
        }, {
            "id": 7322,
            "level_current": 1,
            "level_target": 1
        }, {
            "id": 7323,
            "level_current": 1,
            "level_target": 1
        }],
        "weapon": {
            "id": 14407,
            "name": "万国诸海图谱",
            "icon": "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon_ub1ajh/83f2e5144707a0e5f1a2483c92bbff44.png",
            "weapon_cat_id": 10,
            "weapon_level": 4,
            "max_level": 90,
            "level_current": 50,
            "level_target": 90
        },
        "from_user_sync": true,
        "avatar_promote_level": 4
    }],
    "lang": "zh-cn",
    "region": "cn_gf01",
    "uid": "000000000"
}
"""
    var body: some View {
        VStack {
            Text(test)
            Button("app.name", action: {
                Task {
                    let act = accounts.filter({ $0.active }).first!
                    let url = URL(string: "https://api-takumi.mihoyo.com/event/e20200928calculate/v3/batch_compute")!
                    var req = URLRequest(url: url)
                    req.setUA()
                    req.setDeviceInfoHeaders()
                    req.setHost(host: "api-takumi.mihoyo.com")
                    req.setValue("https://act.mihoyo.com", forHTTPHeaderField: "https://act.mihoyo.com")
                    req.setReferer(referer: "https://act.mihoyo.com/")
                    req.setValue("ltoken=\(act.cookies.ltoken);ltuid=\(act.cookies.stuid)", forHTTPHeaderField: "cookie")
                    let data = await req.receiveOrBlackData(isPost: true, reqBody: testObject.data(using: .utf8))
                    DispatchQueue.main.async {
                        test = String(data: data, encoding: .utf8)!
                    }
                }
            })
        }
        .padding()
    }
}

#Preview {
    CultivationView()
}
