//
//  Constants.swift
//  Podcasts App
//
//  Created by Simran Preet Singh Narang on 2022-02-06.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation

struct Constants {
    
    struct BKConstants {
        static let container = "iCloud.app.simran.PodcastsApp"
        static let recordTypeFavoritePodcasts = "FavoritePodcasts"
        
    }
    
    
    struct InAppSubscribed {
        static var isUserSubscribed: Bool {
            set {
                DispatchQueue.main.async {
                    UserDefaults.standard.set(newValue, forKey: "isUserSubscribed")
                }
            }
            
            get {
                return UserDefaults.standard.bool(forKey: "isUserSubscribed")
            }
        }
        
        
        static var firstTimeSync: Bool {
            set {
                DispatchQueue.main.async {
                    UserDefaults.standard.set(newValue, forKey: "firstTimeSync")
                }
            }
            
            get {
                return UserDefaults.standard.bool(forKey: "firstTimeSync")
            }
        }
    }
}
