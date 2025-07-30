//
//  GroupLocationDetailView.swift
//  Orbit
//
//  Created by NoriDev on 7/23/25.
//

import SwiftUI
import VRCKit

struct GroupLocationDetailView: View {
    let instance: Instance
    @Environment(AppViewModel.self) var appVM
    @Environment(FriendViewModel.self) var friendVM
    
    private typealias InformationItem = (title: String, value: String)
    private var information: [InformationItem] {
        let platforms = instance.userPlatforms.map(\.description).joined(separator: ", ")
        var items = [
            (title: String(localized: "Instance Type"), value: instance.typeDescription),
            (title: String(localized: "Instance ID"), value: "#\(InstanceUtil.extractInstanceNumber(from: instance.instanceId))"),
            (title: String(localized: "Users"), value: instance.userCount.description),
            (title: String(localized: "Capacity"), value: instance.capacity.description),
            (title: String(localized: "Region"), value: instance.region.description),
            (title: String(localized: "Platform"), value: platforms)
        ]
        
        if instance.ageGate == true {
            items.append((title: "Age Gate", value: "Required"))
        }
        
        return items
    }
    
    var body: some View {
        List {
            if let world = instance.world {
                Section("World") {
                    NavigationLink(destination: WorldPresentationView(id: world.id)) {
                        WorldHeaderView(world: world) {
                            Text(world.description ?? "")
                                .font(.footnote)
                                .foregroundStyle(Color.gray)
                                .lineLimit(2)
                        }
                    }
                }
            }
            Section("Friends in Instance") { friendList }
            Section("Information") { informationList }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(instance.world?.name ?? "Unknown World")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var friendList: some View {
        Group {
            let friendsInInstance = friendVM.allFriends.filter { friend in
                if case let .id(locationId) = friend.location {
                    return locationId == instance.id
                }
                return false
            }
            
            if friendsInInstance.isEmpty {
                Label {
                    Text("No friends in this instance")
                        .font(.body)
                        .foregroundColor(.gray)
                } icon: {
                    Image(systemName: "person.2.slash")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            } else {
                ForEach(friendsInInstance) { friend in
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
