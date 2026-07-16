# No base image on purpose: the self-test proves the docker-build block, not a base image,
# and FROM scratch keeps the build free of external pulls.
FROM scratch
COPY hello.txt /hello.txt
