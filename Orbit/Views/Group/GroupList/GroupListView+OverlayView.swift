//
//  GroupListView+OverlayView.swift
//  Orbit
//
//  Created by NoriDev on 7/13/25.
//

import SwiftUI
import VRCKit

extension GroupListView {
    @ViewBuilder var overlayView: some View {
        if groupViewModel.isLoading {
            ProgressView()
                .padding(32)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        } else if let error = groupViewModel.error {
            VStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text("그룹을 불러오는데 실패했습니다")
                    .font(.headline)
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button("다시 시도") {
                    Task {
                        await groupViewModel.loadUserGroups()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        } else if !groupViewModel.hasGroups {
            ContentUnavailableView {
                Label("참여 중인 그룹이 없습니다", systemImage: "person.3")
                    .foregroundColor(.gray)
            } description: {
                Text("VRChat에서 그룹에 가입하면 여기에 표시됩니다")
            }
        } else if !searchText.isEmpty && filteredRepresentedGroups.isEmpty && filteredManagedGroups.isEmpty && filteredMutualGroups.isEmpty && filteredRegularGroups.isEmpty {
            ContentUnavailableView.search
        }
    }
}
