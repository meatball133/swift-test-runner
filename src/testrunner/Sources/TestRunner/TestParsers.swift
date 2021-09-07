//
//  TestParsers.swift
//
//
//  Created by William Neumann on 5/13/20.
//

import Foundation

// MARK: - Test Case Parsing

let suiteAndCase = zip(
    with: { (suite: String($0), case: String($1)) },
    Parser.keep(prefix(until: { $0.isWhitespace }), discard: Parser.whitespace),
    prefix(until: { $0 == "]" })
)
let caseNameParser = zip(
    with: { (open: $0, suiteAndCase: $1, close: $2) },
    Parser.choose(Parser.string("'-["), Parser.string("'")),
    suiteAndCase,
    Parser.choose(Parser.string("]' "), Parser.string("' "))
)
let testNameParser: Parser<(open: String, name: String, close: String)> =
    Parser.choose(Parser.string("'-["), Parser.string("'")).flatMap { openDelim in
        zip(
            with: { name, closeDelim, _, _ in (open: openDelim, name: String(name), close: closeDelim) },
            prefix(until: openDelim == "'" ? { $0 == "'" } : { $0 == "]" }),
            openDelim == "'" ? Parser.string("'") : Parser.string("]'"),
            prefix(until: { $0 == "\n" }),
            Parser.literal("\n")
        )
    }

// Parser.discard(Parser.choose(Parser.literal("'-["), Parser.literal("'")), keep: Parser.keep(suiteAndCase, discard: Parser.choose(Parser.literal("]' "), Parser.literal("' "))))
let caseStartParser = Parser.discard(Parser.literal("Test Case "), keep: testNameParser)
let caseMessageParser = Parser.keep(
    Parser.star(
        Parser.discard(not(Parser.literal("Test Case")), keep: prefix(until: { $0 == "\n" })),
        separatedBy: Parser.literal("\n")
    ), discard: Parser.star(Parser.literal("\n"))
)
let caseParser: Parser<(String, [String], Either<String, Void>)> = caseStartParser.flatMap {
    caseNames in
    let caseFinishParser = Parser.discard(
        Parser.literal("Test Case \(caseNames.open)\(caseNames.name)\(caseNames.close) "),
        keep: Parser.keep(
            Parser.choice([Parser.string("passed"), Parser.string("failed"), Parser.string("skipped")]),
            discard: drop(while: { $0 != "\n" })
        )
    )
    let caseEndParser = Parser.either(
        caseFinishParser, Parser.discard(Parser.star(Parser.whitespace), keep: Parser.end)
    )
    let messageFinishParser = zip(caseMessageParser, caseEndParser).map { result in
        (caseNames.name, result.0.map { String($0) }, result.1)
    }
    return messageFinishParser
}

let testCaseParser = Parser.star(caseParser.map(TestCase.init), separatedBy: Parser.literal("\n"))

// MARK: - Test Suite Parsing

let suiteNameParser = Parser.keep(
    Parser.discard(Parser.literal("'"), keep: prefix(until: { $0 == "'" })),
    discard: Parser.literal("'")
)
let suiteLineParser =
    Parser.discard(Parser.literal("Test Suite "), keep: suiteNameParser)
let suiteStartParser = Parser.keep(
    Parser.discard(Parser.literal(" started at "), keep: prefix(until: { $0 == "\n" })),
    discard: Parser.literal("\n")
)

let openSuiteParser = zip(
    with: { name, startTime in
        (String(name), startTimeFormatter.date(from: String(startTime)) ?? Date())
    },
    suiteLineParser,
    suiteStartParser
)

let suiteParser = openSuiteParser.flatMap { nameAndDate -> Parser<TestSuite> in
    let closeParser =
        Parser.discard(
            Parser.literal("Test Suite '\(nameAndDate.0)' "),
            keep: Parser.choose(Parser.string("passed"), Parser.string("failed")).map { str in
                String(str.prefix(4))
            }
        )
    let skipLine = zip(prefix(until: { $0 == "\n" }), Parser.choose(Parser.literal("\n"), Parser.end))
    let endSuite = Parser.choose(
        Parser.keep(closeParser, discard: skipLine), Parser.end.flatMap { Parser.always("error") }
    )

    return Parser.keep(zip(testCaseParser.eatNewline(), endSuite), discard: skipLine).map {
        casesAndStatus -> TestSuite in
        let status = TestStatus(rawValue: casesAndStatus.1) ?? .error
        return TestSuite(
            name: nameAndDate.0, startTime: nameAndDate.1, status: status, cases: casesAndStatus.0
        )
    }
}

// MARK: - Package Suite Parser

let packageSuiteParser = openSuiteParser.flatMap { nameAndDate -> Parser<PackageSuite> in
    let closeParser =
        Parser.discard(
            Parser.literal("Test Suite '\(nameAndDate.0)' "),
            keep: Parser.choose(Parser.string("passed"), Parser.string("failed")).map { str in
                String(str.prefix(4))
            }
        )
    let skipLine = zip(prefix(until: { $0 == "\n" }), Parser.choose(Parser.literal("\n"), Parser.end))
    let endSuite = Parser.choose(
        Parser.keep(closeParser, discard: skipLine), Parser.end.flatMap { Parser.always("error") }
    )

    return Parser.keep(zip(Parser.plus(suiteParser), endSuite), discard: skipLine).map {
        suitesAndStatus -> PackageSuite in
        let status = TestStatus(rawValue: suitesAndStatus.1) ?? .error
        return PackageSuite(
            name: nameAndDate.0, startTime: nameAndDate.1, status: status, testSuites: suitesAndStatus.0
        )
    }
}

// MARK: - All Tests Parser

let allTestsParser = openSuiteParser.flatMap { nameAndDate -> Parser<TestResult> in
    let closeParser =
        Parser.discard(
            Parser.literal("Test Suite '\(nameAndDate.0)' "),
            keep: Parser.choose(Parser.string("passed"), Parser.string("failed")).map { str in
                String(str.prefix(4))
            }
        )
    let skipLine = zip(prefix(until: { $0 == "\n" }), Parser.choose(Parser.literal("\n"), Parser.end))
    //    let endSuite = Parser.keep(closeParser, discard: skipLine)
    let endSuite = Parser.choose(
        Parser.keep(closeParser, discard: skipLine), Parser.end.flatMap { Parser.always("error") }
    )

    return Parser.keep(zip(Parser.plus(packageSuiteParser), endSuite), discard: skipLine).map {
        packages -> TestResult in
        let status = TestStatus(rawValue: packages.1) ?? .error // == "passed" ? TestStatus.passed : .failed
        return TestResult(
            startTime: nameAndDate.1, status: status, testSuites: packages.0, message: nil
        )
    }
}

let stepLineParser = zip(
    Parser.literal("["),
    Parser.int,
    Parser.literal("/"),
    Parser.int,
    Parser.literal("]"),
    chomp(until: { $0 == "\n" }),
    Parser.literal("\n")
)

let stepFreeParser = Parser.discard(Parser.star(stepLineParser), keep: Parser.rest.map(String.init))
