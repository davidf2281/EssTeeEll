//
//  GeometrySourceFactory.swift
//  EssTeeEll
//
//  Created by David Fearon on 21/12/2022.
//

import Foundation
import SceneKit

protocol SCNGeometrySourceFactoryContract {
   static func scnGeometrySource(from solid: Solid)  -> SCNGeometrySource
}

class SCNGeometrySourceFactory: SCNGeometrySourceFactoryContract {
   
   // Scenekit-friendly vertex type
   private struct Vertex {
      let x, y, z: Float // Vertex
      let nx, ny, nz: Float // Normal
   }
   
   static func scnGeometrySource(from solid: Solid) -> SCNGeometrySource {
      
      let startTime = Date()
      
      let result = self.vertexData(from: solid)
      let geometrySource = SCNGeometrySource(data: result.vertexData,
                                             semantic: .vertex,
                                             vectorCount: result.vertexCount,
                                             usesFloatComponents: true,
                                             componentsPerVector: result.componentsPerVector,
                                             bytesPerComponent: result.bytesPerComponent,
                                             dataOffset: result.dataOffset,
                                             dataStride: result.dataStride)
            
         let elapsed = startTime.timeIntervalSinceNow
         
         print("Created SCGeometrySource in  \(String(format: "%.2f", -elapsed)) seconds")
      
      return geometrySource
   }
   
   // TODO: From facets, not the Solid
   private static func vertexData(from solid: Solid) -> (vertexData: Data,
                                                         vertexCount: Int,
                                                         componentsPerVector: Int,
                                                         bytesPerComponent: Int,
                                                         dataOffset: Int,
                                                         dataStride: Int) {
      let vertexCount = solid.facets.count * 3
      let vertexDataBuffer = UnsafeMutablePointer<Vertex>.allocate(capacity: vertexCount)
      let queue = OperationQueue()
      let threadCount: Int
      let facetCount = solid.facets.count
      let coreCount = ProcessInfo.processInfo.activeProcessorCount
      
      // Account for the edge case where number of available cores exceeds number of facets
      if facetCount < coreCount {
         threadCount = Int(facetCount)
      } else {
         threadCount = coreCount
      }
      
      queue.maxConcurrentOperationCount = threadCount
      
      let facetsPerThread = Int(facetCount) / threadCount
      let facetRemainder = Int(facetCount) % threadCount
      
      for index in 0..<threadCount {
         
         // If facet count is an odd number, the last operation needs to process the remainder
         let facetsToProcess = (index == (0..<threadCount).last) ? facetsPerThread + facetRemainder : facetsPerThread
         
         let operation = BlockOperation(block: {
            let startIndex = index * facetsPerThread
            let endIndex = startIndex + (facetsToProcess - 1)
            let byteBufferStartIndex = index * facetsPerThread * 3
            print("Start index: \(startIndex), end index: \(endIndex), byteBuffer start index: \(byteBufferStartIndex)")
            convertToVertexDataFromFacets(solid.facets[startIndex...endIndex], byteBuffer: vertexDataBuffer, byteBufferStartIndex: byteBufferStartIndex)
          })
         
         queue.addOperation(operation)
      }
      
      queue.waitUntilAllOperationsAreFinished()
      
      let boundVertexBuffer = UnsafeMutableRawPointer(vertexDataBuffer).bindMemory(to: Vertex.self, capacity: vertexCount)
      let boundData = Data(bytesNoCopy: boundVertexBuffer, count: MemoryLayout<Vertex>.stride * vertexCount, deallocator: .none)
      
      return (vertexData: boundData,
              vertexCount: vertexCount,
              componentsPerVector: 3,
              bytesPerComponent: MemoryLayout<Float>.stride,
              dataOffset: MemoryLayout.offset(of: \Vertex.x)!, // TODO: Consider removing force-unwrap
              dataStride: MemoryLayout<Vertex>.stride)
   }
   
   private static func convertToVertexDataFromFacets(_ facets: ArraySlice<Solid.Facet>, byteBuffer: UnsafeMutablePointer<Vertex>, byteBufferStartIndex: Int) {

      var indexCounter = byteBufferStartIndex
      
      for facet in facets {
         
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
         
         byteBuffer[indexCounter + 0] = v1
         byteBuffer[indexCounter + 1] = v2
         byteBuffer[indexCounter + 2] = v3
         
         indexCounter += 3
      }
   }
}

fileprivate extension Array {
   // Credit: adapted from https://stackoverflow.com/a/33802092/2201154
   // Note, as documented in link above this will only work with trivial number types and likely not with, eg, String.
    func asData() -> Data {
        return self.withUnsafeBufferPointer({
           Data(bytes: $0.baseAddress!, count: count * MemoryLayout<Element>.stride)
        })
    }
}
