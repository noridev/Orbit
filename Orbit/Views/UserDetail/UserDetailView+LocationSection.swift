//
//  UserDetailView+LocationSection.swift
//  Orbit
//
//  Created by makinosp on 2024/09/06.
//

import NukeUI
import SwiftUI
import VRCKit

extension UserDetailView {
    var locationSection: some View {
        GroupBox("Location") {
            VStack(alignment: .leading, spacing: 8) {
                if let instance = instance {
                    let friendsInInstance = friendVM.allFriends.filter { friend in
                        if case let .id(locationId) = friend.location {
                            return locationId == instance.id
                        }
                        return false
                    }
                    let location = FriendsLocation(location: .id(instance.id), friends: friendsInInstance)

                    NavigationLink(destination: LocationDetailView(
                        location: location,
                        instance: instance
                    )
                    .environment(appVM)
                    .environment(friendVM)
                    ) {
                        locationContent(instance: instance, location: location)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if user.location == .private {
                    NavigationLink(destination: PrivateLocationView(friends: friendVM.friendsInPrivate)) {
                        privateLocationContent(friends: friendVM.friendsInPrivate)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    HStack(spacing: 16) {
                        GradientOverlayImageView(
                            imageUrl: locationImageUrl,
                            size: CGSize(width: 80, height: 65)
                        )
                        .frame(width: 80, height: 65)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(locationDescription)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        Spacer()
                    }
                }
            }
            .redacted(reason: isRequesting ? .placeholder : [])
        }
        .groupBoxStyle(.card)
    }
    
    private func locationContent(instance: Instance, location: FriendsLocation) -> some View {
        HStack {
            VStack(spacing: 8) {
                WorldHeaderView(redacted: isRequesting, world: instance.world) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(InstanceUtil.getInstanceWithInstanceType(instance))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule()).lineLimit(1)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(personAmount(instance, location: location))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                if !location.friends.isEmpty {
                    HStack(spacing: 10) {
                        HStack(spacing: 2) {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(location.friends.count)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                        
                        HorizontalProfileImages(location.friends)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
                }
            }
            
            Spacer()
            
            IconSet.forward.icon
                .foregroundColor(.gray)
        }
        .contentShape(Rectangle())
    }
    
    private func privateLocationContent(friends: [Friend]) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 16) {
                    GradientOverlayImageView(
                        imageUrl: Const.privateWorldImageUrl,
                        size: CGSize(width: 80, height: 65)
                    )
                    .frame(width: 80, height: 65)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Private Instances")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(friends.count)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
                
                if !friends.isEmpty {
                    HorizontalProfileImages(friends)
                        .padding(.leading, 8)
                }
            }
            Spacer()
            IconSet.forward.icon
                .foregroundColor(.gray)
        }
        .contentShape(Rectangle())
    }

    private var locationDescription: String {
        if let instance = instance {
            instance.world.name
        } else if user.platform == .some(.web) {
            String(localized: "Active on Website")
        } else if user.location == .private {
            String(localized: "User is online in a private instance")
        } else if user.location == .offline {
            String(localized: "Offline")
        } else if isRequesting {
            String(repeating: " ", count: 15)
        } else {
            ""
        }
    }

    private var locationImageUrl: URL? {
        switch user.location {
        case .id:
            user.platform == .some(.web) ? Const.locationOnWebImageUrl : instance?.imageUrl(.x256)
        case .private, .traveling:
            Const.privateWorldImageUrl
        case .offline:
            Const.offlineImageUrl
        }
    }

    private func personAmount(_ instance: Instance, location: FriendsLocation) -> String {
        [location.friends.count, instance.userCount, instance.capacity]
            .map { $0.description }
            .joined(separator: " / ")
    }
}
