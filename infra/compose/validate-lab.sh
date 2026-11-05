#!/bin/bash
# validate-lab.sh - valida infraestrutura, gateway, roteamento e coleta de tráfego do lab
# Uso: cd infra/compose && chmod +x validate-lab.sh && ./validate-lab.sh
# Saída: um .txt por fase em docs/evidence/ (comando executado + resultado real)

set -u                                   # sem set -e: um teste que falha não aborta a bateria
PROJ="${PROJ:-compose}"                  # prefixo das redes (nome da pasta do compose)
OUT="${OUT:-../../docs/evidence}"
mkdir -p "$OUT"

phase() {  # $1=arquivo  $2=título  $3=o que a fase prova
  FILE="$OUT/$1.txt"
  { echo "# $2"; echo "# Objetivo: $3"; echo "# Data: $(date '+%F %T')"; echo; } > "$FILE"
  echo; echo "=== $2 ==="
}

run() {    # mostra o comando exato e grava comando + saída no arquivo da fase
  echo "\$ $1" | tee -a "$FILE"
  eval "$1" 2>&1 | tee -a "$FILE"
  echo | tee -a "$FILE"
}

ip_of() { docker inspect -f "{{(index .NetworkSettings.Networks \"${PROJ}_net-victim\").IPAddress}}" "$1" 2>/dev/null; }

DVWA=$(ip_of dvwa); JUICE=$(ip_of juice-shop); META=$(ip_of metasploitable)
if [ -z "$DVWA" ] || [ -z "$JUICE" ] || [ -z "$META" ]; then
  echo "ERRO: não achei os IPs das vítimas. Confira PROJ (atual: $PROJ) e se os containers estão em execução." >&2
  exit 1
fi

sudo -v || exit 1
# necessário no host para o LOG do iptables de dentro do container aparecer no dmesg
sudo sysctl -w net.netfilter.nf_log_all_netns=1 > /dev/null

# ---------------------------------------------------------------
phase 01-infraestrutura "Fase 1 - Infraestrutura" "Containers ativos e IPs nas três redes segmentadas"
run "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Networks}}'"
run "docker inspect -f '{{.Name}} {{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' attacker gateway dvwa juice-shop metasploitable"

# ---------------------------------------------------------------
phase 02-gateway "Fase 2 - Configuração do gateway" "Roteamento ativo, política deny-by-default, regras de LOG/ACCEPT e NAT"
run "docker exec gateway cat /proc/sys/net/ipv4/ip_forward"
run "docker exec gateway ip -br addr"
run "docker exec gateway iptables -L FORWARD -n -v --line-numbers"
run "docker exec gateway iptables -t nat -L POSTROUTING -n -v"

# ---------------------------------------------------------------
phase 03-roteamento "Fase 3 - Roteamento do atacante" "O tráfego do atacante para a rede vítima passa obrigatoriamente pelo gateway"
run "docker exec attacker ip route"
run "docker exec attacker ip route get $DVWA"

# ---------------------------------------------------------------
phase 04-conectividade "Fase 4 - Conectividade atacante -> vítimas" "Atacante alcança cada vítima atravessando o gateway"
run "docker exec attacker ping -c 3 $DVWA"
run "docker exec attacker ping -c 3 $JUICE"
run "docker exec attacker ping -c 3 $META"
run "docker exec attacker nc -zv -w 2 $DVWA 80"
run "docker exec attacker nc -zv -w 2 $JUICE 3000"

# ---------------------------------------------------------------
phase 05-deteccao-trafego "Fase 5 - Detecção de tráfego de ataque" "Scans do atacante são registrados pelo gateway (prefixo ATTACK-TRAFFIC) e contabilizados nas regras"
START=$(sudo dmesg | grep -c ATTACK-TRAFFIC)
new_logs() { sudo dmesg -T | grep ATTACK-TRAFFIC | tail -n +$((START + 1)); }   # só linhas geradas nesta execução
run "docker exec gateway iptables -Z FORWARD"
run "docker exec attacker nmap -sV -p 80 $DVWA"
run "docker exec attacker nmap -sV -p 3000 $JUICE"
run "docker exec attacker nmap -sT -p 21,22,23,80,445 $META"
run "docker exec attacker nmap -sT --top-ports 100 $META"
run "docker exec gateway iptables -L FORWARD -n -v --line-numbers"
run "new_logs | head -n 10"
run "new_logs | wc -l"
run "new_logs | grep -o 'DPT=[0-9]*' | sort | uniq -c | sort -rn | head -n 10"

# ---------------------------------------------------------------
phase 06-negacao-padrao "Fase 6 - Deny-by-default" "Tráfego não autorizado (vítima -> atacante) é descartado pelo gateway"
run "docker exec gateway iptables -Z FORWARD"
run "docker run --rm --cap-add NET_ADMIN --network ${PROJ}_net-victim --ip 172.20.2.50 alpine sh -c 'ip route add 172.20.1.0/24 via 172.20.2.254 && ping -c 2 -W 1 172.20.1.9'"
run "docker exec gateway iptables -L FORWARD -n -v | head -n 1"

echo
echo "Concluído. Evidências salvas em: $OUT"
ls -1 "$OUT"