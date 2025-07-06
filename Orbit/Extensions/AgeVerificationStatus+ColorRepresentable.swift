//
//  AgeVerificationStatus+ColorRepresentable.swift
//  Orbit
//
//  Created by NoriDev on 7/7/25.
//

import SwiftUI
import VRCKit

extension AgeVerificationStatus: ColorRepresentable {
    var color: Color {
        switch self {
        case .over18:
            return .indigo
        case .hidden:
            return .gray
        default:
            return .clear
        }
    }
}
