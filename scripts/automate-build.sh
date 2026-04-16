#!/usr/bin/env bash
# Script mestre de automação - Build e teste completo do pacote Emacspeak

set -euo pipefail

# Cores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Configurações
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly OUTPUT_DIR="${PROJECT_ROOT}/output"
readonly LOG_DIR="${PROJECT_ROOT}/logs"
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)
readonly LOG_FILE="${LOG_DIR}/build_${TIMESTAMP}.log"

# Estatísticas
START_TIME=$(date +%s)
STEPS_TOTAL=0
STEPS_COMPLETED=0
STEPS_FAILED=0

# Função para logging
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $*" | tee -a "${LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*" | tee -a "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $*" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}✗${NC} $*" | tee -a "${LOG_FILE}"
}

log_step() {
    STEPS_TOTAL=$((STEPS_TOTAL + 1))
    echo -e "\n${CYAN}[Passo ${STEPS_TOTAL}]${NC} $*" | tee -a "${LOG_FILE}"
}

# Função para executar comando com log
run_command() {
    local description="$1"
    shift
    log_info "Executando: $description"

    if "$@" >> "${LOG_FILE}" 2>&1; then
        STEPS_COMPLETED=$((STEPS_COMPLETED + 1))
        log_success "$description - OK"
        return 0
    else
        STEPS_FAILED=$((STEPS_FAILED + 1))
        log_error "$description - FALHOU"
        return 1
    fi
}

# Função para verificar pré-requisitos
check_prerequisites() {
    log_step "Verificando pré-requisitos"

    local prereqs_ok=true

    # Verifica Docker
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version | cut -d' ' -f3 | tr -d ',')
        log_success "Docker instalado: ${docker_version}"
    else
        log_error "Docker não encontrado!"
        prereqs_ok=false
    fi

    # Verifica Docker Compose
    if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
        local compose_version=$(docker-compose --version 2>/dev/null | cut -d' ' -f4 || docker compose version --short)
        log_success "Docker Compose instalado: ${compose_version}"
    else
        log_error "Docker Compose não encontrado!"
        prereqs_ok=false
    fi

    # Verifica se Docker está rodando
    if docker info &> /dev/null; then
        log_success "Docker daemon está rodando"
    else
        log_error "Docker daemon não está rodando!"
        prereqs_ok=false
    fi

    # Verifica arquivos necessários
    local required_files=(
        "Dockerfile"
        "docker-compose.yml"
        "debian/control"
        "debian/rules"
        "scripts/build-package.sh"
        "scripts/test-package.sh"
    )

    for file in "${required_files[@]}"; do
        if [[ -f "${PROJECT_ROOT}/${file}" ]]; then
            log_success "Arquivo encontrado: ${file}"
        else
            log_error "Arquivo não encontrado: ${file}"
            prereqs_ok=false
        fi
    done

    if [[ "$prereqs_ok" == "false" ]]; then
        log_error "Pré-requisitos não satisfeitos. Abortando."
        exit 1
    fi

    log_success "Todos os pré-requisitos verificados!"
}

# Função para preparar ambiente
prepare_environment() {
    log_step "Preparando ambiente"

    # Cria diretórios necessários
    mkdir -p "${OUTPUT_DIR}" "${LOG_DIR}"
    log_success "Diretórios criados"

    # Limpa builds anteriores (opcional)
    if [[ -f "${OUTPUT_DIR}/*.deb" ]]; then
        log_info "Limpando builds anteriores..."
        rm -f "${OUTPUT_DIR}"/*.{deb,buildinfo,changes} 2>/dev/null || true
    fi

    # Verifica permissões dos scripts
    chmod +x "${PROJECT_ROOT}/scripts"/*.sh
    chmod +x "${PROJECT_ROOT}/debian/rules"
    log_success "Permissões configuradas"
}

# Função para construir imagem Docker
build_docker_image() {
    log_step "Construindo imagem Docker (builder)"

    cd "${PROJECT_ROOT}"

    if run_command "Build de imagem Docker builder" \
        docker build --target builder -t emacspeak-builder:60.0 .; then
        log_success "Imagem builder construída com sucesso!"
    else
        log_error "Falha ao construir imagem builder"
        return 1
    fi
}

# Função para extrair pacotes
extract_packages() {
    log_step "Extraindo pacotes .deb"

    cd "${PROJECT_ROOT}"

    # Cria container temporário
    local container_id
    container_id=$(docker create emacspeak-builder:60.0)
    log_info "Container temporário criado: ${container_id:0:12}"

    # Extrai arquivos
    if docker cp "${container_id}:/build/" "${OUTPUT_DIR}/"; then
        log_success "Arquivos extraídos"

        # Move .deb para output/
        find "${OUTPUT_DIR}/build/" -name "*.deb" -exec mv {} "${OUTPUT_DIR}/" \; 2>/dev/null || true
        find "${OUTPUT_DIR}/build/" -name "*.buildinfo" -exec mv {} "${OUTPUT_DIR}/" \; 2>/dev/null || true
        find "${OUTPUT_DIR}/build/" -name "*.changes" -exec mv {} "${OUTPUT_DIR}/" \; 2>/dev/null || true

        log_success "Pacotes movidos para ${OUTPUT_DIR}/"
    else
        log_error "Falha ao extrair arquivos"
    fi

    # Remove container temporário
    docker rm "${container_id}" &> /dev/null
    log_info "Container temporário removido"
}

# Função para listar pacotes gerados
list_packages() {
    log_step "Listando pacotes gerados"

    echo "" | tee -a "${LOG_FILE}"
    echo -e "${MAGENTA}═══════════════════════════════════════${NC}" | tee -a "${LOG_FILE}"
    echo -e "${MAGENTA}  Pacotes Debian Gerados${NC}" | tee -a "${LOG_FILE}"
    echo -e "${MAGENTA}═══════════════════════════════════════${NC}" | tee -a "${LOG_FILE}"

    if compgen -G "${OUTPUT_DIR}/*.deb" > /dev/null; then
        ls -lh "${OUTPUT_DIR}"/*.deb | tee -a "${LOG_FILE}"

        echo "" | tee -a "${LOG_FILE}"
        for deb in "${OUTPUT_DIR}"/*.deb; do
            echo -e "${CYAN}Informações do pacote:${NC}" | tee -a "${LOG_FILE}"
            dpkg-deb --info "$deb" 2>/dev/null | grep -E "^ (Package|Version|Architecture|Depends):" | tee -a "${LOG_FILE}"
        done
    else
        log_warning "Nenhum pacote .deb encontrado"
    fi

    echo "" | tee -a "${LOG_FILE}"
}

# Função para executar lintian
run_lintian() {
    log_step "Executando lintian (verificação de qualidade)"

    if ! compgen -G "${OUTPUT_DIR}/*.deb" > /dev/null; then
        log_warning "Nenhum pacote para verificar com lintian"
        return 0
    fi

    log_info "Executando lintian nos pacotes..."

    docker run --rm -v "${OUTPUT_DIR}:/packages" debian:trixie-slim bash -c \
        "apt-get update -qq && apt-get install -y -qq lintian && \
         for deb in /packages/*.deb; do \
             echo '=== Verificando: \$(basename \$deb) ===' && \
             lintian \$deb || true; \
         done" 2>&1 | tee -a "${LOG_FILE}"

    log_success "Lintian executado"
}

# Função para construir imagem de testes
build_test_image() {
    log_step "Construindo imagem Docker (tester)"

    cd "${PROJECT_ROOT}"

    if run_command "Build de imagem Docker tester" \
        docker build --target tester -t emacspeak-tester:60.0 .; then
        log_success "Imagem tester construída com sucesso!"
    else
        log_error "Falha ao construir imagem tester"
        return 1
    fi
}

# Função para executar testes
run_tests() {
    log_step "Executando suite de testes"

    echo "" | tee -a "${LOG_FILE}"
    echo -e "${MAGENTA}═══════════════════════════════════════${NC}" | tee -a "${LOG_FILE}"
    echo -e "${MAGENTA}  Executando Testes do Pacote${NC}" | tee -a "${LOG_FILE}"
    echo -e "${MAGENTA}═══════════════════════════════════════${NC}" | tee -a "${LOG_FILE}"
    echo "" | tee -a "${LOG_FILE}"

    if docker run --rm emacspeak-tester:60.0 2>&1 | tee -a "${LOG_FILE}"; then
        log_success "Todos os testes passaram!"
        return 0
    else
        log_error "Alguns testes falharam"
        return 1
    fi
}

# Função para gerar relatório final
generate_report() {
    local end_time=$(date +%s)
    local elapsed=$((end_time - START_TIME))
    local minutes=$((elapsed / 60))
    local seconds=$((elapsed % 60))

    echo "" | tee -a "${LOG_FILE}"
    echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════╗${NC}" | tee -a "${LOG_FILE}"
    echo -e "${MAGENTA}║${NC}                  ${GREEN}RELATÓRIO FINAL${NC}                         ${MAGENTA}║${NC}" | tee -a "${LOG_FILE}"
    echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════╝${NC}" | tee -a "${LOG_FILE}"
    echo "" | tee -a "${LOG_FILE}"

    echo -e "${CYAN}Estatísticas:${NC}" | tee -a "${LOG_FILE}"
    echo -e "  Total de passos: ${STEPS_TOTAL}" | tee -a "${LOG_FILE}"
    echo -e "  ${GREEN}Completados: ${STEPS_COMPLETED}${NC}" | tee -a "${LOG_FILE}"
    echo -e "  ${RED}Falhados: ${STEPS_FAILED}${NC}" | tee -a "${LOG_FILE}"
    echo -e "  Tempo decorrido: ${minutes}m ${seconds}s" | tee -a "${LOG_FILE}"
    echo "" | tee -a "${LOG_FILE}"

    echo -e "${CYAN}Pacotes gerados:${NC}" | tee -a "${LOG_FILE}"
    if compgen -G "${OUTPUT_DIR}/*.deb" > /dev/null; then
        for deb in "${OUTPUT_DIR}"/*.deb; do
            echo -e "  ${GREEN}✓${NC} $(basename "$deb")" | tee -a "${LOG_FILE}"
        done
    else
        echo -e "  ${RED}Nenhum pacote gerado${NC}" | tee -a "${LOG_FILE}"
    fi
    echo "" | tee -a "${LOG_FILE}"

    echo -e "${CYAN}Arquivos de log:${NC}" | tee -a "${LOG_FILE}"
    echo -e "  Log principal: ${LOG_FILE}" | tee -a "${LOG_FILE}"
    echo "" | tee -a "${LOG_FILE}"

    if [[ ${STEPS_FAILED} -eq 0 ]]; then
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║${NC}          🎉 ${GREEN}BUILD E TESTES CONCLUÍDOS COM SUCESSO!${NC} 🎉          ${GREEN}║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
        return 0
    else
        echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║${NC}              ⚠️  ${RED}ALGUNS PASSOS FALHARAM${NC} ⚠️                    ${RED}║${NC}"
        echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
        return 1
    fi
}

# Função principal
main() {
    echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}      ${CYAN}Automação de Build - Emacspeak 60.0 Debian${NC}        ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    log_info "Iniciando build em: ${PROJECT_ROOT}"
    log_info "Output directory: ${OUTPUT_DIR}"
    log_info "Log file: ${LOG_FILE}"
    echo ""

    # Executa pipeline de build e teste
    check_prerequisites
    prepare_environment
    build_docker_image
    extract_packages
    list_packages
    run_lintian
    build_test_image
    run_tests

    # Gera relatório
    generate_report
}

# Tratamento de erros
trap 'log_error "Script interrompido!"; exit 1' INT TERM

# Executa
main "$@"
