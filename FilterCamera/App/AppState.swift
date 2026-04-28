//
//  AppState.swift
//  FilterCamera
//
//  Created by binh on 25/04/2026.
//

import Foundation

final class AppState: ObservableObject {
    @Published var route: Route = .splash
}

enum Route: Equatable {
    case splash
    case onboarding
    case paywall
    case purchase
    case camera
    case result(url: URL)
}
