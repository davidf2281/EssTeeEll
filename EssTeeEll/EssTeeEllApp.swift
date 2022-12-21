//
//  EssTeeEllApp.swift
//  EssTeeEll
//
//  Created by David Fearon on 19/12/2022.
//

import SwiftUI

@main
struct EssTeeEllApp: App {
   
   private let viewModel = MeshViewModel(model: MeshParser())
   
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
