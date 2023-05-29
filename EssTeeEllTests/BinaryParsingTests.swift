//
//  BinaryParsingTests.swift
//  EssTeeEllTests
//
//  Created by David Fearon on 19/12/2022.
//

import XCTest
import Combine

final class BinaryParsingTests: XCTestCase {
   
   private var cancellables = Set<AnyCancellable>()
   private var bundle: Bundle!
   private var expectation: XCTestExpectation!
   
   override func setUpWithError() throws {
      bundle = Bundle(for: type(of: self))
   }
   
   func testParsingBinaryViaPublishedProperties() throws {
      
      // Arrange
      let expectation = expectation(description: "testParsing")
      let fileURL = bundle.url(forResource: "pyramid", withExtension: "stl")!
      
      let sut = MeshParser()
      
      sut.statePublisher
         .sink { (state) in
            if case .parsed = state {
               expectation.fulfill()
            }
         }.store(in: &cancellables)
      
      sut.fileURL = fileURL
      
      // Act
      
      sut.start()
      
      waitForExpectations(timeout: 1)
      
      // Assert
      
      XCTAssertNotNil(sut.solid)
      XCTAssertEqual(sut.solid?.facets.count, 4)
   }
   
   func testParsingBinaryWithCoreCountExceedingFacets() throws {
      
      // Arrange
      
      let fileURL = bundle.url(forResource: "pyramid", withExtension: "stl")!
      
      let sut = MeshParser(coreCount: 10)
            
      // Act
      
      let result = sut.parseBinary(fileURL)
      
      // Assert
      
      XCTAssertNotNil(result)
      XCTAssertEqual(result!.facets.count, 4)
   }
   
   func testParsingBinaryWithOddFacetCount() throws {
      
      // Arrange
      
      let fileURL = bundle.url(forResource: "nonManifoldOddFacetCount", withExtension: "stl")!

      let sut = MeshParser()
      
      // Act
      
      let solid = sut.parseBinary(fileURL)
      
      // Assert
            
      XCTAssertNotNil(solid)
      XCTAssertEqual(solid?.facets.count, 9)
   }
}
