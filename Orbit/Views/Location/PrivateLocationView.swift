//
//  PrivateLocationView.swift
//  Orbit
//
//  Created by makinosp on 2024/10/30.
//

import MemberwiseInit
import SwiftUI
import VRCKit

@MemberwiseInit
struct PrivateLocationView: View {
    @InitWrapper(
        .internal,
        default: Binding<SegmentIdSelection?>.constant(nil),
        label: "_",
        type: Binding<SegmentIdSelection?>.self
    )
    @Binding private var selection: SegmentIdSelection?
    @Init(.internal) private let friends: [Friend]

    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(friends) { friend in
                    NavigationLabel {
                        HStack {
                            UserIcon(user: friend, size: Constants.IconSize.userDetailThumbnail)

                            VStack(alignment: .leading) {
                                Text(friend.displayName)
                                    .font(.headline)
                                
                                FriendStatusInLocationView(friend: friend)
                            }
                            .padding(.leading, 4)
                        }
                    }
                    .tag(SegmentIdSelection(friendId: friend.id))
                }
            } header: {
                HStack {
                    Text("Friends")
                    Spacer()
                    Text("\(friends.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Private")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private struct FriendStatusInLocationView: View {
        let friend: Friend
        
        var body: some View {
            if !friend.statusDescription.isEmpty {
                Text(friend.statusDescription)
                    .font(.caption)
                    .foregroundColor(.gray)
            } else if let lastLogin = friend.lastLogin {
                LastLoginView(lastLogin: lastLogin)
            }
        }
    }
}
