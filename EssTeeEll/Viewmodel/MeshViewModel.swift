//
//  MeshViewModel.swift
//  EssTeeEll
//
//  Created by David Fearon on 07/02/2021.
//

import Foundation
import UniformTypeIdentifiers
import Combine
import SceneKit

class MeshViewModel: ObservableObject {
   
   @Published private(set) var validPathDropped = false
   @Published private(set) var parsingState: MeshParsingState = .initial
   @Published private(set) var parsingProgress: Float = 0
    
   public private(set) var solid: Solid?
   public private(set) var solidExtents: SolidExtents?
   public private(set) var scnGeometry: SCNGeometry?
    
   private var cancellables = Set<AnyCancellable>()
   private var model: MeshParsing

   required init(model: MeshParsing) {
      
      self.model = model
      
      model.statePublisher
         .receive(on:DispatchQueue.global(qos: .userInitiated))
         .sink { [weak self] state in
            self?.solid = model.solid
            if case .parsed = state, let solid = self?.solid {
               let geometrySource = SCNGeometrySourceFactory.scnGeometrySource(from: solid)
               let geometryElement = SCNGeometryElementFactory.scnGeometryElement(from: solid)
               let geometry = SCNGeometry(sources: [geometrySource], elements: [geometryElement])
               let material = SCNMaterial()
               material.locksAmbientWithDiffuse = true
               material.diffuse.contents = NSColor(.green)
               geometry.materials = [material]
               
               self?.scnGeometry = geometry
            }
            
            DispatchQueue.main.async {
               self?.parsingState = state
            }
         }.store(in: &cancellables)
      
      model.parsingProgressPublisher
         .receive(on: DispatchQueue.main)
         .sink { parsingProgress in
            self.parsingProgress = parsingProgress
         }.store(in: &cancellables)
   }
}

extension MeshViewModel {
   
   func fileDropped(provider: NSItemProvider) {
      
      provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil, completionHandler: { (urlData, _) in
         
         guard let urlData = urlData as? Data else {
            return
         }
         
         let fileURL = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
         
         if fileURL.isFileURL {
            
            DispatchQueue.main.async {
               self.validPathDropped = true
            }
            
            self.model.fileURL = fileURL
            
            DispatchQueue.global(qos: .userInitiated).async {
               self.model.start()
            }
         }
      })
   }
}
