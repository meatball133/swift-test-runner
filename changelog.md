# 1.1.1

- Fixed an issue causing help functions to be marked as test cases
- Made the output when writting a compile error shorter

# 1.1.0

- The test runner will run one test at a time, this is to be able to give a better error message when a test fails.
  - This may change in the future.
- Improved message handling for unimplemented tests.
- Improved message handling for non existing functions.
- Fixed so the test runner will give messaging for when test doesn't use `XCTAssertEqual`.
- Fixed so the test runner don't remove incorrect characters from test_code.
  - This was caused when a test runner had an if statement, then would the closing bracket be removed.
- Fixed so the test runner can now handle multiline assert statements (window system exercise).
- Fixed so the test runner will no longer output if an error occurred when running the test. 
- The test code will now be indented.
- Slight changes in formatting of the test runners source code.

# 1.0.1

- Fixed an environment variable with caused so only the first test was run.

# 1.0.0

- Initial release
- Add support for Swift 5.8
- Test code
- Task id
- Fixes and performance improvements
- Added so test will run in parallel
