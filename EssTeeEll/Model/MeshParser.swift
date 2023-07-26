//
//  MeshParser.swift
//  EssTeeEll
//
//  Created by David Fearon on 20/12/2022.
//

import Foundation

final class MeshParser: MeshParsing, ObservableObject {
   
   var fileURL: URL?
    
   private(set) var solid: Solid? = nil
   
   @Published public private(set) var state: MeshParsingState = .initial
   var statePublisher: Published<MeshParsingState>.Publisher { $state }
   
   @Published public private(set) var parsingProgress: Float = 0
   var parsingProgressPublisher: Published<Float>.Publisher { $parsingProgress }
   
   private let coreCount: Int
   
   /// The 50 bytes comprise 12 four-byte floats plus two 'attribute byte count'
   /// bytes which are redundant and we ignore.
   private let bytesPerFacet = 50
    
   init(coreCount: Int = ProcessInfo.processInfo.activeProcessorCount) {
      self.coreCount = coreCount
   }
   
   func start() {
      
      guard let fileURL = self.fileURL else {
         self.state = .error(.readFileError)
         return
      }
      
      self.state = .parsing
      
      let fileType = fileType(fileURL)
      
      let result: Solid?
      switch fileType {
            
         case .binary:
            result = parseBinary(fileURL)
            
         case .ascii:
            result = nil // ASCII unsupported since it's largely redundant
            
         case .unknown:
            result = nil
      }
      
      guard let solid = result else {
         self.state = .error(.failedParsing(fileType))
         return
      }
      
      self.solid = solid
      self.state = .parsed
   }
   
   func parseBinary(_ fileURL: URL) -> Solid? {
      
      let startTime = Date()
      
      let result = readFacetData(fileURL)
      
      guard let facetCount = result?.facetCount, let facetDataBuffer = result?.facetDataBuffer else {
         return nil
      }
      
      defer {
         facetDataBuffer.deallocate()
      }
      
      guard let facets = processFacetDataBuffer(facetCount: facetCount, facetDataBuffer: facetDataBuffer) else {
         return nil
      }
      
      let elapsed = startTime.timeIntervalSinceNow
      
      print("Parsed in \(String(format: "%.2f", -elapsed)) seconds")
      
      let solid = Solid(name: fileURL.lastPathComponent, facets: facets)
      
      return solid
   }
   
   private func readFacetData(_ fileURL: URL) -> (facetCount: Int, facetDataBuffer: UnsafeMutablePointer<UInt8>)? {
      
      let headerLength = 80
      
      let facetCount: UInt32
      
      guard let inputStream = InputStream(url: fileURL) else {
         return nil
      }
      
      inputStream.open()
      defer {
         inputStream.close()
      }
      
      // Throw away the 80-byte header
      let headerBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: headerLength)
      defer {
         headerBuffer.deallocate()
      }
      
      let headerBytesRead = inputStream.read(headerBuffer, maxLength: headerLength)
      guard headerBytesRead == 80 else {
         return nil
      }
      
      let facetCountBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 4)
      let facetCountBytesRead = inputStream.read(facetCountBuffer, maxLength: 4)
      guard facetCountBytesRead == 4 else {
         return nil
      }
      
      let facetCountBoundBuffer = UnsafeMutableRawPointer(facetCountBuffer).bindMemory(to: UInt32.self, capacity: 1)
      defer {
         facetCountBoundBuffer.deallocate()
      }
      
      facetCount = facetCountBoundBuffer.pointee
      print("There are \(facetCount) facets")
      
      let totalFacetsByteCount = bytesPerFacet * Int(facetCount)
      let facetDataBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: totalFacetsByteCount)
      
      let facetBufferBytesRead = inputStream.read(facetDataBuffer, maxLength: totalFacetsByteCount)
      
      guard facetBufferBytesRead == totalFacetsByteCount else {
         return nil
      }
      
      return (Int(facetCount), facetDataBuffer)
   }
   
   private func processFacetDataBuffer(facetCount: Int, facetDataBuffer: UnsafeMutablePointer<UInt8>) -> [Solid.Facet]? {
      
      let queue = OperationQueue()
      let threadCount: Int
            
      // Account for the edge case where number of available cores exceeds number of facets
      if facetCount < self.coreCount {
         threadCount = Int(facetCount)
      } else {
         threadCount = self.coreCount
      }
      
      queue.maxConcurrentOperationCount = threadCount
      
      let facetsPerThread = Int(facetCount) / threadCount
      let facetRemainder = Int(facetCount) % threadCount
      var facets: [Solid.Facet] = []
      let lock = NSLock()
      
      for index in 0..<threadCount {
         
         // If facet count is an odd number, the last operation needs to process the remainder
         let facetsToProcess = (index == (0..<threadCount).last) ? facetsPerThread + facetRemainder : facetsPerThread
         
         let operation = BlockOperation(block: {
            let opFacets = self.parseMesh(with: facetDataBuffer, startOffset: facetsPerThread * index, facetCount: facetsToProcess)
            lock.lock()
            facets += opFacets
            lock.unlock()
         })
         
         queue.addOperation(operation)
      }
      
      queue.waitUntilAllOperationsAreFinished()
      
      return facets
   }
   
   private func parseMesh(with facetDataBuffer: UnsafeMutablePointer<UInt8>, startOffset: Int, facetCount: Int) -> [Solid.Facet] {

      var facets: [Solid.Facet] = []
      facets.reserveCapacity(facetCount)
      
      var parsingProgressCount = 0
      let parsingProgressUpdateThreshold = 10000
      
      for index in 0..<facetCount {
         
         let boundFloatsBuffer = UnsafeMutableRawPointer(facetDataBuffer + (startOffset * bytesPerFacet) + Int(index) * bytesPerFacet).bindMemory(to: Float32.self, capacity: 12)
         
         let i = (boundFloatsBuffer + 0).pointee
         let j = (boundFloatsBuffer + 1).pointee
         let k = (boundFloatsBuffer + 2).pointee
         
         let v1x = (boundFloatsBuffer + 3).pointee
         let v1y = (boundFloatsBuffer + 4).pointee
         let v1z = (boundFloatsBuffer + 5).pointee
         
         let v2x = (boundFloatsBuffer + 6).pointee
         let v2y = (boundFloatsBuffer + 7).pointee
         let v2z = (boundFloatsBuffer + 8).pointee
         
         let v3x = (boundFloatsBuffer + 9).pointee
         let v3y = (boundFloatsBuffer + 10).pointee
         let v3z = (boundFloatsBuffer + 11).pointee
         
         let normal = Solid.Normal(i: i, j: j, k: k)
         let v1 = Solid.Vertex(x: v1x, y: v1y, z: v1z)
         let v2 = Solid.Vertex(x: v2x, y: v2y, z: v2z)
         let v3 = Solid.Vertex(x: v3x, y: v3y, z: v3z)
         
         let facet = Solid.Facet(normal: normal, outerLoop: [v1, v2, v3])
         facets.append(facet)
         
         parsingProgressCount += 1
         if parsingProgressCount > parsingProgressUpdateThreshold {
            self.parsingProgress = Float(index) / Float(facetCount)
            parsingProgressCount = 0
         }
      }
      
      return facets
   }
}

extension MeshParser {
   // Determines whether the given STL file is in binary or ASCII STL format.
   // If the first five bytes spell 'solid' we assume it's ASCII per STL specs,
   // otherwise assume it's binary
   private func fileType(_ fileURL: URL) -> MeshParsingState.FileType {
      guard let url = self.fileURL else {
         return .unknown
      }
      
      let cFile = CFile(url: url)
      
      defer {
         cFile.close()
      }
      
      do {
         try cFile.open()
         if let line = try cFile.readLine(maxLength: 5), line.count > 4 {
            let characters = line[0...4].map { UInt8($0) }
            let string = String(bytes: characters, encoding: .utf8)
            return string == "solid" ? .ascii : .binary
         }
         return .unknown
      } catch {
         return .unknown
      }
   }
}
