#! /bin/bash -e

SOLUTION_DIR="${1:-dockerTest}"

# build docker image
docker build --rm --no-cache -t generic-test-runner .

docker run \
    --mount type=bind,src=$PWD/$SOLUTION_DIR/,dst=/solution \
    --mount type=bind,src=$PWD/$SOLUTION_DIR/output/,dst=/output \
    --entrypoint './bin/run-all.sh' generic-test-runner
