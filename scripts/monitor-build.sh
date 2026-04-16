#!/usr/bin/env bash
# Script para monitorar o progresso do build

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOG_DIR="${PROJECT_ROOT}/logs"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    Monitor de Build - Emacspeak      ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════╝${NC}"
echo ""

# Encontra o log mais recente
LATEST_LOG=$(ls -t "${LOG_DIR}"/build_*.log 2>/dev/null | head -1)

if [[ -z "$LATEST_LOG" ]]; then
    echo -e "${YELLOW}Nenhum log de build encontrado.${NC}"
    echo "Inicie um build com: ./scripts/automate-build.sh"
    exit 1
fi

echo -e "${GREEN}Monitorando:${NC} $(basename "$LATEST_LOG")"
echo ""
echo "Progresso atual:"
echo "─────────────────────────────────────"

# Mostra progresso
if [[ -f "$LATEST_LOG" ]]; then
    # Conta passos completados
    passos_concluidos=$(grep -c "✓.*OK$" "$LATEST_LOG" || echo "0")
    passos_falhados=$(grep -c "✗.*FALHOU$" "$LATEST_LOG" || echo "0")

    echo -e "${GREEN}Passos completados:${NC} $passos_concluidos"
    echo -e "${YELLOW}Passos falhados:${NC} $passos_falhados"
    echo ""

    # Mostra últimas linhas do log
    echo "Últimas atividades:"
    echo "─────────────────────────────────────"
    tail -15 "$LATEST_LOG" | sed 's/\[20.*\] \[INFO\] /  • /' | sed 's/\[20.*\] \[ERROR\] /  ✗ /'
    echo ""

    # Verifica se ainda está rodando
    if pgrep -f "automate-build.sh" > /dev/null; then
        echo -e "${BLUE}Status:${NC} ${GREEN}Rodando...${NC}"
        echo ""
        echo "Para ver o log completo:"
        echo "  tail -f $LATEST_LOG"
    else
        if grep -q "BUILD E TESTES CONCLUÍDOS COM SUCESSO" "$LATEST_LOG"; then
            echo -e "${GREEN}Status: ✓ Concluído com sucesso!${NC}"
        elif grep -q "ALGUNS PASSOS FALHARAM" "$LATEST_LOG"; then
            echo -e "${YELLOW}Status: ⚠ Concluído com falhas${NC}"
        else
            echo -e "${YELLOW}Status: Build finalizado${NC}"
        fi
    fi
else
    echo "Log não encontrado."
fi

echo ""
