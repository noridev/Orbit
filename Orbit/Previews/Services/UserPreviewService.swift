//
//  UserPreviewService.swift
//  VRCKit
//
//  Created by makinosp on 2024/07/14.
//

import MemberwiseInit
import Foundation
import VRCKit

@MemberwiseInit
final actor UserPreviewService: APIService, UserServiceProtocol {
    let client: APIClient

    func fetchUser(userId: String) async throws -> UserDetail {
        PreviewData.shared.userDetails.first { $0.id == userId }!
    }

    func fetchUserRawJSON(userId: String) async throws -> Data {
        // For preview, return encoded UserDetail as JSON
        let userDetail = PreviewData.shared.userDetails.first { $0.id == userId }!
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
        encoder.dateEncodingStrategy = .formatted(.iso8601Full)
        return try encoder.encode(userDetail)
    }

    func updateUser(id: String, editedInfo: EditableUserInfo) async throws {}

    func searchUser(displayName: String, n: Int, offset: Int) async throws -> [LimitedUser] {
        // Return an empty array for preview purposes.
        []
    }
}
