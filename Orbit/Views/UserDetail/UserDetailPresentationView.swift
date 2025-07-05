//
//  UserDetailPresentationView.swift
//  Orbit
//
//  Created by makinosp on 2024/07/28.
//

import SwiftUI
import VRCKit

struct UserDetailPresentationView: View {
    @Environment(AppViewModel.self) var appVM
    @State var userDetail: UserDetail?
    @State private var id: String

    init(id: String) {
        _id = State(initialValue: id)
    }

    init(selected: Selected) {
        _id = State(initialValue: selected.id)
    }

    var body: some View {
        if let userDetail = userDetail {
            UserDetailView(user: userDetail)
                .refreshable {
                    await fetchUser(id: id)
                }
                .id(id)
        } else {
            ProgressScreen()
                .task {
                    await fetchUser(id: id)
                }
                .navigationTitle("Loading...")
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func fetchUser(id: String) async {
        do {
            userDetail = try await appVM.services.userService.fetchUser(userId: id)
        } catch {
            appVM.handleError(error)
        }
    }
}
