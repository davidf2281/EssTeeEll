//
//  SceneKitMeshView.swift
//  EssTeeEll
//
//  Created by David Fearon on 27/05/2023.
//

import Foundation
import SwiftUI
import SceneKit

struct SceneKitMeshView: View {
   
   let scene: SCNScene
   let geometryNode: SCNNode
   let backgroundNSColor = NSColor(.black)
   
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
      let box = self.geometryNode.boundingBox
      
      let xExtent = abs(box.max.x - box.min.x)
      let yExtent = abs(box.max.y - box.min.y)
      let zExtent = abs(box.max.z - box.min.z)
      
      let middleX = box.min.x + (xExtent / 2)
      let middleY = box.min.y + (yExtent / 2)
      let middleZ = box.min.z + (zExtent / 2)
      
      cameraNode.position = SCNVector3(x: 0, y: -middleY - yExtent * 2, z: middleZ + zExtent * 2)
      cameraNode.look(at: SCNVector3(x: middleX, y: middleY, z: middleZ))
      
      return cameraNode
   }
   
   var tapGesture: some Gesture {
      SpatialTapGesture()
         .onEnded { event in
            if let renderer = self.renderDelegate.renderer {
               let hits = renderer.hitTest(event.location, options: [.rootNode : self.geometryNode])
               if let _ = hits.first?.node {
                  print("Tapped at \(event.location.x), \(event.location.y)")
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
