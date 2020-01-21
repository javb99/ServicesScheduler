//
//  PersistentCache.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/20/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation

struct CacheInvalidationStrategy<Value> {
    
    var calculateExpiration: (Value) -> Date?
    
    /// Values expire after the given interval.
    static func after(_ interval: TimeInterval) -> Self {
        Self() { _ in Date(timeIntervalSinceNow: interval) }
    }
    static var afterOneHour: Self {
        after(3600)
    }
    /// Values never expire.
    static var never: Self {
        Self() { _ in nil }
    }
}

final class PersistentCache<Key, Value>: AsyncCache
where Key: Codable, Key: Hashable, Value: Codable {
    
    private struct TimestampedValue: Codable {
        var value: Value
        var expiration: Date?
    }
    
    let name: String
    let invalidationStrategy: CacheInvalidationStrategy<Value>
    let getNow: ()->Date
    private var inMemory: Dictionary<Key, TimestampedValue>
    private var needsToSave: Bool = false
    
    private init(
        name: String,
        storage: Dictionary<Key, TimestampedValue>,
        invalidationStrategy: CacheInvalidationStrategy<Value>,
        now: @escaping ()->Date = Date.init
    ) {
        self.name = name
        self.inMemory = storage
        self.invalidationStrategy = invalidationStrategy
        self.getNow = now
    }
    
    func setCached(_ value: Value, for key: Key) {
        let timeStamped = TimestampedValue(value: value, expiration: invalidationStrategy.calculateExpiration(value))
        inMemory[key] = timeStamped
        needsToSave = true
        saveIfNeeded()
    }
    
    func getCachedValue(for key: Key, completion: (Value?)->()) {
        if let timeStamped = inMemory[key], timeStamped.expiration.isNilOrAfter(getNow()) {
            completion(timeStamped.value)
        } else {
            completion(nil)
        }
    }
    
    func removeCachedValue(for key: Key) {
        inMemory[key] = nil
        needsToSave = true
    }
    
    static func load(name: String, invalidationStrategy: CacheInvalidationStrategy<Value> = .never) -> Self? {
        let decoder = JSONDecoder()
        let url = makeURL(forName: name)
        do {
            let data = try Data(contentsOf: url)
            let storedCache = try decoder.decode(Dictionary<Key, TimestampedValue>.self, from: data)
            let loaded = Self(name: name, storage: storedCache, invalidationStrategy: invalidationStrategy)
            return loaded
        } catch {
            return nil
        }
    }
    
    static func loadOrCreate(
        name: String = "\(Key.self)-\(Value.self)",
        invalidationStrategy: CacheInvalidationStrategy<Value> = .never
    ) -> PersistentCache<Key, Value> {
        PersistentCache<Key, Value>.load(
            name: name,
            invalidationStrategy: invalidationStrategy
        )
        ?? PersistentCache<Key, Value>(
            name: name,
            storage: [:],
            invalidationStrategy: invalidationStrategy
        )
    }
    
    private static func makeURL(forName name: String) -> URL {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return folder.appendingPathComponent(name + "-PersistentCache.json")
    }
    
    func saveIfNeeded() {
        guard needsToSave else { return }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(inMemory)
        let url = Self.makeURL(forName: self.name)
        try! data.write(to: url)
        print("Saved to \(url)")
        needsToSave = false
    }
    
    func delete() {
        inMemory = [:]
        try? FileManager.default.removeItem(at: Self.makeURL(forName: name))
        needsToSave = false
    }
}

extension Optional where Wrapped == Date {
    func isNilOrAfter(_ comparable: Date) -> Bool {
        if let value = self {
            return value > comparable
        }
        return true
    }
}
