#!/bin/bash

# ══════════════════════════════════════════════════════════════
#  TuTiVi Core Functions
# ══════════════════════════════════════════════════════════════

# ══════════════════════════════════════════════════════════════
#  Configuración TuTiVi
# ══════════════════════════════════════════════════════════════

CONFIG_DIR="$HOME/.config/tutivi"

USER_CONFIG="$CONFIG_DIR/tutivi.conf"

DEFAULT_CONFIG="$(dirname "${BASH_SOURCE[0]}")/../config/tutivi.conf.example"

# Cargar configuración del usuario si existe
# Si no existe, usar valores por defecto del proyecto

if [[ -f "$USER_CONFIG" ]]; then
    source "$USER_CONFIG"
else
    source "$DEFAULT_CONFIG"
fi

# ══════════════════════════════════════════════════════════════
#  Valores por defecto de seguridad
# ══════════════════════════════════════════════════════════════

MAX_HEIGHT="${MAX_HEIGHT:-720}"

TUTIVI_FORMAT_MODE="${TUTIVI_FORMAT_MODE:-compatible}"

TUTIVI_HWDEC="${TUTIVI_HWDEC:-no}"

TUTIVI_AUDIO_DEVICE="${TUTIVI_AUDIO_DEVICE:-auto}"

TUTIVI_INITIAL_VOLUME="${TUTIVI_INITIAL_VOLUME:-70}"

OSD_DURATION="${OSD_DURATION:-3000}"

OSD_FONT_SIZE="${OSD_FONT_SIZE:-40}"

OSD_MARGIN_Y="${OSD_MARGIN_Y:-80}"

TUTIVI_YTDLP_CLIENT="${TUTIVI_YTDLP_CLIENT:-android}"

MPV_SOCKET="${MPV_SOCKET:-/tmp/tutivi-mpv-socket}"

DISPLAY_ID="${DISPLAY_ID:-:0}"

TUTIVI_DEBUG_WINDOW="${TUTIVI_DEBUG_WINDOW:-no}"

TUTIVI_DEBUG_WINDOW_TIME="${TUTIVI_DEBUG_WINDOW_TIME:-30}"

TUTIVI_LOG_FILE="${TUTIVI_LOG_FILE:-$HOME/.cache/tutivi/logs/mpv.log}"

TUTIVI_DEBUG_PID_FILE="${TUTIVI_DEBUG_PID_FILE:-/tmp/tutivi-debug-window.pid}"

TUTIVI_TITLE_WATCH_INTERVAL="${TUTIVI_TITLE_WATCH_INTERVAL:-3}"

TUTIVI_TITLE_WATCH_DELAY="${TUTIVI_TITLE_WATCH_DELAY:-4}"

TUTIVI_TITLE_WATCH_PID_FILE="${TUTIVI_TITLE_WATCH_PID_FILE:-/tmp/tutivi-title-watch.pid}"

# ══════════════════════════════════════════════════════════════
#  Deno / JS runtime para yt-dlp
#  Necesario para resolver retos JavaScript de YouTube
# ══════════════════════════════════════════════════════════════

export DENO_INSTALL="${DENO_INSTALL:-$HOME/.deno}"
export PATH="$HOME/.local/bin:$DENO_INSTALL/bin:$PATH"

# ══════════════════════════════════════════════════════════════
#  Comprobacion de arranque limpio en MPV 
# ══════════════════════════════════════════════════════════════

_tutivi_running() {
    _tutivi_socket_alive && _tutivi_has_media
}

_tutivi_socket_alive() {
    [[ -S "$MPV_SOCKET" ]] && \
    echo '{"command":["get_property","pid"]}' \
        | socat - "$MPV_SOCKET" >/dev/null 2>&1
}

_tutivi_current_path() {
    [[ ! -S "$MPV_SOCKET" ]] && return 1

    echo '{"command":["get_property","path"]}' \
        | socat - "$MPV_SOCKET" 2>/dev/null \
        | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    data = d.get("data", "")
    print(data if data else "")
except Exception:
    print("")
'
}

_tutivi_has_media() {
    local CURRENT
    CURRENT=$(_tutivi_current_path)

    [[ -n "$CURRENT" && "$CURRENT" != "?" && "$CURRENT" != "null" ]]
}

# ══════════════════════════════════════════════════════════════
#  Enviar comando a mpv IPC
# ══════════════════════════════════════════════════════════════

_tutivi_cmd() {
    echo "$1" | socat - "$MPV_SOCKET" 2>/dev/null
}

# ══════════════════════════════════════════════════════════════
#  OSD en pantalla usando mpv
# ══════════════════════════════════════════════════════════════

_tutivi_osd() {

    local MESSAGE="$1"
    local DURATION="${2:-$OSD_DURATION}"

    [[ ! -S "$MPV_SOCKET" ]] && return 0

    python3 - "$MESSAGE" "$DURATION" "$MPV_SOCKET" >/dev/null 2>&1 <<'PY'
import sys
import json
import socket

message = sys.argv[1]
duration = int(sys.argv[2])
socket_path = sys.argv[3]

payload = {
    "command": ["show-text", message, duration]
}

data = json.dumps(payload).encode("utf-8") + b"\n"

try:
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.settimeout(1)
    sock.connect(socket_path)
    sock.sendall(data)

    try:
        sock.recv(4096)
    except Exception:
        pass

    sock.close()

except Exception:
    pass
PY
}

# ══════════════════════════════════════════════════════════════
#  Mostrar título del video en OSD mientras se reproduce
#  Se ejecuta en un proceso aparte que monitorea cambios en el video
# ══════════════════════════════════════════════════════════════

_tutivi_title_watch() {

    # Si ya hay watcher vivo, no iniciar otro
    if [[ -f "$TUTIVI_TITLE_WATCH_PID_FILE" ]]; then
        local OLD_PID
        OLD_PID="$(cat "$TUTIVI_TITLE_WATCH_PID_FILE" 2>/dev/null)"

        if [[ -n "$OLD_PID" ]] && kill -0 "$OLD_PID" 2>/dev/null; then
            return 0
        else
            rm -f "$TUTIVI_TITLE_WATCH_PID_FILE"
        fi
    fi

    (
        local LAST_PATH=""
        local CURRENT_PATH=""
        local WAIT_COUNT=0

        # Esperar a que el socket de mpv esté listo
        while ! _tutivi_socket_alive; do
            sleep 1
            WAIT_COUNT=$((WAIT_COUNT + 1))

            # Si después de 20 segundos no hay socket, salir
            if [[ "$WAIT_COUNT" -ge 20 ]]; then
                rm -f "$TUTIVI_TITLE_WATCH_PID_FILE"
                exit 0
            fi
        done

        while _tutivi_socket_alive; do

            CURRENT_PATH="$(_tutivi_current_path)"

            if [[ -n "$CURRENT_PATH" \
               && "$CURRENT_PATH" != "?" \
               && "$CURRENT_PATH" != "null" \
               && "$CURRENT_PATH" != "$LAST_PATH" ]]; then

                LAST_PATH="$CURRENT_PATH"

                sleep "$TUTIVI_TITLE_WATCH_DELAY"

                _tutivi_title_osd
            fi

            sleep "$TUTIVI_TITLE_WATCH_INTERVAL"
        done

        rm -f "$TUTIVI_TITLE_WATCH_PID_FILE"

    ) &

    echo "$!" > "$TUTIVI_TITLE_WATCH_PID_FILE"
}
# ══════════════════════════════════════════════════════════════
#  Notificación KDE Connect
# ══════════════════════════════════════════════════════════════

_tutivi_notify() {

    local MESSAGE="$1"

    [[ -z "$KDECONNECT_DEVICE" ]] && return 0

    kdeconnect-cli -d "$KDECONNECT_DEVICE" \
        --ping-msg "$MESSAGE" >/dev/null 2>&1
}

# ══════════════════════════════════════════════════════════════
#  Parsear URL
# ══════════════════════════════════════════════════════════════

_tutivi_parse_url() {

    local INPUT="$1"

    local re_shorts='shorts/([a-zA-Z0-9_-]+)'
    local re_video='[?&]v=([a-zA-Z0-9_-]+)'
    local re_id='^[a-zA-Z0-9_-]{11}$'

    if [[ "$INPUT" =~ $re_shorts ]]; then

        echo "https://youtube.com/watch?v=${BASH_REMATCH[1]}"

    elif [[ "$INPUT" =~ $re_video ]]; then

        echo "https://youtube.com/watch?v=${BASH_REMATCH[1]}"

    elif [[ "$INPUT" =~ $re_id ]]; then

        echo "https://youtube.com/watch?v=$INPUT"

    elif [[ "$INPUT" =~ ^https?:// ]]; then

        echo "$INPUT"

    else

        echo ""

    fi
}
# ══════════════════════════════════════════════════════════════
#  TuTiVi Debug Window
# ══════════════════════════════════════════════════════════════

_tutivi_debug_window() {

    [[ "$TUTIVI_DEBUG_WINDOW" != "yes" ]] && return 0

    command -v xterm >/dev/null 2>&1 || return 0

    mkdir -p "$(dirname "$TUTIVI_LOG_FILE")"

    # Si ya hay una ventana debug viva, no abrir otra
    if [[ -f "$TUTIVI_DEBUG_PID_FILE" ]]; then
        local OLD_PID
        OLD_PID="$(cat "$TUTIVI_DEBUG_PID_FILE" 2>/dev/null)"

        if [[ -n "$OLD_PID" ]] && kill -0 "$OLD_PID" 2>/dev/null; then
            return 0
        else
            rm -f "$TUTIVI_DEBUG_PID_FILE"
        fi
    fi

    DISPLAY="$DISPLAY_ID" xterm \
        -T "TuTiVi Debug" \
        -geometry 120x28+40+40 \
        -fa "Monospace" \
        -fs 12 \
        -bg black \
        -fg white \
        -e bash -lc "
            echo '════════════════════════════════════════════════════'
            echo ' TuTiVi Debug by Intergames'
            echo '════════════════════════════════════════════════════'
            echo
            echo 'Mostrando salida de mpv / yt-dlp...'
            echo 'Esta ventana permanecerá abierta.'
            echo
            echo 'Si mandas otro video, se reutiliza esta misma ventana.'
            echo
            echo '════════════════════════════════════════════════════'
            echo
            tail -n +1 -f '$TUTIVI_LOG_FILE'
        " &

    echo "$!" > "$TUTIVI_DEBUG_PID_FILE"
}
# ══════════════════════════════════════════════════════════════
#  Configuración de formato de yt-dlp según el modo seleccionado
# ══════════════════════════════════════════════════════════════

_tutivi_build_format() {
    case "$TUTIVI_FORMAT_MODE" in
        compatible)
            YTDL_FORMAT="bestvideo[height<=${MAX_HEIGHT}][ext=mp4]+bestaudio[ext=m4a]/best[height<=${MAX_HEIGHT}]"
            ;;

        flexible)
            YTDL_FORMAT="bestvideo[height<=${MAX_HEIGHT}]+bestaudio/best[height<=${MAX_HEIGHT}]"
            ;;

        best)
            YTDL_FORMAT="bestvideo[height<=${MAX_HEIGHT}]+bestaudio/best"
            ;;

        ultralite)
            YTDL_FORMAT="bestvideo[height<=480][ext=mp4]+bestaudio[ext=m4a]/best[height<=480]"
            ;;

        *)
            YTDL_FORMAT="bestvideo[height<=${MAX_HEIGHT}][ext=mp4]+bestaudio[ext=m4a]/best[height<=${MAX_HEIGHT}]"
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════
#  Iniciar mpv
# ══════════════════════════════════════════════════════════════

_tutivi_start_mpv() {

    local URL="$1"
    local MPRIS_OPTION=""

    _tutivi_build_format

    rm -f "$MPV_SOCKET"

    if [[ -f "$MPRIS_SCRIPT" ]]; then
        MPRIS_OPTION="--script=$MPRIS_SCRIPT"
    fi

    mkdir -p "$(dirname "$TUTIVI_LOG_FILE")"
    : > "$TUTIVI_LOG_FILE"

    {
        echo "════════════════════════════════════════════════════"
        echo "TuTiVi Modo Desarrollo en curso"
        echo "Fecha: $(date '+%F %T')"
        echo "URL: $URL"
        echo "Formato: $YTDL_FORMAT"
        echo "Display: $DISPLAY_ID"
        echo "Socket: $MPV_SOCKET"
        echo "Volumen inicial: $TUTIVI_INITIAL_VOLUME"
        echo "Debug window: $TUTIVI_DEBUG_WINDOW"
        echo "════════════════════════════════════════════════════"
        echo
    } >> "$TUTIVI_LOG_FILE"

    _tutivi_debug_window

    DISPLAY="$DISPLAY_ID" mpv --no-config --fs \
        --input-ipc-server="$MPV_SOCKET" \
        $MPRIS_OPTION \
        --osd-playing-msg-duration=5000 \
        --osd-font-size="$OSD_FONT_SIZE" \
        --osd-align-x=center \
        --osd-align-y=bottom \
        --osd-margin-y="$OSD_MARGIN_Y" \
        --volume="$TUTIVI_INITIAL_VOLUME" \
        --ytdl-format="$YTDL_FORMAT" \
        "$URL" >> "$TUTIVI_LOG_FILE" 2>&1 &
}

# ══════════════════════════════════════════════════════════════
#  Mostrar titulo mientras se reproduce el video
# ══════════════════════════════════════════════════════════════

_tutivi_title_osd() {
    local VIDEO_TITLE

    VIDEO_TITLE=$(
        _tutivi_cmd '{"command":["get_property","media-title"]}' | \
        python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    title = d.get("data", "")
    print(title.strip() if isinstance(title, str) else "")
except Exception:
    print("")
'
    )

    if [[ -n "$VIDEO_TITLE" \
       && "$VIDEO_TITLE" != "?" \
       && "$VIDEO_TITLE" != "title" \
       && "$VIDEO_TITLE" != *"watch?v="* \
       && "$VIDEO_TITLE" != http://* \
       && "$VIDEO_TITLE" != https://* ]]; then

        _tutivi_osd $'TuTiVi Player:\n'"$VIDEO_TITLE" 5000
    else
        _tutivi_osd "TuTiVi Player - Sin título" 5000
    fi
}
# ══════════════════════════════════════════════════════════════
#  Modo Sayayin - HTTP/HTTPS handler
# ══════════════════════════════════════════════════════════════

_tutivi_restore_handler_or_fallback() {

    local SCHEME="$1"
    local BACKUP_FILE="$2"
    local OLD_HANDLER=""

    OLD_HANDLER="$(cat "$BACKUP_FILE" 2>/dev/null)"

    if [[ -n "$OLD_HANDLER" && "$OLD_HANDLER" != "tutivi-handler.desktop" ]]; then
        xdg-mime default "$OLD_HANDLER" "x-scheme-handler/$SCHEME"
        return 0
    fi

    for candidate in \
        google-chrome.desktop \
        com.google.Chrome.desktop \
        firefox.desktop \
        chromium.desktop \
        chromium-browser.desktop \
        brave-browser.desktop
    do
        if [[ -f "$HOME/.local/share/applications/$candidate" || -f "/usr/share/applications/$candidate" ]]; then
            xdg-mime default "$candidate" "x-scheme-handler/$SCHEME"
            return 0
        fi
    done

    echo "[AVISO] No se encontró navegador para restaurar $SCHEME."
    return 1
}


_tutivi_sayayin_backup_current() {

    local BACKUP_DIR="$HOME/.config/tutivi/backup"
    local CURRENT_HTTP=""
    local CURRENT_HTTPS=""

    mkdir -p "$BACKUP_DIR"

    if [[ -f "$HOME/.config/mimeapps.list" && ! -f "$BACKUP_DIR/mimeapps.list.before-sayayin" ]]; then
        cp "$HOME/.config/mimeapps.list" "$BACKUP_DIR/mimeapps.list.before-sayayin"
    fi

    CURRENT_HTTP="$(xdg-mime query default x-scheme-handler/http 2>/dev/null || true)"
    CURRENT_HTTPS="$(xdg-mime query default x-scheme-handler/https 2>/dev/null || true)"

    if [[ ! -f "$BACKUP_DIR/http-handler.before-sayayin" ]]; then
        if [[ "$CURRENT_HTTP" != "tutivi-handler.desktop" ]]; then
            echo "$CURRENT_HTTP" > "$BACKUP_DIR/http-handler.before-sayayin"
        else
            : > "$BACKUP_DIR/http-handler.before-sayayin"
        fi
    fi

    if [[ ! -f "$BACKUP_DIR/https-handler.before-sayayin" ]]; then
        if [[ "$CURRENT_HTTPS" != "tutivi-handler.desktop" ]]; then
            echo "$CURRENT_HTTPS" > "$BACKUP_DIR/https-handler.before-sayayin"
        else
            : > "$BACKUP_DIR/https-handler.before-sayayin"
        fi
    fi
}


_tutivi_sayayin_on() {

    local DESKTOP_SRC_INSTALLED="$HOME/.config/tutivi/desktop/tutivi-handler.desktop"
    local DESKTOP_SRC_PROJECT="$HOME/TuTiVi/desktop/tutivi-handler.desktop"
    local DESKTOP_DEST="$HOME/.local/share/applications/tutivi-handler.desktop"

    mkdir -p "$HOME/.local/share/applications"

    _tutivi_sayayin_backup_current

    if [[ -f "$DESKTOP_SRC_INSTALLED" ]]; then
        cp "$DESKTOP_SRC_INSTALLED" "$DESKTOP_DEST"
    elif [[ -f "$DESKTOP_SRC_PROJECT" ]]; then
        cp "$DESKTOP_SRC_PROJECT" "$DESKTOP_DEST"
    else
        echo "[ERROR] No se encontró tutivi-handler.desktop"
        return 1
    fi

    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

    xdg-mime default tutivi-handler.desktop x-scheme-handler/http
    xdg-mime default tutivi-handler.desktop x-scheme-handler/https

    echo "Modo Sayayin activado."
    echo "HTTP : $(xdg-mime query default x-scheme-handler/http)"
    echo "HTTPS: $(xdg-mime query default x-scheme-handler/https)"
}


_tutivi_sayayin_off() {

    local BACKUP_DIR="$HOME/.config/tutivi/backup"

    _tutivi_restore_handler_or_fallback "http" "$BACKUP_DIR/http-handler.before-sayayin"
    _tutivi_restore_handler_or_fallback "https" "$BACKUP_DIR/https-handler.before-sayayin"

    echo "Modo Sayayin desactivado."
    echo "HTTP : $(xdg-mime query default x-scheme-handler/http)"
    echo "HTTPS: $(xdg-mime query default x-scheme-handler/https)"
}


_tutivi_sayayin_status() {

    local HTTP_HANDLER=""
    local HTTPS_HANDLER=""

    HTTP_HANDLER="$(xdg-mime query default x-scheme-handler/http 2>/dev/null)"
    HTTPS_HANDLER="$(xdg-mime query default x-scheme-handler/https 2>/dev/null)"

    echo ""
    echo "═══════════════════════════════════════════════"
    echo "        Estado del Modo Sayayin"
    echo "═══════════════════════════════════════════════"
    echo ""

    echo "HTTP : ${HTTP_HANDLER:-sin configurar}"
    echo "HTTPS: ${HTTPS_HANDLER:-sin configurar}"
    echo ""

    if [[ "$HTTP_HANDLER" == "tutivi-handler.desktop" && "$HTTPS_HANDLER" == "tutivi-handler.desktop" ]]; then
        echo "✅ Modo Sayayin ACTIVADO"
        echo ""
        echo "TuTiVi está configurado para recibir enlaces HTTP/HTTPS."
        echo "Los enlaces enviados por xdg-open, KDE Connect o el sistema"
        echo "deberían abrirse con TuTiVi."
    else
        echo "⚠️ Modo Sayayin DESACTIVADO o incompleto"
        echo ""
        echo "Actualmente los enlaces web no están completamente asociados a TuTiVi."

        if [[ "$HTTP_HANDLER" != "tutivi-handler.desktop" ]]; then
            echo "HTTP no apunta a TuTiVi."
        fi

        if [[ "$HTTPS_HANDLER" != "tutivi-handler.desktop" ]]; then
            echo "HTTPS no apunta a TuTiVi."
        fi

        echo ""
        echo "Para activarlo:"
        echo "  tutivi modo_sayayin on"
    fi

    echo ""
}