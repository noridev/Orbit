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
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            friendsHistoryViewButton
            presentSheetButton
        }
    }
    
    private var friendsHistoryViewButton: some View {
        NavigationLink(destination: FriendsHistoryView()) {
            Image(systemName: IconSet.friendsHistory.systemName)
        }
    }

    private var presentSheetButton: some View {
        Button("", systemImage: IconSet.filter.systemName) {
            isPresentedSheet.toggle()
        }
    }
}
