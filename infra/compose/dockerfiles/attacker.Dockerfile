FROM kalilinux/kali-rolling@sha256:6ec743d9fc5cd397451eeddeff3869bcfab5de9bd5dec5b1f34cbfbd80313073

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    nmap \
    hydra \
    sqlmap \
    metasploit-framework \
    netcat-traditional \
    iproute2 \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoints/attacker-entrypoint.sh /usr/local/bin/attacker-entrypoint.sh

RUN chmod +x /usr/local/bin/attacker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/attacker-entrypoint.sh"]