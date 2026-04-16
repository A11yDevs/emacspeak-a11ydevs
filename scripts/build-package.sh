#!/usr/bin/env bash
# Script para construir pacotes Debian do Emacspeak 30.0

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Build de Pacote Debian - Emacspeak 60.0${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Verificar se estamos no diretório correto
if [ ! -f "Dockerfile" ]; then
    echo -e "${RED}Erro: Dockerfile não encontrado!${NC}"
    echo "Execute este script do diretório raiz do projeto."
    exit 1
fi

# Variáveis
IMAGE_NAME="emacspeak-builder"
IMAGE_TAG="60.0"
CONTAINER_NAME="emacspeak-build-$$"
OUTPUT_DIR="./output"

# Criar diretório de saída
mkdir -p "$OUTPUT_DIR"

echo -e "${YELLOW}[1/4] Construindo imagem Docker...${NC}"
docker build --target builder -t "${IMAGE_NAME}:${IMAGE_TAG}" .

echo -e ""
echo -e "${YELLOW}[2/4] Extraindo pacotes .deb...${NC}"
TEMP_CONTAINER=$(docker create "${IMAGE_NAME}:${IMAGE_TAG}")
docker cp "${TEMP_CONTAINER}:/build/" "$OUTPUT_DIR/"
docker rm "${TEMP_CONTAINER}"

# Mover os .deb para o diretório output
find "$OUTPUT_DIR/build/" -name "*.deb" -exec mv {} "$OUTPUT_DIR/" \;
find "$OUTPUT_DIR/build/" -name "*.buildinfo" -exec mv {} "$OUTPUT_DIR/" \;
find "$OUTPUT_DIR/build/" -name "*.changes" -exec mv {} "$OUTPUT_DIR/" \;

echo -e ""
echo -e "${YELLOW}[3/4] Executando lintian nos pacotes...${NC}"
docker run --rm -v "$(pwd)/$OUTPUT_DIR:/packages" debian:trixie-slim bash -c "
    apt-get update -qq && apt-get install -y -qq lintian > /dev/null 2>&1
    for deb in /packages/*.deb; do
        echo \"Verificando: \$(basename \$deb)\"
        lintian \$deb || true
    done
"

echo -e ""
echo -e "${YELLOW}[4/4] Construindo imagem de teste...${NC}"
docker build --target tester -t "${IMAGE_NAME}-test:${IMAGE_TAG}" .

echo -e ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Build concluído com sucesso!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Pacotes gerados em: ${YELLOW}$OUTPUT_DIR/${NC}"
echo ""
ls -lh "$OUTPUT_DIR"/*.deb 2>/dev/null || echo "Nenhum pacote .deb encontrado"
echo ""
echo -e "Para testar o pacote, execute:"
echo -e "  ${YELLOW}./scripts/test-package.sh${NC}"
echo ""
echo -e "Para executar interativamente:"
echo -e "  ${YELLOW}docker run -it --rm ${IMAGE_NAME}-test:${IMAGE_TAG} /bin/bash${NC}"
echo ""
