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

let printFunc : @convention(block) (String) -> Void  = { text in print(text) }

context?.setObject(unsafeBitCast(printFunc, to: AnyObject.self), forKeyedSubscript: "print"
    as NSCopying & NSObjectProtocol);

context?.exceptionHandler = { ctx, ex in print("\(ex!)") }

XMLHttpRequest.polyfill(context: context!);

var result = context?.evaluateScript("""
    (function () {
        print(DataView);
        var xhr = new XMLHttpRequest();

        xhr.setRequestHeader("X-Test", "Hello");

        xhr.open('POST', 'https://entt10ke7u5w.x.pipedream.net');

        xhr.onload = function() {
          if (xhr.status != 200) { // analyze HTTP status of the response
            print(`Error ${xhr.status}: ${xhr.statusText}`); // e.g. 404: Not Found
          } else { // show the result
            print(`Done, got ${xhr.response.length} bytes`); // response is the server
          }
        };

        xhr.onprogress = function(event) {
          if (event.lengthComputable) {
            print(`Received ${event.loaded} of ${event.total} bytes`);
          } else {
            print(`Received ${event.loaded} bytes`); // no Content-Length
          }

        };

        xhr.onerror = function() {
          print("Request failed");
        };

        xhr.send("Test");

        var x = setTimeout(() => {
            print('Timeout hello');
        }, 1000);
        
        clearTimeout(x);
    })();
""");

print("\(result?.toString())")

RunLoop.main.run()
