#!/bin/bash

# ══════════════════════════════════════════════════════════════
#  TuTiVi Installer
# ══════════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════"
echo "           TuTiVi 0.1 Installer"
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
)

for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "Instalando dependencia faltante: $pkg"
        sudo apt install -y "$pkg" >/dev/null 2>&1
    fi
done

echo "[2/7] Instalando/actualizando yt-dlp..."

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

echo "[3/7] Creando directorios..."

mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/history"
mkdir -p "$INSTALL_DIR/downloads"
mkdir -p "$INSTALL_DIR/logs"
mkdir -p "$INSTALL_DIR/mpv"

echo "[4/7] Copiando configuración..."

cp config/tutivi.conf.example \
    "$INSTALL_DIR/tutivi.conf"

echo "[5/7] Copiando configuración mpv..."

cp mpv/mpv.conf \
    "$INSTALL_DIR/mpv/mpv.conf"

echo "[6/7] Instalando core..."

cp -r core "$INSTALL_DIR/"

echo "[7/7] Instalando comando global..."

sudo ln -sf "$(pwd)/tutivi" /usr/local/bin/tutivi
sudo ln -sf "$(pwd)/handlers/tutivi-handler" /usr/local/bin/tutivi-handler
sudo ln -sf "$(pwd)/handlers/tutivi-handler" /usr/local/bin/enlazador-tutivi


chmod +x tutivi
chmod +x handlers/tutivi-handler
chmod +x core/functions.sh

echo ""
echo "✅ TuTiVi instalado correctamente."
echo ""
echo "Usa por ejemplo:"
echo ""
echo "   tutivi play https://www.youtube.com/watch?v=7QU1nvuxaMA"
echo ""
echo "        Desarrollado por Intergames Còrdoba v.0.01"