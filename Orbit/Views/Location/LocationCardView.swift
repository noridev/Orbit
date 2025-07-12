//
//  LocationCardView.swift
//  Orbit
//
//  Created by makinosp on 2024/06/15.
//

import NukeUI
import SwiftUI
import VRCKit

enum LocationCardData {
    case friendLocation(FriendsLocation)
    case privateLocation([Friend])
}

struct LocationCardView: View {
    @Environment(AppViewModel.self) var appVM
    @Binding var selected: InstanceLocation?
    
    let data: LocationCardData

    var body: some View {
        switch data {
        case .friendLocation(let location):
            FriendLocationContent(location: location, selected: $selected)
        case .privateLocation(let friends):
            PrivateLocationContent(friends: friends)
        }
    }
}

private struct FriendLocationContent: View {
    @Environment(AppViewModel.self) var appVM
    let location: FriendsLocation
    @Binding var selected: InstanceLocation?
    
    @State private var instance: Instance?
    @State private var isRequesting = true
    @State private var isFailure = false

    var body: some View {
        locationCardContent(instance: instance ?? PreviewData.instance)
            .redacted(reason: instance == nil ? .placeholder : [])
            .task {
                if case let .id(id) = location.location {
                    do {
                        defer { withAnimation { isRequesting = false } }
                        let service = appVM.services.instanceService
                        instance = try await service.fetchInstance(location: id)
                    } catch {
                        print(error)
                        isFailure = true
                    }
                }
            }
    }

    private func locationCardContent(instance: Instance) -> some View {
        NavigationLink(value: tag(instance)) {
            VStack(spacing: 0) {
                WorldHeaderView(redacted: isRequesting, world: instance.world) {
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
                        
                        Text(personAmount(instance))
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
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
                    .padding(.top, 8)
                }
            }
        }
        .disabled(isRequesting)
        .animation(.easeInOut(duration: 0.2), value: selected?.id == tag(instance).id)
    }

    private func tag(_ instance: Instance) -> InstanceLocation {
        InstanceLocation(location: location, instance: instance)
    }

    private func personAmount(_ instance: Instance) -> String {
        [location.friends.count, instance.userCount, instance.capacity]
            .map { $0.description }
            .joined(separator: " / ")
    }
}

private struct PrivateLocationContent: View {
    let friends: [Friend]
    
    var body: some View {
        NavigationLink(value: InstanceLocation(friends: friends)) {
            VStack(spacing: 0) {
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
                            .fontWeight(.medium)
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
                    HStack(spacing: 10) {
                        HorizontalProfileImages(friends)
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
}
