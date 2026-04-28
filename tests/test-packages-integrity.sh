#!/bin/bash
# tests/test-packages-integrity.sh - Valida integridade e funcionamento dos pacotes .deb do Emacspeak

set -euo pipefail

echo "=== Teste de Integridade e Funcionamento dos Pacotes Emacspeak ==="
echo

# Função para encontrar o pacote mais recente
find_latest_pkg() {
  local pattern="$1"
  local latest
  latest="$(ls -1 output/${pattern}_*_amd64.deb 2>/dev/null | sort -V | tail -n 1 || true)"
  if [[ -z "${latest}" ]]; then
    echo ""
    return
  fi
  echo "${latest}"
}

EMACSPEAK_PKG="$(find_latest_pkg emacspeak)"
DBGSYM_PKG="$(find_latest_pkg emacspeak-dbgsym)"

if [[ -z "${EMACSPEAK_PKG}" ]]; then
  echo "❌ Pacote emacspeak .deb não encontrado em output/."
  echo "   Execute o build antes: make automate"
  exit 1
fi

echo "✓ Pacotes encontrados:"
echo "  - ${EMACSPEAK_PKG}"
if [[ -n "${DBGSYM_PKG}" ]]; then
  echo "  - ${DBGSYM_PKG}"
fi
echo

echo "◆ Hash SHA256 dos pacotes:"
if [[ -n "${DBGSYM_PKG}" ]]; then
  sha256sum "${EMACSPEAK_PKG}" "${DBGSYM_PKG}" | sed 's/^/  /'
else
  sha256sum "${EMACSPEAK_PKG}" | sed 's/^/  /'
fi
echo

echo "◆ Validando metadados e estrutura do pacote..."

# Validar estrutura do .deb
dpkg-deb --info "${EMACSPEAK_PKG}" | grep -q "Package: emacspeak" || {
  echo "❌ Metadados inválidos no pacote"
  exit 1
}

dpkg-deb --info "${EMACSPEAK_PKG}" | grep -q "Architecture: amd64" || {
  echo "❌ Arquitetura incorreta no pacote"
  exit 1
}

VERSION="$(dpkg-deb -f "${EMACSPEAK_PKG}" Version)"
echo "  ✓ Versão: ${VERSION}"

MAINTAINER="$(dpkg-deb -f "${EMACSPEAK_PKG}" Maintainer)"
echo "  ✓ Maintainer: ${MAINTAINER}"

echo "  ✓ Estrutura do pacote válida"
echo

echo "◆ Validando conteúdo do pacote..."

# Listar conteúdo
CONTENTS="$(dpkg-deb -c "${EMACSPEAK_PKG}")"

# Verificar arquivos essenciais
for file in \
  "./usr/bin/emacspeak" \
  "./usr/share/emacs/site-lisp/emacspeak/" \
  "./etc/emacspeak.sh"; do

  if echo "${CONTENTS}" | grep -q "${file}"; then
    echo "  ✓ ${file}"
  else
    echo "  ❌ Arquivo ausente: ${file}"
    exit 1
  fi
done
echo

echo "◆ Testando instalação e execução em container Debian..."

docker run --rm \
  -v "${PWD}/${EMACSPEAK_PKG}:/tmp/emacspeak.deb:ro" \
  debian:trixie-slim \
  bash -c '
set -euo pipefail

echo "  > Instalando dependências..."
apt-get update -qq
apt-get install -y -qq --no-install-recommends \
  /tmp/emacspeak.deb \
  emacs-nox \
  espeak-ng \
  tcl8.6

echo "  > Verificando instalação..."
dpkg -s emacspeak >/dev/null || {
  echo "❌ Pacote emacspeak não instalado corretamente"
  exit 1
}

echo "  > Verificando arquivos instalados..."
test -f /usr/bin/emacspeak || {
  echo "❌ Binário /usr/bin/emacspeak não encontrado"
  exit 1
}

test -d /usr/share/emacs/site-lisp/emacspeak || {
  echo "❌ Diretório de Elisp não encontrado"
  exit 1
}

test -f /etc/emacspeak.sh || {
  echo "❌ Arquivo de configuração /etc/emacspeak.sh não encontrado"
  exit 1
}

echo "  > Testando carregamento do Elisp..."
emacs --batch --eval "(progn (add-to-list '\''load-path \"/usr/share/emacs/site-lisp/emacspeak\") (require '\''emacspeak-setup))" 2>&1 | grep -q "error" && {
  echo "❌ Erro ao carregar emacspeak-setup"
  exit 1
} || true

echo "  > Verificando servidor TTS espeak..."
test -x /usr/share/emacs/site-lisp/emacspeak/servers/espeak || {
  echo "❌ Servidor TTS espeak não executável"
  exit 1
}

echo "  ✓ Instalação e execução básica funcionam"
'

echo
echo "✅ Todos os testes de integridade passaram com sucesso!"
