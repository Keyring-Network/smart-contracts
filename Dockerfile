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
    pkg-config

# Install Foundry (Forge and Cast)
RUN curl -L https://foundry.paradigm.xyz | bash \
    && ~/.foundry/bin/foundryup

# Ensure the PATH includes Foundry binaries
ENV PATH="/root/.foundry/bin:${PATH}"

# Set up the project directory
WORKDIR /usr/src/app

# Copy the project files
COPY . .

# Initialize the Forge project
RUN forge install

# Expose the default JSON-RPC port
EXPOSE 8545

# Copy the deployment script
COPY deployunsafe.sh /usr/src/app/deploy.sh
RUN chmod +x /usr/src/app/deploy.sh

# Start Anvil and deploy contracts
CMD ["sh", "-c", "./deploy.sh"]