//
//  LocationDetailView.swift
//  Orbit
//
//  Created by makinosp on 2024/07/17.
//

import AsyncSwiftUI
import NukeUI
import MemberwiseInit
import VRCKit

@MemberwiseInit
struct LocationDetailView: View {
    @Init(.internal) private let location: FriendsLocation
    @Init(.internal) private let instance: Instance

    private typealias InformationItem = (title: String, value: String)
    private var information: [InformationItem] {
        let platforms = instance.userPlatforms.map(\.description).joined(separator: ", ")
        return [
            (title: String(localized: "Instance Type"), value: instance.typeDescription),
            (title: String(localized: "Instance ID"), value: "#\(InstanceUtil.extractInstanceNumber(from: instance.instanceId))"),
            (title: String(localized: "Friends"), value: location.friends.count.description),
            (title: String(localized: "Users"), value: instance.userCount.description),
            (title: String(localized: "Capacity"), value: instance.capacity.description),
            (title: String(localized: "Region"), value: instance.region.description),
            (title: String(localized: "Platform"), value: platforms)
        ]
    }

    var body: some View {
        List {
            Section("World") {
                NavigationLink(destination: WorldPresentationView(id: instance.world.id)) {
                    WorldHeaderView(world: instance.world) {
                        Text(instance.world.description ?? "")
                            .font(.footnote)
                            .foregroundStyle(Color.gray)
                            .lineLimit(2)
                    }
                }
            }
            Section("Friends") { friendList }
            Section("Information") { informationList }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(instance.world.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var friendList: some View {
        Group {
            if location.friends.isEmpty {
                Label {
                    Text("No users added as friends")
                        .font(.body)
                        .foregroundColor(.gray)
                } icon: {
                    Image(systemName: "person.2.slash")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            } else {
                ForEach(location.friends) { friend in
                    NavigationLink(destination: UserDetailPresentationView(id: friend.id)) {
                        HStack {
                            UserIcon(user: friend, size: Constants.IconSize.thumbnail)

                            VStack(alignment: .leading) {
                                Text(friend.displayName)
                                    .font(.headline)
                                
                                FriendStatusInLocationView(friend: friend)
                            }
                            .padding(.leading, 4)
                        }
                    }
                }
            }
        }
    }

    private var informationList: ForEach<[InformationItem], String, some View> {
        ForEach(information, id: \.title) { informationItem in
            LabeledContent {
                Text(informationItem.value)
            } label: {
                Text(informationItem.title)
            }
        }
    }
    
    private struct FriendStatusInLocationView: View {
        let friend: Friend
        
        var body: some View {
            if !friend.statusDescription.isEmpty {
                Text(friend.statusDescription)
                    .font(.caption)
                    .foregroundColor(.gray)
            } else if let lastActivity = friend.lastActivity {
                LastActivityView(lastActivity: lastActivity)
            }
        }
    }
}
