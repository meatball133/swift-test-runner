FROM swift:latest AS builder
# WORKDIR /opt/testrunner
COPY src/testrunner ./

# Print Installed Swift Version
RUN swift --version
#RUN swift package clean
RUN swift build --configuration release

FROM swift:latest
WORKDIR /opt/test-runner/
COPY bin/ bin/
COPY --from=builder /.build/release/TestRunner bin/

ENV NAME RUNALL

ENTRYPOINT ["./bin/run.sh"]
