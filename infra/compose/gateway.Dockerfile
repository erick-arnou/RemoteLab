FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    iptables \
    iproute2 \
    && apt-get clean

COPY gateway-entrypoint.sh /usr/local/bin/gateway-entrypoint.sh

RUN chmod +x /usr/local/bin/gateway-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/gateway-entrypoint.sh"]