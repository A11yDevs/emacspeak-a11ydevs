#!/usr/bin/env bash
# Script de teste para o pacote Emacspeak

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Testes do Pacote Emacspeak 60.0${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Contador de testes
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Função para executar teste
run_test() {
    local test_name="$1"
    local test_command="$2"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${YELLOW}[Teste $TOTAL_TESTS] $test_name${NC}"

    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ PASSOU${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗ FALHOU${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Teste 1: Verificar instalação do Emacspeak
run_test "Verificar diretório de instalação" \
    "[ -d /opt/emacspeak ]"

# Teste 2: Verificar arquivos principais
run_test "Verificar emacspeak-setup.el" \
    "[ -f /opt/emacspeak/lisp/emacspeak-setup.el ]"

# Teste 3: Verificar servidores TTS
run_test "Verificar servidor espeak" \
    "[ -f /opt/emacspeak/servers/espeak ]"

# Teste 4: Verificar servidor nativo espeak
run_test "Verificar servidor native-espeak" \
    "[ -f /opt/emacspeak/servers/native-espeak/libtclespeak.so ] || [ -d /opt/emacspeak/servers/native-espeak ]"

# Teste 5: Verificar sons
run_test "Verificar diretório de sons" \
    "[ -d /opt/emacspeak/sounds ]"

# Teste 6: Verificar XSL
run_test "Verificar diretório XSL" \
    "[ -d /opt/emacspeak/xsl ]"

# Teste 7: Verificar se Emacs está instalado
run_test "Verificar instalação do Emacs" \
    "which emacs"

# Teste 8: Verificar se espeak-ng está instalado
run_test "Verificar instalação do espeak-ng" \
    "which espeak-ng"

# Teste 9: Verificar se TCL está instalado
run_test "Verificar instalação do TCL" \
    "which tclsh"

# Teste 10: Tentar carregar Emacspeak no Emacs (teste básico)
run_test "Carregar Emacspeak no Emacs (sintaxe)" \
    "emacs --batch --eval '(progn (add-to-list (quote load-path) \"/opt/emacspeak/lisp\") (load \"/opt/emacspeak/lisp/emacspeak-preamble.el\"))' 2>&1 | grep -q 'Loading.*emacspeak-preamble'"

# Teste 11: Verificar permissões dos servidores
run_test "Verificar permissões executáveis dos servidores" \
    "[ -x /opt/emacspeak/servers/espeak ]"

# Teste 12: Verificar se espeak-ng funciona
run_test "Teste básico do espeak-ng" \
    "echo 'test' | espeak-ng --stdout > /dev/null 2>&1"

# Teste 13: Verificar estrutura de diretórios
run_test "Verificar estrutura de diretórios completa" \
    "[ -d /opt/emacspeak/lisp ] && [ -d /opt/emacspeak/servers ] && [ -d /opt/emacspeak/etc ]"

# Teste 14: Verificar configuração do usuário
run_test "Verificar configuração do Emacs" \
    "[ -f /root/.emacs.d/init.el ]"

# Teste 15: Verificar early-init.el
run_test "Verificar early-init.el" \
    "[ -f /root/.emacs.d/early-init.el ]"

# Teste 16: Verificar script de inicialização
run_test "Verificar script start-emacspeak.sh" \
    "[ -x /usr/local/bin/start-emacspeak.sh ]"

# Teste 17: Teste de sintaxe Elisp dos principais arquivos
echo -e "${YELLOW}[Teste $((TOTAL_TESTS + 1))] Verificar sintaxe de arquivos Elisp principais${NC}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))
elisp_errors=0
for elisp_file in /opt/emacspeak/lisp/emacspeak-{setup,preamble,speak}.el; do
    if [ -f "$elisp_file" ]; then
        if ! emacs --batch --eval "(condition-case err (progn (load \"$elisp_file\" nil t)) (error (message \"%s\" err) (kill-emacs 1)))" 2>&1 | grep -i error; then
            :
        else
            elisp_errors=$((elisp_errors + 1))
        fi
    fi
done

if [ $elisp_errors -eq 0 ]; then
    echo -e "  ${GREEN}✓ PASSOU${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "  ${RED}✗ FALHOU${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Teste 18: Verificar se pacote está instalado
run_test "Verificar instalação do pacote" \
    "dpkg -s emacspeak >/dev/null 2>&1"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Resultado dos Testes${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Total de testes: ${TOTAL_TESTS}"
echo -e "${GREEN}Testes passados: ${TESTS_PASSED}${NC}"
echo -e "${RED}Testes falhados: ${TESTS_FAILED}${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ Todos os testes passaram!${NC}"
    echo ""
    echo -e "${YELLOW}Informações do pacote:${NC}"
    dpkg -s emacspeak 2>/dev/null | grep -E "^(Package|Version|Status|Description):" || true
    echo ""
    exit 0
else
    echo -e "${RED}✗ Alguns testes falharam.${NC}"
    echo ""
    exit 1
fi
