//
//  KeychainError.swift
//  TravellersBag
//
//  Created by 鸳汐 on 2025/1/11.
//

import Foundation

enum KeychainError: Error {
    case noPassword
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
}
