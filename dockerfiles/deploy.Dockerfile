# Use a lightweight base image
FROM ubuntu:20.04

# Set the timezone to UTC non-interactively
ENV TZ=Etc/UTC
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    tzdata \
    curl \
    git \
    build-essential \
    libssl-dev \
    pkg-config \
    jq \
    openssl \
    xxd

# Install Foundry (Forge and Cast)
RUN curl -L https://foundry.paradigm.xyz | bash \
    && ~/.foundry/bin/foundryup

# Ensure the PATH includes Foundry binaries
ENV PATH="/root/.foundry/bin:${PATH}"

# Set up the project directory
WORKDIR /usr/src/app

# Copy only the necessary files for the initial setup
COPY foundry.toml .
COPY genesis.json .
COPY lib ./lib
COPY src ./src

# Copy the .git directory to ensure forge install works correctly
COPY .git .git

# Initialize the Forge project
RUN forge install && forge build

# Copy the remaining project files
COPY bin ./bin
COPY dockerfiles ./dockerfiles
COPY script ./script
COPY test ./test
COPY utils ./utils
COPY README.md .

# Expose the default JSON-RPC port
EXPOSE 8545