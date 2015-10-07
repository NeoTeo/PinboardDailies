//
//  main.swift
//  PinboardDailies
//
//  Created by Matteo Sartori on 03/06/14.
//  Licensed under MIT See LICENCE file in the root of this project for details.
//

import Foundation

enum FetchMode: Int {
    case display = 0
    case silent
}

func fetchBookmarks(tag tag: String, token: String, mode: FetchMode ) {

    let url     = NSURL(string: "https://api.pinboard.in/v1/posts/all?auth_token=\(token)&tag=\(tag)&format=json")
    let request = NSURLRequest(URL: url!)

    let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
        (data: NSData?, response: NSURLResponse?, urlError: NSError?) -> Void in
        
        if urlError != nil {
            print("Much error. Great bye")
            NSLog("ERROR: %@",urlError!)
            exit(-1)
        }

        // Parse the data into an array of string : anyobject dictionaries.
        let json    = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? [[String : AnyObject]]
        let rootXML = NSXMLElement(name: "items")
        
        // traverse the data and turn it into an XML format Alfred understands.
        for entry in json! {
            if let
                description     = entry["description"] as? String,
                href            = entry["href"] as? String
            {
                let childXML = NSXMLElement(name: "item")
                
                childXML.addAttribute(NSXMLNode.attributeWithName("arg"     , stringValue:   href) as! NSXMLNode)
                childXML.addAttribute(NSXMLNode.attributeWithName("valid"   , stringValue:  "YES") as! NSXMLNode)
                childXML.addAttribute(NSXMLNode.attributeWithName("type"    , stringValue: "file") as! NSXMLNode)
                
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
        
        let alfredDoc               = NSXMLDocument(rootElement: rootXML)
        alfredDoc.version           = "1.0"
        alfredDoc.characterEncoding = "UTF-8"
        
        if mode == .display {
            print(alfredDoc.XMLString)
        }
        
        // Write it out to disk (just the dailies for now)
        if tag == "daily" {
            alfredDoc.XMLData.writeToFile("/Users/teo/tmp/cachedDailiesXML.xml", atomically: true)
        }
        exit(0)
    
    }
    
    task.resume()
}

func checkForCachedXML(cachedXMLURL: NSURL) -> NSXMLDocument? {
    
    do {
        let cachedXML: NSXMLDocument? = try NSXMLDocument(contentsOfURL: cachedXMLURL, options: Int(NSXMLDocumentContentKind.XMLKind.rawValue))
        return cachedXML
        
    } catch {
        print(error)
        return nil
    }
}

func runRun() {

    var userToken: String?
    var userTag  = "daily"
    let argArray = Process.arguments as [String]
    
    if argArray.count < 3 { exit(0) }
    
    // Skip the first index as it is always the application name.
    for index in 1.stride(through: argArray.count-1, by: 2) {
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
        if userTag.lowercaseString == "daily",
            let cachedXML = checkForCachedXML(NSURL(fileURLWithPath: "/Users/teo/tmp/cachedDailiesXML.xml")) {
                print(cachedXML)
                fetchMode = .silent
        }
        

        fetchBookmarks(tag: userTag, token: userToken!, mode: fetchMode)
        
        CFRunLoopRun()
    } else {
        print("Error! No valid token provided.")
        print("Usage: PinboardDailies tag: \"daily\" token: \"username:tokendata\"")
    }
}

runRun()
