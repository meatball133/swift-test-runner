import ArgumentParser
import Foundation

struct RunnerOptions: ParsableArguments {
  @Option()
  var slug: String

  @Option()
  var solutionDirectory: String

  @Option()
  var outputDirectory: String

  @Option()
  var swiftLocation: String

  @Option()
  var buildDirectory: String

  @Flag()
  var showSkipped: Bool
}

// macOS test options
//  let options = 
//     RunnerOptions.parseOrExit(
//         ["--slug", "multiple-tests-with-exception"
//         , "--solution-directory", "/Users/wdn/Documents/Dev/Exercism/Utilities/swift-test-runner/testrunner/testfiles/"
//         , "--output-directory", "/Users/wdn/Documents/Dev/tmp/output"
//         , "--swift-location", "/usr/bin/swift"
//         , "--build-directory", "/Users/wdn/Documents/Dev/tmp/"
//         ]
//     )
// linux test options
// let options = 
//     RunnerOptions.parseOrExit(
//         ["--slug", "multiple-tests-all-pass"
//         , "--solution-directory", "/home/wdn/dev/exercism/utilities/swift-test-runner/testrunner/testfiles"
//         , "--output-directory", "/home/wdn/dev/tmp/output"
//         , "--swift-location", "/home/wdn/Library/swift/usr/bin/swift"
//         ,"--build-directory", "/home/wdn/dev/tmp/"
//         ]
//     )
let options = RunnerOptions.parseOrExit()
print(options)

let tempDir = URL(fileURLWithPath: options.buildDirectory, isDirectory: true)
  .appendingPathComponent(UUID().uuidString, isDirectory: true)
print("tempDir: \(tempDir.absoluteString)")

guard
  let _ = try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
else {
  print("Could not create temp directory: \(tempDir.path)")
  exit(1)
}
defer {
  do {
    try FileManager.default.removeItem(at: tempDir)
  } catch {
    print(error)
    exit(1)
  }
}

let process = Process()
#if os(macOS)
  var testFileRoot = options.solutionDirectory
  process.launchPath = options.swiftLocation
  process.currentDirectoryPath = testFileRoot + options.slug
#else
  var testFileRoot = URL(fileURLWithPath: options.solutionDirectory)
  process.executableURL = URL(fileURLWithPath: options.swiftLocation)
  process.currentDirectoryURL = testFileRoot.appendingPathComponent(options.slug)
#endif

process.arguments = ["test", "--build-path", tempDir.path]

let combinedPipe = Pipe()
let outPipe = Pipe()
process.standardOutput = combinedPipe
let errPipe = Pipe()
process.standardError = combinedPipe

do {
  if #available(macOS 10.13, *) {
    try process.run()
  } else {
    process.launch()
  }

  let comboData = combinedPipe.fileHandleForReading.readDataToEndOfFile()
  guard let comboOutput = String(data: comboData, encoding: .utf8) else {
    fatalError("comboData Malformed")
  }

  let stepFreeOutput = try stepFreeParser.run(comboOutput).match.get()

  let testResult: TestResult
  switch allTestsParser.run(stepFreeOutput).match {
  case let .success(result):
    testResult = result
  case .failure:
    testResult = TestResult(
      startTime: Date(), status: .error, testSuites: [], message: stepFreeOutput)
  }

  let jenc = JSONEncoder()
  jenc.outputFormatting.update(with: .prettyPrinted)
  #if os(macOS)
    if #available(macOS 10.13, *) {
      jenc.outputFormatting.update(with: .sortedKeys)
    }
  #else
    jenc.outputFormatting.update(with: .sortedKeys)
  #endif
  let jData = try jenc.encode(options.showSkipped ? testResult : testResult.dropSkips)

  let outputFile = URL(fileURLWithPath: options.outputDirectory, isDirectory: true)
    .appendingPathComponent("results.json", isDirectory: false)
  try jData.write(to: outputFile)

  if let jStr = String(data: jData, encoding: .utf8) { print(jStr) }
} catch {
  print(error)
  exit(1)
}
