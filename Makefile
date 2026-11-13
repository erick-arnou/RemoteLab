#variáveis

COMPOSE_DIR := infra/compose
COMPOSE     := docker compose -f $(COMPOSE_DIR)/docker-compose.yaml

# Nos comandos que não sobem o ambiente, ativamos todos os perfis ("*").
ALL := $(COMPOSE) --profile "*"

.DEFAULT_GOAL := help
.PHONY: help up up-core up-full down build restart logs ps clean


#comandos de automação

up: up-core ## sobe o ambiente mínimo (atalho de up-core)

up-core: ## sobe o ambiente mínimo (gateway + suricata + attacker + dvwa)
	$(COMPOSE) --profile core up -d

up-full: ## sobe o ambiente completo
	$(COMPOSE) --profile full up -d

down: ## derruba containers e redes
	$(ALL) down

clean: ## derruba tudo, incluindo volumes
	$(ALL) down -v

build: ## build das imagens
	$(ALL) build

restart: ## reinicia um serviço, ex: make restart svc=suricata
	$(ALL) restart $(svc)

logs: ## logs de um serviço, ex: make logs svc=suricata
	$(ALL) logs -f $(svc)

ps: ## lista os containers
	$(ALL) ps -a

help: ## lista os comandos
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'