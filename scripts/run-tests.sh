#!/usr/bin/env bash
# Script conveniente para executar testes no container Docker

set -euo pipefail

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

IMAGE_NAME="emacspeak-builder-test"
IMAGE_TAG="60.0"

echo -e "${GREEN}Executando testes do Emacspeak no container Docker...${NC}"
echo ""

if ! docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" > /dev/null 2>&1; then
    echo -e "${YELLOW}Imagem de teste não encontrada. Construindo...${NC}"
    docker build --target tester -t "${IMAGE_NAME}:${IMAGE_TAG}" .
fi

echo -e "${YELLOW}Iniciando testes...${NC}"
echo ""

docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}"

exit $?
