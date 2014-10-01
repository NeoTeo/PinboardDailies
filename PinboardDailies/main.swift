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

        let url = NSURL(string: "https://api.pinboard.in/v1/posts/all?auth_token=\(token)&tag=\(tag)&format=json")
        if url == nil { return }
        let request = NSURLRequest(URL: url!)
        let queue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: {
            (response, data, error) -> Void in
            
            if error != nil {
                println("Much error. Great bye")
                println(error)
                exit(-1)
            } else {

                let json: NSArray = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSArray

                if let rootXML = NSXMLElement(name: "items") {
                
                    for entry: AnyObject in json {
                        var description     = entry.objectForKey("description") as String
                        var href            = entry.objectForKey("href") as String
                        
                        if var childXML = NSXMLElement(name: "item") {
                        
                            childXML.addAttribute(NSXMLNode.attributeWithName("arg", stringValue: href) as NSXMLNode)
                            childXML.addAttribute(NSXMLNode.attributeWithName("valid", stringValue: "YES") as NSXMLNode)
                            childXML.addAttribute(NSXMLNode.attributeWithName("type", stringValue: "file") as NSXMLNode)
                            
                            // Add the child to the root.
                            rootXML.addChild(childXML)
                            
                            if var subChildXML = NSXMLElement(name: "subtitle", stringValue: href) {
                                childXML.addChild(subChildXML)
                            }
                            
                            if var subChildXML = NSXMLElement(name: "icon") {
                                subChildXML.addAttribute(NSXMLNode.attributeWithName("type", stringValue: "fileicon") as NSXMLNode)
                                childXML.addChild(subChildXML)
                            }
                            
                            if var subChildXML = NSXMLElement(name: "title", stringValue: description) {
                                childXML.addChild(subChildXML)
                            }
                        }
                        
                    }
                    
                    var alfredDoc = NSXMLDocument(rootElement: rootXML)
                    alfredDoc.version = "1.0"
                    alfredDoc.characterEncoding = "UTF-8"
                    
                    println(alfredDoc.XMLString)
                }
                // Write it out to disk
                //alfredDoc.XMLData.writeToFile("/Users/teo/tmp/test.xml", atomically: true)
                exit(0)
            }
        })
    }
    
    func runRun() {

        let main = PinboardToAlfred()
        var userToken: String?
        var userTag: String = "daily"
        let argArray = Process.arguments as [String]
        
        if argArray.count < 3 { exit(0) }
        
        // Skip the first index as it is always the application name.
        for index in stride(from: 1, through: argArray.count-1, by: 2) {
            switch (argArray[index], argArray[index+1]) {

                case ("tag:", let value):
                    userTag = value
                
                case ("token:", let value):
                    userToken = value
                
                default:
                    break
            }
        }

        if userToken != nil {
            main.fetchBookmarks(tag: userTag, token: userToken!)

            CFRunLoopRun()
        } else {
            println("Error! No valid token provided.")
            println("Usage: PinboardDailies tag: \"daily\" token: \"username:tokendata\"")
        }
    }
}

PinboardToAlfred().runRun()
