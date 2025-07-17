//
//  GroupSectionHeader.swift
//  Orbit
//
//  Created by NoriDev on 7/17/25.
//

import SwiftUI

struct GroupSectionHeader: View {
    let iconName: String
    let iconColor: Color
    let title: String
    let count: Int?
    
    init(
        iconName: String,
        iconColor: Color,
        title: String,
        count: Int? = nil
    ) {
        self.iconName = iconName
        self.iconColor = iconColor
        self.title = title
        self.count = count
    }
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.caption)
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
            Spacer()
            if let count = count {
                Text("\(count)개")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        GroupSectionHeader(
            iconName: "star.fill",
            iconColor: .yellow,
            title: "Representing"
        )
        
        GroupSectionHeader(
            iconName: "shield.fill",
            iconColor: .blue,
            title: "관리 중인 그룹",
            count: 5
        )
        
        GroupSectionHeader(
            iconName: "person.2.circle.fill",
            iconColor: .purple,
            title: "함께 속한 그룹",
            count: 3
        )
        
        GroupSectionHeader(
            iconName: "person.3.fill",
            iconColor: .green,
            title: "소속된 그룹",
            count: 12
        )
    }
    .padding()
}
