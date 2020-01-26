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
            .receive(on: RunLoop.main)
            .compactMap { _ in
                // Ensure that `start`ing before the delay ends doesn't display wrong status.
                return self.status == .errorDisplayed ? OperationStatus.notActive : nil
            }
        
        let dismissSuccessPublisher = newStatusPublisher
            .filter { status in status == .successDisplayed }
            .delay(for: .seconds(3), scheduler: DispatchQueue.global())
            .receive(on: RunLoop.main)
            .compactMap { _ in
                // Ensure that `start`ing before the delay ends doesn't display wrong status.
                return self.status == .successDisplayed ? OperationStatus.notActive : nil
            }
            
        let combinedPublisher = Publishers.Merge3(newStatusPublisher, dismissFailurePublisher, dismissSuccessPublisher)
        
        subscription = combinedPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.status, on: self)
    }
}

extension OperationStatusPresenter {
    
    typealias Service<I,O> = (I, @escaping Completion<O>)->()
    
    /// Return a presenter and a decorated version of the function.
    fileprivate static func observing<I, O>(_ function: @escaping Service<I,O>) -> (OperationStatusPresenter, Service<I,O>) {
        let (pub, wrappedFunction) = publisherObserving(function)
        let presenter = OperationStatusPresenter(eventPublisher: pub)
        return (presenter, wrappedFunction)
    }
    
    /// Return a publisher and a decorated version of the function.
    fileprivate static func publisherObserving<I, O>(_ function: @escaping Service<I,O>) -> (AnyPublisher<OperationEvent, Never>, Service<I,O>) {
        let pub = PassthroughSubject<OperationEvent, Never>()
        let wrappedFunction: Service<I,O> = { input, completion in
            pub.send(.start)
            function(input) { result in
                completion(result)
                switch result {
                case .success:
                    pub.send(.success)
                case .failure:
                    pub.send(.failure)
                }
            }
        }
        return (pub.eraseToAnyPublisher(), wrappedFunction)
    }
    
    typealias Service2<I, I2, O> = (I, I2, @escaping Completion<O>)->()
    
    /// Return a presenter and a decorated version of the function.
    static func observing<I, I2, O>(_ function: @escaping Service2<I, I2, O>) -> (OperationStatusPresenter, Service2<I, I2, O>) {
        let (pub, wrappedFunction) = publisherObserving(function)
        let presenter = OperationStatusPresenter(eventPublisher: pub)
        return (presenter, wrappedFunction)
    }

    /// Return a publisher and a decorated version of the function.
    fileprivate static func publisherObserving<I, I2, O>(_ function: @escaping Service2<I, I2, O>) -> (AnyPublisher<OperationEvent, Never>, Service2<I, I2, O>) {
        let pub = PassthroughSubject<OperationEvent, Never>()
        let wrappedFunction: Service2<I, I2, O> = { input, input2, completion in
            pub.send(.start)
            function(input, input2) { result in
                completion(result)
                switch result {
                case .success:
                    pub.send(.success)
                case .failure:
                    pub.send(.failure)
                }
            }
        }
        return (pub.eraseToAnyPublisher(), wrappedFunction)
    }
}
