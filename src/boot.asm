; boot.asm - GELİŞMİŞ SÜRÜM
BITS 16
ORG 0x7C00

start:

    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti


    mov ah, 0x00
    int 0x13
    jc disk_error

    mov bx, 0x8000
    mov al, 50      
    mov ch, 0       
    mov dh, 0       
    mov cl, 2       
    mov ah, 0x02   
    int 0x13
    jc disk_error

    
    jmp 0x8000

disk_error:

    mov ah, 0x0E
    mov al, 'E'
    int 0x10
    jmp $

times 510 - ($ - $$) db 0
dw 0xAA55
