#!/bin/bash

echo "=== Veltora OS Build System ==="

# Bootloade
echo "Building bootloader..."
nasm -f bin src/boot.asm -o boot.bin

# Kernel Entry 
echo "Building kernel entry..."
nasm -f elf32 src/kernel/kernel_entry.asm -o kernel_entry.o

# Kernel
echo "Building kernel..."
i686-elf-gcc -c src/kernel/kernel.c -o kernel.o -ffreestanding -std=gnu99

echo "Linking kernel..."
i686-elf-ld -o kernel.bin -Ttext 0x1000 kernel_entry.o kernel.o --oformat binary

# Create image
echo "Creating disk image..."
dd if=/dev/zero of=veltora.img bs=512 count=2880
dd if=boot.bin of=veltora.img conv=notrunc
dd if=kernel.bin of=veltora.img bs=512 seek=1 conv=notrunc

rm -f boot.bin kernel.bin *.o

echo "Build successful!"
