//
//  DuplicatesListView.swift
//  deedoop
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
//               .contentShape(Rectangle())
//               .onTapGesture {
//                  print("Hi!")
//               }
         case .error:
            errorView()
//               .contentShape(Rectangle())
//               .onTapGesture {
//                  print("Hi!")
//               }
      }
   }
}

extension ContentView {
   
   private func initialView() -> some View {
      Text("Drop an STL file here to start")
         .frame(maxWidth: .infinity, maxHeight: .infinity)
         .onDrop(of: [.fileURL], delegate: self)
   }
   
   private func parsingView() -> some View {
      VStack {
         Text("Parsing")
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

struct SceneKitMeshView: View {
   
   let scene: SCNScene
   let geometryNode: SCNNode
   let backgroundNSColor = PlatformSpecific.color(.black)
   
   let backgroundColor = Color.black
   let renderDelegate = RenderDelegate()
   init(viewModel: MeshViewModel) {
      let scene = SCNScene()
      scene.background.contents = backgroundNSColor
      let geometryNode = SCNNode(geometry: viewModel.scnGeometry)
      scene.rootNode.addChildNode(geometryNode)
      self.scene = scene
      self.geometryNode = geometryNode
   }
   
   var cameraNode: SCNNode? {
      let cameraNode = SCNNode()
      let camera = SCNCamera()
      camera.automaticallyAdjustsZRange = true
      camera.fieldOfView = 30
      cameraNode.camera = camera
      cameraNode.position = SCNVector3(x: 0, y: 0, z: 100)
      
      return cameraNode
   }
   
   var tapGesture: some Gesture {
      SpatialTapGesture()
         .onEnded { event in
            if let renderer = self.renderDelegate.renderer {
               let hits = renderer.hitTest(event.location, options: [.rootNode : self.geometryNode])
               if let tappedNode = hits.first?.node {
                  print("Tapped at \(event.location.x), \(event.location.y)")
                  print("Got a hit")
               }
            }
         }
   }
   
   var body: some View {
      VStack{
         SceneView(
            scene: self.scene,
            pointOfView: self.cameraNode,
            options: [
                              .allowsCameraControl,
               .autoenablesDefaultLighting,
               .temporalAntialiasingEnabled
            ],
            delegate: renderDelegate
         )
         .background(backgroundColor)
      }
            .contentShape(Rectangle())
            .gesture(self.tapGesture)
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
