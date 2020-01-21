//
//  PersistentCache.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/20/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation

final class PersistentCache<Key, Value>: AsyncCache
where Key: Codable, Key: Hashable, Value: Codable {
    
    let name: String
    private var inMemory: Dictionary<Key, Value>
    private var needsToSave: Bool = false
    
    private init(name: String, storage: Dictionary<Key, Value>) {
        self.name = name
        self.inMemory = storage
    }
    
    func setCached(_ value: Value, for key: Key) {
        inMemory[key] = value
        needsToSave = true
        saveIfNeeded()
    }
    
    func getCachedValue(for key: Key, completion: (Value?)->()) {
        completion(inMemory[key])
    }
    
    func removeCachedValue(for key: Key) {
        inMemory[key] = nil
        needsToSave = true
    }
    
    static func load(name: String) -> Self? {
        let decoder = JSONDecoder()
        let url = makeURL(forName: name)
        do {
            let data = try Data(contentsOf: url)
            let storedCache = try decoder.decode(Dictionary<Key, Value>.self, from: data)
            let loaded = Self(name: name, storage: storedCache)
            return loaded
        } catch {
            return nil
        }
    }
    
    static func loadOrCreate(name: String = "\(Key.self)-\(Value.self)") -> PersistentCache<Key, Value> {
        return PersistentCache<Key, Value>.load(name: name)
            ?? PersistentCache<Key, Value>(name: name, storage: [:])
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
