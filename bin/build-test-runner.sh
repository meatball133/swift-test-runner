#!/usr/bin/env bash

# Synopsis:
# Build the test runner

# Output:
# Build the test runner file needed to run the test runner

# Example:
# ./bin/build-test-runner.sh

BIN_DIR="bin"
BUILD_DIR="src/testrunner"
RELEASE_DIR=".build/release"

# Build the test runner file
cd "$BUILD_DIR"
swift build  --configuration release
cd -

# Copy generated file to bin dir
cp "$BUILD_DIR/$RELEASE_DIR/TestRunner" "$BIN_DIR"/