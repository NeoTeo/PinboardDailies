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
    case fetchOnly
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
//        if let url = URL(string: "file://"+NSHomeDirectory()+"/tmp/cachedDailiesXML.xml"), tag == "daily" {
        if let url = URL(string: "file://"+NSTemporaryDirectory()+"cached\(tag)XML.xml") {
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

enum ArgType {
    case Mode
    case Tag
    case Token
}

func parseArgs(args: [String]) -> [ArgType : String] {

    var parsedArgs = [ArgType : String]()
    
    guard args.count >= 2 else {
        printUsage(error: "Incorrect number of arguments.")
        exit(-1)
    }
    
    /// Traverse args, skipping the command name.
    for idx in 1..<args.count {
        
        let arg = args[idx]
        /// split the arg name from the value. 
        /// The requirement is that they are separated by =
        let keyVal = arg.components(separatedBy: "=")
        guard keyVal.count == 2 else { printUsage(error: "Incorrect argument format.") ; exit(-1) }
        let val = keyVal[1]
        
        switch keyVal[0].lowercased() {
        case "--mode":
            parsedArgs[.Mode] = val
        case "--tag":
            parsedArgs[.Tag] = val
        case "--token":
            parsedArgs[.Token] = val
        default:
            printUsage(error: "Argument parse error.")
            exit(-1)
        }
    }
    
    return parsedArgs
}

func printUsage(error: String) {
    print("Error: \(error)")
    print("Usage: pinboardDailies <--token=usertoken> [--mode=fetch|display] [--tag=sometag]")
}

func main() {
    let argArray = CommandLine.arguments as [String]
    let parsedArgs = parseArgs(args: argArray)
    
    guard let token = parsedArgs[.Token] else { printUsage(error: "Missing token.") ; exit(-1) }
    
    let userTag = parsedArgs[.Tag] ?? "daily"
    
    if let mode = parsedArgs[.Mode], mode == "fetch" {
        
        let minQueryInterval: Double = 300.0
        let accessCache = UserDefaults.standard

        /// Ensure we don't spam Pinboard with requests
        if let lastCacheDate = accessCache.object(forKey: "lastCache") as? Date {
            let delta = Date().timeIntervalSince(lastCacheDate)
            if delta < minQueryInterval { print("Exceeded request quota. Next valid request in \(minQueryInterval-delta) seconds.") ; exit(0) }
        }
        
        fetchBookmarks(with: userTag, token: token, mode: .silent)
        
        accessCache.setValue(Date(), forKey: "lastCache")
        
        /// This keeps the app running until fetchBookmarks exits explicitly.
        CFRunLoopRun()
    } else {
        // But if we already have a cache, there's no need to display the bookmarks we fetch below.
         if let cachedXML = checkForCachedXML(URL(fileURLWithPath: NSTemporaryDirectory()+"cached\(userTag)XML.xml")) {
            print(cachedXML)
        }
    }
}

main()
