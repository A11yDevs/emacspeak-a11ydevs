#!/usr/bin/env bash
#
# generate-apt-repo.sh
# Gera estrutura de repositório APT Debian para o Emacspeak
#
# Uso: ./scripts/generate-apt-repo.sh <diretorio-output> <diretorio-apt>
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
    local output_dir="${1:-${PROJECT_ROOT}/output}"
    local apt_repo_dir="${2:-${PROJECT_ROOT}/apt-repo}"

    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Geração de Repositório APT - Emacspeak${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    log_info "Diretório de pacotes: ${output_dir}"
    log_info "Diretório do repositório APT: ${apt_repo_dir}"
    echo ""

    # Verificar se existem pacotes .deb
    if ! ls "${output_dir}"/*.deb &>/dev/null; then
        log_error "Nenhum pacote .deb encontrado em ${output_dir}"
        log_error "Execute o build primeiro: make build-all"
        exit 1
    fi

    # Criar estrutura de diretórios
    log_info "Criando estrutura de diretórios..."

    local pool_dir="${apt_repo_dir}/debian/pool/main/e/emacspeak"
    local dists_dir="${apt_repo_dir}/debian/dists/stable/main/binary-amd64"

    mkdir -p "${pool_dir}"
    mkdir -p "${dists_dir}"

    log_success "Estrutura criada"

    # Copiar pacotes .deb para pool
    log_info "Copiando pacotes para pool..."

    cp -v "${output_dir}"/*.deb "${pool_dir}/"

    # Copiar também .buildinfo e .changes se existirem
    if ls "${output_dir}"/*.buildinfo &>/dev/null; then
        cp -v "${output_dir}"/*.buildinfo "${pool_dir}/"
    fi

    if ls "${output_dir}"/*.changes &>/dev/null; then
        cp -v "${output_dir}"/*.changes "${pool_dir}/"
    fi

    log_success "Pacotes copiados"

    # Gerar arquivo Packages
    log_info "Gerando arquivo Packages..."

    cd "${apt_repo_dir}/debian"

    # Usar dpkg-scanpackages para gerar o índice
    if command -v dpkg-scanpackages &>/dev/null; then
        dpkg-scanpackages --multiversion pool/ /dev/null > "${dists_dir}/Packages"
        log_success "Packages gerado com dpkg-scanpackages"
    else
        log_warning "dpkg-scanpackages não encontrado, usando fallback"
        # Fallback: criar Packages manualmente (básico)
        generate_packages_fallback "${pool_dir}" "${dists_dir}/Packages"
    fi

    # Comprimir Packages
    gzip -9 -c "${dists_dir}/Packages" > "${dists_dir}/Packages.gz"
    log_success "Packages.gz gerado"

    # Gerar arquivo Release
    log_info "Gerando arquivo Release..."

    generate_release_file "${apt_repo_dir}/debian/dists/stable"

    log_success "Release gerado"

    # Gerar InRelease (opcional, para compatibilidade)
    log_info "Repositório APT pronto para assinatura"
    log_warning "Execute scripts/sign-repo.sh para assinar o repositório"

    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Repositório APT gerado com sucesso!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    log_info "Estrutura criada em: ${apt_repo_dir}/debian"
    log_info "Próximo passo: Assinar com scripts/sign-repo.sh"
}

# Função para gerar arquivo Packages (fallback)
generate_packages_fallback() {
    local pool_dir="$1"
    local packages_file="$2"

    > "${packages_file}"  # Limpar arquivo

    for deb in "${pool_dir}"/*.deb; do
        if [[ ! -f "${deb}" ]]; then
            continue
        fi

        local filename=$(basename "${deb}")
        local size=$(stat -f%z "${deb}" 2>/dev/null || stat -c%s "${deb}")
        local md5sum=$(md5sum "${deb}" | cut -d' ' -f1)
        local sha256=$(sha256sum "${deb}" | cut -d' ' -f1)

        # Extrair informações do .deb
        dpkg-deb -f "${deb}" >> "${packages_file}"

        # Adicionar informações de arquivo
        cat >> "${packages_file}" << EOF
Filename: pool/main/e/emacspeak/${filename}
Size: ${size}
MD5sum: ${md5sum}
SHA256: ${sha256}

EOF
    done
}

# Função para gerar arquivo Release
generate_release_file() {
    local dists_stable_dir="$1"
    local release_file="${dists_stable_dir}/Release"

    local date_rfc=$(date -R)

    cat > "${release_file}" << EOF
Origin: Emacspeak A11y
Label: Emacspeak Accessibility Repository
Suite: stable
Codename: stable
Version: 1.0
Architectures: amd64
Components: main
Description: Emacspeak - Complete audio desktop for Emacs
Date: ${date_rfc}
EOF

    # Adicionar checksums dos arquivos Packages
    echo "MD5Sum:" >> "${release_file}"
    (cd "${dists_stable_dir}" && find . -type f -name 'Packages*' -exec md5sum {} \; | sed 's/\.\///' | awk '{print " " $1 " " $2}') >> "${release_file}"

    echo "SHA256:" >> "${release_file}"
    (cd "${dists_stable_dir}" && find . -type f -name 'Packages*' -exec sha256sum {} \; | sed 's/\.\///' | awk '{print " " $1 " " $2}') >> "${release_file}"
}

# Executar
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
