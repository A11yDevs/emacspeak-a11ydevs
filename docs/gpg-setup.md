# Configuração de Chaves GPG para o Repositório APT

Guia passo a passo para gerar e configurar chaves GPG para assinar o repositório APT do Emacspeak.

---

## 📋 Visão Geral

O repositório APT usa assinaturas GPG para garantir a autenticidade e integridade dos pacotes. Este guia mostra como:

1. Gerar um par de chaves GPG
2. Exportar as chaves nos formatos necessários
3. Configurar os GitHub Secrets
4. Verificar a configuração

---

## 🔐 Passo 1: Gerar Chaves GPG

### Instalar GnuPG

```bash
# Debian/Ubuntu
sudo apt install gnupg

# macOS
brew install gnupg

# Verificar instalação
gpg --version
```

### Gerar Par de Chaves

```bash
gpg --full-generate-key
```

**Configure quando solicitado:**

1. **Tipo de chave:** `(1) RSA and RSA` (padrão)
2. **Tamanho:** `4096` bits (recomendado para segurança)
3. **Validade:**
   - `0` = Não expira (mais simples)
   - `2y` = Expira em 2 anos (mais seguro)
4. **Nome:** `Emacspeak A11y Repository`
5. **Email:** `emacspeak@a11ydevs.github.io`
6. **Comentário:** `APT repository signing key` (opcional)
7. **Senha:** Defina uma senha forte ou deixe vazio para uso automatizado

**Exemplo de saída:**
```
pub   rsa4096 2026-04-28 [SC]
      ABCD1234EFGH5678IJKL9012MNOP3456QRST7890
uid           [ultimate] Emacspeak A11y Repository <emacspeak@a11ydevs.github.io>
sub   rsa4096 2026-04-28 [E]
```

---

## 📤 Passo 2: Exportar Chaves

### Obter o KEY_ID

```bash
# Listar chaves disponíveis
gpg --list-secret-keys --keyid-format=long

# A saída será algo como:
# sec   rsa4096/ABCD1234EFGH5678 2026-04-28 [SC]
#       Fingerprint: ABCD 1234 EFGH 5678 IJKL  9012 MNOP 3456 QRST 7890
# uid           [ultimate] Emacspeak A11y Repository <emacspeak@a11ydevs.github.io>

# O KEY_ID é: ABCD1234EFGH5678 (parte após rsa4096/)
```

**Defina uma variável com seu KEY_ID:**
```bash
export KEY_ID="ABCD1234EFGH5678"  # Substitua pelo seu KEY_ID real
```

### Exportar Chave Privada (para GitHub Secrets)

```bash
# Exportar em base64 (formato necessário para GitHub)
gpg --export-secret-keys "${KEY_ID}" | base64 > emacspeak-private-key.b64

# Verificar arquivo
ls -lh emacspeak-private-key.b64
```

⚠️ **IMPORTANTE:** Este arquivo contém sua chave privada. Mantenha-o seguro!

### Exportar Chave Pública (para usuários finais)

```bash
# Formato ASCII (legível)
gpg --export --armor "${KEY_ID}" > emacspeak-archive-keyring.asc

# Formato binário (usado pelo APT)
gpg --export "${KEY_ID}" > emacspeak-archive-keyring.gpg

# Verificar arquivos
ls -lh emacspeak-archive-keyring.*
```

---

## 🔧 Passo 3: Configurar GitHub Secrets

### 1. Acessar Settings no GitHub

1. Vá para: https://github.com/A11yDevs/emacspeak-a11ydevs/settings/secrets/actions
2. Ou: **Settings** > **Secrets and variables** > **Actions**

### 2. Adicionar Secret: APT_GPG_PRIVATE_KEY_B64

1. Clique em **New repository secret**
2. **Name:** `APT_GPG_PRIVATE_KEY_B64`
3. **Secret:** Cole o conteúdo de `emacspeak-private-key.b64`
   ```bash
   # Copiar para clipboard (macOS)
   cat emacspeak-private-key.b64 | pbcopy

   # Ou exibir para copiar manualmente
   cat emacspeak-private-key.b64
   ```
4. Clique em **Add secret**

### 3. Adicionar Secret: APT_GPG_PASSPHRASE

1. Clique em **New repository secret**
2. **Name:** `APT_GPG_PASSPHRASE`
3. **Secret:**
   - Se sua chave **tem senha:** Digite a senha
   - Se sua chave **não tem senha:** Deixe vazio ou digite um espaço
4. Clique em **Add secret**

### Verificar Secrets Configurados

Você deve ver:
- ✅ `APT_GPG_PRIVATE_KEY_B64`
- ✅ `APT_GPG_PASSPHRASE`

---

## ✅ Passo 4: Verificar Configuração

### Testar Importação da Chave

```bash
# Criar ambiente temporário
mkdir -p /tmp/gpg-test
export GNUPGHOME=/tmp/gpg-test

# Importar chave do base64
cat emacspeak-private-key.b64 | base64 -d | gpg --import

# Listar chaves importadas
gpg --list-secret-keys

# Limpar
rm -rf /tmp/gpg-test
unset GNUPGHOME
```

### Testar Assinatura

```bash
# Criar arquivo de teste
echo "Test content" > test.txt

# Assinar
gpg --default-key "${KEY_ID}" --armor --detach-sign test.txt

# Verificar
gpg --verify test.txt.asc test.txt

# Limpar
rm test.txt test.txt.asc
```

---

## 🚀 Passo 5: Executar Workflow

### Trigger Manual

1. Vá para: **Actions** > **Publish APT Repository**
2. Clique em **Run workflow**
3. Selecione branch `main`
4. Clique em **Run workflow**

### Monitorar Execução

Acompanhe o progresso em **Actions**. O workflow deve:

1. ✅ Build dos pacotes
2. ✅ Gerar estrutura APT
3. ✅ Importar chave GPG
4. ✅ Assinar repositório
5. ✅ Deploy no GitHub Pages

### Verificar Publicação

Após ~5 minutos:

```bash
# Verificar Release assinado
curl -I https://a11ydevs.github.io/emacspeak-a11ydevs/debian/dists/stable/Release

# Verificar chave pública
curl https://a11ydevs.github.io/emacspeak-a11ydevs/debian/emacspeak-archive-keyring.gpg | gpg --show-keys

# Testar instalação (em VM/container)
sudo curl -fsSL https://a11ydevs.github.io/emacspeak-a11ydevs/debian/emacspeak-archive-keyring.gpg \
  -o /usr/share/keyrings/emacspeak-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/emacspeak-archive-keyring.gpg] \
  https://a11ydevs.github.io/emacspeak-a11ydevs/debian stable main" | \
  sudo tee /etc/apt/sources.list.d/emacspeak.list

sudo apt update
```

---

## 🔄 Rotação de Chaves

### Quando Rotacionar

- **Obrigatório:**
  - Chave comprometida
  - Senha da chave vazada
  - Acesso não autorizado aos secrets

- **Recomendado:**
  - Chave com data de expiração próxima
  - Mudança de administradores
  - Auditoria de segurança

### Como Rotacionar

1. **Gerar nova chave** (seguir Passo 1)
2. **Exportar nova chave** (seguir Passo 2)
3. **Atualizar secrets** no GitHub (seguir Passo 3)
4. **Executar workflow** para republica
5. **Comunicar aos usuários:**
   ```bash
   # Usuários precisam baixar nova chave
   sudo curl -fsSL https://a11ydevs.github.io/emacspeak-a11ydevs/debian/emacspeak-archive-keyring.gpg \
     -o /usr/share/keyrings/emacspeak-archive-keyring.gpg
   sudo apt update
   ```

### Revogar Chave Antiga

```bash
# Gerar certificado de revogação
gpg --output revoke-${KEY_ID}.asc --gen-revoke "${KEY_ID}"

# Publicar revogação em servidor de chaves
gpg --send-keys "${KEY_ID}"
gpg --import revoke-${KEY_ID}.asc
gpg --send-keys "${KEY_ID}"
```

---

## 🐛 Troubleshooting

### Erro: "No secret key"

**Causa:** Chave não foi importada corretamente.

**Solução:**
```bash
# Verificar conteúdo do secret
echo "${APT_GPG_PRIVATE_KEY_B64}" | base64 -d | gpg --show-keys

# Reimportar
echo "${APT_GPG_PRIVATE_KEY_B64}" | base64 -d | gpg --import
```

### Erro: "Inappropriate ioctl for device"

**Causa:** GPG tentando usar terminal interativo no CI.

**Solução:** Já configurado no workflow com:
```yaml
env:
  GPG_TTY: $(tty)
```

### Erro: "Signing failed: No pinentry"

**Causa:** Senha da chave não configurada corretamente.

**Solução:**
- Verificar secret `APT_GPG_PASSPHRASE`
- Considerar gerar chave sem senha para automação

### Secret não reconhecido no workflow

**Causa:** Secret não foi salvo ou nome incorreto.

**Solução:**
1. Verificar nome exato: `APT_GPG_PRIVATE_KEY_B64` (case-sensitive)
2. Confirmar que secret está no nível de **repositório**, não de ambiente
3. Reexecutar workflow após salvar secret

---

## 📚 Referências

- [GnuPG Manual](https://www.gnupg.org/documentation/manuals/gnupg/)
- [GitHub Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Debian APT Secure](https://wiki.debian.org/SecureApt)
- [GPG Best Practices](https://riseup.net/en/security/message-security/openpgp/best-practices)

---

## 🔒 Segurança

### Boas Práticas

- ✅ Use chaves de 4096 bits
- ✅ Defina data de expiração (2 anos recomendado)
- ✅ Faça backup da chave privada em local seguro
- ✅ Nunca compartilhe a chave privada
- ✅ Rotacione chaves periodicamente
- ✅ Use senhas fortes ou HSM para chaves críticas

### Backup da Chave

```bash
# Backup completo
gpg --export-secret-keys --armor "${KEY_ID}" > backup-secret-key.asc
gpg --export-ownertrust > backup-ownertrust.txt

# Armazenar em local seguro:
# - Password manager (LastPass, 1Password, Bitwarden)
# - Hardware token (YubiKey, Nitrokey)
# - Cofre físico
```

---

*Última atualização: 28 de Abril de 2026*
