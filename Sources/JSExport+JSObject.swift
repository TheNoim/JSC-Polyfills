//
//  JSExport+JSObject.swift
//  JSContextFetch
//
//  Created by Nils Bergmann on 25.06.20.
//

import Foundation
import JavaScriptCore

@objc public protocol JSObjectProtocol: JSExport {
    var setThisValue: (@convention(block)(JSValue) -> Void)? { get }
}
 
public class JSObject: NSObject, JSObjectProtocol {
    var this: JSManagedValue?
    
    override init() {
        super.init()
    }
    
    public var setThisValue: (@convention(block)(JSValue) -> Void)? {
        return { [unowned self] (value: JSValue) in
            self.this = JSManagedValue(value: value)
        }
    }
}
