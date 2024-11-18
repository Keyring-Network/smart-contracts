# This Dockerfile builds upon the base image `core-v2:base` to set up the environment for compiling and running the core-v2 project.
# It compiles the Solidity contracts and includes all necessary project files for deployment and testing.

FROM core-v2:base

# Compile
COPY src ./src
RUN forge build

# Copy the remaining project files
COPY bin ./bin
COPY script ./script
COPY test ./test
COPY genesis.json .