.PHONY: help build test clean run-tests run-runtime install-scripts lint release automate validate test-integration

# Variáveis
IMAGE_BUILDER := emacspeak-builder:60.0
IMAGE_TESTER := emacspeak-tester:60.0
IMAGE_RUNTIME := emacspeak-runtime:60.0
OUTPUT_DIR := ./output

help: ## Mostra esta mensagem de ajuda
	@echo "Emacspeak 60.0 - Build de Pacotes Debian"
	@echo ""
	@echo "Comandos disponíveis:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

build: install-scripts ## Constrói o pacote Debian
	@echo "Construindo pacote Debian..."
	./scripts/build-package.sh

test: ## Executa a suite de testes
	@echo "Executando testes..."
	./scripts/run-tests.sh

run-tests: test ## Alias para 'test'

build-docker: ## Constrói imagens Docker (todas as stages)
	@echo "Construindo imagens Docker..."
	docker-compose build

build-builder: ## Constrói apenas a imagem builder
	@echo "Construindo imagem builder..."
	docker build --target builder -t $(IMAGE_BUILDER) .

build-tester: ## Constrói apenas a imagem tester
	@echo "Construindo imagem tester..."
	docker build --target tester -t $(IMAGE_TESTER) .

build-runtime: ## Constrói apenas a imagem runtime
	@echo "Construindo imagem runtime..."
	docker build --target runtime -t $(IMAGE_RUNTIME) .

run-runtime: ## Executa o container runtime interativamente
	@echo "Iniciando Emacspeak runtime..."
	docker-compose up -d runtime
	docker-compose exec runtime /usr/local/bin/start-emacspeak.sh

shell-runtime: ## Abre shell no container runtime
	@echo "Abrindo shell no runtime..."
	docker-compose run --rm runtime /bin/bash

shell-builder: ## Abre shell no container builder
	@echo "Abrindo shell no builder..."
	docker-compose run --rm builder /bin/bash

shell-tester: ## Abre shell no container tester
	@echo "Abrindo shell no tester..."
	docker-compose run --rm tester /bin/bash

install-scripts: ## Dá permissão de execução aos scripts
	@echo "Configurando permissões dos scripts..."
	@chmod +x scripts/*.sh

lint: ## Executa lintian nos pacotes gerados
	@echo "Executando lintian..."
	@if [ ! -f $(OUTPUT_DIR)/*.deb ]; then \
		echo "Nenhum pacote .deb encontrado em $(OUTPUT_DIR)/"; \
		echo "Execute 'make build' primeiro."; \
		exit 1; \
	fi
	docker run --rm -v "$(PWD)/$(OUTPUT_DIR):/packages" debian:trixie-slim bash -c \
		"apt-get update -qq && apt-get install -y -qq lintian && lintian /packages/*.deb"

clean: ## Remove artefatos de build e containers
	@echo "Limpando artefatos..."
	rm -rf $(OUTPUT_DIR)/*
	docker-compose down -v
	@echo "Limpeza concluída!"

clean-all: clean ## Remove tudo incluindo imagens Docker
	@echo "Removendo imagens Docker..."
	docker rmi $(IMAGE_BUILDER) $(IMAGE_TESTER) $(IMAGE_RUNTIME) 2>/dev/null || true
	@echo "Limpeza completa!"

list-packages: ## Lista pacotes gerados
	@echo "Pacotes em $(OUTPUT_DIR):"
	@ls -lh $(OUTPUT_DIR)/*.deb 2>/dev/null || echo "Nenhum pacote encontrado"

package-info: ## Mostra informações dos pacotes gerados
	@echo "Informações dos pacotes:"
	@for pkg in $(OUTPUT_DIR)/*.deb; do \
		if [ -f "$$pkg" ]; then \
			echo ""; \
			echo "=== $$(basename $$pkg) ==="; \
			dpkg-deb --info "$$pkg"; \
		fi; \
	done

release: build test lint ## Build completo + testes + lint
	@echo "Release pronto!"
	@echo ""
	@make list-packages

up: ## Inicia todos os serviços com docker-compose
	docker-compose up -d

down: ## Para todos os serviços
	docker-compose down

logs: ## Mostra logs dos containers
	docker-compose logs -f

status: ## Mostra status dos containers
	docker-compose ps

volumes: ## Lista volumes Docker criados
	@echo "Volumes Docker:"
	@docker volume ls | grep emacspeak || echo "Nenhum volume encontrado"

automate: install-scripts ## Executa build automatizado completo (build + testes)
	@echo "Executando build automatizado..."
	./scripts/automate-build.sh

validate: install-scripts ## Valida estrutura do projeto antes do build
	@echo "Validando estrutura do projeto..."
	./scripts/validate-prebuild.sh

test-integration: ## Executa testes de integração avançados
	@echo "Executando testes de integração..."
	./scripts/test-integration.sh

ci: validate automate ## Pipeline CI completo (validação + build + testes)
	@echo "Pipeline CI concluído!"

all: clean validate automate ## Build completo do zero
	@echo "Build completo concluído!"

# ══════════════════════════════════════════════════════════════════════════════
# APT Repository Management
# ══════════════════════════════════════════════════════════════════════════════

apt-repo: install-scripts ## Gera repositório APT local
	@echo "Gerando repositório APT..."
	@if [ ! -f $(OUTPUT_DIR)/emacspeak_*.deb ]; then \
		echo "Nenhum pacote .deb encontrado."; \
		echo "Execute 'make build' primeiro."; \
		exit 1; \
	fi
	./scripts/generate-apt-repo.sh $(OUTPUT_DIR) ./apt-repo
	@echo ""
	@echo "Repositório APT gerado em: ./apt-repo/debian"
	@echo "Próximo passo: make apt-sign KEY_ID=<your-key-id>"

apt-sign: install-scripts ## Assina o repositório APT (requer KEY_ID=...)
	@echo "Assinando repositório APT..."
	@if [ -z "$(KEY_ID)" ]; then \
		echo "Erro: KEY_ID não especificado."; \
		echo "Uso: make apt-sign KEY_ID=<your-gpg-key-id>"; \
		echo ""; \
		echo "Para listar suas chaves:"; \
		echo "  gpg --list-secret-keys --keyid-format=long"; \
		exit 1; \
	fi
	@if [ ! -d ./apt-repo/debian ]; then \
		echo "Repositório não encontrado. Execute 'make apt-repo' primeiro."; \
		exit 1; \
	fi
	./scripts/sign-repo.sh ./apt-repo $(KEY_ID)
	@echo ""
	@echo "Repositório assinado com sucesso!"

apt-clean: ## Remove repositório APT local
	@echo "Removendo repositório APT local..."
	rm -rf ./apt-repo
	@echo "Repositório removido!"

apt-verify: ## Verifica assinatura do repositório APT
	@echo "Verificando assinatura do repositório..."
	@if [ ! -f ./apt-repo/debian/dists/stable/Release.gpg ]; then \
		echo "Repositório não assinado. Execute 'make apt-sign' primeiro."; \
		exit 1; \
	fi
	gpg --verify ./apt-repo/debian/dists/stable/Release.gpg \
		./apt-repo/debian/dists/stable/Release
	@echo ""
	@echo "Assinatura válida!"

apt-full: build apt-repo ## Build + Gera repositório APT (sem assinar)
	@echo ""
	@echo "Repositório APT pronto para assinatura!"
	@echo "Execute: make apt-sign KEY_ID=<your-key-id>"
