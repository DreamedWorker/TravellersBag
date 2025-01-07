//
//  URLs.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2024/10/25.
//

import Foundation

extension URL {
    func toStringPath() -> String {
        return self.path().removingPercentEncoding!
    }
}
