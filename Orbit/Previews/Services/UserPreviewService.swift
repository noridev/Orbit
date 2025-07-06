//
//  UserPreviewService.swift
//  VRCKit
//
//  Created by makinosp on 2024/07/14.
//

import MemberwiseInit
import VRCKit

@MemberwiseInit
final actor UserPreviewService: APIService, UserServiceProtocol {
    let client: APIClient

    func fetchUser(userId: String) async throws -> UserDetail {
        PreviewData.shared.userDetails.first { $0.id == userId }!
    }

    func updateUser(id: String, editedInfo: EditableUserInfo) async throws {}

    func searchUser(displayName: String, n: Int, offset: Int) async throws -> [LimitedUser] {
        // Return an empty array for preview purposes.
        []
    }
}
