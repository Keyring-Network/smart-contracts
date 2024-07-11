# This Dockerfile extends the core-v2:latest image to configure and run a local Anvil testnet node.

FROM core-v2:latest

ENV ANVIL_CHAIN=1337
ENV ANVIL_PORT=8545
ENV ANVIL_DNS=0.0.0.0

EXPOSE $ANVIL_PORT

ENTRYPOINT [ \
    "/bin/bash", "-c", \
    "./bin/testnet-config.sh \
            --host ${ANVIL_DNS} \
            --port ${ANVIL_PORT} \
            --chain ${ANVIL_CHAIN} \
            --genesis ./genesis.json \
        && tail -f /dev/null" \
]