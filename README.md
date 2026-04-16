# Emacspeak 60.0 - Pacotes Debian

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/gpl-2.0)
[![Debian](https://img.shields.io/badge/Debian-Trixie-red.svg)](https://www.debian.org/)
[![Emacspeak](https://img.shields.io/badge/Emacspeak-60.0-green.svg)](https://github.com/tvraman/emacspeak)

Sistema completo de construção de pacotes Debian para o **Emacspeak 60.0**, o revolucionário sistema de áudio desktop que fornece feedback auditivo completo para o GNU Emacs.

## 📋 Sobre o Projeto

Este projeto fornece uma infraestrutura completa para:

- ✅ Baixar o código-fonte do Emacspeak 60.0
- ✅ Compilar em ambiente Debian Trixie
- ✅ Criar pacotes `.deb` totalmente funcionais
- ✅ Executar testes automatizados em containers
- ✅ Suporte a múltiplos sintetizadores TTS (espeak-ng)
- ✅ Pré-compilação nativa de arquivos Elisp
- ✅ Configuração otimizada para produção

## 🚀 Início Rápido

### Pré-requisitos

- Docker (>= 20.10)
- Docker Compose (>= 1.29)
- 4GB de espaço em disco
- Conexão com a Internet

### Construindo o Pacote

#### Opção 1: Usando Scripts (Recomendado)

```bash
# Clone o repositório
git clone https://github.com/A11yDevs/emacspeak-a11ydevs.git
cd emacspeak-a11ydevs

# Dê permissão de execução aos scripts
chmod +x scripts/*.sh

# Construa o pacote
./scripts/build-package.sh
```

Os pacotes `.deb` serão criados no diretório `./output/`.

#### Opção 2: Usando Docker Compose

```bash
# Construir o pacote
docker-compose up builder

# Testar o pacote
docker-compose up tester

# Executar interativamente
docker-compose up -d runtime
docker-compose exec runtime /bin/bash
```

### Executando Testes

```bash
# Executar suite completa de testes
./scripts/run-tests.sh

# Ou usando Docker Compose
docker-compose run tester
```

## 📦 Estrutura do Projeto

```
emacspeak-a11ydevs/
├── Dockerfile              # Multi-stage build (builder, tester, runtime)
├── docker-compose.yml      # Orquestração de containers
├── .env.example            # Variáveis de ambiente de exemplo
├── README.md               # Este arquivo
├── LICENSE                 # Licença GPL-2
├── debian/                 # Arquivos de controle Debian
│   ├── control             # Metadados do pacote
│   ├── changelog           # Histórico de versões
│   ├── rules               # Regras de build
│   ├── compat              # Nível de compatibilidade debhelper
│   ├── copyright           # Informações de copyright
│   ├── install             # Arquivos a instalar
│   └── postinst            # Script pós-instalação
├── scripts/                # Scripts de automação
│   ├── build-package.sh    # Constrói pacotes .deb
│   ├── test-package.sh     # Suite de testes
│   └── run-tests.sh        # Executa testes no container
└── output/                 # Pacotes .deb gerados (criado automaticamente)
```

## 🔧 Uso Avançado

### Instalando o Pacote Gerado

```bash
# Em um sistema Debian/Ubuntu
sudo dpkg -i output/emacspeak_30.0-1_*.deb
sudo apt-get install -f  # Resolver dependências
```

### Usando o Emacspeak

Após a instalação:

```bash
# Adicione ao seu ~/.emacs ou ~/.emacs.d/init.el:
(load-file "/opt/emacspeak/lisp/emacspeak-setup.el")

# Ou execute diretamente:
emacs --eval '(load-file "/opt/emacspeak/lisp/emacspeak-setup.el")'
```

### Usando o Container Runtime

```bash
# Iniciar o container interativo
docker-compose up -d runtime

# Acessar o Emacspeak
docker-compose exec runtime /usr/local/bin/start-emacspeak.sh

# Ou em modo bash
docker-compose exec runtime /bin/bash
```

### Configurando TTS (Text-to-Speech)

#### Linux (ALSA/PulseAudio)

```bash
# Padrão: usa espeak-ng
export DTK_PROGRAM=espeak
```

#### macOS (via relay TCP)

```bash
# Use o servidor espeak-socat
export DTK_SPEECH_SERVER=espeak-socat

# Configure o relay no host (terminal separado)
nc -l 5500 | aplay
```

## 🧪 Testes

O projeto inclui uma suite completa de testes automatizados:

- ✅ Verificação de instalação de arquivos
- ✅ Validação de estrutura de diretórios
- ✅ Testes de sintaxe Elisp
- ✅ Verificação de dependências
- ✅ Testes de permissões
- ✅ Validação de servidores TTS
- ✅ Testes de integração Emacs

### Executando Testes Individuais

```bash
# Dentro do container
docker-compose exec tester /bin/bash

# Executar teste específico
emacs --batch --eval '(load-file "/opt/emacspeak/lisp/emacspeak-setup.el")'
```

## 📚 Documentação

### Emacspeak

- [Website Oficial](https://github.com/tvraman/emacspeak)
- [Manual do Usuário](https://tvraman.github.io/emacspeak/manual/)
- [Guia de Comandos](https://tvraman.github.io/emacspeak/commands.html)

### Debian Packaging

- [Debian New Maintainers' Guide](https://www.debian.org/doc/manuals/maint-guide/)
- [Debian Policy Manual](https://www.debian.org/doc/debian-policy/)

## 🐛 Troubleshooting

### Problema: Build falha com erro de dependências

**Solução:**
```bash
docker-compose build --no-cache builder
```

### Problema: Testes falham ao carregar Emacspeak

**Solução:**
Verifique se todas as dependências foram instaladas:
```bash
docker-compose run tester dpkg -l | grep -E '(emacs|espeak|tcl)'
```

### Problema: espeak-ng não sintetiza voz

**Solução:**
Verifique se o ALSA/PulseAudio está configurado ou use o modo relay TCP:
```bash
export DTK_SPEECH_SERVER=espeak-socat
```

### Problema: Cache ELN não persiste

**Solução:**
Use volumes nomeados do Docker:
```bash
docker volume create emacspeak-eln-cache
docker-compose up -d runtime
```

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'Adiciona MinhaFeature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto é licenciado sob a GPL-2.0 - veja o arquivo [LICENSE](LICENSE) para detalhes.

O Emacspeak original é Copyright © 1994-2024 T. V. Raman e licenciado sob GPL-2+.

## 👥 Autores

- **A11yDevs** - *Empacotamento Debian* - [@A11yDevs](https://github.com/A11yDevs)
- **T. V. Raman** - *Autor Original do Emacspeak* - [@tvraman](https://github.com/tvraman)

## 🙏 Agradecimentos

- T. V. Raman pelo desenvolvimento do Emacspeak
- Comunidade Debian pela infraestrutura de empacotamento
- Projeto espeak-ng pelo sintetizador TTS
- Comunidade GNU Emacs

## 📞 Suporte

- **Issues:** [GitHub Issues](https://github.com/A11yDevs/emacspeak-a11ydevs/issues)
- **Email:** dev@a11ydevs.org
- **Emacspeak Mailing List:** [emacspeak@googlegroups.com](https://groups.google.com/g/emacspeak)

## 🗺️ Roadmap

- [ ] Suporte a Ubuntu LTS (22.04, 24.04)
- [ ] Pacotes para Fedora/RPM
- [ ] CI/CD com GitHub Actions
- [ ] Repositório APT para instalação direta
- [ ] Suporte a múltiplos backends TTS (Festival, eSpeak, etc.)
- [ ] Testes de integração expandidos
- [ ] Documentação em múltiplos idiomas

---

**Desenvolvido com ❤️ pela comunidade de acessibilidade**
