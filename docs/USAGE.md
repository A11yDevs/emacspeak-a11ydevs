# Guia de Uso do Emacspeak

Guia completo para usar o Emacspeak 60.0 após a instalação.

## 📚 Índice

- [Primeiros Passos](#primeiros-passos)
- [Comandos Básicos](#comandos-básicos)
- [Navegação](#navegação)
- [Configuração de Voz](#configuração-de-voz)
- [Modos Especiais](#modos-especiais)
- [Dicas e Truques](#dicas-e-truques)

## 🚀 Primeiros Passos

### Iniciando o Emacspeak

```bash
# Opção 1: Emacs normal com Emacspeak carregado via init.el
emacs

# Opção 2: Emacs com carregamento manual
emacs --eval '(load-file "/opt/emacspeak/lisp/emacspeak-setup.el")'

# Opção 3: No container Docker
docker-compose exec runtime /usr/local/bin/start-emacspeak.sh
```

### Configuração Inicial

Adicione ao seu `~/.emacs` ou `~/.emacs.d/init.el`:

```elisp
;; Carrega o Emacspeak
(load-file "/opt/emacspeak/lisp/emacspeak-setup.el")

;; Ajusta velocidade (opcional)
(setq dtk-speech-rate 225)
```

## ⌨️ Comandos Básicos

### Prefixo do Emacspeak

O Emacspeak usa **C-e** (Control + e) como prefixo para a maioria dos comandos.

### Comandos de Fala Essenciais

| Comando | Função |
|---------|--------|
| `C-e d` | Fala data e hora |
| `C-e s` | Para a fala (silence) |
| `C-e b` | Fala o buffer inteiro |
| `C-e l` | Fala a linha atual |
| `C-e w` | Fala a palavra atual |
| `C-e c` | Fala o caractere atual |
| `C-e SPC` | Fala ponto (cursor) |
| `C-e p` | Fala parágrafo atual |
| `C-e r` | Fala região selecionada |

### Comandos de Navegação com Fala

| Comando | Função |
|---------|--------|
| `C-e n` | Fala próxima linha |
| `C-e p` | Fala linha anterior |
| `C-e f` | Fala próxima palavra |
| `C-e b` | Fala palavra anterior |
| `C-e [` | Fala sentença anterior |
| `C-e ]` | Fala próxima sentença |

### Controle de Velocidade

| Comando | Função |
|---------|--------|
| `C-e ]` | Aumenta velocidade |
| `C-e [` | Diminui velocidade |
| `C-e 0-9` | Define velocidade (0=lento, 9=rápido) |

### Informações do Sistema

| Comando | Função |
|---------|--------|
| `C-e d` | Data e hora |
| `C-e i` | Informações do modo |
| `C-e m` | Mensagem anterior |
| `C-e v` | Versão do Emacspeak |

## 🧭 Navegação Avançada

### Navegação por Estrutura

```
C-e C-n    - Próximo elemento (modo-dependente)
C-e C-p    - Elemento anterior
C-e C-f    - Próximo elemento estrutural
C-e C-b    - Elemento estrutural anterior
```

### Busca com Fala

```
C-s        - Busca incremental (fala matches)
C-r        - Busca reversa
C-e /      - Busca com fala detalhada
```

### Marcadores e Posições

```
C-SPC      - Define marca (falada)
C-x C-x    - Troca ponto e marca
C-e .      - Fala marca atual
```

## 🎵 Configuração de Voz

### Ajustando Parâmetros de Voz

```elisp
;; Velocidade (100-500)
(setq dtk-speech-rate 225)

;; Fator de caracteres
(setq dtk-character-scale 1.0)

;; Pontuação: 'all, 'some, 'none
(setq dtk-punctuation-mode 'some)
```

### Ecos de Feedback

```elisp
;; Ativar/desativar ecos
(setq emacspeak-line-echo t)      ;; Fala linha ao pressionar RET
(setq emacspeak-word-echo t)      ;; Fala palavra ao pressionar SPC
(setq emacspeak-character-echo t) ;; Fala caractere ao digitar
```

### Personalidades de Voz

O Emacspeak usa "personalidades" para distinguir diferentes tipos de texto:

```elisp
;; Ativar split-caps (fala CamelCase separadamente)
(setq emacspeak-split-caps t)
```

## 📝 Modos Especiais

### Org Mode

```
C-e o n    - Próximo heading
C-e o p    - Heading anterior
C-e o t    - Fala árvore
C-e o s    - Fala subtree
```

### Dired (Navegador de Arquivos)

```
n          - Próximo arquivo (falado)
p          - Arquivo anterior (falado)
RET        - Abre arquivo
d          - Marca para deletar
u          - Desmarca
x          - Executa ações marcadas
C-e C-s    - Fala estatísticas do arquivo
```

### EWW (Navegador Web)

```
G          - Abre URL
l          - Volta histórico
r          - Avança histórico
w          - Copia URL
C-e C-n    - Próximo link
C-e C-p    - Link anterior
```

### Shell Mode

```
C-e C-n    - Próximo prompt
C-e C-p    - Prompt anterior
C-e o      - Fala output do último comando
```

## ⚡ Dicas e Truques

### 1. Silenciar Rapidamente

```
C-e s      - Para a fala imediatamente
```

### 2. Repetir Última Mensagem

```
C-e m      - Repete última mensagem falada
```

### 3. Soletrar Palavra

```
C-e w C-e  - Soletra palavra atual
```

### 4. Ler por Linhas com Pausa

```
C-e RET    - Lê próximas N linhas (prompt)
```

### 5. Fala Seletiva

```
C-e r      - Fala apenas região selecionada
```

### 6. Informações de Contexto

```
C-e i      - Informações do modo atual
C-e .      - Posição atual no buffer
```

### 7. Copiar como Fala

```
C-e y      - Fala último texto copiado
```

### 8. Filtros de Fala

```
C-e f      - Aplica filtro de fala
```

## 🛠️ Personalização Avançada

### Criar Atalhos Personalizados

```elisp
;; Atalho para falar buffer inteiro
(global-set-key (kbd "C-c b") 'emacspeak-speak-buffer)

;; Atalho para ajustar velocidade
(global-set-key (kbd "C-c +") 'dtk-increase-speed)
(global-set-key (kbd "C-c -") 'dtk-decrease-speed)
```

### Função Personalizada

```elisp
(defun my-speak-file-name ()
  "Fala o nome do arquivo atual."
  (interactive)
  (dtk-speak (buffer-file-name)))

(global-set-key (kbd "C-c f") 'my-speak-file-name)
```

### Hooks para Modos

```elisp
;; Anunciar ao entrar em um modo
(add-hook 'python-mode-hook
  (lambda ()
    (emacspeak-play-auditory-icon 'open-object)
    (message "Python mode ativado")))
```

## 🐛 Troubleshooting

### Sem Som

```bash
# Verifique espeak-ng
echo "teste" | espeak-ng

# Verifique servidor TTS
ps aux | grep espeak
```

### Fala Muito Rápida/Lenta

```elisp
;; Ajuste no init.el
(setq dtk-speech-rate 180)  ;; Mais lento
(setq dtk-speech-rate 300)  ;; Mais rápido
```

### Reiniciar Servidor de Fala

```elisp
M-x dtk-initialize
```

### Verificar Configuração

```
C-e C-s    - Fala configurações atuais
```

## 📚 Recursos Adicionais

### Documentação Oficial

- [Manual do Emacspeak](https://tvraman.github.io/emacspeak/manual/)
- [Lista de Comandos](https://tvraman.github.io/emacspeak/commands.html)
- [Tutorial em Vídeo](https://www.youtube.com/results?search_query=emacspeak+tutorial)

### Comunidade

- **Lista de Discussão:** emacspeak@googlegroups.com
- **GitHub:** https://github.com/tvraman/emacspeak
- **IRC:** #emacs no libera.chat

### Exemplos de Configuração

Veja [docs/emacspeak-config-example.el](emacspeak-config-example.el) para um arquivo de configuração completo comentado.

## 💡 Workflow Sugerido

### Para Programação

1. Use `C-e l` para ouvir linhas de código
2. Use `C-e w` para ouvir palavras específicas
3. Use `org-mode` para documentação com estrutura
4. Configure `flycheck` para feedback de erros falado

### Para Escrita

1. Ative `emacspeak-word-echo` para feedback ao escrever
2. Use `org-mode` para documentos estruturados
3. Use `C-e p` para ouvir parágrafos
4. Configure spell-checking com `flyspell`

### Para Navegação Web

1. Use `eww` como navegador integrado
2. `C-e C-n`/`C-e C-p` para navegar links
3. Configure bookmarks para acesso rápido
4. Use `C-e b` para ouvir página inteira

## 🎓 Pratique

Comece com estes exercícios:

1. Abra um arquivo de texto e pratique `C-e l`, `C-e w`, `C-e c`
2. Navegue em dired com `n` e `p`
3. Abra um site com eww e navegue por links
4. Ajuste velocidade com `C-e [` e `C-e ]`
5. Crie seu próprio atalho personalizado

---

**Divirta-se com o Emacspeak!** 🎉

*"The Complete Audio Desktop" - T. V. Raman*
