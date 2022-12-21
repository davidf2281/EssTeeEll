//
//  GeometrySourceFactory.swift
//  EssTeeEll
//
//  Created by David Fearon on 21/12/2022.
//

import Foundation
import SceneKit

class GeometrySourceFactory {
   
   static func scnGeometrySource(from solid: Solid) -> SCNGeometrySource {
      let result = vertexData(from: solid)
      let geometrySource = SCNGeometrySource(data: result.vertexData,
                                             semantic: .vertex,
                                             vectorCount: result.vertexCount,
                                             usesFloatComponents: true,
                                             componentsPerVector: result.componentsPerVector,
                                             bytesPerComponent: result.bytesPerComponent,
                                             dataOffset: result.dataOffset,
                                             dataStride: result.dataStride)
      
      return geometrySource
   }
   
   private struct Vertex {
      let x, y, z: Float // Vertex
      let nx, ny, nz: Float // Normal
   }
   
   private static func vertexData(from solid: Solid) -> (vertexData: Data,
                                                         vertexCount: Int,
                                                         componentsPerVector: Int,
                                                         bytesPerComponent: Int,
                                                         dataOffset: Int,
                                                         dataStride: Int) {
      var vertices: [Vertex] = []
      vertices.reserveCapacity(solid.facets.count * 3)
      
      for facet in solid.facets {
         
         let v1 = Vertex(x: facet.outerLoop[0].x,
                         y: facet.outerLoop[0].y,
                         z: facet.outerLoop[0].z,
                         nx: facet.normal.i,
                         ny: facet.normal.j,
                         nz: facet.normal.k)
         
         let v2 = Vertex(x: facet.outerLoop[1].x,
                         y: facet.outerLoop[1].y,
                         z: facet.outerLoop[1].z,
                         nx: facet.normal.i,
                         ny: facet.normal.j,
                         nz: facet.normal.k)
         
         let v3 = Vertex(x: facet.outerLoop[2].x,
                         y: facet.outerLoop[2].y,
                         z: facet.outerLoop[2].z,
                         nx: facet.normal.i,
                         ny: facet.normal.j,
                         nz: facet.normal.k)
         
         vertices.append(v1)
         vertices.append(v2)
         vertices.append(v3)
      }
      
      let data = vertices.asData()
   
      return (vertexData: data,
              vertexCount:vertices.count,
              componentsPerVector: 3,
              bytesPerComponent: MemoryLayout<Float>.stride,
              dataOffset:MemoryLayout.offset(of: \Vertex.x)!, // TODO: Consider removing force-unwrap
              dataStride: MemoryLayout<Vertex>.stride)
   }
}

extension Array {
   // Credit: adapted from https://stackoverflow.com/a/33802092/2201154
    func asData() -> Data {
        return self.withUnsafeBufferPointer({
           Data(bytes: $0.baseAddress!, count: count * MemoryLayout<Element>.stride)
        })
    }
}
