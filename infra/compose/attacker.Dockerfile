FROM kalilinux/kali-rolling

RUN apt-get update && apt-get install -y \
    nmap \
    hydra \
    sqlmap \
    metasploit-framework \
    netcat-traditional \
    iproute2 \
    iputils-ping \
    && apt-get clean

COPY attacker-entrypoint.sh /usr/local/bin/attacker-entrypoint.sh

RUN chmod +x /usr/local/bin/attacker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/attacker-entrypoint.sh"]