#! /bin/sh
set -e

test_root="${1:-/solution}"
output_dir="${2:-/output/}"

# echo "Output:"
# echo "${output_dir}"
# echo "Test root:"
# echo "${test_root}"

for testdir in "${test_root}"/*; do
    testname="$(basename $testdir)"
    # echo "testdir"
    # echo "${testdir}"
    # echo "testname"
    # echo "${testname}"
    # echo "-----------"
    if [ "$testname" != output ] && [ -f "${testdir}/results.json" ]; then
        bin/run.sh "$testname" "$test_root" "$output_dir"
    fi
done
