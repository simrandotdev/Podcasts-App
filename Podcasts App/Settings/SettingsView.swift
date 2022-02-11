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
import Purchases

struct SettingsView: View {
    
    @StateObject private var settingsViewModel = DebugSettingsViewModel()
    
    
    var body: some View {
        Form {
            #if DEBUG
            Toggle("Is User subscriber", isOn: $settingsViewModel.isUserSubscriber)
            #endif
            
            if settingsViewModel.yearlySubscription ?? false {
                Text("Get your yearly subscription")
            }
            
            if settingsViewModel.monthlySubscription ?? false {
                Text("Get your monthly subscription")
            }
            
            if settingsViewModel.weeklySubscription ?? false {
                Text("Get your weekly subscription")
            }
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
    @Published var yearlySubscription: Bool? = nil
    @Published var monthlySubscription: Bool? = nil
    @Published var weeklySubscription: Bool? = nil
    
    private var cancallable = Set<AnyCancellable>()
    
    @Injected private var favoritePodcastService: FavoritePodcastsService
    
    init() {
        
        isUserSubscriber = Constants.InAppSubscribed.isUserSubscribed
        
        $isUserSubscriber
            .sink { isUserSubscriber in
            Constants.InAppSubscribed.isUserSubscribed = isUserSubscriber
        }
        .store(in: &cancallable)
        
        getOfferings()
    }
    
    func getOfferings() {
        Purchases.shared.offerings { (offerings, error) in
            guard let offerings = offerings else { return }
            
            if let annualSubscription = offerings.current?.annual {
                self.yearlySubscription = true
            }
            
            if let monthlySubscription = offerings.current?.monthly {
                self.monthlySubscription = true
            }
            
            if let weeklySubscription = offerings.current?.weekly {
                self.weeklySubscription = true
            }
//            
//            debug("\(offerings.current?.annual?.product.localizedTitle)")
//            debug("\(offerings.current?.annual?.product.localizedDescription)")
//            debug("\(offerings.current?.annual?.product.price)")
        }
    }
}
