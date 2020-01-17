//
//  MServiceTypeService.swift
//  ServicesSchedulerTests
//
//  Created by Joseph Van Boxtel on 1/17/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import XCTest
import Scheduler
import PlanningCenterSwift
import JSONAPISpec

func compose<A, B, C>(_ h: @escaping (A)->B, into g: @escaping (B)->C) -> (A)->C {
    return { a in
        g(h(a))
    }
}

class MServiceTypeService {
    
    let network: PCODownloadService
    
    init(network: PCODownloadService) {
        self.network = network
    }
    
    func fetchServiceType(withId id: MServiceType.ID, completion: @escaping Scheduler.Completion<MServiceType>) {
        let endpoint = Endpoints.services.serviceTypes[id: id]
        network.fetch(endpoint, completion: compose(validateResult, into: completion))
    }
    
    func validateResult<Endpt: Endpoint, R: ResourceProtocol>(_ result: Result<(HTTPURLResponse, Endpt, ResourceDocument<R>), NetworkError>) -> Result<Resource<R>, Error> where Endpt.ResponseBody == ResourceDocument<R> {
        result
            .map{ (response, endpoint, body) in body.data! }
            .mapError { $0 as Error }
    }
}

class MServiceTypeServiceTests: XCTestCase {
    func testSuccess() {
        let sut = MServiceTypeService(network: MockService())
        let id: MServiceType.ID = "1"
        let e = expectation(description: "Fetch ServiceType")
        var received: Result<MServiceType, Error>?
        
        sut.fetchServiceType(withId: id) { result in
            received = result
            e.fulfill()
        }
        
        wait(for: [e], timeout: 0.5)
        XCTAssertEqual("1", try? received?.get().identifer.id)
    }
}

class MockService: PCODownloadService {
    
    let serviceTypeDoc = ResourceDocument(data: MServiceType(id: "1", name: nil, sequenceIndex: 0))
    
    func fetch<Endpt>(_ endpoint: Endpt, completion: @escaping (Result<(HTTPURLResponse, Endpt, Endpt.ResponseBody), NetworkError>) -> ()) where Endpt : Endpoint, Endpt.RequestBody == JSONAPISpec.Empty {
        let response = HTTPURLResponse(url: URL(string: "/")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        completion(.success((response, endpoint, serviceTypeDoc as! Endpt.ResponseBody)))
    }
}
