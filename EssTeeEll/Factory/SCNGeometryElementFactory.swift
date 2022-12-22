//
//  GeometryElementFactory.swift
//  EssTeeEll
//
//  Created by David Fearon on 21/12/2022.
//

import Foundation
import SceneKit

protocol SCNGeometryElementFactoryContract {
   static func scnGeometryElement(from solid: Solid) -> SCNGeometryElement
}

class SCNGeometryElementFactory: SCNGeometryElementFactoryContract {
   static func scnGeometryElement(from solid: Solid) -> SCNGeometryElement {
      var indices: [UInt32] = []
      indices.reserveCapacity(solid.facets.count * 3) 
      
      var currentIndex: UInt32 = 0
      
      for _ in solid.facets {
         indices.append(currentIndex)
         indices.append(currentIndex + 1)
         indices.append(currentIndex + 2)
         currentIndex += 3
      }
      
      let geometryElement = SCNGeometryElement(indices: indices, primitiveType: .triangles)
      
      return geometryElement
   }
}
