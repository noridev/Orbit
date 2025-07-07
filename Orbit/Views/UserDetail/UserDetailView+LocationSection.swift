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
                    NavigationLink(destination: LocationDetailView(
                        location: FriendsLocation(location: .id(instance.id), friends: friendVM.allFriends.filter { friend in
                            if case let .id(locationId) = friend.location {
                                return locationId == instance.id
                            }
                            return false
                        }),
                        instance: instance
                    )
                    .environment(appVM)
                    .environment(friendVM)
                    ) {
                        HStack {
                            SquareURLImage(imageUrl: locationImageUrl)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(locationDescription)
                                    .font(.headline)
                                    .padding(.leading, 8)
                                    .lineLimit(2)
                                    .truncationMode(.tail)
                                Text("#\(InstanceUtil.extractInstanceNumber(from: instance.instanceId)) \(InstanceUtil.getInstanceTypeWithUserCount(instance))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 8)
                            }
                            Spacer()
                            IconSet.forward.icon
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    HStack {
                        SquareURLImage(imageUrl: locationImageUrl)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(locationDescription)
                                .font(.headline)
                                .padding(.leading, 8)
                        }
                    }
                }
            }
            .redacted(reason: isRequesting ? .placeholder : [])
        }
        .groupBoxStyle(.card)
    }

    private var locationDescription: String {
        if let instance = instance {
            instance.world.name
        } else if user.platform == .some(.web) {
            "Active on Website"
        } else if user.location == .private {
            "Private World"
        } else if user.location == .offline {
            "Offline"
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
}
