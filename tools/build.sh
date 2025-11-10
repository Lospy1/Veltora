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

# Bootloader'ı derle
echo "Building bootloader..."
nasm -f bin src/boot.asm -o boot.bin

if [ $? -ne 0 ]; then
    echo "Bootloader build failed!"
    exit 1
fi

echo "Creating disk image..."
dd if=/dev/zero of=veltora.img bs=512 count=2880
dd if=boot.bin of=veltora.img conv=notrunc

rm -f boot.bin

echo "Build successful!"
