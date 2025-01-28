//
//  NetworkTaskError.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/28.
//

import Foundation

enum NetworkTaskError: Error {
    case systemLayer(String)
    case requestLayer(String)
}
