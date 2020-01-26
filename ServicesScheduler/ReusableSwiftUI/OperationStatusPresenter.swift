//
//  OperationStatusOverlay.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/25/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI
import Combine

public enum OperationEvent: String {
    case start
    case success
    case failure
}

public enum OperationStatus: String {
    case notActive
    case active
    case errorDisplayed
    case successDisplayed
}

public class OperationStatusPresenter: ObservableObject {
    @Published var status: OperationStatus = .notActive
    
    private var subscription: AnyCancellable!
    
    init(eventPublisher: AnyPublisher<OperationEvent, Never>) {
        let newStatusPublisher = eventPublisher.map { event -> OperationStatus in
            switch event {
            case .start:   return .active
            case .failure: return .errorDisplayed
            case .success: return .successDisplayed
            }
        }
        let dismissFailurePublisher = newStatusPublisher
            .filter { status in status == .errorDisplayed }
            .delay(for: .seconds(3), scheduler: DispatchQueue.global())
            .map { _ in OperationStatus.notActive }
        
        let dismissSuccessPublisher = newStatusPublisher
            .filter { status in status == .successDisplayed }
            .delay(for: .seconds(3), scheduler: DispatchQueue.global())
            .map { _ in OperationStatus.notActive }
            
        let combinedPublisher = Publishers.Merge3(newStatusPublisher, dismissFailurePublisher, dismissSuccessPublisher)
        
        subscription = combinedPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.status, on: self)
    }
}

