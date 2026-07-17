# No base image on purpose: the self-test proves the docker-build block, not a base image,
# and FROM scratch keeps the build free of external pulls. The non-root USER keeps the
# fixture clean under the security-iac-scan self-test.
FROM scratch
COPY hello.txt /hello.txt
USER 65534:65534
