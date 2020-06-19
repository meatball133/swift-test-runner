FROM swift:latest AS builder
# WORKDIR /opt/testrunner
COPY testrunner ./

# Print Installed Swift Version
RUN swift --version
#RUN swift package clean
RUN swift build --configuration release

FROM swift:latest
WORKDIR /opt/test-runner/
COPY --from=builder /.build/release/TestRunner bin/
COPY run.sh bin/

ENV NAME RUNALL

# ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
# ENTRYPOINT ["bin/TestRunner", "--help"]
