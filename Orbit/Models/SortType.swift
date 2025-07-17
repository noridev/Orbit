//
//  SortType.swift
//  Orbit
//
//  Created by makinosp on 2024/10/19.
//

import Foundation

enum SortType: String, Hashable, CaseIterable, Identifiable {
    case name
    case status, latestLogin, oldestLogin, latestActivity, oldestActivity
    case timeDescending, timeAscending
    case memberCount
    
    var id: String { rawValue }

    enum Context {
        case friends, history, groups
    }

    func description(for context: Context) -> String {
        switch self {
        case .name:
            String(localized: "Name")
        case .status:
            String(localized: "Status")
        case .latestLogin:
            String(localized: "Latest login")
        case .oldestLogin:
            String(localized: "Oldest Login")
        case .latestActivity:
            String(localized: "Latest activity")
        case .oldestActivity:
            String(localized: "Oldest activity")
        case .timeDescending:
            String(localized: "Latest")
        case .timeAscending:
            String(localized: "Oldest")
        case .memberCount:
            String(localized: "Member Count")
        }
    }

    var icon: Iconizable {
        switch self {
        case .name: IconSet.at
        case .status: IconSet.circleFilled
        case .latestLogin, .oldestLogin: IconSet.calendar
        case .latestActivity, .oldestActivity: IconSet.lastActivity
        case .timeAscending, .timeDescending: IconSet.clock
        case .memberCount: IconSet.friendsFilled
        }
    }
}
