//
//  GeometryElementFactory.swift
//  EssTeeEll
//
//  Created by David Fearon on 21/12/2022.
//

import Foundation
import SceneKit

class GeometryElementFactory {
   static func scnGeometryElement(from solid: Solid) -> SCNGeometryElement {
      var indices: [UInt32] = []
      indices.reserveCapacity(solid.facets.count * 4) // Four because each triangular facet connects in the general vertex order 0, 1, 2, 0
      
      var currentIndex: UInt32 = 0
      
      for _ in solid.facets {
         indices.append(currentIndex)
         indices.append(currentIndex + 1)
         indices.append(currentIndex + 2)
         indices.append(currentIndex)
         
         currentIndex += 3
      }
      
      let geometryElement = SCNGeometryElement(indices: indices, primitiveType: .triangles)
      
      return geometryElement
   }
}
