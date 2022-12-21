//
//  DuplicatesViewModel.swift
//  deedoop
//
//  Created by David Fearon on 07/02/2021.
//

import Foundation
import UniformTypeIdentifiers
import Combine

class MeshViewModel: ObservableObject {
   
   @Published private(set) var validPathDropped = false
   @Published private(set) var parsingState: MeshParsingState = .initial

   private var model: MeshParsing // TODO: make private and add separate mesh to viewmodel
   public private(set) var solid: Solid?
   public private(set) var solidExtents: SolidExtents?
   private var cancellables = Set<AnyCancellable>()
   
   required init(model: MeshParsing) {
      
      self.model = model
      
      // Bind model's state
      model.statePublisher
         .receive(on: DispatchQueue.main)
         .sink { (state) in
            self.solid = model.solid
            self.solidExtents = model.solidExtents
            self.parsingState = state
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
