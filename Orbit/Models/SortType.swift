//
//  SortType.swift
//  Orbit
//
//  Created by makinosp on 2024/10/19.
//

import Foundation

enum SortType: String, Hashable, CaseIterable, Identifiable {
    case name, loginLatest, loginOldest, status, timeDescending, timeAscending
    
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
        case .timeAscending, .timeDescending: IconSet.clock
        case .status: IconSet.circleFilled
        }
    }
}
