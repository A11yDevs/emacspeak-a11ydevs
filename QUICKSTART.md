# 🚀 Quick Start - Emacspeak 60.0

Guia rápido para começar a usar o Emacspeak 60.0 em minutos!

## Para Usuários (Instalação)

### Opção 1: Instalar Pacote Pré-compilado (Recomendado)

```bash
# 1. Baixe o pacote .deb da última release
wget https://github.com/A11yDevs/emacspeak-a11ydevs/releases/latest/download/emacspeak_60.0-1_amd64.deb

# 2. Instale o pacote
sudo dpkg -i emacspeak_60.0-1_amd64.deb

# 3. Instale dependências (se necessário)
sudo apt-get install -f

# 4. Configure seu ~/.emacs ou ~/.emacs.d/init.el
echo '(load-file "/opt/emacspeak/lisp/emacspeak-setup.el")' >> ~/.emacs

# 5. Execute o Emacs
emacs
```

### Opção 2: Usar Container Docker

```bash
# 1. Clone o repositório
git clone https://github.com/A11yDevs/emacspeak-a11ydevs.git
cd emacspeak-a11ydevs

# 2. Execute o container
docker-compose up -d runtime
docker-compose exec runtime /usr/local/bin/start-emacspeak.sh
```

## Para Desenvolvedores (Build)

### Build Rápido com Make

```bash
# 1. Clone o repositório
git clone https://github.com/A11yDevs/emacspeak-a11ydevs.git
cd emacspeak-a11ydevs

# 2. Build tudo
make release

# 3. Os pacotes estarão em ./output/
ls -lh output/*.deb
```

### Build Passo a Passo

```bash
# 1. Clone
git clone https://github.com/A11yDevs/emacspeak-a11ydevs.git
cd emacspeak-a11ydevs

# 2. Torne scripts executáveis
chmod +x scripts/*.sh

# 3. Construa o pacote
./scripts/build-package.sh

# 4. Execute testes
./scripts/run-tests.sh

# 5. Verifique com lintian
make lint
```

## Primeiros Passos com Emacspeak

### Comandos Básicos

Após iniciar o Emacs com Emacspeak:

- **C-e d** - Fala a data e hora
- **C-e s** - Para a fala (silence)
- **C-e b** - Fala o buffer atual
- **C-e l** - Fala a linha atual
- **C-e w** - Fala a palavra atual
- **C-e c** - Fala o caractere atual
- **C-e C-s** - Fala configurações do Emacspeak

### Configuração de Voz

```elisp
;; Adicione ao seu init.el para customizar:

;; Ajustar velocidade da fala (100-500)
(setq dtk-speech-rate 225)

;; Ativar ecos de linha
(setq emacspeak-line-echo t)

;; Ativar ecos de palavras
(setq emacspeak-word-echo t)

;; Desativar ícones auditivos (se preferir)
(setq emacspeak-use-auditory-icons nil)
```

### Usando Diferentes Sintetizadores TTS

#### Linux (padrão: espeak-ng)

```bash
# Padrão - espeak-ng via ALSA
export DTK_PROGRAM=espeak
emacs
```

#### macOS (via relay TCP)

```bash
# Terminal 1: Iniciar relay
nc -l 5500 | afplay -

# Terminal 2: Configurar e executar
export DTK_SPEECH_SERVER=espeak-socat
docker-compose up -d runtime
docker-compose exec -e DTK_SPEECH_SERVER=espeak-socat runtime start-emacspeak.sh
```

## Recursos Adicionais

### Documentação

- [README completo](README.md)
- [Guia de Contribuição](CONTRIBUTING.md)
- [Manual do Emacspeak](https://tvraman.github.io/emacspeak/manual/)

### Suporte

- **Issues:** https://github.com/A11yDevs/emacspeak-a11ydevs/issues
- **Email:** dev@a11ydevs.org
- **Lista de discussão:** emacspeak@googlegroups.com

### Comandos Úteis do Make

```bash
make help          # Mostra todos os comandos disponíveis
make build         # Constrói o pacote
make test          # Executa testes
make lint          # Executa lintian
make clean         # Limpa artefatos
make run-runtime   # Executa interativamente
make shell-runtime # Shell no container
```

## Troubleshooting Rápido

### Problema: Sem som

```bash
# Verifique se espeak-ng está funcionando
echo "teste" | espeak-ng

# Verifique ALSA/PulseAudio
aplay -l
pactl list sinks
```

### Problema: Emacspeak não carrega

```bash
# Teste manualmente
emacs --batch --eval '(load-file "/opt/emacspeak/lisp/emacspeak-setup.el")'
```

### Problema: Build falha

```bash
# Limpe e reconstrua
make clean-all
make build
```

## Próximos Passos

1. ✅ Instale o Emacspeak
2. 📖 Leia o [Manual do Usuário](https://tvraman.github.io/emacspeak/manual/)
3. ⌨️ Pratique os comandos básicos
4. 🎨 Customize conforme sua preferência
5. 🤝 Contribua com o projeto!

---

**Enjoy Emacspeak!** 🎉
