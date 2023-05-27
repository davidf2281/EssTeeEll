//
//  ContentView.swift
//  EssTeeEll
//
//  Created by David Fearon on 14/02/2021.
//

import SwiftUI
import SceneKit

struct ContentView: View {
   
   private enum ViewState {
      case initial
      case parsing
      case parsed
   }
   
   @ObservedObject public private(set) var viewModel: MeshViewModel
   
   init(viewModel: MeshViewModel) {
      self.viewModel = viewModel
   }
   
   var body: some View {
      
      switch viewModel.parsingState {
         case .initial:
            initialView()
         case .parsing:
            parsingView()
         case .parsed:
            parsedView()
         case .error:
            errorView()
      }
   }
}

extension ContentView {
   
   private func initialView() -> some View {
      Text("Drop an STL file here")
         .frame(maxWidth: .infinity, maxHeight: .infinity)
         .onDrop(of: [.fileURL], delegate: self)
   }
   
   private func parsingView() -> some View {
      VStack {
         Text("Parsing...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
         ProgressView(value: viewModel.parsingProgress)
      }
   }
   
   private func parsedView() -> some View {
      SceneKitMeshView(viewModel: viewModel)
         .frame(maxWidth: .infinity, maxHeight: .infinity)
   }
   
   private func errorView() -> some View {
      Text("Parsing error")
         .frame(maxWidth: .infinity, maxHeight: .infinity)
   }
}

extension ContentView: DropDelegate {
   
   func performDrop(info: DropInfo) -> Bool {
      
      guard let provider = info.itemProviders(for: [.fileURL]).first else {
         return false
      }
      
      viewModel.fileDropped(provider: provider)
      
      return true
   }
}

class RenderDelegate: NSObject, SCNSceneRendererDelegate {
   
   var renderer: SCNSceneRenderer?
   
   func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
      if self.renderer == nil || self.renderer !== renderer{
         self.renderer = renderer
      }
   }
}
