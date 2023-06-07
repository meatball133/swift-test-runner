FROM swift:5.8-bionic AS builder
# WORKDIR /opt/testrunner
COPY src/testrunner ./

# Print Installed Swift Version
RUN swift --version
#RUN swift package clean
RUN swift build --configuration release

FROM swift:5.8-bionic
WORKDIR /opt/test-runner/
COPY bin/ bin/
COPY --from=builder /.build/release/TestRunner bin/

RUN apk add --no-cache bash jq coreutils

ENV NAME RUNALL

ENTRYPOINT ["./bin/run.sh"]
