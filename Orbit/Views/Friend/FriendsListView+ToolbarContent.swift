//
//  FriendsListView+ToolbarContent.swift
//  Orbit
//
//  Created by makinosp on 2024/08/12.
//

import SwiftUI
import VRCKit

extension FriendsListView {
    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigation) { presentSheetButton }
    }

    private var presentSheetButton: some View {
        Button("", systemImage: "sidebar.leading") {
            isPresentedSheet.toggle()
        }
    }
}
