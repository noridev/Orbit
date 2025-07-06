//
//  UserDetailView+ActivitySection.swift
//  Orbit
//
//  Created by makinosp on 2024/08/12.
//

import SwiftUI

extension UserDetailView {
    var activitySection: some View {
        GroupBox("Activity") {
            DividedVStack(alignment: .leading, spacing: 8) {
                if let lastLogin = user.lastLogin {
                    VStack(alignment: .leading) {
                        Text("Last Login")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        Text(lastLogin.formatted(date: .numeric, time: .shortened))
                            .font(.callout)
                    }
                }
                
                if let lastActivity = user.lastActivity {
                    VStack(alignment: .leading) {
                        Text("Last Activity")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        Text(lastActivity.formatted(date: .numeric, time: .shortened))
                            .font(.callout)
                    }
                }
                
                if let dateJoined = user.dateJoined {
                    VStack(alignment: .leading) {
                        Text("Date Joined")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        Text(dateJoined.formatted(date: .numeric, time: .shortened))
                            .font(.callout)
                    }
                }
            }
        }
        .groupBoxStyle(.card)
    }
}
