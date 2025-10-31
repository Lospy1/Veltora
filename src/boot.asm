
---

## boot.asm (a)

```asm
org 0x7C00

mov ax, 0xB800
mov es, ax
xor di, di

mov cx, 2000
mov al, ' '
mov ah, 0x1F
rep stosw

mov si, msg
mov di, 80*6 + 12*2
.next_char:
    lodsb
    cmp al,0
    je .done
    mov ah,0x1F
    stosw
    jmp .next_char
.done:

jmp $

msg db "Hello GUI Kernel!",0

times 510-($-$$) db 0
dw 0xAA55

