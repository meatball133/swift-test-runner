#!/usr/bin/env bash
set -e

# Synopsis:
# Run the test runner on a solution using the test runner Docker image.
# The test runner Docker image is built automatically.

# Arguments:
# $1: exercise slug
# $2: absolute path to solution folder
# $3: absolute path to output directory

# Output:
# Writes the test results to a results.json file in the passed-in output directory.
# The test results are formatted according to the specifications at https://github.com/exercism/docs/blob/main/building/tooling/test-runners/interface.md

# Example:
# ./bin/run-in-docker.sh two-fer /absolute/path/to/two-fer/solution/folder/ /absolute/path/to/output/directory/

# If any required arguments is missing, print the usage and exit
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "usage: ./bin/run-in-docker.sh exercise-slug /absolute/path/to/solution/folder/ /absolute/path/to/output/directory/"
    exit 1
fi

SLUG="$1"
INPUT_DIR="${2%/}"
OUTPUT_DIR="${3%/}"

# Create the output directory if it doesn't exist
mkdir -p "${OUTPUT_DIR}"

# build docker image
docker build --rm -t exercism/swift-test-runner .

# run image passing the arguments
# TODO: support --read-only flag
docker run \
    --network none \
    --mount type=bind,src="${INPUT_DIR}",dst=/solution \
    --mount type=bind,src="${OUTPUT_DIR}",dst=/output \
    --mount type=volume,dst=/tmp \
    exercism/swift-test-runner $SLUG /solution/ /output/
