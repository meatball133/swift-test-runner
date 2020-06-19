//
//  Suites.swift
//  
//
//  Created by William Neumann on 5/13/20.
//

import Foundation

let startTimeFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.timeZone = TimeZone(secondsFromGMT: 0)
  formatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ss.SSS"
  return formatter
}()

enum TestStatus: String, Codable {
  case pass, fail, error
}

struct TestCase: CustomStringConvertible, Encodable {
  //    let suiteName: String
  let testName: String
  private(set) var message: String? = nil
  private(set) var output: String? = nil
  let status: TestStatus

  init(_ testCase: (String, [String], Either<String, Void>)) {
    var messages = testCase.1

    //        self.suiteName = testCase.0.suite
    self.testName = testCase.0
    switch testCase.2 {
    case .right:
      self.status = .error
      self.message = messages.popLast()
    case .left("passed"):
      self.status = .pass
    case .left("failed"):
      self.status = .fail
      self.message = messages.popLast()
    case .left(let stat): fatalError("impossible parsing of status, got: \(stat)")
    }
    if !messages.isEmpty {
      self.output = "\(messages.joined(separator: "\n").prefix(499))…"
    }
  }

  var description: String {
    "Test: \(testName) - \(status)\nmessage: \(message ?? "null")\noutput: \(output ?? "null")"
  }

  enum CodingKeys: String, CodingKey {
    case testName = "name"
    case status
    case message
    case output
  }
}

struct TestSuite: CustomStringConvertible {
  let name: String
  let startTime: Date
  let status: TestStatus
  let cases: [TestCase]

  var description: String {
    let casestrs = cases.map {
      "\t" + $0.description.components(separatedBy: "\n").joined(separator: "\n\t")
    }.joined(separator: "\n")
    return "Suite: \(name), started at \(startTime) - \(status)\n\(casestrs)"
  }
}

struct PackageSuite: CustomStringConvertible {
  let name: String
  let startTime: Date
  let status: TestStatus
  let testSuites: [TestSuite]

  var description: String {
    return
      "\n_________________\n\nPackage: \(name) started at \(startTime) -- \(status)\n•••\n\(testSuites.map { $0.description }.joined(separator: "\n••••\n"))"
  }
}

struct TestResult: CustomStringConvertible, Encodable {
  let startTime: Date
  let status: TestStatus
  let testSuites: [PackageSuite]
  let message: String?
  let tests: [TestCase]

  init(startTime: Date, status: TestStatus, testSuites: [PackageSuite], message: String?) {
    self.startTime = startTime
    self.status = status
    self.testSuites = testSuites
    self.message = message
    self.tests = testSuites.flatMap { packageSuite in
      packageSuite.testSuites.flatMap { testSuite in
        testSuite.cases
      }
    }

  }

  var description: String {
    return
      "\n_________________\n\nAll tests started at \(startTime) -- \(status)\n•••\n\(testSuites.map { $0.description }.joined(separator: "\n••••\n"))\nmessage: \(message ?? "null")"
  }

  enum CodingKeys: String, CodingKey {
    case status
    case message
    case tests
  }

}

