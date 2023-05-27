//
//  Solid.swift
//  EssTeeEll
//
//  Created by David Fearon on 19/12/2022.
//

import Foundation

struct Solid {
   
   struct Vertex {
      let x: Float
      let y: Float
      let z: Float
   }

   struct Normal {
      let i: Float
      let j: Float
      let k: Float
   }

   struct Facet {
      let normal: Normal
      let outerLoop: [Vertex]
   }
   
   let name: String
   let facets: [Facet]
}
