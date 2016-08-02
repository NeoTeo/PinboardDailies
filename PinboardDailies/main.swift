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

func fetchBookmarks(with tag: String, token: String, mode: FetchMode ) {

    let url     = URL(string: "https://api.pinboard.in/v1/posts/all?auth_token=\(token)&tag=\(tag)&format=json")
    let request = URLRequest(url: url!)

    let task = URLSession.shared.dataTask(with: request) {
        (data: Data?, response: URLResponse?, urlError: Error?) -> Void in
        
        guard urlError == nil else {
            print("Much error. Great bye. \(urlError)")
            exit(-1)
        }

        // Parse the data into an array of string : anyobject dictionaries.
        let json    = try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? [[String : AnyObject]]
        let rootXML = XMLElement(name: "items")
        
        // traverse the data and turn it into an XML format Alfred understands.
        for entry in json! {
            
            guard let description = entry["description"] as? String, let href = entry["href"] as? String
            else { continue }
            
            let childXML = XMLElement(name: "item")
            
            childXML.addAttribute(XMLNode.attribute(withName: "arg"     , stringValue:   href) as! XMLNode)
            childXML.addAttribute(XMLNode.attribute(withName: "valid"   , stringValue:  "YES") as! XMLNode)
            childXML.addAttribute(XMLNode.attribute(withName: "type"    , stringValue: "file") as! XMLNode)
            
            // Add the child to the root.
            rootXML.addChild(childXML)
            
            var subChildXML = XMLElement(name: "subtitle", stringValue: href)
            childXML.addChild(subChildXML)
            
            
            subChildXML = XMLElement(name: "icon")
            subChildXML.addAttribute(XMLNode.attribute(withName: "type", stringValue: "fileicon") as! XMLNode)
            childXML.addChild(subChildXML)
        
            
            subChildXML = XMLElement(name: "title", stringValue: description)
            childXML.addChild(subChildXML)
            
            
        }
        
        let alfredDoc               = XMLDocument(rootElement: rootXML)
        alfredDoc.version           = "1.0"
        alfredDoc.characterEncoding = "UTF-8"
        
        if mode == .display {
            print(alfredDoc.xmlString)
        }
        
        // Write it out to disk (just the dailies for now)
        if let url = URL(string: "file://"+NSHomeDirectory()+"/tmp/cachedDailiesXML.xml"), tag == "daily" {
            do {
                try alfredDoc.xmlData.write(to: url, options: NSData.WritingOptions.atomicWrite)
            } catch {
                print("Error \(error) writing XML data. Exiting.")
            }
        }
        exit(0)
    
    }
    
    task.resume()
}

func checkForCachedXML(_ cachedXMLURL: URL) -> XMLDocument? {
    
    do {
        let cachedXML: XMLDocument? = try XMLDocument(contentsOf: cachedXMLURL, options: Int(XMLDocument.ContentKind.xml.rawValue))
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
    for index in stride(from:1, through: argArray.count-1, by: 2) {
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
        if userTag.lowercased() == "daily",
            let cachedXML = checkForCachedXML(URL(fileURLWithPath: NSHomeDirectory()+"/tmp/cachedDailiesXML.xml")) {
                print(cachedXML)
                fetchMode = .silent
        
        }

        fetchBookmarks(with: userTag, token: userToken!, mode: fetchMode)
        
        CFRunLoopRun()
    } else {
        print("Error! No valid token provided.")
        print("Usage: PinboardDailies tag: \"daily\" token: \"username:tokendata\"")
    }
}

runRun()
