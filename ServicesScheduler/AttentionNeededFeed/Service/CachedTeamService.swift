//
//  TeamCache.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 1/20/20.
//  Copyright © 2020 Joseph Van Boxtel. All rights reserved.
//

import Foundation

protocol SyncCache: class {
    associatedtype Key: Hashable
    associatedtype Value
    
    func setCached(_ value: Value, for key: Key)
    func getCachedValue(for key: Key) -> Value?
}

protocol AsyncCache: class {
    associatedtype Key: Hashable
    associatedtype Value
    
    func setCached(_ value: Value, for key: Key)
    func getCachedValue(for key: Key, completion: @escaping (Value?)->())
}

class CachedService<Key, Value>: PrimaryOrSecondaryService<Key, Value>
where Key: Hashable {
    
    typealias Service = (Key, @escaping Completion<Value>)->()
    
    init<Cache: AsyncCache>(service: @escaping Service, cache: Cache) where Cache.Key == Key, Cache.Value == Value {
        super.init(primary: cache.service(), secondary: cache.cacheResultsOf(service))
    }
    
    convenience init<Cache: SyncCache>(service: @escaping Service, cache: Cache) where Cache.Key == Key, Cache.Value == Value {
        let adaptedCache = InstantToAsyncCacheAdapter(sync: cache)
        self.init(service: service, cache: adaptedCache)
    }
}

fileprivate enum CacheError: Error {
    case cacheMissed
}

extension AsyncCache {
    
    typealias Service = (Key, @escaping Completion<Value>)->()
    
    func service() -> Service {
        return { key, completion in
            self.getCachedValue(for: key) { valueOrNil in
                if let value = valueOrNil {
                    completion(.success(value))
                } else {
                    completion(.failure(CacheError.cacheMissed))
                }
            }
        }
    }
    
    func cacheResultsOf(_ service: @escaping Service) -> Service {
        return { input, completion in
            service(input) { result in
                if let value = result.value {
                    self.setCached(value, for: input)
                }
                completion(result)
            }
        }
    }
}

class InstantToAsyncCacheAdapter<WrappedCache>: AsyncCache
    where WrappedCache: SyncCache {
    
    typealias Key = WrappedCache.Key
    typealias Value = WrappedCache.Value
    
    let cache: WrappedCache
    
    init(sync cache: WrappedCache) {
        self.cache = cache
    }
    
    func setCached(_ value: WrappedCache.Value, for key: WrappedCache.Key) {
        cache.setCached(value, for: key)
    }
    
    func getCachedValue(for key: WrappedCache.Key, completion: @escaping (WrappedCache.Value?) -> ()) {
        completion(cache.getCachedValue(for: key))
    }
}

extension SyncCache {
    typealias Service = (Key, Completion<Value>)->()
    
    func cacheResultsOf(_ service: @escaping Service) -> Service {
        return { input, completion in
            service(input) { result in
                if let value = result.value {
                    self.setCached(value, for: input)
                }
                completion(result)
            }
        }
    }
}

class InMemoryCache<Key: Hashable, Value>: SyncCache {
    private var storage: Dictionary<Key, Value> = [:]
    
    func setCached(_ value: Value, for key: Key) {
        storage[key] = value
    }
    func getCachedValue(for key: Key) -> Value? {
        return storage[key]
    }
}

extension SyncCache {
    func wrapInAsync() -> InstantToAsyncCacheAdapter<Self> {
        InstantToAsyncCacheAdapter(sync: self)
    }
}
