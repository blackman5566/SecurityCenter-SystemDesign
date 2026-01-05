//
//  BiometryType.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

//生物啟用功能列表,目前就是 faceid 跟 touchId
enum BiometryType {
    case faceId
    case touchId

    var title: String {
        switch self {
        case .faceId: return "Face ID"
        case .touchId: return "Touch ID"
        }
    }

    var iconName: String {
        switch self {
        case .faceId: return "face_id_24"
        case .touchId: return "touch_id_2_24"
        }
    }
}
