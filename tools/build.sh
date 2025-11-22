#!/bin/bash

echo "=== Veltora OS Build System ==="
echo "Building from: $(pwd)"

# NASM kontrolü
if ! command -v nasm &> /dev/null
then
    echo "NASM bulunamadı. Yükleniyor..."
    
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
        echo "Otomatik yükleme desteklenmiyor. Lütfen NASM'i manuel kurun."
        exit 1
    fi
fi

echo "Building bootloader..."
nasm -f bin src/boot.asm -o boot.bin || { echo "Boot build failed!"; exit 1; }

echo "Building kernel..."
nasm -f bin src/kernel/kernel.asm -o kernel.bin || { echo "Kernel build failed!"; exit 1; }

echo "Merging boot + kernel into disk image..."
cat boot.bin kernel.bin > veltora.img

# Temizlik
rm -f boot.bin kernel.bin

echo "Build successful! Created: veltora.img"
