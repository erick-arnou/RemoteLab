#!/bin/bash
set -e

[ "$(cat /proc/sys/net/ipv4/ip_forward)" = "1" ] || { echo "ERRO: ip_forward desligado" >&2; exit 1; }

iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -s 172.20.1.0/24 -d 172.20.2.0/24 -m conntrack --ctstate NEW -j LOG --log-prefix "ATTACK-TRAFFIC: "
iptables -A FORWARD -s 172.20.1.0/24 -d 172.20.2.0/24 -j ACCEPT
iptables -P FORWARD DROP

iptables -t nat -A POSTROUTING -s 172.20.1.0/24 -d 172.20.2.0/24 -j MASQUERADE

exec sleep infinity