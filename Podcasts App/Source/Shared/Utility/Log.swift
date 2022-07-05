//
//  Log.swift
//  Podcasts App
//
//  Created by Simran Preet Narang on 2022-02-07.
//  Copyright © 2022 Simran App. All rights reserved.
//

import Foundation


func info(_ message: String...) {
    print("ℹ️", message)
}

func err(_ message: String...) {
    print("❌", message)
}

func warn(_ message: String...) {
    print("⚠️", message)
}

func debug(_ message: String...) {
    print("📱", message)
}
