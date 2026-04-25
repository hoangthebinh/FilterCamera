//
//  FilterCameraApp.swift
//  FilterCamera
//
//  Created by binh on 25/04/2026.
//

import SwiftUI

@main
struct FilterCameraApp: App {

    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
