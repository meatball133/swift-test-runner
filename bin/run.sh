#! /bin/sh
set -e

# If arguments not provided, print usage and exit
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "usage: run.sh exercise-slug ./relative/path/to/solution/folder/ ./relative/path/to/output/directory/"
    exit 1
fi

SLUG="$1"
INPUT_DIR="$2"
OUTPUT_DIR="$3"

BASEDIR=$(dirname "$0")

# echo "$SLUG: testing..."
# echo "$1"
# echo "$2"
# echo "$3"
# echo "-------------"
RUNALL=true "${BASEDIR}"/TestRunner --slug "${SLUG}" --solution-directory "${INPUT_DIR}/${SLUG}" --output-directory "${OUTPUT_DIR}" --swift-location $(which swift) --build-directory "/tmp/"

#echo "$SLUG: processing test output in $INPUT_DIR..."
## PLACEHOLDER - OPTIONAL: Your language may support outputting results
##   in the correct format
#
# Create $OUTPUT_DIR if it doesn't exist
[ -d "$OUTPUT_DIR" ] || mkdir -p "$OUTPUT_DIR"
#
#echo "$SLUG: copying processed results to $OUTPUT_DIR..."
## PLACEHOLDER - OPTIONAL: Your language may support placing results
##   directly in $OUTPUT_DIR
#cp "${INPUT_DIR}/results.json" "$OUTPUT_DIR"

echo "$SLUG: comparing ${OUTPUT_DIR}/results"
diff "${INPUT_DIR}/${SLUG}/results.json" "${OUTPUT_DIR}/results.json"

echo "$SLUG: OK\n-------------\n"


