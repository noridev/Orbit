//
//  GroupDetailView+DescriptionSection.swift
//  Orbit
//
//  Created by NoriDev on 7/17/25.
//

import SwiftUI
import VRCKit

extension GroupDetailView {
    func descriptionSection(_ description: String) -> some View {
        GroupBox("설명") {
            Text(description)
                .font(.body)
        }
        .groupBoxStyle(.card)
    }
}
