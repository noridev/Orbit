//
//  GroupDetailView+StatsSection.swift
//  Orbit
//
//  Created by NoriDev on 7/17/25.
//

import SwiftUI
import VRCKit

extension GroupDetailView {
    var statsSection: some View {
        GroupBox("통계") {
            HStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                    
                    Text("\(currentGroup.memberCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("멤버")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                if let lastPostCreatedAt = currentGroup.lastPostCreatedAt {
                    VStack(spacing: 8) {
                        Image(systemName: "message.fill")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                        
                        Text(lastPostCreatedAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("마지막 포스트")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 8)
        }
        .groupBoxStyle(.card)
    }
}
