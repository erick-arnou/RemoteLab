FROM kalilinux/kali-rolling

RUN apt-get update && apt-get install -y \
    nmap \
    hydra \
    sqlmap \
    metasploit-framework \
    netcat-traditional \
    iputils-ping \
    && apt-get clean

    # modo standard mantendo o container ocioso
CMD ["sleep", "infinity"]