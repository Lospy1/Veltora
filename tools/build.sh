#!/bin/bash

echo "=== Veltora OS Derleme Sistemi ==="
echo "Çalışma dizini: $(pwd)"

# NASM kontrolü
if ! command -v nasm &> /dev/null
then
    echo -n "NASM bulunamadı. Yükleniyor"
    for i in {1..3}; do
        sleep 0.5
        echo -n "."
    done
    echo
    if [ -f /etc/debian_version ]; then
        sudo apt update && sudo apt install -y nasm
    elif [ -f /etc/arch-release ]; then
        sudo pacman -S --noconfirm nasm
    elif [ -f /etc/fedora-release ]; then
        sudo dnf install -y nasm
    elif [ -f "$PREFIX/etc/apt/sources.list" ]; then
        # Termux
        pkg install -y nasm
    else
        echo "Otomatik yükleme desteklenmiyor. Lütfen NASM'i manuel olarak kurun."
        exit 1
    fi
fi

# Build klasörü oluştur (tarih/saat tabanlı)
BUILD_DIR="build_twirl_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BUILD_DIR"

# Karmaşık dosya ismi üret (rasgele karakterler ve noktalar)
IMG_NAME="veltora.$(head /dev/urandom | tr -dc 'a-zA-Z0-9._' | head -c12).img"

# Animasyon fonksiyonu
function animate {
    local pid=$1
    local delay=0.1
    local spin='|/-\'
    while kill -0 $pid 2>/dev/null; do
        for i in $(seq 0 3); do
            echo -ne "\r${spin:$i:1} $2"
            sleep $delay
        done
    done
    echo -ne "\r✓ $2\n"
}

# Önyükleyici derleme
(
    nasm -f bin src/boot.asm -o "$BUILD_DIR/boot.bin"
) & animate $! "Önyükleyici derleniyor"

# Çekirdek derleme
(
    nasm -f bin src/kernel/kernel.asm -o "$BUILD_DIR/kernel.bin"
) & animate $! "Çekirdek derleniyor"

# Birleştirme
(
    cat "$BUILD_DIR/boot.bin" "$BUILD_DIR/kernel.bin" > "$BUILD_DIR/$IMG_NAME"
) & animate $! "Önyükleyici ve çekirdek birleştiriliyor"

# Temizlik
rm -f "$BUILD_DIR/boot.bin" "$BUILD_DIR/kernel.bin"

# Mesaj
echo
echo "[💾] Derleme başarılı! Oluşturulan dosya: $BUILD_DIR/$IMG_NAME"
echo
echo
echo "Aramıza Hoş Geldin!" 
