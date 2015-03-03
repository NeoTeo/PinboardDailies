//
//  main.swift
//  PinboardDailies
//
//  Created by Matteo Sartori on 03/06/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Foundation


class PinboardToAlfred {
    
    enum FetchMode: Int {
        case display = 0
        case silent
    }
    
    func fetchBookmarks(#tag: String, token: String, mode: FetchMode ) {

        let url = NSURL(string: "https://api.pinboard.in/v1/posts/all?auth_token=\(token)&tag=\(tag)&format=json")
        let request = NSURLRequest(URL: url!)
        let queue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: {
            (response: NSURLResponse?, data: NSData?, urlError: NSError?) -> Void in
            
            if urlError != nil {
                println("Much error. Great bye")
                NSLog("ERROR: %@",urlError!)
                exit(-1)
            }
            
            var anError: NSError?

            // Parse the data into an array of string : anyobject dictionaries.
            let json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: &anError) as? [[String : AnyObject]]
            if json == nil { println(anError) ; exit(-1) }
            let rootXML = NSXMLElement(name: "items")
            
            // traverse the data and turn it into an XML format Alfred understands.
            for entry in json! {
                if let
                    description     = entry["description"] as? String,
                    href            = entry["href"] as? String
                {
                    var childXML = NSXMLElement(name: "item")
                    
                    childXML.addAttribute(NSXMLNode.attributeWithName("arg", stringValue: href) as! NSXMLNode)
                    childXML.addAttribute(NSXMLNode.attributeWithName("valid", stringValue: "YES") as! NSXMLNode)
                    childXML.addAttribute(NSXMLNode.attributeWithName("type", stringValue: "file") as! NSXMLNode)
                    
                    // Add the child to the root.
                    rootXML.addChild(childXML)
                    
                    var subChildXML = NSXMLElement(name: "subtitle", stringValue: href)
                    childXML.addChild(subChildXML)
                    
                    
                    subChildXML = NSXMLElement(name: "icon")
                    subChildXML.addAttribute(NSXMLNode.attributeWithName("type", stringValue: "fileicon") as! NSXMLNode)
                    childXML.addChild(subChildXML)
                
                    
                    subChildXML = NSXMLElement(name: "title", stringValue: description)
                    childXML.addChild(subChildXML)
                }
                
            }
            
            var alfredDoc = NSXMLDocument(rootElement: rootXML)
            alfredDoc.version = "1.0"
            alfredDoc.characterEncoding = "UTF-8"
            
            if mode == .display {
                println(alfredDoc.XMLString)
            }
            
            // Write it out to disk (just the dailies for now)
            if tag == "daily" {
                alfredDoc.XMLData.writeToFile("/Users/teo/tmp/cachedDailiesXML.xml", atomically: true)
            }
            exit(0)
        
        })
    }
    
    func checkForCachedXML(cachedXMLURL: NSURL) -> NSXMLDocument? {
        var error: NSError?
        let cachedXML = NSXMLDocument(contentsOfURL: cachedXMLURL, options: Int(NSXMLDocumentContentKind.XMLKind.rawValue), error: &error)
        return cachedXML
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
            // By default the fetchBookmarks display the bookmarks it finds
            var fetchMode = FetchMode.display
            
            // But if we already have a cache, there's no need to display the bookmarks we fetch below.
            if userTag == "daily" {
                if let cachedXML = checkForCachedXML(NSURL(fileURLWithPath: "/Users/teo/tmp/cachedDailiesXML.xml")!) {
                println(cachedXML)
                fetchMode = .silent
                }
            }
            
            main.fetchBookmarks(tag: userTag, token: userToken!, mode: fetchMode)
            
            CFRunLoopRun()
        } else {
            println("Error! No valid token provided.")
            println("Usage: PinboardDailies tag: \"daily\" token: \"username:tokendata\"")
        }
    }
}

PinboardToAlfred().runRun()
