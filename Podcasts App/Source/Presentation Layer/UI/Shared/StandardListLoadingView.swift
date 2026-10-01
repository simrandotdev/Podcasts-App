//
//  StandardListLoadingView.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-07-23.
//  Copyright © 2022 Simran App. All rights reserved.
//

import SwiftUI

struct StandardListLoadingView: View {
    var body: some View {
        ForEach(1..<30) { _ in
            StandardListItemView(title: "Podcast title",
                                 subtitle: "Author",
                                 moreInfo: "101",
                                 imageUrlString: "")
            .listRowCard()
        }
        .redacted(reason: .placeholder)
        .disabled(true)
        .accessibilityHidden(true)
    }
}

struct StandardListLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        List { StandardListLoadingView() }
            .listStyle(.plain)
    }
}


extension View {
    /// Rounded gray card used behind rows in the podcast and episode lists.
    func listRowCard() -> some View {
        background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .listRowSeparator(.hidden)
    }
}
