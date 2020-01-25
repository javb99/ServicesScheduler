//
//  UserBoundCache.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/25/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation
import Combine

protocol UserLinkedStorage {
    func removeStorageForCurrentUser()
}

class UserLogOutWatchdog {
    
    private var linkedStorage: [UserLinkedStorage] =  []
    
    private var subscription: AnyCancellable!
    
    init(notificationCenter center: NotificationCenter = .default) {
        subscription = center.publisher(for: .userDidLogOut)
            .sink { _ in
                self.notifyStorageToBeRemoved()
            }
    }
    
    func linkStorageToCurrentUser(_ storage: UserLinkedStorage) {
        linkedStorage.append(storage)
    }
    
    func notifyStorageToBeRemoved() {
        linkedStorage.forEach {
            $0.removeStorageForCurrentUser()
        }
    }
}

extension UserLinkedStorage {
    @discardableResult // Enable chaining.
    func clearOnUserLogOutNotification(by watchdog: UserLogOutWatchdog) -> Self {
        watchdog.linkStorageToCurrentUser(self)
        return self
    }
}

extension PersistentCache: UserLinkedStorage {
    func removeStorageForCurrentUser() {
        delete()
    }
}

extension InMemoryCache: UserLinkedStorage {
    func removeStorageForCurrentUser() {
        clear()
    }
}
