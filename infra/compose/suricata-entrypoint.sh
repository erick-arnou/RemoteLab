#!/bin/sh

#ESSE ARQUIVO FOI GERADO USANDO INTELIGÊNCIA ARTIFICIAL E ESTÁ PREVISTO SEU USO NO TÓPICO 4 DO DOCUMENTO OFICIAL DO PROJETO.  

set -e

# 172.20.1.0/24 em hexadecimal "little-endian", como aparece em /proc/net/route
DEST=$(printf '%02X%02X%02X%02X' 0 1 20 172)

# o gateway pode demorar um instante para ligar as interfaces: tenta por até 30 s
IFACE=""
n=0
while [ "$n" -lt 30 ]; do
  IFACE=$(while read -r i d _; do [ "$d" = "$DEST" ] && { echo "$i"; break; }; done < /proc/net/route)
  [ -n "$IFACE" ] && break
  n=$((n + 1)); sleep 1
done

[ -n "$IFACE" ] || { echo "ERRO: interface da rede 172.20.2.0/24 não encontrada" >&2; exit 1; }

echo "Suricata escutando em $IFACE"
# o -k none evita descartar pacotes por causa do checksum offload em interfaces virtuais
exec /docker-entrypoint.sh -i "$IFACE" -k none