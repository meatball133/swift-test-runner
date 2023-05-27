import SwiftParser
import Foundation
import SwiftSyntax
import FoundationXML

struct testFile: Codable  {
    var version: Int = 3
    var status: String? = nil
    var message: String? = nil
    var tests: [testCases] = []
}

print("hi")

struct testCases: Codable {
    var name: String = ""
    var test_code: String = ""
    var status: String? = nil
    var message: String? =  nil
    var output: String? = nil
    var task_id: Int? = nil
}


class TestRunner{
    func run(file_path : String, xml_path : String, context : String, result_path : String){

    var swiftSource = ""
    do {
        // Use contentsOfFile overload.
        // ... Specify ASCII encoding.
        // ... Ignore errors.
        swiftSource = try NSString(contentsOfFile: file_path,
            encoding: String.Encoding.ascii.rawValue) as String

        // If a value was returned, print it.
    }catch {
            print("Error file_path: \(error)")
            return // Return or handle the error appropriately
    }

    let rootNode: SourceFileSyntax = try! Parser.parse(source: swiftSource)
    
    class getTestName: SyntaxVisitor  {
        var tests: [testCases] = []

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            let bodyCheck = node.body
            if bodyCheck != nil{
                let name: String = String(describing: node.identifier)
                let body: String = String(describing: bodyCheck!)
                tests.append(testCases(name: name, test_code: body, status: nil, message: nil, output: nil, task_id: nil))
            }
            return SyntaxVisitorContinueKind.visitChildren
        }
    }
    let start = Date()
    var process = getTestName(viewMode: SyntaxTreeViewMode.all)
    process.walk(rootNode)
    let tests = process.tests
    print("Elapsed time: \(start.timeIntervalSinceNow) seconds")
    
    var result = ""
    
    do {
        // Use contentsOfFile overload.
        // ... Specify ASCII encoding.
        // ... Ignore errors.
        result = try NSString(contentsOfFile: xml_path,
            encoding: String.Encoding.ascii.rawValue) as String
        print("mynameis")
        // If a value was returned, print it.
    }catch {
            print("Error xml_path: \(error)")
            writeJson(result_path: result_path, error: erorrContext(context: context))
            return
        }
    class MyXMLParserDelegate: NSObject, XMLParserDelegate {
        var counter = 0
        var tests: [testCases] // Add a property for tests

        init(tests: [testCases]) {
            self.tests = tests
        }
        // Called when the parser encounters the start of an element
        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
            if elementName == "failure"{
                tests[counter].status = "failure"
            }
            else{
                counter = tests.firstIndex(where: {$0.name == attributeDict["name"]}) ?? counter
                tests[counter].status = "succes"
            }
        }
    }


    let xmlData = Data(result.utf8)

    let xmlParser = XMLParser(data: xmlData)
    let delegate  = MyXMLParserDelegate(tests: tests)
    xmlParser.delegate = delegate 
    xmlParser.parse()
    var xml_tests = delegate.tests

    var something = ""
    do {
        // Use contentsOfFile overload.
        // ... Specify ASCII encoding.
        // ... Ignore errors.
        something = try NSString(contentsOfFile: context,
            encoding: String.Encoding.ascii.rawValue) as String

        // If a value was returned, print it.
    }catch {
            print("Error context_path: \(error)")
        }

    print(something)
    for (idx, x) in xml_tests.enumerated(){
        print(x, x.status)
        if x.status == "failure"{
            print("test", "\(x.name) : XCTAssertEqual failed: ")
            if let range2 = something.range(of: "\(x.name) : XCTAssertEqual failed: ") {
                if let range1 = something.range(of: "-Test Case ", options: [], range: (range2.upperBound..<something.endIndex)){
                    print("something")
                    print("bye")
                    let sum = something.distance(from: something.startIndex, to: range2.upperBound)
                    let lowerBound1 = String.Index(encodedOffset: sum + something.distance(from: range2.upperBound, to: range1.lowerBound))
                    let upperBound1 = String.Index(encodedOffset: sum)
                    print(lowerBound1)
                    let newSubstring = something[upperBound1..<lowerBound1]
                    print("hi")
                    xml_tests[idx].message = String(newSubstring)
                }
            }else {
                let type = something.components(separatedBy: "\n")[1...]
                var current = ""
                var index = 1
                print("this route")
                for (idx2, y) in type.enumerated(){
                    let indexy = y.index(y.startIndex, offsetBy: 0)
                    print(y)
                    if y.count > 0{
                        if y.contains(x.name) && y[indexy] != "[" {
                            current = x.name
                            xml_tests[idx].message = y
                            break
                    }   
                }
            }
        }
        }
    }
    writeJson(xml_tests: xml_tests, result_path: result_path)
    }

    func erorrContext(context : String) -> String{
        var something = ""
        do {
            // Use contentsOfFile overload.
            // ... Specify ASCII encoding.
            // ... Ignore errors.
            something = try NSString(contentsOfFile: context,
                encoding: String.Encoding.ascii.rawValue) as String

            // If a value was returned, print it.
        }catch {
                print("Error context_path: \(error)")
        }
        let message = something.components(separatedBy: "\n")[1...]
        let new = message.filter { 
            if $0.count > 0 {
                let index = $0.index($0.startIndex, offsetBy: 0)
            return $0[index] != "[" }
            return true}

        return new.joined(separator: "\n")
    }

    func writeJson(xml_tests: [testCases] = [], result_path: String, error: String = ""){
        let encoder = JSONEncoder()
        var json : testFile
        if error != ""{
            json = testFile(status: "failed", message: error)
        }else{
            json = testFile(tests: xml_tests)
        }
        var data: Data
        print(xml_tests)
        do {
            data = try encoder.encode(json)
        }
        catch {  
            print("Error can't parse json: \(error)")
            return
        }
        print(data)
        let data_json = String(data: data, encoding: .utf8)!
        do {
            try data_json.write(toFile: result_path, atomically: true, encoding: String.Encoding.utf8)
            print(data_json, result_path)
        }
        catch {  
            print("Error result_path: \(error)")
            return
        }
    }
}

TestRunner().run(file_path: CommandLine.arguments[1], xml_path: CommandLine.arguments[2],context:  CommandLine.arguments[3], result_path: CommandLine.arguments[4])


