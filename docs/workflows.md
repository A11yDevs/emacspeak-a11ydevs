# Workflows CI/CD

Documentação completa dos workflows de integração e entrega contínuas do projeto Emacspeak A11yDevs.

---

## 📋 Visão Geral

O projeto utiliza **GitHub Actions** para automatizar:

1. ✅ **Testes** - Validação de integridade dos pacotes e repositório APT
2. 📦 **Releases** - Publicação de pacotes .deb no GitHub Releases
3. 🌐 **APT Repository** - Publicação do repositório APT no GitHub Pages

---

## 🔄 Workflows Disponíveis

### 1. CI - Build and Tests

**Arquivo:** `.github/workflows/ci-tests.yml`

**Triggers:**
- Pull requests para `main`
- Push na branch `main`
- Execução manual (`workflow_dispatch`)

**Jobs:**

#### Job 1: `build-and-test`
Executa em **todos os eventos** (PRs, pushes, manual).

**Etapas:**
1. Checkout do código
2. Build completo com Docker (`make automate`)
3. Lista pacotes gerados
4. Upload dos pacotes como artifacts (retenção: 30 dias)
5. **Teste de integridade dos pacotes** (`tests/test-packages-integrity.sh`)
   - Verifica metadados (Package, Version, Architecture)
   - Valida estrutura interna do .deb
   - Testa instalação em container Debian
   - Valida carregamento do Elisp no Emacs
6. Upload dos logs de teste (retenção: 7 dias)

#### Job 2: `apt-repository-test`
Executa **apenas em pushes na branch main**.

**Etapas:**
1. Checkout do código
2. **Teste do repositório APT** (`tests/test-apt-repository.sh`)
   - Valida arquivo Release
   - Verifica assinaturas GPG
   - Testa índice de pacotes
   - Valida URLs dos .deb
   - Testa `apt update` e `apt install` em container

**Artifacts:**
- `emacspeak-packages` - Pacotes .deb, .buildinfo, .changes
- `test-logs` - Logs de execução dos testes

**Status:** [![CI Tests](https://github.com/A11yDevs/emacspeak-a11ydevs/actions/workflows/ci-tests.yml/badge.svg)](https://github.com/A11yDevs/emacspeak-a11ydevs/actions/workflows/ci-tests.yml)

---

### 2. Release Debian Packages

**Arquivo:** `.github/workflows/release-packages.yml`

**Triggers:**
- Push de tags no formato `v*` (ex: `v60.0-1`, `v60.0-2`)

**Workflow:**
1. Resolve versão da tag (remove prefixo `v`)
2. Atualiza `debian/changelog` com a nova versão
3. Constrói pacotes Debian com Docker
4. Verifica se pacotes foram gerados
5. Gera checksums SHA256
6. Cria release notes automáticas
7. **Publica GitHub Release** com:
   - Pacotes `.deb`
   - Arquivos `.buildinfo` e `.changes`
   - `SHA256SUMS.txt`
   - Release notes com instruções de instalação

**Release Notes incluem:**
- Instruções de instalação via APT
- Instruções de instalação manual
- Links para documentação e repositório APT
- Checksums para validação

**Exemplo de uso:**
```bash
# Criar release v60.0-1
git tag v60.0-1
git push origin v60.0-1

# O workflow automaticamente:
# 1. Constrói pacotes
# 2. Cria release no GitHub
# 3. Anexa pacotes .deb e checksums
```

---

### 3. Publish APT Repository (GitHub Pages)

**Arquivo:** `.github/workflows/publish-apt-repo.yml`

**Triggers:**
- Push na branch `main`
- Push de tags no formato `v*`
- Execução manual (`workflow_dispatch`)

**Workflow:**

#### Etapa 1: Preparação
1. Resolve versão (da tag ou do Makefile/changelog)
2. Atualiza `debian/changelog` se necessário
3. Constrói pacotes Debian

#### Etapa 2: Criação do Repositório APT
1. Instala ferramentas (`apt-utils`, `gnupg`)
2. Importa chave GPG privada (do secret `APT_GPG_PRIVATE_KEY_B64`)
3. Cria estrutura de diretórios:
   ```
   pages/debian/
   ├── pool/main/e/emacspeak/
   │   └── emacspeak_X.Y-Z_amd64.deb
   └── dists/stable/main/binary-amd64/
       ├── Packages
       └── Packages.gz
   ```
4. Gera índice de pacotes com `apt-ftparchive`
5. Gera arquivo `Release` com checksums

#### Etapa 3: Assinatura
1. Assina `Release` → `Release.gpg` (detached signature)
2. Assina `Release` → `InRelease` (inline signature)
3. Exporta chaves públicas (`.asc` e `.gpg`)

#### Etapa 4: Publicação
1. Cria `index.html` com instruções
2. Adiciona `.nojekyll` para desabilitar Jekyll
3. Publica no branch `gh-pages` (force orphan)

**Secrets Necessários:**
- `APT_GPG_PRIVATE_KEY_B64` - Chave privada GPG em base64
- `APT_GPG_PASSPHRASE` - Senha da chave GPG (ou vazio)

**Resultado:** Repositório APT disponível em https://a11ydevs.github.io/emacspeak-a11ydevs/debian

---

## 🔐 Configuração de Secrets

### Gerar Chave GPG

```bash
# 1. Gerar chave
gpg --full-generate-key
# Tipo: RSA 4096
# Nome: Emacspeak A11y Repository
# Email: emacspeak@a11ydevs.github.io

# 2. Listar chaves
gpg --list-secret-keys --keyid-format=long
export KEY_ID="SEU_KEY_ID_AQUI"

# 3. Exportar para GitHub
gpg --export-secret-keys "${KEY_ID}" | base64 > emacspeak-private-key.b64
```

### Adicionar no GitHub

1. Acesse: https://github.com/A11yDevs/emacspeak-a11ydevs/settings/secrets/actions
2. Adicione os secrets:
   - `APT_GPG_PRIVATE_KEY_B64` (conteúdo de `emacspeak-private-key.b64`)
   - `APT_GPG_PASSPHRASE` (senha da chave ou vazio)

Consulte [docs/gpg-setup.md](../docs/gpg-setup.md) para guia completo.

---

## 🧪 Scripts de Teste

### test-packages-integrity.sh

**Localização:** `tests/test-packages-integrity.sh`

**Propósito:** Valida integridade e funcionamento dos pacotes .deb.

**Verificações:**
1. ✅ Localiza pacotes em `output/`
2. ✅ Gera SHA256 checksums
3. ✅ Valida metadados (Package, Version, Architecture, Maintainer)
4. ✅ Verifica arquivos essenciais:
   - `/usr/bin/emacspeak`
   - `/usr/share/emacs/site-lisp/emacspeak/`
   - `/etc/emacspeak.sh`
5. ✅ Testa instalação em container Debian limpo
6. ✅ Valida carregamento do Elisp: `(require 'emacspeak-setup)`
7. ✅ Verifica servidor TTS espeak

**Uso local:**
```bash
# Após build
make automate

# Executar testes
bash tests/test-packages-integrity.sh
```

---

### test-apt-repository.sh

**Localização:** `tests/test-apt-repository.sh`

**Propósito:** Valida saúde do repositório APT publicado no GitHub Pages.

**Verificações:**
1. ✅ Valida arquivo `Release`:
   - Origin: A11yDevs
   - Label: emacspeak-a11ydevs
   - Suite: stable
   - Architectures: amd64
2. ✅ Verifica assinaturas:
   - `Release.gpg` (detached)
   - `InRelease` (inline)
3. ✅ Valida índice `Packages`:
   - Pacote `emacspeak` listado
   - Campo `Filename` com paths corretos (não contém `pages/` ou `output/`)
4. ✅ Testa URLs dos .deb (HTTP 200)
5. ✅ Testa instalação end-to-end em container Debian:
   - Download da chave GPG
   - Configuração de `/etc/apt/sources.list.d/emacspeak.list`
   - `apt update`
   - `apt install emacspeak`
   - Validação de arquivos instalados

**Uso local:**
```bash
# Testar repositório publicado
bash tests/test-apt-repository.sh

# Testar URL customizada
APT_BASE_URL="http://localhost:8000/debian" bash tests/test-apt-repository.sh
```

**Variáveis de ambiente:**
- `APT_BASE_URL` - URL base do repositório (padrão: GitHub Pages)
- `DIST` - Distribuição (padrão: `stable`)
- `COMPONENT` - Componente (padrão: `main`)
- `ARCH` - Arquitetura (padrão: `amd64`)

---

## 📊 Pipeline Completo

### Fluxo de Desenvolvimento

```
┌─────────────────────────┐
│ Developer Push/PR       │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ CI: Build and Tests     │◄─── Pull Request / Push
├─────────────────────────┤
│ • Build com Docker      │
│ • Test Integrity        │
│ • Upload Artifacts      │
└───────────┬─────────────┘
            │
            ▼ (merge to main)
┌─────────────────────────┐
│ APT Repository Test     │◄─── Push to main
├─────────────────────────┤
│ • Test GitHub Pages     │
│ • Test apt install      │
└─────────────────────────┘
```

### Fluxo de Release

```
┌─────────────────────────┐
│ Create Tag: vX.Y.Z      │
└───────────┬─────────────┘
            │
            ├──────────────────┬─────────────────┐
            ▼                  ▼                 ▼
┌───────────────────┐  ┌──────────────┐  ┌─────────────┐
│ Release Packages  │  │ Publish APT  │  │ CI Tests    │
├───────────────────┤  ├──────────────┤  ├─────────────┤
│ • Build           │  │ • Build      │  │ • Build     │
│ • SHA256 Sums     │  │ • Sign GPG   │  │ • Test      │
│ • GitHub Release  │  │ • gh-pages   │  │             │
└───────────────────┘  └──────────────┘  └─────────────┘
            │                  │                 │
            ▼                  ▼                 ▼
     GitHub Release      GitHub Pages      CI Report
```

---

## 🎯 Comandos Úteis

### Desenvolvimento Local

```bash
# Build completo com testes
make automate

# Teste de integridade
bash tests/test-packages-integrity.sh

# Gerar repositório APT local
make apt-repo

# Assinar repositório local
make apt-sign KEY_ID=<your-gpg-key-id>

# Testar repositório local (servidor HTTP)
cd apt-repo && python3 -m http.server 8000
# Em outro terminal:
APT_BASE_URL="http://localhost:8000/debian" bash tests/test-apt-repository.sh
```

### Triggering Workflows

```bash
# Trigger CI manualmente
gh workflow run ci-tests.yml

# Criar release v60.0-1
git tag v60.0-1
git push origin v60.0-1

# Trigger publicação APT manualmente
gh workflow run publish-apt-repo.yml
```

### Monitoramento

```bash
# Ver status dos workflows
gh workflow list

# Ver runs recentes
gh run list --workflow=ci-tests.yml

# Ver logs de um run
gh run view <run-id> --log
```

---

## 🐛 Troubleshooting

### CI Tests Falhando

**Problema:** `test-packages-integrity.sh` falha com "Pacote não encontrado"

**Solução:**
```bash
# Verificar se build gerou pacotes
ls -lh output/*.deb

# Verificar logs do Docker
make logs
```

---

### APT Repository Test Falhando

**Problema:** `test-apt-repository.sh` falha com "Release não encontrado"

**Causa:** GitHub Pages ainda não publicou ou está desabilitado.

**Solução:**
1. Verificar status: Settings > Pages
2. Aguardar ~5 minutos após primeiro deploy
3. Verificar URL: https://a11ydevs.github.io/emacspeak-a11ydevs/debian/dists/stable/Release

---

### Release Workflow Falhando

**Problema:** "Tag inválida"

**Causa:** Tag não segue formato `vX.Y.Z`

**Solução:**
```bash
# Formato correto
git tag v60.0-1
git tag v60.0-2

# Formato INCORRETO
git tag 60.0
git tag release-60.0
```

---

### Assinatura GPG Falhando

**Problema:** "No secret key" ou "Signing failed"

**Causa:** Secret `APT_GPG_PRIVATE_KEY_B64` não configurado ou inválido.

**Solução:**
1. Verificar secret em Settings > Secrets > Actions
2. Regenerar chave:
   ```bash
   gpg --export-secret-keys "${KEY_ID}" | base64 > emacspeak-private-key.b64
   cat emacspeak-private-key.b64  # Copiar e colar no secret
   ```
3. Verificar `APT_GPG_PASSPHRASE`:
   - Se chave tem senha: configurar secret com a senha
   - Se chave sem senha: deixar secret vazio ou com espaço

Consulte [docs/gpg-setup.md](../docs/gpg-setup.md) para mais detalhes.

---

## 📚 Referências

- [GitHub Actions Documentation](https://docs.github.com/actions)
- [GitHub Pages](https://docs.github.com/pages)
- [Debian APT Repository Format](https://wiki.debian.org/DebianRepository/Format)
- [apt-ftparchive Manual](https://manpages.debian.org/testing/apt-utils/apt-ftparchive.1.en.html)
- [GnuPG Documentation](https://www.gnupg.org/documentation/)

---

*Última atualização: 28 de Abril de 2026*
