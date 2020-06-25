//
//  JSContext+setTimeout.swift
//  JSContextFetch
//
//  Created by Nils Bergmann on 25.06.20.
//

import Foundation
import JavaScriptCore

let setTimeoutFunc: @convention(block) (JSValue, JSValue) -> Void = { (funct, timeout) in
    var realTimeout = 0
    if timeout.isNumber && (timeout.toNumber()! as! Int) > 0 {
        realTimeout = timeout.toNumber()! as! Int
    }
    if realTimeout < 1 {
        funct.objectForKeyedSubscript("callback")?.call(withArguments: []);
    } else {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(realTimeout)) {
            funct.objectForKeyedSubscript("callback")?.call(withArguments: []);
        }
    }
}

public func addSetTimeoutPolyfill(context: JSContext) {
    context.setObject(unsafeBitCast(setTimeoutFunc, to: AnyObject.self), forKeyedSubscript: "__setTimeout" as NSCopying & NSObjectProtocol);
    
    context.evaluateScript("""
        var __timeoutMap = {};
        var __lastTimeout = 0;

        function setTimeout(__f, __t, ...args) {
            var id = __lastTimeout;
            __setTimeout({
                callback: () => {
                    if (__timeoutMap[id]) {
                        delete __timeoutMap[id];
                        return;
                    }
                    __f(...args);
                }
            }, __t);
            __lastTimeout++;
            return id;
        }
        function clearTimeout(id) {
            __timeoutMap[id] = true;
        }
    """)
}
