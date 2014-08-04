//
//  main.swift
//  PinboardDailies
//
//  Created by Matteo Sartori on 03/06/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Foundation


class PinboardToAlfred {
    
    func fetchBookmarks(#tag: String, token: String) {
        let url = NSURL.URLWithString("https://api.pinboard.in/v1/posts/all?auth_token=\(token)&tag=\(tag)&format=json")
        let request = NSURLRequest(URL: url)
        let queue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: {
            (response, data, error) -> Void in

            if error != nil {
                println("Much error. Great bye")
                println(error)
            } else {
                
                let json: NSArray = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSArray
                
                var rootXML = NSXMLElement(name: "items")
                
                for entry: AnyObject in json {
                    
                    var description     = entry.objectForKey("description") as String
                    var href            = entry.objectForKey("href") as String
                    var childXML        = NSXMLElement(name: "item")
                    
                    childXML.addAttribute(NSXMLNode.attributeWithName("arg", stringValue: href) as NSXMLNode)
                    childXML.addAttribute(NSXMLNode.attributeWithName("valid", stringValue: "YES") as NSXMLNode)
                    childXML.addAttribute(NSXMLNode.attributeWithName("type", stringValue: "file") as NSXMLNode)
                    
                    // Add the child to the root.
                    rootXML.addChild(childXML)
                    
                    var subChildXML = NSXMLElement(name: "subtitle", stringValue: href)
                    childXML.addChild(subChildXML)
                    
                    subChildXML = NSXMLElement(name: "icon")
                    subChildXML.addAttribute(NSXMLNode.attributeWithName("type", stringValue: "fileicon") as NSXMLNode)
                    childXML.addChild(subChildXML)
                    
                    subChildXML = NSXMLElement(name: "title", stringValue: description)
                    childXML.addChild(subChildXML)
                    
                }
                
                var alfredDoc = NSXMLDocument(rootElement: rootXML)
                alfredDoc.version = "1.0"
                alfredDoc.characterEncoding = "UTF-8"
                
                println(alfredDoc.XMLString)
                
                // Write it out to disk
                //alfredDoc.XMLData.writeToFile("/Users/teo/tmp/test.xml", atomically: true)
                exit(0)
            }
        })
    }
    
    func runRun() {
        let runLoop = NSRunLoop.currentRunLoop()
        let main = PinboardToAlfred()
        var tag: String?
        var token: String?

        var index = 1
        while index+1 < Int(C_ARGC) {
            switch (String.fromCString(C_ARGV[index++]),String.fromCString(C_ARGV[index++])) {
            case (.Some("tag:"), .Some(let value)):
                tag = value
            case (.Some("token:"), .Some(let value)):
                token = value
            default:
                break
            }
        }
        
        if token != nil {
            main.fetchBookmarks(tag: tag!, token: token!)
            runLoop.run()
        } else {
            println("Error! No valid token provided.")
            println("Usage: PinboardDailies tag: \"daily\" token: \"username:tokendata\"")
        }
    }
}

PinboardToAlfred().runRun()
