# Repositório APT - Emacspeak A11y

Documentação técnica do repositório APT para distribuição do Emacspeak.

---

## 📋 Visão Geral

O projeto publica automaticamente um repositório APT estático no GitHub Pages, permitindo instalação e atualização do Emacspeak via `apt` em sistemas Debian e Ubuntu.

### URLs do Repositório

- **Repositório APT:** https://a11ydevs.github.io/emacspeak-a11ydevs/debian
- **Chave pública GPG:** https://a11ydevs.github.io/emacspeak-a11ydevs/debian/emacspeak-archive-keyring.gpg
- **Página web:** https://a11ydevs.github.io/emacspeak-a11ydevs/

---

## 🚀 Instalação (Usuário Final)

### Passo 1: Adicionar Chave GPG

```bash
sudo curl -fsSL https://a11ydevs.github.io/emacspeak-a11ydevs/debian/emacspeak-archive-keyring.gpg \
  -o /usr/share/keyrings/emacspeak-archive-keyring.gpg
```

### Passo 2: Adicionar Repositório

```bash
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/emacspeak-archive-keyring.gpg] \
  https://a11ydevs.github.io/emacspeak-a11ydevs/debian stable main" | \
  sudo tee /etc/apt/sources.list.d/emacspeak.list
```

### Passo 3: Instalar Pacote

```bash
sudo apt update
sudo apt install emacspeak
```

### Atualização

```bash
sudo apt update
sudo apt upgrade
```

---

## 🔧 Arquitetura Técnica

### Estrutura do Repositório APT

```
debian/
├── dists/stable/
│   ├── main/binary-amd64/
│   │   ├── Packages           # Índice de pacotes
│   │   └── Packages.gz        # Índice comprimido
│   ├── Release                # Metadados do repositório
│   ├── Release.gpg            # Assinatura destacada
│   └── InRelease              # Assinatura inline
├── pool/main/e/emacspeak/
│   ├── emacspeak_60.0-1_amd64.deb
│   ├── emacspeak-dbgsym_60.0-1_amd64.deb
│   ├── emacspeak_60.0-1_amd64.buildinfo
│   └── emacspeak_60.0-1_amd64.changes
├── emacspeak-archive-keyring.gpg  # Chave pública (formato binário)
├── emacspeak-archive-keyring.asc  # Chave pública (formato ASCII)
└── LAST_UPDATED                   # Timestamp da última atualização
```

### Componentes

- **Suite:** `stable`
- **Componente:** `main`
- **Arquitetura:** `amd64`
- **Origin:** `Emacspeak A11y`
- **Label:** `Emacspeak Accessibility Repository`

---

## 🔐 Segurança e Assinaturas

### Chave GPG

O repositório é assinado com uma chave GPG dedicada para garantir autenticidade e integridade dos pacotes.

**Informações da chave:**
- **Nome:** Emacspeak A11y Repository
- **Email:** emacspeak@a11ydevs.github.io
- **Tipo:** RSA 4096 bits (recomendado)

### Verificação de Assinatura

```bash
# Importar chave pública
curl -fsSL https://a11ydevs.github.io/emacspeak-a11ydevs/debian/emacspeak-archive-keyring.asc | gpg --import

# Verificar Release
gpg --verify Release.gpg Release
```

---

## 🛠️ Desenvolvimento

### Configuração Inicial

#### 1. Gerar Chaves GPG

```bash
# Gerar par de chaves
gpg --full-generate-key

# Configurações recomendadas:
# - Tipo: RSA and RSA
# - Tamanho: 4096 bits
# - Validade: 0 (não expira) ou 2 anos
# - Nome: Emacspeak A11y Repository
# - Email: emacspeak@a11ydevs.github.io
```

#### 2. Exportar Chaves

```bash
# Obter KEY_ID
gpg --list-secret-keys --keyid-format=long

# Exportar chave privada em base64
gpg --export-secret-keys KEY_ID | base64 > private.key.b64

# Exportar chave pública
gpg --export --armor KEY_ID > emacspeak-archive-keyring.asc
gpg --export KEY_ID > emacspeak-archive-keyring.gpg
```

#### 3. Configurar GitHub Secrets

No repositório GitHub, vá em **Settings > Secrets and variables > Actions** e adicione:

| Secret | Valor | Descrição |
|--------|-------|-----------|
| `APT_GPG_PRIVATE_KEY_B64` | Conteúdo de `private.key.b64` | Chave privada GPG em base64 |
| `APT_GPG_PASSPHRASE` | Senha da chave (ou vazio) | Passphrase para desbloquear chave |

#### 4. Habilitar GitHub Pages

1. Vá em **Settings > Pages**
2. Configurar:
   - **Source:** Deploy from a branch
   - **Branch:** `gh-pages`
   - **Folder:** `/(root)`
3. Salvar

A URL do repositório será: `https://a11ydevs.github.io/emacspeak-a11ydevs/`

### Scripts Locais

#### Gerar Repositório APT Localmente

```bash
# Após build dos pacotes
./scripts/generate-apt-repo.sh output apt-repo
```

**Parâmetros:**
- `output/`: Diretório com pacotes .deb
- `apt-repo/`: Diretório de saída do repositório

**Saída:**
- Estrutura `apt-repo/debian/` criada
- Arquivo `Packages` e `Packages.gz` gerados
- Arquivo `Release` criado (não assinado)

#### Assinar Repositório

```bash
# Assinar com chave GPG específica
./scripts/sign-repo.sh apt-repo YOUR_KEY_ID

# Ou deixar escolher interativamente
./scripts/sign-repo.sh apt-repo
```

**Saída:**
- `Release.gpg` — Assinatura destacada
- `InRelease` — Assinatura inline
- `emacspeak-archive-keyring.gpg` — Chave pública exportada
- `emacspeak-archive-keyring.asc` — Chave pública em ASCII

### Workflow de CI/CD

O workflow `.github/workflows/publish-apt.yml` executa automaticamente em:

- **Push na branch `main`:** Publica versão de desenvolvimento
- **Tags `v*`:** Publica release estável e cria GitHub Release

**Etapas do workflow:**

1. **Build:** Constrói imagem Docker e gera pacotes .deb
2. **Generate APT:** Cria estrutura do repositório APT
3. **Sign:** Assina repositório com chave GPG dos secrets
4. **Deploy:** Publica no GitHub Pages (branch `gh-pages`)
5. **Release:** Cria GitHub Release com assets (apenas em tags)

---

## 🧪 Testes

### Teste Local (Docker)

```bash
# Criar container Debian
docker run -it --rm debian:bookworm bash

# Dentro do container:
apt update && apt install -y curl gnupg

# Adicionar repositório
curl -fsSL https://a11ydevs.github.io/emacspeak-a11ydevs/debian/emacspeak-archive-keyring.gpg \
  -o /usr/share/keyrings/emacspeak-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/emacspeak-archive-keyring.gpg] \
  https://a11ydevs.github.io/emacspeak-a11ydevs/debian stable main" \
  > /etc/apt/sources.list.d/emacspeak.list

# Instalar
apt update
apt install emacspeak

# Verificar
emacspeak --version
dpkg -l | grep emacspeak
```

### Teste em VM/WSL

```bash
# Em sistema Debian/Ubuntu real
sudo curl -fsSL https://a11ydevs.github.io/emacspeak-a11ydevs/debian/emacspeak-archive-keyring.gpg \
  -o /usr/share/keyrings/emacspeak-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/emacspeak-archive-keyring.gpg] \
  https://a11ydevs.github.io/emacspeak-a11ydevs/debian stable main" | \
  sudo tee /etc/apt/sources.list.d/emacspeak.list

sudo apt update
sudo apt install emacspeak
```

### Validação de Assinatura

```bash
# Verificar que o APT valida corretamente
sudo apt update
# Deve mostrar: "Get:X https://a11ydevs.github.io/emacspeak-a11ydevs/debian stable InRelease"
# Sem erros de assinatura

# Verificar manualmente
curl -fsSL https://a11ydevs.github.io/emacspeak-a11ydevs/debian/dists/stable/Release > Release
curl -fsSL https://a11ydevs.github.io/emacspeak-a11ydevs/debian/dists/stable/Release.gpg > Release.gpg
curl -fsSL https://a11ydevs.github.io/emacspeak-a11ydevs/debian/emacspeak-archive-keyring.asc | gpg --import
gpg --verify Release.gpg Release
```

---

## 🔍 Troubleshooting

### Erro: "Release file not found"

**Causa:** Workflow ainda não executou ou GitHub Pages não está ativo.

**Solução:**
1. Verificar workflow em **Actions**
2. Confirmar GitHub Pages ativo em **Settings > Pages**
3. Aguardar alguns minutos para propagação
4. Executar `sudo apt update` novamente

### Erro: "The following signatures couldn't be verified"

**Causa:** Chave GPG não foi importada ou está incorreta.

**Solução:**
```bash
# Reimportar chave
sudo rm /usr/share/keyrings/emacspeak-archive-keyring.gpg
sudo curl -fsSL https://a11ydevs.github.io/emacspeak-a11ydevs/debian/emacspeak-archive-keyring.gpg \
  -o /usr/share/keyrings/emacspeak-archive-keyring.gpg

sudo apt update
```

### Erro: "404 Not Found" ao baixar .deb

**Causa:** Cache local do APT desatualizado.

**Solução:**
```bash
sudo apt clean
sudo rm -rf /var/lib/apt/lists/*
sudo apt update
```

### Workflow falha na assinatura

**Causa:** Secrets não configurados ou chave GPG inválida.

**Solução:**
1. Verificar secrets em **Settings > Secrets**
2. Confirmar que `APT_GPG_PRIVATE_KEY_B64` está em base64 válido
3. Testar chave localmente:
   ```bash
   echo "CONTEUDO_DO_SECRET" | base64 -d | gpg --import
   gpg --list-secret-keys
   ```

---

## 📊 Monitoramento

### Verificar Publicação

```bash
# Verificar se repositório está acessível
curl -I https://a11ydevs.github.io/emacspeak-a11ydevs/debian/dists/stable/Release

# Verificar última atualização
curl https://a11ydevs.github.io/emacspeak-a11ydevs/debian/LAST_UPDATED

# Listar pacotes disponíveis
curl https://a11ydevs.github.io/emacspeak-a11ydevs/debian/dists/stable/main/binary-amd64/Packages
```

### Logs do Workflow

Acessar em **Actions > Publish APT Repository**

**Pontos importantes:**
- Build dos pacotes concluído
- Assinatura GPG bem-sucedida
- Deploy no gh-pages executado
- Nenhum erro 404 ou permission denied

---

## 🔄 Atualização de Pacotes

### Processo Automático

1. Fazer commit/push na branch `main` ou criar tag `vX.Y.Z`
2. Workflow executa automaticamente
3. Novos pacotes são buildados
4. Repositório APT é regerado e assinado
5. GitHub Pages atualizado
6. Usuários executam `sudo apt update && sudo apt upgrade`

### Versionamento

**Tags recomendadas:**
- `v60.0` — Release estável baseada no Emacspeak 60.0
- `v60.1` — Correções/melhorias na versão 60.0
- `v61.0` — Upgrade para Emacspeak 61.0

**Convenção:**
- Tags `v*` criam GitHub Releases + atualizam APT
- Pushes diretos na `main` apenas atualizam APT (desenvolvimento)

---

## 📚 Referências

- [Debian Repository Format](https://wiki.debian.org/DebianRepository/Format)
- [APT Secure](https://wiki.debian.org/SecureApt)
- [GitHub Pages](https://docs.github.com/en/pages)
- [GnuPG Manual](https://www.gnupg.org/documentation/manuals/gnupg/)
- [dpkg-scanpackages](https://man7.org/linux/man-pages/man1/dpkg-scanpackages.1.html)

---

## 📞 Suporte

- **Issues:** https://github.com/A11yDevs/emacspeak-a11ydevs/issues
- **Discussions:** https://github.com/A11yDevs/emacspeak-a11ydevs/discussions
- **Projeto Original:** https://github.com/tvraman/emacspeak

---

*Última atualização: 28 de Abril de 2026*
