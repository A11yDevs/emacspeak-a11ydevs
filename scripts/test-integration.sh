#!/usr/bin/env bash
# Testes de integração avançados para o pacote Emacspeak

set -euo pipefail

# Cores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
TOTAL_TESTS=0

# Função para executar teste
run_integration_test() {
    local test_name="$1"
    local test_command="$2"
    local optional="${3:-false}"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${YELLOW}[Teste $TOTAL_TESTS]${NC} $test_name"

    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ PASSOU${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        if [[ "$optional" == "true" ]]; then
            echo -e "  ${BLUE}○ PULADO (teste opcional)${NC}"
            TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
            return 0
        else
            echo -e "  ${RED}✗ FALHOU${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    fi
}

# Função para teste com output
run_test_with_output() {
    local test_name="$1"
    local test_command="$2"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${YELLOW}[Teste $TOTAL_TESTS]${NC} $test_name"

    local output
    if output=$(eval "$test_command" 2>&1); then
        echo -e "  ${GREEN}✓ PASSOU${NC}"
        if [[ -n "$output" ]]; then
            echo "  Output: $output"
        fi
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗ FALHOU${NC}"
        if [[ -n "$output" ]]; then
            echo "  Erro: $output"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Testes de Integração - Emacspeak 60.0             ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# SEÇÃO 1: Verificação de Instalação
# ============================================================================
echo -e "${BLUE}═══ Seção 1: Verificação de Instalação ═══${NC}"
echo ""

run_integration_test \
    "Verificar pacote emacspeak instalado" \
    "dpkg -l | grep -q emacspeak"

run_integration_test \
    "Verificar diretório base /opt/emacspeak" \
    "[[ -d /opt/emacspeak ]]"

run_integration_test \
    "Verificar diretório lisp" \
    "[[ -d /opt/emacspeak/lisp ]]"

run_integration_test \
    "Verificar diretório servers" \
    "[[ -d /opt/emacspeak/servers ]]"

run_integration_test \
    "Verificar diretório sounds" \
    "[[ -d /opt/emacspeak/sounds ]]"

echo ""

# ============================================================================
# SEÇÃO 2: Arquivos Críticos
# ============================================================================
echo -e "${BLUE}═══ Seção 2: Arquivos Críticos ═══${NC}"
echo ""

run_integration_test \
    "Verificar emacspeak-setup.el" \
    "[[ -f /opt/emacspeak/lisp/emacspeak-setup.el ]]"

run_integration_test \
    "Verificar emacspeak-preamble.el" \
    "[[ -f /opt/emacspeak/lisp/emacspeak-preamble.el ]]"

run_integration_test \
    "Verificar servidor espeak" \
    "[[ -f /opt/emacspeak/servers/espeak ]]"

run_integration_test \
    "Verificar servidor espeak executável" \
    "[[ -x /opt/emacspeak/servers/espeak ]]"

run_integration_test \
    "Verificar servidor espeak-socat" \
    "[[ -f /opt/emacspeak/servers/espeak-socat ]]" \
    "true"

echo ""

# ============================================================================
# SEÇÃO 3: Dependências do Sistema
# ============================================================================
echo -e "${BLUE}═══ Seção 3: Dependências do Sistema ═══${NC}"
echo ""

run_test_with_output \
    "Verificar Emacs instalado e versão" \
    "emacs --version | head -1"

run_integration_test \
    "Verificar espeak-ng instalado" \
    "command -v espeak-ng"

run_integration_test \
    "Verificar tclsh instalado" \
    "command -v tclsh"

run_integration_test \
    "Verificar biblioteca TCL" \
    "dpkg -l | grep -q tclx"

echo ""

# ============================================================================
# SEÇÃO 4: Testes Funcionais do Emacs
# ============================================================================
echo -e "${BLUE}═══ Seção 4: Testes Funcionais do Emacs ═══${NC}"
echo ""

run_integration_test \
    "Emacs consegue iniciar em batch mode" \
    "emacs --batch --eval '(message \"OK\")'"

run_integration_test \
    "Emacs consegue carregar emacspeak-preamble" \
    "emacs --batch --eval '(progn (add-to-list \'load-path \"/opt/emacspeak/lisp\") (load \"/opt/emacspeak/lisp/emacspeak-preamble\"))'"

run_integration_test \
    "Verificar variáveis do Emacspeak estão definidas" \
    "emacs --batch --eval '(progn (add-to-list \'load-path \"/opt/emacspeak/lisp\") (load \"/opt/emacspeak/lisp/emacspeak-preamble\") (unless (boundp \'emacspeak-version) (kill-emacs 1)))'"

echo ""

# ============================================================================
# SEÇÃO 5: Testes de Compilação Nativa
# ============================================================================
echo -e "${BLUE}═══ Seção 5: Testes de Compilação Nativa ═══${NC}"
echo ""

run_integration_test \
    "Verificar diretório .eln existe" \
    "[[ -d /opt/emacspeak/eln ]]" \
    "true"

run_integration_test \
    "Verificar arquivos .eln compilados" \
    "[[ -n \$(find /opt/emacspeak/eln -name '*.eln' 2>/dev/null) ]]" \
    "true"

run_integration_test \
    "Verificar configuração early-init.el" \
    "[[ -f /root/.emacs.d/early-init.el ]]"

run_integration_test \
    "Verificar configuração init.el" \
    "[[ -f /root/.emacs.d/init.el ]]"

echo ""

# ============================================================================
# SEÇÃO 6: Testes de TTS (Sintetizador)
# ============================================================================
echo -e "${BLUE}═══ Seção 6: Testes de TTS ═══${NC}"
echo ""

run_integration_test \
    "espeak-ng consegue gerar output" \
    "echo 'test' | espeak-ng --stdout > /dev/null"

run_integration_test \
    "Verificar biblioteca espeak-ng" \
    "dpkg -l | grep -q libespeak-ng"

run_integration_test \
    "Verificar dados do espeak-ng" \
    "dpkg -l | grep -q espeak-ng-data"

echo ""

# ============================================================================
# SEÇÃO 7: Testes de Permissões e Segurança
# ============================================================================
echo -e "${BLUE}═══ Seção 7: Testes de Permissões ═══${NC}"
echo ""

run_integration_test \
    "Diretório /opt/emacspeak legível" \
    "[[ -r /opt/emacspeak ]]"

run_integration_test \
    "Arquivos .el legíveis" \
    "[[ -r /opt/emacspeak/lisp/emacspeak-setup.el ]]"

run_integration_test \
    "Servidores TTS executáveis" \
    "[[ -x /opt/emacspeak/servers/espeak ]]"

echo ""

# ============================================================================
# SEÇÃO 8: Testes de Configuração
# ============================================================================
echo -e "${BLUE}═══ Seção 8: Testes de Configuração ═══${NC}"
echo ""

run_integration_test \
    "Script start-emacspeak.sh existe" \
    "[[ -f /usr/local/bin/start-emacspeak.sh ]]" \
    "true"

run_integration_test \
    "Script start-emacspeak.sh executável" \
    "[[ -x /usr/local/bin/start-emacspeak.sh ]]" \
    "true"

run_integration_test \
    "Variável DTK_PROGRAM definida" \
    "[[ -n \"\${DTK_PROGRAM:-}\" ]]" \
    "true"

echo ""

# ============================================================================
# SEÇÃO 9: Testes de Integridade de Arquivos
# ============================================================================
echo -e "${BLUE}═══ Seção 9: Testes de Integridade ═══${NC}"
echo ""

run_integration_test \
    "Verificar quantidade de arquivos .el" \
    "[[ \$(find /opt/emacspeak/lisp -name '*.el' | wc -l) -gt 50 ]]"

run_integration_test \
    "Verificar arquivos de som existem" \
    "[[ \$(find /opt/emacspeak/sounds -type f | wc -l) -gt 0 ]]" \
    "true"

run_integration_test \
    "Verificar arquivos XSL existem" \
    "[[ -d /opt/emacspeak/xsl ]]"

echo ""

# ============================================================================
# SEÇÃO 10: Testes de Carga do Emacspeak
# ============================================================================
echo -e "${BLUE}═══ Seção 10: Testes de Carga Completa ═══${NC}"
echo ""

run_integration_test \
    "Carregar Emacspeak completamente (sem erros fatais)" \
    "timeout 30 emacs --batch --eval '(condition-case err (progn (setq emacspeak-xslt-directory \"/opt/emacspeak/xsl\") (setq emacspeak-sounds-dir \"/opt/emacspeak/sounds/\") (add-to-list \"'\"'load-path \"/opt/emacspeak/lisp\") (load \"/opt/emacspeak/lisp/emacspeak-setup.el\")) (error (progn (message \"Error: %s\" err) (kill-emacs 1))))' 2>&1 | grep -v Warning"

echo ""

# ============================================================================
# Resumo Final
# ============================================================================
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              RESUMO DOS TESTES DE INTEGRAÇÃO              ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Total de testes: ${TOTAL_TESTS}"
echo -e "${GREEN}Passaram: ${TESTS_PASSED}${NC}"
echo -e "${RED}Falharam: ${TESTS_FAILED}${NC}"
echo -e "${BLUE}Pulados: ${TESTS_SKIPPED}${NC}"
echo ""

if [[ ${TESTS_FAILED} -eq 0 ]]; then
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          ✓ TODOS OS TESTES DE INTEGRAÇÃO PASSARAM!       ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Informações do Pacote:${NC}"
    dpkg -s emacspeak 2>/dev/null | grep -E "^(Package|Version|Status|Architecture):" || true
    echo ""
    exit 0
else
    echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║            ✗ ALGUNS TESTES FALHARAM                      ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 1
fi
