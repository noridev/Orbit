//
//  FavoriteGroupsListView.swift
//  Orbit
//
//  Created by makinosp on 2024/10/04.
//

import AsyncSwiftUI
import SwiftUI
import VRCKit

struct FavoriteGroupsListView: View {
    @Environment(FavoriteViewModel.self) var favoriteVM
    @Environment(AppViewModel.self) var appVM
    @Environment(\.dismiss) private var dismiss
    @State private var editingGroups: [FavoriteGroup.ID: String] = [:]
    @State private var isRequesting = false
    
    var body: some View {
        List {
            let types: [FavoriteType] = [.friend, .world]
            ForEach(types, id: \.hashValue) { type in
                Section(type.localizedStringKey) {
                    ForEach(favoriteVM.favoriteGroups(type)) { group in
                        TextField(
                            "Group Name",
                            text: Binding(
                                get: { editingGroups[group.id] ?? group.displayName },
                                set: { editingGroups[group.id] = $0 }
                            )
                        )
                    }
                }
            }
        }
        .navigationTitle("Edit Favorite Groups")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                AsyncButton {
                    await saveAllChanges()
                } label: {
                    if isRequesting {
                        ProgressView()
                    } else {
                        Text("Done")
                    }
                }
                .disabled(isRequesting)
            }
        }
        .onAppear {
            for group in favoriteVM.favoriteGroups {
                editingGroups[group.id] = group.displayName
            }
        }
    }
    
    private func saveAllChanges() async {
        isRequesting = true
        defer { isRequesting = false }
        
        do {
            for (groupId, newName) in editingGroups {
                if let group = favoriteVM.getFavoriteGroup(id: groupId),
                   group.displayName != newName {
                    try await favoriteVM.updateFavoriteGroup(
                        service: appVM.services.favoriteService,
                        id: groupId,
                        displayName: newName,
                        visibility: group.visibility
                    )
                }
            }
            dismiss()
        } catch {
            appVM.handleError(error)
        }
    }
}
