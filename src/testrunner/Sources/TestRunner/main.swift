import SwiftParser
import Foundation
import SwiftSyntax
import FoundationXML

struct testFile: Codable  {
    var version: Int = 3
    var status: String = "pass"
    var message: String? = nil
    var tests: [testCases] = []
}

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
        swiftSource = try NSString(contentsOfFile: file_path,
            encoding: String.Encoding.ascii.rawValue) as String
    }catch {
            print("Error file_path: \(error)")
    }
    let rootNode: SourceFileSyntax = try! Parser.parse(source: swiftSource)
    
    class getTestName: SyntaxVisitor  {
        var tests: [testCases] = []
        var task_id = 0
        var in_class = 0
        let charactersToRemove = CharacterSet(charactersIn: "\n{} ")

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            let bodyCheck = node.body
            if bodyCheck != nil{
                let name: String = String(describing: node.identifier)
                var body: String = String(describing: bodyCheck!).trimmingCharacters(in: charactersToRemove)
                var bodyList = body.components(separatedBy: "\n")
                for (idx, x) in bodyList.enumerated(){
                    bodyList[idx] = x.trimmingCharacters(in: CharacterSet.whitespaces)
                }
                body = bodyList.joined(separator: "\n")
                tests.append(testCases(name: name, test_code: body, task_id: task_id))
            }
            return SyntaxVisitorContinueKind.visitChildren
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            if in_class == 0{
                task_id += 1
            } 
            in_class += 1  
            return SyntaxVisitorContinueKind.visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            in_class -= 1
        }
    }
    var process = getTestName(viewMode: SyntaxTreeViewMode.all)
    process.walk(rootNode)
    let tests = process.tests
    var result = ""
    do {
        result = try NSString(contentsOfFile: xml_path,
            encoding: String.Encoding.ascii.rawValue) as String
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
                tests[counter].status = "fail"
            }
            else{
                counter = tests.firstIndex(where: {$0.name == attributeDict["name"]}) ?? counter
                tests[counter].status = "pass"
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
        something = try NSString(contentsOfFile: context,
            encoding: String.Encoding.ascii.rawValue) as String
    }catch {
            print("Error context_path: \(error)")
        }
    for (idx, x) in xml_tests.enumerated(){
        if x.status == "fail"{
            let type = something.components(separatedBy: "\n")[1...]
            var found = false
            for (idx2, y) in type.enumerated(){
                if let range2 = y.range(of: "\(x.name) : XCTAssertEqual failed: ") {
                    found = true
                    if let range1 = y.range(of: "-Test Case ", options: [], range: (range2.upperBound..<y.endIndex)){
                        let sum = y.distance(from: y.startIndex, to: range2.upperBound)
                        let lowerBound1 = String.Index(encodedOffset: sum + y.distance(from: range2.upperBound, to: range1.lowerBound))
                        let upperBound1 = String.Index(encodedOffset: sum)
                        let newSubstring = y[upperBound1..<lowerBound1]
                        xml_tests[idx].message = String(newSubstring)
                        break
                    }else{
                        let sum = y.distance(from: y.startIndex, to: range2.upperBound)
                        let upperBound1 = String.Index(encodedOffset: sum)
                        let newSubstring = y[upperBound1..<y.endIndex]
                        xml_tests[idx].message = String(newSubstring)
                        break
                    }
                }
            }
            if !found {
                var current = ""
                var index = 1
                for (idx2, y) in type.enumerated(){
                    let indexy = y.index(y.startIndex, offsetBy: 0)
                    if y.count > 0{
                        if y.contains(x.name) && y[indexy] != "[" {
                            current = x.name
                            xml_tests[idx].status = "fail"
                            xml_tests[idx].message = y
                            break
                    }   
                }
            }
        }
        }
        if x.status != "error"{
            let type2 = something.components(separatedBy: "\n")[1...]
            var start = 0
            var startString = ""
            for (idx3, z) in type2.enumerated(){
                let indexz = z.index(z.startIndex, offsetBy: 0)
                if z.count > 0{
                    if start == 0 && z.contains(x.name) && z[indexz] != "["{
                        if let range = z.range(of: "started at", options: .backwards) {
                            if let range1 = z.range(of: ".", options: [], range: (range.upperBound..<z.endIndex)){
                                let newIndex = z.index(range1.upperBound, offsetBy: 3)
                                startString = String(z[newIndex..<z.endIndex])
                            }
                        }
                        start = idx3 + 2
                    } else if z.contains(x.name) && z[indexz] != "[" {
                        if start < idx3{
                            xml_tests[idx].output = startString + "\n" + type2[start...idx3].joined(separator: "\n")
                        }
                        break
                    }   
                }
            }
            if startString != "" && xml_tests[idx].output == nil{
                xml_tests[idx].output = startString
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
        if xml_tests.contains {$0.status == "fail" } {
            json = testFile(status: "fail")
        }
        else if error != ""{
            json = testFile(status: "error", message: error)
        }else{
            json = testFile(tests: xml_tests)
        }
        var data: Data
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
