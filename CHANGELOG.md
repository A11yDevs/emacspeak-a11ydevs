# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [60.0-1] - 2026-04-15

### Adicionado

#### Infraestrutura de Build
- Dockerfile multi-stage (builder, tester, runtime) para construção de pacotes Debian
- docker-compose.yml para orquestração de containers
- Sistema de build automatizado com scripts Bash
- Makefile com comandos convenientes
- GitHub Actions workflow para CI/CD automático

#### Arquivos de Controle Debian
- debian/control com metadados e dependências do pacote
- debian/changelog com histórico de versões
- debian/rules com regras de build personalizadas
- debian/compat para compatibilidade debhelper 13
- debian/copyright com informações de licenciamento
- debian/postinst para configuração pós-instalação

#### Scripts
- scripts/build-package.sh - Constrói pacotes .deb completos
- scripts/test-package.sh - Suite de 18 testes automatizados
- scripts/run-tests.sh - Executa testes em container Docker

#### Documentação
- README.md completo com instruções detalhadas
- QUICKSTART.md para início rápido
- CONTRIBUTING.md com guia para contribuidores
- Documentação inline em scripts e Dockerfiles

#### Features do Emacspeak
- Compilação do Emacspeak 60.0 a partir do fonte
- Pré-compilação nativa de arquivos Elisp para performance
- Servidor TTS nativo espeak compilado
- Servidor espeak-socat para relay TCP (suporte macOS)
- Configuração otimizada de native compilation do Emacs
- Cache persistente de arquivos .eln via volumes Docker
- Suporte a múltiplos backends TTS

#### Testes
- Verificação de instalação de arquivos
- Validação de estrutura de diretórios
- Testes de sintaxe Elisp
- Verificação de dependências do sistema
- Testes de permissões de executáveis
- Validação de servidores TTS
- Testes de integração com Emacs

### Configuração
- Variáveis de ambiente configuráveis (.env.example)
- Configuração automática do Emacs (init.el, early-init.el)
- Script de inicialização personalizado (start-emacspeak.sh)
- Suporte a volumes Docker para persistência

### Ferramentas de Desenvolvimento
- Lintian para verificação de qualidade dos pacotes
- Build artifacts (*.deb, *.buildinfo, *.changes)
- Suporte a build paralelo com múltiplos cores

## [Unreleased]

### Planejado

- Suporte a Ubuntu LTS (22.04, 24.04)
- Pacotes para Fedora/RPM
- Repositório APT para instalação direta
- Suporte a múltiplos backends TTS adicionais (Festival, Flite)
- Testes de integração expandidos
- Documentação em múltiplos idiomas
- Script de migração de versões antigas

---

## Notas de Versão

### [60.0-1] - Release Inicial

Esta é a primeira release do projeto de empacotamento Debian do Emacspeak.

**Compatibilidade:**
- Debian Trixie (testing)
- Arquitetura: amd64 (x86_64)
- Emacs: 28+ com native compilation

**Dependências Principais:**
- emacs-nox (ou variantes gtk/lucid)
- espeak-ng e espeak-ng-data
- tcl e tclx8.4

**Instalação:**
```bash
sudo dpkg -i emacspeak_60.0-1_amd64.deb
sudo apt-get install -f
```

**Uso:**
```elisp
;; Adicione ao seu ~/.emacs
(load-file "/opt/emacspeak/lisp/emacspeak-setup.el")
```

**Bugs Conhecidos:**
- Nenhum relatado ainda

**Agradecimentos:**
- T. V. Raman pelo Emacspeak
- Comunidade Debian pelos padrões de empacotamento
- Projeto espeak-ng pelo sintetizador TTS

---

Para detalhes completos de cada mudança, veja os commits no Git:
https://github.com/A11yDevs/emacspeak-a11ydevs/commits/main
