//
//  StandardListItemView.swift
//  Podcasts App
//
//  Created by Simran Preet Narang on 2022-07-04.
//  Copyright © 2022 Simran App. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct StandardListItemView: View {
    
    
    // MARK: - Public properties
    
    var title: String
    var subtitle: String
    var moreInfo: String
    var imageUrlString: String
    
    
    // MARK: - Body
    
    
    var body: some View {
        HStack(alignment: .top) {
            WebImage(url: URL(string: imageUrlString))
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 8) {
                if !title.isEmpty {
                    Text(title)
                        .font(.body)
                }
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.footnote)
                }
                
                if !moreInfo.isEmpty {
                    Text(moreInfo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(8)
    }
}


// MARK: - Previews

struct StandardListItemView_Previews: PreviewProvider {
    static var previews: some View {
        StandardListItemView(title: "Title", subtitle: "Subtitle", moreInfo: "More Info", imageUrlString: "")
    }
}
