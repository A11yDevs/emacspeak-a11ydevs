#!/usr/bin/env bash
#
# sign-repo.sh
# Assina o repositório APT com chave GPG
#
# Uso: ./scripts/sign-repo.sh <diretorio-apt> [key-id]
#

set -euo pipefail

# Cores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Configurações
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Funções auxiliares
log_info() {
    echo -e "${CYAN}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*" >&2
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

# Função principal
main() {
    local apt_repo_dir="${1:-${PROJECT_ROOT}/apt-repo}"
    local key_id="${2:-}"

    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Assinatura de Repositório APT - Emacspeak${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    # Verificar se o diretório existe
    if [[ ! -d "${apt_repo_dir}/debian/dists/stable" ]]; then
        log_error "Diretório do repositório não encontrado: ${apt_repo_dir}"
        log_error "Execute scripts/generate-apt-repo.sh primeiro"
        exit 1
    fi

    local dists_dir="${apt_repo_dir}/debian/dists/stable"
    local release_file="${dists_dir}/Release"

    if [[ ! -f "${release_file}" ]]; then
        log_error "Arquivo Release não encontrado: ${release_file}"
        exit 1
    fi

    log_info "Repositório: ${apt_repo_dir}"
    log_info "Arquivo Release: ${release_file}"
    echo ""

    # Verificar se GPG está disponível
    if ! command -v gpg &>/dev/null; then
        log_error "gpg não encontrado. Instale o GnuPG primeiro."
        exit 1
    fi

    # Listar chaves disponíveis se key_id não foi fornecido
    if [[ -z "${key_id}" ]]; then
        log_info "Chaves GPG disponíveis:"
        gpg --list-secret-keys --keyid-format=long
        echo ""
        log_error "Especifique o KEY_ID como segundo argumento"
        log_info "Uso: $0 <diretorio-apt> <key-id>"
        exit 1
    fi

    # Assinar arquivo Release
    log_info "Assinando Release com chave ${key_id}..."

    # Gerar Release.gpg (assinatura destacada)
    gpg --default-key "${key_id}" \
        --armor \
        --detach-sign \
        --output "${dists_dir}/Release.gpg" \
        "${release_file}"

    log_success "Release.gpg gerado"

    # Gerar InRelease (assinatura inline)
    gpg --default-key "${key_id}" \
        --armor \
        --clearsign \
        --output "${dists_dir}/InRelease" \
        "${release_file}"

    log_success "InRelease gerado"

    # Exportar chave pública
    log_info "Exportando chave pública..."

    gpg --export --armor "${key_id}" > "${apt_repo_dir}/debian/emacspeak-archive-keyring.asc"
    gpg --export "${key_id}" > "${apt_repo_dir}/debian/emacspeak-archive-keyring.gpg"

    log_success "Chaves públicas exportadas"

    # Verificar assinatura
    log_info "Verificando assinatura..."

    if gpg --verify "${dists_dir}/Release.gpg" "${release_file}" &>/dev/null; then
        log_success "Assinatura verificada com sucesso!"
    else
        log_error "Falha na verificação da assinatura"
        exit 1
    fi

    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Repositório APT assinado com sucesso!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    log_info "Arquivos gerados:"
    log_info "  - ${dists_dir}/Release.gpg"
    log_info "  - ${dists_dir}/InRelease"
    log_info "  - ${apt_repo_dir}/debian/emacspeak-archive-keyring.gpg"
    log_info "  - ${apt_repo_dir}/debian/emacspeak-archive-keyring.asc"
    echo ""
    log_success "Repositório pronto para publicação!"
}

# Executar
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
