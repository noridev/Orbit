//
//  GroupListView+ToolbarContent.swift
//  Orbit
//
//  Created by NoriDev on 7/13/25.
//

import SwiftUI
import VRCKit

extension GroupListView {
    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            presentSheetButton
        }
    }
    
    private var presentSheetButton: some View {
        Button("", systemImage: IconSet.filter.systemName) {
            isPresentedSheet.toggle()
        }
    }
}
