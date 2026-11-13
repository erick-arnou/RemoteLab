FROM debian:bookworm-slim

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    iptables \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoints/gateway-entrypoint.sh /usr/local/bin/gateway-entrypoint.sh

RUN chmod +x /usr/local/bin/gateway-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/gateway-entrypoint.sh"]