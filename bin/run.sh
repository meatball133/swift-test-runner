#!/usr/bin/env bash

# Synopsis:
# Run the test runner on a solution.

# Arguments:
# $1: exercise slug
# $2: absolute path to solution folder
# $3: absolute path to output directory

# Output:
# Writes the test results to a results.json file in the passed-in output directory.
# The test results are formatted according to the specifications at https://github.com/exercism/docs/blob/main/building/tooling/test-runners/interface.md

# Example:
# ./bin/run.sh two-fer /absolute/path/to/two-fer/solution/folder/ /absolute/path/to/output/directory/

# If any required arguments is missing, print the usage and exit
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "usage: ./bin/run.sh exercise-slug /absolute/path/to/two-fer/solution/folder/ /absolute/path/to/output/directory/"
    exit 1
fi

SLUG="$1"
INPUT_DIR="${2%/}"
OUTPUT_DIR="${3%/}"
junit_file="${INPUT_DIR}/results.xml"
capture_file="${OUTPUT_DIR}/capture"
spec_file="${INPUT_DIR}/$(jq -r '.files.test[0]' ${INPUT_DIR}/.meta/config.json)"
results_file="${OUTPUT_DIR}/results.json"
BASEDIR=$(dirname "$0")

touch "${results_file}"
start=`date +%s`
swift test --package-path "${INPUT_DIR}" -v --parallel  --xunit-output "${junit_file}" &> "${capture_file}"
echo "hi"

./bin/TestRunner "${spec_file}" "${junit_file}" "${capture_file}" "${results_file}"
end=`date +%s`
runtime=$((end-start))
echo "${runtime}"