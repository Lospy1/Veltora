#!/bin/bash

echo "=== Veltora OS Build System ==="
echo "Building from: $(pwd)"

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
echo "Run with: qemu-system-i386 -fda veltora.img"
