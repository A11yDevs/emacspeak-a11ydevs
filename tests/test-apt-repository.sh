#!/bin/bash
# tests/test-apt-repository.sh - Valida saúde do repositório APT Emacspeak no GitHub Pages

set -euo pipefail

APT_BASE_URL="${APT_BASE_URL:-https://a11ydevs.github.io/emacspeak-a11ydevs/debian}"
DIST="${DIST:-stable}"
COMPONENT="${COMPONENT:-main}"
ARCH="${ARCH:-amd64}"

echo "=== Teste do Repositório APT Emacspeak (GitHub Pages) ==="
echo "APT_BASE_URL=${APT_BASE_URL}"
echo "DIST=${DIST} COMPONENT=${COMPONENT} ARCH=${ARCH}"
echo

if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker não encontrado no host"
  exit 1
fi

echo "◆ Executando validações em container Debian limpo..."

docker run --rm \
  -e APT_BASE_URL="${APT_BASE_URL}" \
  -e DIST="${DIST}" \
  -e COMPONENT="${COMPONENT}" \
  -e ARCH="${ARCH}" \
  debian:trixie-slim \
  bash -c '
set -euo pipefail

apt-get update -qq
apt-get install -y -qq --no-install-recommends curl gzip ca-certificates

TMP_DIR="$(mktemp -d)"
trap "rm -rf ${TMP_DIR}" EXIT

echo "  > Verificando Release..."
if ! curl -fsSL "${APT_BASE_URL}/dists/${DIST}/Release" -o "${TMP_DIR}/Release"; then
  echo "❌ Arquivo Release não encontrado ou inacessível"
  exit 1
fi

grep -q "^Origin: A11yDevs$" "${TMP_DIR}/Release" || {
  echo "❌ Release não contém Origin correto"
  exit 1
}

grep -q "^Label: emacspeak-a11ydevs$" "${TMP_DIR}/Release" || {
  echo "❌ Release não contém Label correto"
  exit 1
}

echo "✓ Release válido"

echo "  > Verificando assinatura GPG..."
if ! curl -fsSL "${APT_BASE_URL}/dists/${DIST}/Release.gpg" -o "${TMP_DIR}/Release.gpg"; then
  echo "❌ Assinatura Release.gpg não encontrada"
  exit 1
fi

if ! curl -fsSL "${APT_BASE_URL}/dists/${DIST}/InRelease" -o "${TMP_DIR}/InRelease"; then
  echo "❌ InRelease não encontrado"
  exit 1
fi

echo "✓ Arquivos de assinatura presentes"

echo "  > Verificando índice de pacotes..."
if ! curl -fsSL "${APT_BASE_URL}/dists/${DIST}/${COMPONENT}/binary-${ARCH}/Packages.gz" -o "${TMP_DIR}/Packages.gz"; then
  echo "❌ Packages.gz não encontrado"
  exit 1
fi

gzip -dc "${TMP_DIR}/Packages.gz" > "${TMP_DIR}/Packages"

grep -q "^Package: emacspeak$" "${TMP_DIR}/Packages" || {
  echo "❌ Pacote emacspeak não encontrado no índice"
  exit 1
}

echo "✓ Pacote emacspeak listado no índice"

# Verificar se Filename não contém paths inválidos (pages/debian, output/, etc)
if grep -q "^Filename: pages/" "${TMP_DIR}/Packages"; then
  echo "❌ Índice com Filename inválido (pages/...)"
  exit 1
fi

if grep -q "^Filename: output/" "${TMP_DIR}/Packages"; then
  echo "❌ Índice com Filename inválido (output/...)"
  exit 1
fi

echo "  > Verificando URLs dos .deb listados no índice..."
while IFS= read -r rel_path; do
  [[ -z "${rel_path}" ]] && continue

  deb_url="${APT_BASE_URL}/${rel_path}"
  status="$(curl -s -o /dev/null -w "%{http_code}" "${deb_url}")"

  if [[ "${status}" != "200" ]]; then
    echo "❌ .deb indisponível (${status}): ${deb_url}"
    exit 1
  fi

  echo "  ✓ ${deb_url}"
done < <(awk -F": " "/^Filename: /{print \$2}" "${TMP_DIR}/Packages")

echo "  > Baixando chave GPG do repositório..."
curl -fsSL "${APT_BASE_URL}/emacspeak-archive-keyring.gpg" \
  -o /usr/share/keyrings/emacspeak-archive-keyring.gpg

echo "  > Configurando repositório APT..."
echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/emacspeak-archive-keyring.gpg] ${APT_BASE_URL} ${DIST} ${COMPONENT}" \
  > /etc/apt/sources.list.d/emacspeak.list

echo "  > Executando apt update..."
apt-get update -qq

echo "  > Instalando pacote emacspeak via APT..."
apt-get install -y -qq --no-install-recommends emacspeak emacs-nox espeak-ng tcl8.6

echo "  > Verificando instalação..."
dpkg-query -W emacspeak >/dev/null || {
  echo "❌ Pacote emacspeak não instalado"
  exit 1
}

test -f /opt/emacspeak/lisp/emacspeak-setup.el || {
  echo "❌ Arquivo /opt/emacspeak/lisp/emacspeak-setup.el não encontrado"
  exit 1
}

test -d /opt/emacspeak/servers || {
  echo "❌ Diretório /opt/emacspeak/servers não encontrado"
  exit 1
}

test -d /opt/emacspeak/etc || {
  echo "❌ Diretório /opt/emacspeak/etc não encontrado"
  exit 1
}

echo "✓ apt update/install funcionou no container"
'

echo
echo "✅ Repositório APT no GitHub Pages validado com sucesso!"
