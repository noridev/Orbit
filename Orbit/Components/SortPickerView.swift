//
//  SortPickerView.swift
//  Orbit
//
//  Created by NoriDev on 7/6/25.
//

import SwiftUI

struct SortPickerView: View {
    @Binding var selection: SortType
    let context: SortType.Context
    
    private var sortCases: [SortType] {
        switch context {
        case .friends:
            return [.name, .status, .latestLogin, .oldestLogin, .latestActivity, .oldestActivity]
        case .history:
            return [.name, .timeDescending, .timeAscending]
        }
    }

    var body: some View {
        Picker("Sort", selection: $selection) {
            ForEach(sortCases) { type in
                Label(type.description(for: context), systemImage: type.icon.systemName).tag(type)
            }
        }
        .pickerStyle(.inline)
    }
}
