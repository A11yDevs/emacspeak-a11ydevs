;;; emacspeak-config-example.el --- Exemplo de configuração do Emacspeak
;;; Commentary:
;;
;; Este arquivo fornece um exemplo de configuração do Emacspeak 60.0
;; para uso em seu ~/.emacs ou ~/.emacs.d/init.el
;;
;; Para usar:
;; 1. Copie as seções desejadas para seu arquivo de configuração
;; 2. Ajuste os valores conforme suas preferências
;; 3. Reinicie o Emacs
;;

;;; Code:

;; ============================================================================
;; CONFIGURAÇÃO BÁSICA DO EMACSPEAK
;; ============================================================================

;; Define qual servidor TTS usar
;; Opções: "espeak", "espeak-socat", "native-espeak"
;; Linux: use "espeak" (padrão)
;; macOS: use "espeak-socat" com relay TCP
(setq dtk-program
      (let ((server (getenv "DTK_SPEECH_SERVER")))
        (if (and server (not (string= server "")))
            server
          "espeak")))

;; Desabilita o programa de reprodução de sons (opcional)
(setq emacspeak-play-program nil)

;; Desabilita ícones auditivos (sons de feedback)
;; Defina como 't' se quiser ativar
(setq emacspeak-use-auditory-icons nil)

;; Carrega o Emacspeak
(load-file "/opt/emacspeak/lisp/emacspeak-setup.el")

;; ============================================================================
;; CONFIGURAÇÕES DE VOZ E VELOCIDADE
;; ============================================================================

;; Velocidade da fala (100-500, padrão: 225)
;; Valores mais baixos = mais lento
;; Valores mais altos = mais rápido
(setq dtk-speech-rate 225)

;; Taxa de caracteres (para soletração)
(setq dtk-character-scale 1.0)

;; Pontuação: 'all, 'some, ou 'none
(setq dtk-punctuation-mode 'some)

;; ============================================================================
;; ECOS DE FEEDBACK
;; ============================================================================

;; Eco de linha (fala a linha ao pressionar RET)
(setq emacspeak-line-echo t)

;; Eco de palavra (fala a palavra ao pressionar SPC)
(setq emacspeak-word-echo nil)

;; Eco de caractere (fala o caractere ao digitar)
(setq emacspeak-character-echo nil)

;; ============================================================================
;; CONFIGURAÇÕES DE INTERFACE
;; ============================================================================

;; Silencia o beep do Emacs
(setq ring-bell-function 'ignore)

;; Remove a tela de boas-vindas
(setq inhibit-startup-screen t)

;; Mata processos automaticamente ao sair
(setq confirm-kill-processes nil)

;; ============================================================================
;; NATIVE COMPILATION (EMACS 28+)
;; ============================================================================

;; Desabilita JIT compilation (Emacspeak já está pré-compilado)
(setq native-comp-jit-compilation nil)

;; Diretório de cache de native compilation
(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache
   (or (getenv "EMACS_ELN_CACHE")
       (expand-file-name "eln-cache" user-emacs-directory))))

;; Registra diretório .eln do Emacspeak
(let ((emacspeak-eln-dir "/opt/emacspeak/eln"))
  (when (file-directory-p emacspeak-eln-dir)
    (dolist (sym '(comp-eln-load-path native-comp-eln-load-path))
      (when (boundp sym)
        (unless (member emacspeak-eln-dir (symbol-value sym))
          (set sym (cons emacspeak-eln-dir (symbol-value sym))))))))

;; ============================================================================
;; ATALHOS PERSONALIZADOS (OPCIONAL)
;; ============================================================================

;; Atalho para parar a fala rapidamente
(global-set-key (kbd "C-c s") 'dtk-stop)

;; Atalho para falar o buffer inteiro
(global-set-key (kbd "C-c b") 'emacspeak-speak-buffer)

;; Atalho para ajustar velocidade
(global-set-key (kbd "C-c +") 'dtk-increase-speed)
(global-set-key (kbd "C-c -") 'dtk-decrease-speed)

;; ============================================================================
;; CONFIGURAÇÕES AVANÇADAS (OPCIONAL)
;; ============================================================================

;; Diretórios do Emacspeak
(defvar emacspeak-xslt-directory "/opt/emacspeak/xsl"
  "Diretório de transformações XSLT do Emacspeak.")

(defvar emacspeak-sounds-dir "/opt/emacspeak/sounds/"
  "Diretório de sons do Emacspeak.")

;; Split caps: fala maiúsculas separadamente em CamelCase
;; (setq emacspeak-split-caps t)

;; Auto-fala de mensagens de ajuda
;; (setq emacspeak-speak-messages t)

;; ============================================================================
;; INTEGRAÇÃO COM MODOS ESPECÍFICOS (OPCIONAL)
;; ============================================================================

;; Configurações para org-mode
(with-eval-after-load 'org
  (require 'emacspeak-org nil t))

;; Configurações para eww (navegador web)
(with-eval-after-load 'eww
  (require 'emacspeak-eww nil t))

;; Configurações para dired
(with-eval-after-load 'dired
  (require 'emacspeak-dired nil t))

;; ============================================================================
;; TEMAS E APARÊNCIA (se usar interface gráfica)
;; ============================================================================

;; Se estiver usando Emacs com GUI, você pode querer um tema
;; (load-theme 'modus-vivendi t)  ;; Tema escuro de alto contraste
;; (load-theme 'modus-operandi t) ;; Tema claro de alto contraste

;; ============================================================================
;; FUNÇÕES ÚTEIS
;; ============================================================================

(defun my/emacspeak-restart-speech ()
  "Reinicia o servidor de fala do Emacspeak."
  (interactive)
  (dtk-stop)
  (dtk-initialize))

(defun my/emacspeak-toggle-character-echo ()
  "Alterna eco de caracteres on/off."
  (interactive)
  (setq emacspeak-character-echo (not emacspeak-character-echo))
  (message "Character echo: %s"
           (if emacspeak-character-echo "ON" "OFF")))

(defun my/emacspeak-toggle-word-echo ()
  "Alterna eco de palavras on/off."
  (interactive)
  (setq emacspeak-word-echo (not emacspeak-word-echo))
  (message "Word echo: %s"
           (if emacspeak-word-echo "ON" "OFF")))

;; Atalhos para funções úteis
(global-set-key (kbd "C-c e r") 'my/emacspeak-restart-speech)
(global-set-key (kbd "C-c e c") 'my/emacspeak-toggle-character-echo)
(global-set-key (kbd "C-c e w") 'my/emacspeak-toggle-word-echo)

;; ============================================================================
;; MENSAGEM DE INICIALIZAÇÃO
;; ============================================================================

(message "Emacspeak 60.0 configurado e pronto!")

(provide 'emacspeak-config-example)
;;; emacspeak-config-example.el ends here
