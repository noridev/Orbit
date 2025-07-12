//
//  SortType.swift
//  Orbit
//
//  Created by makinosp on 2024/10/19.
//

import Foundation

enum SortType: String, Hashable, CaseIterable, Identifiable {
    case name, loginLatest, loginOldest, latestActivity, oldestActivity, status, timeDescending, timeAscending
    
    var id: String { rawValue }

    enum Context {
        case friends, history
    }

    func description(for context: Context) -> String {
        switch self {
        case .name:
            String(localized: "Name")
        case .loginLatest:
            String(localized: "Login latest")
        case .loginOldest:
            String(localized: "Login oldest")
        case .latestActivity:
            String(localized: "Latest activity")
        case .oldestActivity:
            String(localized: "Oldest activity")
        case .status:
            String(localized: "Status")
        case .timeDescending:
            String(localized: "Latest")
        case .timeAscending:
            String(localized: "Oldest")
        }
    }

    var icon: Iconizable {
        switch self {
        case .name: IconSet.at
        case .loginLatest, .loginOldest: IconSet.calendar
        case .latestActivity, .oldestActivity: IconSet.lastActivity
        case .timeAscending, .timeDescending: IconSet.clock
        case .status: IconSet.circleFilled
        }
    }
}
