FROM busybox AS fetcher

# https://docs.codeclimate.com/docs/configuring-test-coverage#section-locations-of-pre-built-binaries
RUN wget https://codeclimate.com/downloads/test-reporter/test-reporter-0.6.3-linux-amd64 -O test-reporter
WORKDIR /
RUN chmod +x test-reporter

FROM scratch
WORKDIR /
COPY --from=fetcher /test-reporter .
ENTRYPOINT ["/test-reporter"]
