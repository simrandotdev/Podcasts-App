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
        List {
            ForEach(1..<10) { _ in
                StandardListItemView(title: "Podcast title",
                                     subtitle: "Author",
                                     moreInfo: "101",
                                     imageUrlString: "")
                .redacted(reason: .placeholder)
            }
        }
    }
}

struct StandardListLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        StandardListLoadingView()
    }
}
