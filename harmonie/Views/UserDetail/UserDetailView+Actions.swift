//
//  UserDetailView+Actions.swift
//  Harmonie
//
//  Created by makinosp on 2024/08/11.
//

import VRCKit

extension UserDetailView {
    func fetchInstance(id: String) async {
        do {
            defer { isRequesting = false }
            isRequesting = true
            instance = try await instanceService.fetchInstance(location: id)
        } catch {
            appVM.handleError(error)
        }
    }

    func updateFavorite(friendId: String, group: FavoriteGroup) async {
        guard let friend = friendVM.getFriend(id: friendId) else { return }
        do {
            try await favoriteVM.updateFavorite(
                service: favoriteService,
                friend: friend,
                targetGroup: group
            )
        } catch {
            appVM.handleError(error)
        }
    }

    func saveNote() async {
        let service: UserNoteServiceProtocol = appVM.isPreviewMode
        ? UserNotePreviewService(client: appVM.client)
        : UserNoteService(client: appVM.client)
        do {
            if note.isEmpty {
                try await service.clearUserNote(targetUserId: user.id)
            } else {
                _ = try await service.updateUserNote(
                    targetUserId: user.id,
                    note: note
                )
            }
        } catch {
            appVM.handleError(error)
        }
    }
}
