#!/bin/bash
# 2>/dev/null -> envia os streams de erros vindos de stderror para descarte

ip route add 172.20.2.0/24 via 172.20.1.254 2>/dev/null

exec sleep infinity