# Guia de Contribuição

Obrigado por considerar contribuir com o projeto Emacspeak Debian Packaging! 

## 🤝 Como Contribuir

### Reportando Bugs

Se você encontrou um bug, por favor abra uma issue incluindo:

- **Descrição clara** do problema
- **Passos para reproduzir** o comportamento
- **Comportamento esperado** vs. comportamento atual
- **Ambiente:** Versão do Docker, SO, arquitetura
- **Logs** relevantes (se aplicável)

### Sugerindo Melhorias

Sugestões são sempre bem-vindas! Inclua:

- **Descrição detalhada** da melhoria
- **Justificativa:** Por que isso seria útil?
- **Exemplos** de uso, se aplicável

### Pull Requests

1. **Fork** o repositório
2. **Clone** seu fork localmente
   ```bash
   git clone https://github.com/seu-usuario/emacspeak-a11ydevs.git
   cd emacspeak-a11ydevs
   ```

3. **Crie uma branch** para sua feature
   ```bash
   git checkout -b feature/minha-feature
   ```

4. **Faça suas alterações** seguindo as diretrizes abaixo

5. **Teste suas alterações**
   ```bash
   make build
   make test
   make lint
   ```

6. **Commit** suas mudanças com mensagens descritivas
   ```bash
   git commit -m "Adiciona feature X que resolve Y"
   ```

7. **Push** para sua branch
   ```bash
   git push origin feature/minha-feature
   ```

8. **Abra um Pull Request** com:
   - Descrição clara das mudanças
   - Referência a issues relacionadas
   - Screenshots/logs se aplicável

## 📋 Diretrizes de Código

### Estrutura de Arquivos

- **Dockerfile:** Multi-stage builds bem documentados
- **debian/:** Seguir padrões Debian Policy
- **scripts/:** Scripts Bash com `set -euo pipefail`
- **Documentação:** Manter README.md atualizado

### Estilo de Código

#### Shell Scripts

```bash
#!/usr/bin/env bash
# Descrição do script

set -euo pipefail  # Fail fast

# Variáveis em MAIÚSCULAS
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Funções bem nomeadas
function build_package() {
    local package_name="$1"
    # ...
}
```

#### Dockerfile

```dockerfile
# Comentários claros em cada seção
FROM debian:trixie-slim AS builder

# Agrupe instalações relacionadas
RUN apt-get update && apt-get install -y --no-install-recommends \
    package1 \
    package2 \
 && rm -rf /var/lib/apt/lists/*

# Uma operação por RUN para melhor cache
RUN make config
RUN make build
```

#### Debian Control Files

- Seguir [Debian Policy Manual](https://www.debian.org/doc/debian-policy/)
- Versões explícitas de dependências quando necessário
- Descrições claras e concisas

### Testes

Todo novo código deve incluir testes:

```bash
# scripts/test-package.sh
run_test "Descrição do teste" \
    "comando_de_teste"
```

### Documentação

- Comentários em código complexo
- Atualizar README.md para novas features
- Incluir exemplos de uso

## 🔍 Checklist de PR

Antes de enviar seu PR, verifique:

- [ ] Código segue as diretrizes de estilo
- [ ] Testes passam localmente (`make test`)
- [ ] Build é bem-sucedido (`make build`)
- [ ] Lintian não reporta erros críticos (`make lint`)
- [ ] Documentação atualizada
- [ ] Commit messages são descritivos
- [ ] Branch está atualizada com main
- [ ] Sem conflitos de merge

## 🏷️ Versionamento

Seguimos [Semantic Versioning](https://semver.org/):

- **MAJOR.MINOR.PATCH-REVISION** (ex: 30.0-1)
- MAJOR.MINOR: Versão do Emacspeak upstream
- PATCH: Correções de bugs do pacote
- REVISION: Número de revisão do pacote Debian

## 📝 Mensagens de Commit

Formato recomendado:

```
Tipo: Breve descrição (máx 50 caracteres)

Descrição detalhada do que foi mudado e por quê.
Pode ter múltiplas linhas.

Refs: #123
```

**Tipos:**
- `feat:` Nova feature
- `fix:` Correção de bug
- `docs:` Apenas documentação
- `style:` Formatação, espaços, etc.
- `refactor:` Refatoração de código
- `test:` Adição/modificação de testes
- `chore:` Manutenção, build, etc.

**Exemplos:**

```
feat: Adiciona suporte a Ubuntu 24.04

- Atualiza Dockerfile para multi-distro
- Adiciona scripts de detecção de distro
- Atualiza documentação

Refs: #42
```

```
fix: Corrige permissões do servidor TTS

O servidor espeak não estava sendo marcado como executável
durante a instalação.

Refs: #56
```

## 🧪 Executando Testes

```bash
# Build completo
make build

# Testes
make test

# Lint
make lint

# Release completo
make release
```

## 📦 Adicionando Novas Dependências

1. Adicione ao `debian/control` (Build-Depends ou Depends)
2. Atualize o Dockerfile se necessário
3. Documente no README.md
4. Teste a instalação limpa

## 🎯 Áreas para Contribuição

Contribuições são especialmente bem-vindas em:

- [ ] Suporte a outras distribuições (Ubuntu, Fedora)
- [ ] Testes adicionais
- [ ] Otimizações de build
- [ ] Documentação e tutoriais
- [ ] Suporte a backends TTS adicionais
- [ ] CI/CD pipelines
- [ ] Internacionalização (i18n)

## 💬 Comunicação

- **Issues:** Para bugs e sugestões
- **Pull Requests:** Para código
- **Discussions:** Para perguntas gerais
- **Email:** dev@a11ydevs.org

## 📜 Código de Conduta

Este projeto adere a um código de conduta respeitoso e inclusivo:

- Seja respeitoso e inclusivo
- Critique código, não pessoas
- Aceite feedback construtivo
- Foque no melhor para a comunidade

## 🙏 Agradecimentos

Suas contribuições fazem este projeto melhor para todos!

---

**Dúvidas?** Abra uma issue ou entre em contato!
