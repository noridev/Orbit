//
//  CardGroupBoxStyle.swift
//  Orbit
//
//  Created by makinosp on 2024/09/27.
//

import SwiftUI

struct CardGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            configuration.label
                .font(.subheadline)
                .foregroundStyle(Color.gray)
            configuration.content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 24)
                .foregroundStyle(Color(.secondarySystemGroupedBackground))
        }
        //.shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        .padding(.horizontal, 16)
    }
}

extension GroupBoxStyle where Self == CardGroupBoxStyle {
    static var card: CardGroupBoxStyle {
        CardGroupBoxStyle()
    }
}
