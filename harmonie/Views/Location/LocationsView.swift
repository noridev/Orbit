//
//  LocationsView.swift
//  Harmonie
//
//  Created by makinosp on 2024/03/16.
//

import SwiftUI
import VRCKit

struct InstanceLocation: Hashable, Identifiable {
    var location: FriendsLocation
    var instance: Instance
    var id: Int { hashValue }
}

struct LocationsView: View {
    @EnvironmentObject var friendVM: FriendViewModel
    @State var selected: InstanceLocation?
    let appVM: AppViewModel

    var service: any InstanceServiceProtocol {
        appVM.isDemoMode ? InstancePreviewService(client: appVM.client) : InstanceService(client: appVM.client)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            locationList
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .navigationTitle("Locations")
                .navigationDestination(item: $selected) { selected in
                    LocationDetailView(
                        instance: selected.instance,
                        location: selected.location
                    )
                }
        } detail: {
            Text("Select a location")
        }
        .navigationSplitViewStyle(.balanced)
        .refreshable {
            do {
                try await friendVM.fetchAllFriends()
            } catch {
                appVM.handleError(error)
            }
        }
    }

    var locationList: some View {
        ScrollView {
            LazyVStack {
                ForEach(friendVM.friendsLocations) { location in
                    if location.isVisible {
                        locatoinItem(location)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }

    func locatoinItem(_ location: FriendsLocation) -> some View {
        LocationCardView(selected: $selected, service: service, location: location)
    }
}
