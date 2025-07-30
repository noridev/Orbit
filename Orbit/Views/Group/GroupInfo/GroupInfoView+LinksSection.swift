//
//  GroupInfoView+LinksSection.swift
//  Orbit
//
//  Created by NoriDev on 7/18/25.
//

import SwiftUI
import VRCKit

extension GroupInfoView {
    func socialLinksSection(_ urls: [URL]) -> some View {
        GroupBox("Links") {
            DividedVStack(alignment: .leading) {
                ForEach(urls) { url in
                    ExternalLink(title: url.description, url: url, systemImage: IconSet.link.systemName)
                }
            }
        }
        .groupBoxStyle(.card)
    }
}
