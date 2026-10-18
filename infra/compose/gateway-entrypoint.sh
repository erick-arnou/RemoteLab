#!/bin/bash

set -e                                                                                                      #para tudo, se falhar

[ "$(cat /proc/sys/net/ipv4/ip_forward)" = "1" ] || { echo "ERRO: ip_forward desligado" >&2; exit 1; }

iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT                                          #troca de pacotes liberada para atacante -> vítima -> atacante

iptables -P FORWARD DROP                                                                                    #deny by default

#regras usando o iptables
iptables -A FORWARD -s 172.20.1.0/24 -d 172.20.2.0/24 -j LOG --log-prefix "ATTACK-TRAFFIC: "                #ATTACK-TRAFFIC para facilitar a filtragem
iptables -A FORWARD -s 172.20.1.0/24 -d 172.20.2.0/24 -j ACCEPT

iptables -t nat -A POSTROUTING -s 172.20.1.0/24 -d 172.20.2.0/24 -j MASQUERADE

exec sleep infinity