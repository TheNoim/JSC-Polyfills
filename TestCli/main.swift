//
//  main.swift
//  TestCli
//
//  Created by Nils Bergmann on 25.06.20.
//

import Foundation
import JavaScriptCore
import JSContextFetch

let vm = JSVirtualMachine()
let context = JSContext(virtualMachine: vm)

context?.exceptionHandler = { ctx, ex in print("\(ex!)") }

XMLHttpRequest.polyfill(context: context!);

let printFunc : @convention(block) (String) -> Void  = { text in print(text) }
context?.setObject(unsafeBitCast(printFunc, to: AnyObject.self), forKeyedSubscript: "print"
    as NSCopying & NSObjectProtocol);

var result = context?.evaluateScript("""
    (function () {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function (v) {
            print("Test: " + v);
        }
        xhr.open("", "");
        return xhr;
    })();
""");

print("\(result?.toString())")
