//
//  Observable.swift
//  Giphy
//
//  Created by Varun on 27/04/23.
//

import Foundation

final public class Observable<Value> {
    
    public typealias Listner = (Value) -> Void
    private var listner: Listner?
    
    public var value: Value {
        didSet {
            listner?(value)
        }
    }
    
    public init(_ value: Value) {
        self.value = value
    }
    
    public func subscribe(listner: Listner?) {
        self.listner = listner
        listner?(value)
    }
    
    public func unsubscribe() {
        self.listner = nil
    }
}
