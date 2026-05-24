#!/bin/bash

# ══════════════════════════════════════════════════════════════
#  TuTiVi Installer
# ══════════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════"
echo "           TuTiVi V1.0507 Installer"
echo "                By Arturo B                    "
echo "═══════════════════════════════════════════════"
echo ""

INSTALL_DIR="$HOME/.config/tutivi"

echo "[1/9] Verificando dependencias..."

REQUIRED_PACKAGES=(
    mpv
    socat
    python3
    curl
    xclip
    kdeconnect
    ffmpeg
    mpv-mpris
    xdg-utils
    desktop-file-utils
)

for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "Instalando dependencia faltante: $pkg"
        sudo apt install -y "$pkg" >/dev/null 2>&1
    fi
done

echo "[2/9] Instalando/actualizando yt-dlp..."

mkdir -p "$HOME/.local/bin"

rm -f "$HOME/.local/bin/yt-dlp"

curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp \
    -o "$HOME/.local/bin/yt-dlp" >/dev/null 2>&1

chmod +x "$HOME/.local/bin/yt-dlp"

export PATH="$HOME/.local/bin:$PATH"

grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" || \
echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"

if ! command -v yt-dlp >/dev/null 2>&1; then
    echo "ADVERTENCIA: yt-dlp no está en PATH."
    echo "Agrega esta línea a tu ~/.bashrc:"
    echo 'export PATH="$HOME/.local/bin:$PATH"'
fi

echo "[3/9]Instalando/verificando Deno para yt-dlp..."

if command -v deno >/dev/null 2>&1; then
    echo "Deno ya está instalado: $(deno --version | head -1)"
else
    echo "Deno no encontrado. Instalando en $HOME/.deno..."
    curl -fsSL https://deno.land/install.sh | sh

    export DENO_INSTALL="$HOME/.deno"
    export PATH="$DENO_INSTALL/bin:$PATH"

    if command -v deno >/dev/null 2>&1; then
        echo "Deno instalado correctamente: $(deno --version | head -1)"
    else
        echo "ERROR: Deno no se pudo instalar correctamente."
        echo "YouTube puede fallar con bot check, 429 o formatos faltantes."
        exit 1
    fi
fi
if ! grep -q 'DENO_INSTALL="$HOME/.deno"' "$HOME/.bashrc"; then
    {
        echo ''
        echo '# Deno para TuTiVi / yt-dlp'
        echo 'export DENO_INSTALL="$HOME/.deno"'
        echo 'export PATH="$DENO_INSTALL/bin:$PATH"'
    } >> "$HOME/.bashrc"
fi

echo "[4/9] Creando directorios y archivos necesarios..."

mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/history"
mkdir -p "$INSTALL_DIR/downloads"
mkdir -p "$INSTALL_DIR/logs"
mkdir -p "$INSTALL_DIR/mpv"
mkdir -p "$INSTALL_DIR/backup"
mkdir -p "$HOME/.cache/tutivi/logs"
mkdir -p "$HOME/.local/share/applications"

echo "[5/9] Verificando si existe configuración previa..."

if [[ ! -f "$INSTALL_DIR/tutivi.conf" ]]; then
    cp config/tutivi.conf.example "$INSTALL_DIR/tutivi.conf"
else
    echo "Configuración existente detectada, no se sobrescribe tutivi.conf"
fi

echo "[6/9] Copiando configuración mpv..."

cp mpv/mpv.conf \
    "$INSTALL_DIR/mpv/mpv.conf"

echo "[7/9] Instalando core..."

cp -r core "$INSTALL_DIR/"

echo "[8/9] Instalando comando global..."

sudo ln -sf "$(pwd)/tutivi" /usr/local/bin/tutivi
sudo ln -sf "$(pwd)/handlers/tutivi-handler" /usr/local/bin/tutivi-handler
sudo ln -sf "$(pwd)/handlers/tutivi-handler" /usr/local/bin/enlazador-tutivi
sudo ln -sf "$(pwd)/handlers/abrir-tutivi" /usr/local/bin/abrir-tutivi

chmod +x tutivi
chmod +x handlers/tutivi-handler
chmod +x handlers/abrir-tutivi
chmod +x core/functions.sh

echo "[9/9] Activando Modo Sayayin..."

SAYAYIN_DESKTOP_SRC="desktop/tutivi-handler.desktop"
SAYAYIN_DESKTOP_DEST="$HOME/.local/share/applications/tutivi-handler.desktop"

mkdir -p "$HOME/.local/share/applications"
mkdir -p "$INSTALL_DIR/backup"

# Guardar backup completo de mimeapps.list solo la primera vez
if [[ -f "$HOME/.config/mimeapps.list" && ! -f "$INSTALL_DIR/backup/mimeapps.list.before-sayayin" ]]; then
    cp "$HOME/.config/mimeapps.list" "$INSTALL_DIR/backup/mimeapps.list.before-sayayin"
fi

# Guardar manejadores actuales solo la primera vez
if [[ ! -f "$INSTALL_DIR/backup/http-handler.before-sayayin" ]]; then
    xdg-mime query default x-scheme-handler/http > "$INSTALL_DIR/backup/http-handler.before-sayayin" 2>/dev/null || true
fi

if [[ ! -f "$INSTALL_DIR/backup/https-handler.before-sayayin" ]]; then
    xdg-mime query default x-scheme-handler/https > "$INSTALL_DIR/backup/https-handler.before-sayayin" 2>/dev/null || true
fi

# Copiar archivo desktop de TuTiVi
if [[ -f "$SAYAYIN_DESKTOP_SRC" ]]; then
    cp "$SAYAYIN_DESKTOP_SRC" "$SAYAYIN_DESKTOP_DEST"
else
    echo "ERROR: No existe $SAYAYIN_DESKTOP_SRC"
    echo "No se pudo activar Modo Sayayin."
    exit 1
fi

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# Activar TuTiVi como manejador de enlaces web
xdg-mime default tutivi-handler.desktop x-scheme-handler/http
xdg-mime default tutivi-handler.desktop x-scheme-handler/https

echo "Modo Sayayin activado."
echo "HTTP : $(xdg-mime query default x-scheme-handler/http)"
echo "HTTPS: $(xdg-mime query default x-scheme-handler/https)"

echo ""
echo "✅ TuTiVi instalado correctamente."
echo ""
echo "Usa por ejemplo:"
echo ""
echo "   tutivi reproducir https://www.youtube.com/watch?v=7QU1nvuxaMA"
echo ""
echo "        Desarrollado por Intergames Còrdoba V1.0507"