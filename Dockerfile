FROM debian:trixie-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV EMACSPEAK_VERSION=60.0
ENV DTK_PROGRAM=espeak
ENV EMACS_ELN_CACHE=/root/.emacs.d/eln-cache

# Instala dependências de build e runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    bash \
    make \
    gcc \
    g++ \
    libc6-dev \
    tcl \
    tcl8.6-dev \
    tclx8.4 \
    emacs-nox \
    espeak-ng \
    espeak-ng-data \
    libespeak-ng-dev \
    libespeak-ng-libespeak-dev \
    file \
    procps \
    curl \
    libcurl4 \
    libcurl4-openssl-dev \
    cmake \
    socat \
    debhelper \
    devscripts \
    dh-make \
    build-essential \
    fakeroot \
    lintian \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Baixa o código-fonte do Emacspeak 60.0
RUN git clone https://github.com/tvraman/emacspeak.git \
    && cd emacspeak \
    && git fetch --all --tags \
    && git checkout 60.0 \
    && git describe --tags

# Compila o Emacspeak
RUN cd /build/emacspeak \
    && make config \
    && make -j"$(nproc)"

# Compila o servidor nativo espeak
RUN cd /build/emacspeak/servers/native-espeak \
    && make clean || true \
    && make

# Cria o servidor espeak-socat
RUN cat > /build/emacspeak/servers/espeak-socat <<'EOF'
#!/usr/bin/tclsh
package require Tclx
set servers /opt/emacspeak/servers
source $servers/tts-lib.tcl

# --------------- backend TTS ---------------
proc synth {text} {
    global tts
    set tmpfile [exec mktemp /tmp/espk.XXXXXX]
    catch {
        set fh [open $tmpfile w]
        fconfigure $fh -encoding utf-8
        puts $fh $text
        close $fh
        exec espeak-ng -s $tts(speech_rate) -f $tmpfile --stdout \
             | socat - TCP4:host.docker.internal:5500
    }
    catch {file delete -force $tmpfile}
    return ""
}

proc stop {} {
    catch {exec pkill -f {espeak-ng.*--stdout}}
    return ""
}

proc speakingP {} { return 0 }

proc service {} {
    update idletasks
    return 0
}

proc setRate {ignore rate} {
    global tts
    set tts(speech_rate) [expr {int($rate)}]
    return ""
}

# --------------- protocolo emacspeak ---------------
proc tts_say {text} {
    synth "$text "
    return ""
}

proc l {text} {
    synth "$text "
    return ""
}

proc d {} { speech_task }

proc s {} {
    stop
    queue_clear
    return ""
}

proc t  {{pitch 440} {duration 50}} { return "" }
proc sh {{duration 50}} { return "" }

proc tts_set_speech_rate {rate} {
    global tts
    set tts(speech_rate) $rate
    return ""
}

proc tts_set_punctuations {mode} {
    global tts
    set tts(punctuations) $mode
    return ""
}

proc tts_set_character_scale {factor} {
    global tts
    set tts(char_factor) $factor
    return ""
}

proc tts_split_caps {flag} {
    global tts
    set tts(split_caps) $flag
    return ""
}

proc r {rate} {
    global queue tts
    set queue($tts(q_tail)) [list r $rate]
    incr tts(q_tail)
    return ""
}

proc tts_reset {} {
    stop
    queue_clear
    return ""
}

proc clean {element} {
    return $element
}

proc speech_task {} {
    global queue tts
    set tts(talking?) 1
    set length [queue_length]
    loop index 0 $length {
        set event [queue_remove]
        set event_type [lindex $event 0]
        switch -exact -- $event_type {
            s {
                synth "[clean [lindex $event 1]] "
            }
            c {
                synth "[lindex $event 1] "
            }
            a {
                catch {exec $tts(play) [lindex $event 1] >/dev/null &}
            }
            b {
                if {$tts(beep)} { eval beep [lreplace $event 0 0] }
            }
            r {
                set tts(speech_rate) [lindex $event 1]
            }
        }
        if {$tts(talking?) == 0} break
    }
    set tts(talking?) 0
    return ""
}

# --------------- inicialização ---------------
fconfigure stdin -encoding utf-8
tts_initialize
set tts(speech_rate) 225
set tts(char_factor) 1.0
set tts(play) "true"
commandloop
EOF

RUN chmod +x /build/emacspeak/servers/espeak-socat

# Pré-compila nativamente os arquivos do emacspeak
RUN cat > /tmp/precompile-emacspeak.el <<'ELISP'
(add-to-list 'load-path "/build/emacspeak/lisp")
(defvar emacspeak-xslt-directory "/build/emacspeak/xsl")
(defvar emacspeak-sounds-dir     "/build/emacspeak/sounds/")
(make-directory "/build/emacspeak/eln" t)
(dolist (sym '(comp-eln-load-path native-comp-eln-load-path))
  (when (boundp sym)
    (set sym (list "/build/emacspeak/eln/"))))
(when (fboundp 'native-compile)
  (dolist (f (directory-files "/build/emacspeak/lisp/" t))
    (when (and (string-match-p "\\.el$" f) (file-regular-p f))
      (condition-case err
          (native-compile f)
        (error (message "Skipped %s: %s" f (error-message-string err)))))))
ELISP

RUN emacs --batch -l /tmp/precompile-emacspeak.el || true

# Copia arquivos de controle Debian
COPY debian /build/emacspeak/debian

# Constrói o pacote Debian
WORKDIR /build/emacspeak
RUN dpkg-buildpackage -us -uc -b

# Executa lintian para verificar o pacote
RUN lintian /build/*.deb || true

# Stage de teste
FROM debian:trixie-slim AS tester

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV DTK_PROGRAM=espeak
ENV EMACS_ELN_CACHE=/root/.emacs.d/eln-cache

# Instala dependências de runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    emacs-nox \
    espeak-ng \
    espeak-ng-data \
    tcl \
    tclx8.4 \
    socat \
    && rm -rf /var/lib/apt/lists/*

# Copia o pacote .deb construído
COPY --from=builder /build/*.deb /tmp/

# Instala o pacote
RUN dpkg -i /tmp/*.deb || apt-get install -f -y

# Cria configuração do Emacspeak
RUN mkdir -p /root/.emacs.d "$EMACS_ELN_CACHE" \
    && cat > /root/.emacs.d/early-init.el <<'EOF'
(setq native-comp-jit-compilation nil)
(let ((dir "/opt/emacspeak/eln"))
  (dolist (sym '(comp-eln-load-path native-comp-eln-load-path))
    (when (boundp sym)
      (unless (member dir (symbol-value sym))
        (set sym (cons dir (symbol-value sym)))))))
EOF

RUN cat > /root/.emacs.d/init.el <<'EOF_INIT'
(setq dtk-program
      (let ((s (getenv "DTK_SPEECH_SERVER")))
        (if (and s (not (string= s ""))) s "espeak")))
(setq emacspeak-play-program nil)
(setq emacspeak-use-auditory-icons nil)
(setq emacspeak-line-echo t)
(setq ring-bell-function 'ignore)
(setq confirm-kill-processes nil)
(setq inhibit-startup-screen t)
(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache (or (getenv "EMACS_ELN_CACHE")
                                   (expand-file-name "eln-cache" user-emacs-directory))))
(defvar emacspeak-xslt-directory "/opt/emacspeak/xsl")
(defvar emacspeak-sounds-dir "/opt/emacspeak/sounds/")
(load-file "/opt/emacspeak/lisp/emacspeak-setup.el")
EOF_INIT

# Script de inicialização
RUN cat > /usr/local/bin/start-emacspeak.sh <<'EOF'
#!/usr/bin/env bash
exec emacs --init-directory=/root/.emacs.d -nw "$@"
EOF

RUN chmod +x /usr/local/bin/start-emacspeak.sh

# Copia script de teste
COPY scripts/test-package.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/test-package.sh

VOLUME ["/root/.emacs.d/eln-cache"]
WORKDIR /workspace

CMD ["/usr/local/bin/test-package.sh"]

# Stage final para distribuição
FROM debian:trixie-slim AS runtime

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV DTK_PROGRAM=espeak
ENV EMACS_ELN_CACHE=/root/.emacs.d/eln-cache

RUN apt-get update && apt-get install -y --no-install-recommends \
    emacs-nox \
    espeak-ng \
    espeak-ng-data \
    tcl \
    tclx8.4 \
    socat \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/*.deb /packages/
COPY --from=builder /build/emacspeak/debian /packages/debian/

RUN dpkg -i /packages/*.deb || apt-get install -f -y

RUN mkdir -p /root/.emacs.d "$EMACS_ELN_CACHE" \
    && cat > /root/.emacs.d/early-init.el <<'EOF'
(setq native-comp-jit-compilation nil)
(let ((dir "/opt/emacspeak/eln"))
  (dolist (sym '(comp-eln-load-path native-comp-eln-load-path))
    (when (boundp sym)
      (unless (member dir (symbol-value sym))
        (set sym (cons dir (symbol-value sym)))))))
EOF

RUN cat > /root/.emacs.d/init.el <<'EOF_INIT'
(setq dtk-program
      (let ((s (getenv "DTK_SPEECH_SERVER")))
        (if (and s (not (string= s ""))) s "espeak")))
(setq emacspeak-play-program nil)
(setq emacspeak-use-auditory-icons nil)
(setq emacspeak-line-echo t)
(setq ring-bell-function 'ignore)
(setq confirm-kill-processes nil)
(setq inhibit-startup-screen t)
(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache (or (getenv "EMACS_ELN_CACHE")
                                   (expand-file-name "eln-cache" user-emacs-directory))))
(defvar emacspeak-xslt-directory "/opt/emacspeak/xsl")
(defvar emacspeak-sounds-dir "/opt/emacspeak/sounds/")
(load-file "/opt/emacspeak/lisp/emacspeak-setup.el")
EOF_INIT

RUN cat > /usr/local/bin/start-emacspeak.sh <<'EOF'
#!/usr/bin/env bash
exec emacs --init-directory=/root/.emacs.d -nw "$@"
EOF

RUN chmod +x /usr/local/bin/start-emacspeak.sh

VOLUME ["/root/.emacs.d/eln-cache"]
WORKDIR /workspace
CMD ["/usr/local/bin/start-emacspeak.sh"]
