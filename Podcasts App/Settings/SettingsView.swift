//
//  SettingsView.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2021-12-21.
//  Copyright © 2021 Simran App. All rights reserved.
//

import SwiftUI
import Combine
import Resolver

struct SettingsView: View {
    
    @StateObject private var settingsViewModel = DebugSettingsViewModel()
    
    
    var body: some View {
        Form {
            #if DEBUG
            Toggle("Is User subscriber", isOn: $settingsViewModel.isUserSubscriber)
            #endif
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}


class DebugSettingsViewModel: ObservableObject {
    
    @Published var isUserSubscriber = false
    
    private var cancallable = Set<AnyCancellable>()
    
    @Injected private var favoritePodcastService: FavoritePodcastsService
    
    init() {
        
        isUserSubscriber = Constants.InAppSubscribed.isUserSubscribed
        
        $isUserSubscriber
            .sink { isUserSubscriber in
            Constants.InAppSubscribed.isUserSubscribed = isUserSubscriber
        }
        .store(in: &cancallable)
    }
}
