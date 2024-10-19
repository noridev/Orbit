//
//  MainTabViewSegment.swift
//  Harmonie
//
//  Created by makinosp on 2024/10/12.
//

import Foundation

enum MainTabViewSegment: String, CaseIterable {
    case social, friends, favorites, settings
}

extension MainTabViewSegment: CustomStringConvertible {
    var localizedString: LocalizedStringResource {
        LocalizedStringResource(stringLiteral: rawValue.capitalized)
    }

    var description: String {
        String(localized: localizedString)
    }
}

extension MainTabViewSegment: Identifiable {
    var id: Int { hashValue }
}
