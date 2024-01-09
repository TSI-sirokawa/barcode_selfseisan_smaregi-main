//
//  Queue.swift
//  seisan
//
//  Created by 加治木啓之 on 2023/05/02.
//

import Foundation

/// スレッドセーフなキュー
final class Queue<T> {
    private var elems: [T] = []
    private let semaphore = DispatchSemaphore(value: 1)
    
    var count: Int {
        semaphore.wait()
        defer { semaphore.signal() }
        
        return elems.count
    }
    
    func enqueue(_ value: T) {
        semaphore.wait()
        defer { semaphore.signal() }
        
        elems.append(value)
    }
    
    func dequeue() -> T? {
        semaphore.wait()
        defer { semaphore.signal() }
        
        let ret = elems.isEmpty ? nil : elems.removeFirst()
        return ret
    }

    func peek() -> T? {
        semaphore.wait()
        defer { semaphore.signal() }
        
        return elems.first
    }
}
