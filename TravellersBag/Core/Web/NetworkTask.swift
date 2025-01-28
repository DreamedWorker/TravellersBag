//
//  NetworkTask.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/28.
//

import Foundation
import SwiftyJSON

class NetworkTask {
    
    struct PreliminaryAnalysis: Codable {
        var retcode: Int
        var message: String?
    }
    
    static func fetchFromRemote(request: URLRequest, isPost: Bool = false, reqBody: Data? = nil) async -> Result<Data, NetworkTaskError> {
        var innerReq = request
        if isPost { // 设定请求方法 已知水社只需要下面两个方法就够了
            innerReq.httpMethod = "POST"
            innerReq.httpBody = reqBody
        } else {
            innerReq.httpMethod = "GET"
        }
        do {
            let (data, _) = try await URLSession.shared.data(for: innerReq)
            let msgBody = try JSONDecoder().decode(PreliminaryAnalysis.self, from: data)
            if msgBody.retcode == 0 || msgBody.retcode == 200 {
                let json = try! JSON(data: data)
                return .success(try! json["data"].rawData())
            } else {
                return .failure(.requestLayer(msgBody.message ?? NSLocalizedString("def.unknownError", comment: "")))
            }
        } catch {
            return .failure(.systemLayer(error.localizedDescription))
        }
    }
}
