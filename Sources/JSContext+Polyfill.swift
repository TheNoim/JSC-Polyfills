//
//  JSContext+Polyfill.swift
//  JSContextFetch
//
//  Created by Nils Bergmann on 26.06.20.
//

import Foundation
import JavaScriptCore

public extension JSContext {
    
    func addPolyfills() {
        addSetTimeoutPolyfill(context: self);
        XMLHttpRequest.polyfill(context: self);
        let bundle = Bundle(identifier: "io.noim.JSContextFetch")!;
        let url = bundle.url(forResource: "bundle", withExtension: "js");
        self.evaluateScript(try! NSString.init(contentsOf: url!, encoding: 4) as String, withSourceURL: url);
    }
    
}
