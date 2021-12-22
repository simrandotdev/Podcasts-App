//
//  SettingsView.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2021-12-21.
//  Copyright © 2021 Simran App. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    
    @State private var isSyncingWithiCloud = false
    
    var body: some View {
        Form {
            Button("Subscribe to get all features") { }
            .foregroundColor(Color.purple)
            
            Toggle("Sync with iCloud", isOn: $isSyncingWithiCloud)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
