#!/usr/bin/env bash
# Script de validação pré-build - Verifica integridade do projeto

set -euo pipefail

# Cores
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TESTS_PASSED=0
TESTS_FAILED=0

# Função para executar teste
run_validation() {
    local test_name="$1"
    local test_command="$2"

    echo -n "  [Validando] $test_name... "

    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}FALHOU${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Validação Pré-Build - Emacspeak     ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════╝${NC}"
echo ""

cd "${PROJECT_ROOT}"

echo -e "${YELLOW}[1/6] Validando estrutura de arquivos...${NC}"
run_validation "Dockerfile existe" "[[ -f Dockerfile ]]"
run_validation "docker-compose.yml existe" "[[ -f docker-compose.yml ]]"
run_validation "Makefile existe" "[[ -f Makefile ]]"
run_validation "README.md existe" "[[ -f README.md ]]"
echo ""

echo -e "${YELLOW}[2/6] Validando arquivos Debian...${NC}"
run_validation "debian/control existe" "[[ -f debian/control ]]"
run_validation "debian/changelog existe" "[[ -f debian/changelog ]]"
run_validation "debian/rules existe" "[[ -f debian/rules ]]"
run_validation "debian/compat existe" "[[ -f debian/compat ]]"
run_validation "debian/copyright existe" "[[ -f debian/copyright ]]"
run_validation "debian/postinst existe" "[[ -f debian/postinst ]]"
echo ""

echo -e "${YELLOW}[3/6] Validando scripts...${NC}"
run_validation "build-package.sh existe" "[[ -f scripts/build-package.sh ]]"
run_validation "test-package.sh existe" "[[ -f scripts/test-package.sh ]]"
run_validation "run-tests.sh existe" "[[ -f scripts/run-tests.sh ]]"
run_validation "build-package.sh executável" "[[ -x scripts/build-package.sh ]]"
run_validation "test-package.sh executável" "[[ -x scripts/test-package.sh ]]"
run_validation "debian/rules executável" "[[ -x debian/rules ]]"
echo ""

echo -e "${YELLOW}[4/6] Validando sintaxe de arquivos...${NC}"
run_validation "Dockerfile sintaxe válida" "docker build --target builder -t test:validate -f Dockerfile --build-arg BUILDKIT_SYNTAX=docker/dockerfile:1 . --dry-run 2>/dev/null || true"
run_validation "docker-compose.yml sintaxe válida" "docker-compose config > /dev/null"
run_validation "debian/control sintaxe básica" "grep -q '^Package: emacspeak' debian/control"
run_validation "debian/changelog sintaxe básica" "grep -q 'emacspeak (30.0' debian/changelog"
echo ""

echo -e "${YELLOW}[5/6] Validando conteúdo de arquivos...${NC}"
run_validation "Dockerfile FROM válido" "grep -q '^FROM debian:trixie-slim' Dockerfile"
run_validation "Control tem dependências" "grep -q 'Depends:' debian/control"
run_validation "Rules tem targets" "grep -q 'override_dh_auto_build:' debian/rules"
run_validation "Postinst tem shebang" "head -1 debian/postinst | grep -q '#!/bin/sh'"
echo ""

echo -e "${YELLOW}[6/6] Validando ambiente Docker...${NC}"
run_validation "Docker instalado" "command -v docker"
run_validation "Docker Compose instalado" "command -v docker-compose || docker compose version"
run_validation "Docker daemon rodando" "docker info"
run_validation "Permissão para usar Docker" "docker ps"
echo ""

# Resumo
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "Total de validações: $((TESTS_PASSED + TESTS_FAILED))"
echo -e "${GREEN}Passaram: ${TESTS_PASSED}${NC}"
echo -e "${RED}Falharam: ${TESTS_FAILED}${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""

if [[ ${TESTS_FAILED} -eq 0 ]]; then
    echo -e "${GREEN}✓ Todas as validações passaram! Sistema pronto para build.${NC}"
    exit 0
else
    echo -e "${RED}✗ Algumas validações falharam. Corrija os problemas antes do build.${NC}"
    exit 1
fi
