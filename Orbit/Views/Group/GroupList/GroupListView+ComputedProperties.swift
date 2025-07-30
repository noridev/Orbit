//
//  GroupListView+ComputedProperties.swift
//  Orbit
//
//  Created by NoriDev on 7/13/25.
//

import SwiftUI
import VRCKit

extension GroupListView {
    var navigationTitle: String {
        if let userName = userName {
            return "\(userName)'s Groups"
        } else {
            return "그룹"
        }
    }
    
    var filteredRepresentedGroups: [VRCGroup] {
        sortedAndFilteredGroups(for: groupViewModel.representedGroups)
    }
    
    var filteredManagedGroups: [VRCGroup] {
        sortedAndFilteredGroups(for: groupViewModel.managedGroups)
    }
    
    var filteredMutualGroups: [VRCGroup] {
        sortedAndFilteredGroups(for: groupViewModel.mutualGroups)
    }
    
    var filteredRegularGroups: [VRCGroup] {
        sortedAndFilteredGroups(for: groupViewModel.regularGroups)
    }
    
    func sortedAndFilteredGroups(for groups: [VRCGroup]) -> [VRCGroup] {
        let filtered = groups.filter { group in
            searchText.isEmpty ||
            group.name.localizedCaseInsensitiveContains(searchText) ||
            group.shortCode.localizedCaseInsensitiveContains(searchText) ||
            group.discriminator.localizedCaseInsensitiveContains(searchText)
        }
        
        return filtered.sorted {
            switch sortType {
            case .name:
                return $0.name.lowercased() < $1.name.lowercased()
            case .memberCount:
                return $0.memberCount > $1.memberCount
            default:
                return $0.name.lowercased() < $1.name.lowercased()
            }
        }
    }
}
