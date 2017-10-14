//
//  main.swift
//  PinboardDailies
//
//  Created by Matteo Sartori on 03/06/14.
//  Licensed under MIT See LICENCE file in the root of this project for details.
//

import Foundation

enum ArgType {
    case Mode
    case Tag
    case Token
}

enum OutputMode: Int {
    case display = 0
    case silent
}

struct PinboardEntry : Decodable {
    var href: String
    var description: String
// Unused parts of the returned json.
//    var extended: String
//    var meta: String
//    var hash: String
//    var time: String
//    var shared: String
//    var toread: String
//    var tags: String
}

// Takes a comma separated string of tags and returns a query string where each
// tag is prepended with &tag=
func makeMultiTagQuery(from tags: [String]) -> String {
    
//    let tags = tags.split(separator: ",")
    var multiTags = ""
    for tag in tags {
        multiTags += "&tag=\(tag)"
    }
    
    return multiTags
}

//func fetchBookmarks(with tag: String, token: String, handler: @escaping (XMLDocument) -> () ) {
func fetchBookmarks(with tags: [String], token: String, handler: @escaping (XMLDocument) -> () ) {
    
    // Format the tags correctly.
    let tags    = makeMultiTagQuery(from: tags)
    let url     = URL(string: "https://api.pinboard.in/v1/posts/all?auth_token=\(token)\(tags)&format=json")
    let request = URLRequest(url: url!)

    let myDecoder = JSONDecoder()
    
    let task = URLSession.shared.dataTask(with: request) {
        (data: Data?, response: URLResponse?, urlError: Error?) -> Void in
        
        guard urlError == nil else { fatalError("Much error. Great bye. \(String(describing: urlError))") }
        guard let data = data else { fatalError("No data in received.") }
        
        do {
            let pinboardEntries: [PinboardEntry] = try myDecoder.decode([PinboardEntry].self, from: data)
        
            let rootXML = XMLElement(name: "items")
            
            // traverse the data and turn it into an XML format Alfred understands.
            for entry in pinboardEntries {
                
                let description = entry.description
                let href = entry.href
                
                let childXML = XMLElement(name: "item")
                
                childXML.addAttribute(XMLNode.attribute(withName: "arg", stringValue: href) as! XMLNode)
                childXML.addAttribute(XMLNode.attribute(withName: "valid", stringValue: "YES") as! XMLNode)
                childXML.addAttribute(XMLNode.attribute(withName: "type", stringValue: "file") as! XMLNode)
                
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
            
            handler(alfredDoc)
            
        } catch { fatalError("fetchBookmarks could not decode the JSON. Exiting. \(error)") }

    }
    
    task.resume()
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
        guard keyVal.count == 2 else {
            
            printUsage(error: "Incorrect argument format.") ; exit(-1) }
        let val = keyVal[1]
        
        switch keyVal[0].lowercased() {
        case "--mode":
            parsedArgs[.Mode] = val
            
        case "--tag":
            // To deal with multiple tag args we build it here as a comma separated string.
            // We will deal with building a proper query from it in the query method.
            var tmpTagString = parsedArgs[.Tag] ?? ""
            tmpTagString += val
            parsedArgs[.Tag] = tmpTagString
            
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
    print("Usage: pinboardDailies <--token=usertoken> [--mode=fetch|display|uncached] [--tag=sometag]")
}

//func fetch(quota: Double, tag: String, token: String, handler: @escaping (XMLDocument)->()) {
func fetch(quota: Double, tags: [String], token: String, handler: @escaping (XMLDocument)->()) {
    /// set the query interval to five minutes 60*5 = 300
    let minQueryInterval: Double = quota//300.0
    let accessCache = UserDefaults.standard
    
    /// Ensure we don't spam Pinboard with requests
    if let lastCacheDate = accessCache.object(forKey: "lastCache") as? Date {
        let delta = Date().timeIntervalSince(lastCacheDate)
        if delta < minQueryInterval { print("Exceeded request quota. Next valid request in \(minQueryInterval-delta) seconds.") ; exit(0) }
    }
    
    fetchBookmarks(with: tags, token: token, handler: handler)
    
    accessCache.setValue(Date(), forKey: "lastCache")
    
    /// This keeps the app running until fetchBookmarks exits explicitly.
    CFRunLoopRun()
}

// XML store and load functions
func storeXml(in doc: XMLDocument, tag: String) {
    // Write it out to disk
    if let url = URL(string: "file://"+NSTemporaryDirectory()+"cached\(tag)XML.xml") {
        do {
            try doc.xmlData.write(to: url, options: NSData.WritingOptions.atomicWrite)
        } catch {
            print("Error \(error) writing XML data. Exiting.")
        }
    }
}

func checkForCachedXML(_ cachedXMLURL: URL) -> XMLDocument? {
    
    do {
        let cachedXML: XMLDocument? = try XMLDocument(contentsOf: cachedXMLURL, options: XMLNode.Options(rawValue: XMLNode.Options.RawValue(Int(XMLDocument.ContentKind.xml.rawValue))))
        return cachedXML
        
    } catch {
        print(error)
        return nil
    }
}

func main() {
    let argArray = CommandLine.arguments as [String]
    let parsedArgs = parseArgs(args: argArray)
    
    guard let token = parsedArgs[.Token] else { printUsage(error: "Missing token.") ; exit(-1) }
    
    //let userTag = parsedArgs[.Tag] ?? "daily"
    let tagsString = parsedArgs[.Tag] ?? "daily"
    let userTags = tagsString.components(separatedBy: ",")
    
    guard userTags.count < 4 else {
        printUsage(error: "Maximum three tags supported")
        return
    }
    
    let joinedTags = userTags.joined(separator: "_")
    
    switch parsedArgs[.Mode] {
    /// This case fetches and then displays the fetched. No cache is used.
    case .some("uncached"):
        fetch(quota: 0.5, tags: userTags, token: token ) { (alfredDoc: XMLDocument) in
            
            storeXml(in: alfredDoc, tag: joinedTags)
            print(alfredDoc.xmlString)
            exit(0)
        }
        
    /// This case updates the cache by fetching and saving without outputting. Can be slow.
    case .some("fetch"):
        fetch(quota: 300.0, tags: userTags, token: token) { (alfredDoc: XMLDocument) in
            
            storeXml(in: alfredDoc, tag: joinedTags)
            exit(0)
        }
    
    /// This case displays any existing cache without fetching. This is fast.
    case .some("display"):
        
        // If we already have a cache, there's no need to display the bookmarks we fetch below.
         if let cachedXML = checkForCachedXML(URL(fileURLWithPath: NSTemporaryDirectory()+"cached\(joinedTags)XML.xml")) {
            print(cachedXML)
        }
        
    default:
        printUsage(error: "Unrecognized mode.")
    }
}

main()
