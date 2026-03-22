//
//  UserInfoStore.swift
//  dylib.ios.card
//
//  对应 dylib.verify.oc 的 UserInfoManager，供登录成功后写入解析字段。
//

import Foundation

final class UserInfoStore {
    static let shared = UserInfoStore()

    var state01: String?
    var state1081: String?
    var deviceID: String?
    var returnData: String?
    var expirationTime: String?
    var activationTime: String?

    private init() {}
}
