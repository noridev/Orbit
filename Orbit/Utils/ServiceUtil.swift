//
//  ServiceUtil.swift
//  Orbit
//
//  Created by makinosp on 2024/10/19.
//

import VRCKit

actor APIServiceUtil {
    let authenticationService: AuthenticationProvidable
    let favoriteService: FavoriteProvidable
    let friendService: FriendProvidable
    let groupService: GroupProvidable
    let instanceService: InstanceProvidable
    let userNoteService: UserNoteProvidable
    let userService: UserProvidable
    let worldService: WorldProvidable

    init(isPreviewMode: Bool = false, client: APIClient) {
        if isPreviewMode {
            authenticationService = AuthenticationPreviewService(client: client)
            favoriteService = FavoritePreviewService(client: client)
            friendService = FriendPreviewService(client: client)
            groupService = GroupPreviewService(client: client)
            instanceService = InstancePreviewService(client: client)
            userNoteService = UserNotePreviewService(client: client)
            userService = UserPreviewService(client: client)
            worldService = WorldPreviewService(client: client)
        } else {
            authenticationService = AuthenticationService(client: client)
            favoriteService = FavoriteService(client: client)
            friendService = FriendService(client: client)
            groupService = GroupService(client: client)
            instanceService = InstanceService(client: client)
            userNoteService = UserNoteService(client: client)
            userService = UserService(client: client)
            worldService = WorldService(client: client)
        }
    }
}
