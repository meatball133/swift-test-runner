FROM swift:5.5.3-bionic AS builder
# WORKDIR /opt/testrunner
COPY src/testrunner ./

# Print Installed Swift Version
RUN swift --version
#RUN swift package clean
RUN swift build --configuration release

FROM swift:5.5.3-bionic
WORKDIR /opt/test-runner/
COPY bin/ bin/
COPY --from=builder /.build/release/TestRunner bin/

ENV NAME RUNALL

ENTRYPOINT ["./bin/run.sh"]
