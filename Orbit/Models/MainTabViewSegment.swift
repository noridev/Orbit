//
//  MainTabViewSegment.swift
//  Orbit
//
//  Created by makinosp on 2024/10/12.
//

import Foundation
import SwiftUI

enum MainTabViewSegment: String, CaseIterable {
    case social, friends, search, favorites, friendsHistory, profile
}

extension MainTabViewSegment: CustomStringConvertible {
    var localizedString: LocalizedStringResource {
        switch self {
        case .friendsHistory:
            return LocalizedStringResource(stringLiteral: "Friends History")
        default:
            return LocalizedStringResource(stringLiteral: rawValue.capitalized)
        }
    }

    var description: String {
        String(localized: localizedString)
    }
}

extension MainTabViewSegment: Identifiable {
    var id: String { rawValue }
}

extension MainTabViewSegment {
    var icon: Iconizable {
        switch self {
        case .social: IconSet.social
        case .friends: IconSet.friends
        case .search: IconSet.search
        case .favorites: IconSet.favorite
        case .friendsHistory: IconSet.friendsHistory
        case .profile: IconSet.profile
        }
    }
}
