//
//  FriendsListSheetView.swift
//  Orbit
//
//  Created by makinosp on 2025/01/22.
//

import SwiftUI
import VRCKit

struct FriendsListSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FriendViewModel.self) private var friendVM
    @Environment(FavoriteViewModel.self) private var favoriteVM

    var body: some View {
        NavigationStack {
            Form {
                @Bindable var friendVM = friendVM
                SortPickerView(selection: $friendVM.sortType, context: .friends)

                Section {
                    ForEach(UserStatus.allCases) { userStatus in
                        let isOn = $friendVM.filterUserStatus.containsBinding(for: userStatus)
                        Toggle(isOn: isOn) {
                            Label {
                                Text(userStatus.description)
                            } icon: {
                                Image(systemName: IconSet.circleFilled.systemName)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(userStatus.color)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Statuses")
                        Spacer()
                        Button("Clear") {
                            friendVM.filterUserStatus.removeAll()
                        }
                        .font(.caption)
                    }
                }

                Section {
                    ForEach(favoriteVM.favoriteGroups(.friend)) { favoriteGroup in
                        let isOn = $friendVM.filterFavoriteGroups.containsBinding(for: favoriteGroup.id)
                        Toggle(isOn: isOn) {
                            Label {
                                Text(favoriteGroup.displayName)
                            } icon: {
                                Image(systemName: IconSet.favoriteGroup.systemName)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Favorite Groups")
                        Spacer()
                        Button("Clear") {
                            friendVM.filterFavoriteGroups.removeAll()
                        }
                        .font(.caption)
                    }
                }
            }
            .navigationTitle("Display Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button {
                        dismiss()
                    } label: {
                        ExitButton()
                    }
                }
            }
        }
    }
}
