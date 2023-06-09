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
    var xmlTests: [testCases] = []

    class getTestName: SyntaxVisitor  {
        var tests: [testCases] = []
        var taskId = 0
        var inClass = 0
        let charactersToRemove = CharacterSet(charactersIn: "\n{} ")

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            let bodyCheck = node.body
            if bodyCheck != nil{
                let name: String = String(describing: node.identifier)
                var body: String = String(describing: bodyCheck!).trimmingCharacters(in: charactersToRemove)
                var bodyList = body.components(separatedBy: "\n")
                for (rowIdx, row) in bodyList.enumerated(){
                    bodyList[rowIdx] = row.trimmingCharacters(in: CharacterSet.whitespaces)
                }
                body = bodyList.joined(separator: "\n")
                tests.append(testCases(name: name, test_code: body, task_id: taskId == 0 ? nil : taskId))
            }
            return SyntaxVisitorContinueKind.visitChildren
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            if inClass == 0 && String(describing: node.identifier).hasPrefix("Task") {
                taskId += 1
            } 
            inClass += 1  
            return SyntaxVisitorContinueKind.visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            inClass -= 1
        }
    }

    class MyXMLParserDelegate: NSObject, XMLParserDelegate {
        var counter = 0
        var tests: [testCases] // Add a property for tests

        init(tests: [testCases]) {
            self.tests = tests
        }
        // Called when the parser encounters the start of an element
        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName _: String?, attributes attributeDict: [String : String] = [:]) {
            if elementName == "failure"{
                tests[counter].status = "fail"
            }
            else{
                counter = tests.firstIndex(where: {$0.name == attributeDict["name"]}) ?? counter
                tests[counter].status = "pass"
            }
        }
    }


    func run(filePath : String, xmlPath : String, contextPath : String, resultPath : String){
    var swiftSource = ""
    do {
        swiftSource = try NSString(contentsOfFile: filePath,
            encoding: String.Encoding.ascii.rawValue) as String
    }catch {
            print("Error filePath: \(error)")
    }
    let rootNode: SourceFileSyntax = try! Parser.parse(source: swiftSource)
    var process = getTestName(viewMode: SyntaxTreeViewMode.all)
    process.walk(rootNode)
    let tests = process.tests
    var result = ""
    do {
        result = try NSString(contentsOfFile: xmlPath,
            encoding: String.Encoding.ascii.rawValue) as String
    }catch {
            print("Error xmlPath: \(error)")
            writeJson(resultPath: resultPath, error: errorContext(context: contextPath))
            return
    }

    let xmlData = Data(result.utf8)
    let xmlParser = XMLParser(data: xmlData)
    let delegate  = MyXMLParserDelegate(tests: tests)
    xmlParser.delegate = delegate 
    xmlParser.parse()
    xmlTests = delegate.tests

    var context = ""
    do {
        context = try NSString(contentsOfFile: contextPath,
            encoding: String.Encoding.ascii.rawValue) as String
    }catch {
            print("Error contextPath: \(error)")
        }
    addContext(context: context)

    writeJson(resultPath: resultPath)
    }

    func addContext(context: String) {
        for (testIdx, testCase) in xmlTests.enumerated(){
            var error = false
            if testCase.status == "fail"{
                let contextLines = context.components(separatedBy: "\n")[1...]
                var found = false
                for row in contextLines{
                    if let startRange = row.range(of: "\(testCase.name) : XCTAssertEqual failed: ") {
                        found = true
                        if let endRange = row.range(of: "Test Case ", options: [], range: (startRange.upperBound..<row.endIndex)){
                            let sum = row.distance(from: row.startIndex, to: startRange.upperBound)
                            let lowerBound1 = String.Index(encodedOffset: sum + row.distance(from: startRange.upperBound, to: endRange.lowerBound))
                            let upperBound1 = String.Index(encodedOffset: sum)
                            let newSubstring = row[upperBound1..<lowerBound1]
                            xmlTests[testIdx].message = String(newSubstring)
                            break
                        }else{
                            let sum = row.distance(from: row.startIndex, to: startRange.upperBound)
                            let upperBound1 = String.Index(encodedOffset: sum)
                            let newSubstring = row[upperBound1..<row.endIndex]
                            xmlTests[testIdx].message = String(newSubstring)
                            break
                        }
                    }
                }
                if !found {
                    var current = ""
                    var index = 1
                    error = true
                    for row in contextLines{
                        let startIndex = row.index(row.startIndex, offsetBy: 0)
                        if row.count > 0{
                            if row.contains(testCase.name) && row[startIndex] != "[" {
                                current = testCase.name
                                if let startRange = row.range(of: "started at", options: .backwards) {
                                    if let newStartRange = row.range(of: ".", options: [], range: (startRange.upperBound..<row.endIndex)){
                                        if let endRange = row.range(of: "Test Case ", options: [], range: (newStartRange.upperBound..<row.endIndex)){
                                            let newIndex = row.index(newStartRange.upperBound, offsetBy: 3)
                                            let sum = row.distance(from: row.startIndex, to: newIndex)
                                            let lowerBound1 = String.Index(encodedOffset: sum + row.distance(from: newIndex, to: endRange.lowerBound))
                                            let upperBound1 = String.Index(encodedOffset: sum)
                                            let newSubstring = row[upperBound1..<lowerBound1]
                                            xmlTests[testIdx].message = String(newSubstring)
                                            break
                                        }
                                    }
                                }
                        }   
                    }
                }
            }
        }
        if !error {
            let contextLinesOutput = context.components(separatedBy: "\n")[1...]
            var start = 0
            var startString = ""
            for (rowIdx, row) in contextLinesOutput.enumerated(){
                let startIndex = row.index(row.startIndex, offsetBy: 0)
                if row.count > 0{
                    if start == 0 && row.contains(testCase.name + "'") && row[startIndex] != "["{
                        if let startRange = row.range(of: "started at", options: .backwards) {
                            if let newStartRange = row.range(of: ".", options: [], range: (startRange.upperBound..<row.endIndex)){
                                let newIndex = row.index(newStartRange.upperBound, offsetBy: 3)
                                startString = String(row[newIndex..<row.endIndex])
                                if startString.hasPrefix("Test Case") || startString.contains(testCase.name + "'"){
                                    startString = ""
                                    break
                                }
                            }
                        }
                        start = rowIdx + 2
                    } else if (row.contains(testCase.name + "'") && row[startIndex] != "[") || row.hasPrefix("\\")  {
                        if start < rowIdx{
                            xmlTests[testIdx].output = startString + "\n" + contextLinesOutput[start...rowIdx].joined(separator: "\n")
                        }
                        break
                    }   
                }
            }
            if startString != "" && xmlTests[testIdx].output == nil{
                xmlTests[testIdx].output = startString
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
    }

    func errorContext(context : String) -> String{
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
        var start = 0
        for (rowIdx, row) in message.enumerated(){
            if row.contains("CompileError.swift:"){
                start = rowIdx + 1
                break
            }
        }
        if start != 0{
            return message[start...].joined(separator: "\n")
        }
        return message.joined(separator: "\n")
    }

    func writeJson( resultPath: String, error: String = ""){
        let encoder = JSONEncoder()
        encoder.outputFormatting.update(with: .prettyPrinted)
        encoder.outputFormatting.update(with: .sortedKeys)
        var json : testFile
        if xmlTests.contains {$0.status == "fail" } {
            json = testFile(status: "fail", tests: xmlTests)
        }
        else if error != ""{
            json = testFile(status: "error", message: error)
        }else{
            json = testFile(tests: xmlTests)
        }
        var data: Data
        do {
            data = try encoder.encode(json)
        }
        catch {  
            print("Error can't encode json: \(error)")
            return
        }
        let dataJson = String(data: data, encoding: .utf8)!
        do {
            try dataJson.write(toFile: resultPath, atomically: true, encoding: String.Encoding.utf8)
        }
        catch {  
            print("Error resultPath: \(error)")
            return
        }
    }
}

TestRunner().run(filePath: CommandLine.arguments[1], xmlPath: CommandLine.arguments[2], contextPath:  CommandLine.arguments[3], resultPath: CommandLine.arguments[4])
