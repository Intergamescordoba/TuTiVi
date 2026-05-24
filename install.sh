#!/bin/bash

# ══════════════════════════════════════════════════════════════
#  TuTiVi Installer
# ══════════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════"
echo "           TuTiVi V 0.02 Installer"
echo "                By Arturo B                    "
echo "═══════════════════════════════════════════════"
echo ""

INSTALL_DIR="$HOME/.config/tutivi"

echo "[1/7] Verificando dependencias..."

REQUIRED_PACKAGES=(
    mpv
    socat
    python3
    curl
    xclip
    kdeconnect
    ffmpeg
    mpv-mpris
)

for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "Instalando dependencia faltante: $pkg"
        sudo apt install -y "$pkg" >/dev/null 2>&1
    fi
done

echo "[2.1/7] Instalando/actualizando yt-dlp..."

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

echo "[2.2/7]Instalando/verificando Deno para yt-dlp..."

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

echo "[3/7] Creando directorios..."

mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/history"
mkdir -p "$INSTALL_DIR/downloads"
mkdir -p "$INSTALL_DIR/logs"
mkdir -p "$INSTALL_DIR/mpv"
mkdir -p "$HOME/.cache/tutivi/logs"

echo "[4/7] Verificando si existe configuración previa..."

if [[ ! -f "$INSTALL_DIR/tutivi.conf" ]]; then
    cp config/tutivi.conf.example "$INSTALL_DIR/tutivi.conf"
else
    echo "Configuración existente detectada, no se sobrescribe tutivi.conf"
fi

echo "[5/7] Copiando configuración mpv..."

cp mpv/mpv.conf \
    "$INSTALL_DIR/mpv/mpv.conf"

echo "[6/7] Instalando core..."

cp -r core "$INSTALL_DIR/"

echo "[7/7] Instalando comando global..."

sudo ln -sf "$(pwd)/tutivi" /usr/local/bin/tutivi
sudo ln -sf "$(pwd)/handlers/tutivi-handler" /usr/local/bin/tutivi-handler
sudo ln -sf "$(pwd)/handlers/tutivi-handler" /usr/local/bin/enlazador-tutivi
sudo ln -sf "$(pwd)/handlers/abrir-tutivi" /usr/local/bin/abrir-tutivi

chmod +x tutivi
chmod +x handlers/tutivi-handler
chmod +x handlers/abrir-tutivi
chmod +x core/functions.sh

echo ""
echo "✅ TuTiVi instalado correctamente."
echo ""
echo "Usa por ejemplo:"
echo ""
echo "   tutivi reproducir https://www.youtube.com/watch?v=7QU1nvuxaMA"
echo ""
echo "        Desarrollado por Intergames Còrdoba v.0.02"