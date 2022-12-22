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
         case .error:
            errorView()
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

struct NaiveMeshView: View {
   
   private var viewModel: MeshViewModel
   
   init(viewModel: MeshViewModel) {
      self.viewModel = viewModel
   }
   
   var body: some View {
      let scaleFactor: Float = 15
      GeometryReader { reader in
         let widthByTwo = Float(reader.size.width / 2)
         let heightByTwo = Float(reader.size.height / 2)
         Path() { path in
            for facet in viewModel.solid!.facets { // TODO: remove force-unwrap
               path.move(to: CGPoint(x: Double(facet.outerLoop[0].x * scaleFactor + widthByTwo), y: Double(facet.outerLoop[0].y * scaleFactor + heightByTwo)))
               path.addLine(to: CGPoint(x: Double(facet.outerLoop[1].x * scaleFactor + widthByTwo), y: Double(facet.outerLoop[1].y * scaleFactor + heightByTwo)))
               path.addLine(to: CGPoint(x: Double(facet.outerLoop[2].x * scaleFactor + widthByTwo), y: Double(facet.outerLoop[2].y * scaleFactor + heightByTwo)))
            }
         }.stroke(Color.black, lineWidth: 1)
      }
   }
}

struct SceneKitMeshView: View {
      
   let scene: SCNScene
   let backgroundNSColor = NSColor.black
   let backgroundColor = Color.black
   init(viewModel: MeshViewModel) {
      let scene = SCNScene()
      scene.background.contents = backgroundNSColor
      let geometryNode = SCNNode(geometry: viewModel.scnGeometry)
      scene.rootNode.addChildNode(geometryNode)
      self.scene = scene
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
   
   var body: some View {
      SceneView(
         scene: self.scene,
         pointOfView: self.cameraNode,
         options: [
            .allowsCameraControl,
            .autoenablesDefaultLighting,
            .temporalAntialiasingEnabled
         ]
      ).background(backgroundColor)
   }
}
