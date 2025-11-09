ORG 0x7C00
BITS 16

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; VGA 320x200 256-color mod
    mov ax, 0x0013
    int 0x10

    call init_mouse
    call draw_desktop
    call draw_taskbar
    call draw_icons

.main_loop:
    call draw_mouse
    call check_keyboard
    jmp .main_loop

    jmp $

init_mouse:
    mov ax, 0x0000
    int 0x33
    cmp ax, 0x0000
    je .no_mouse
    mov ax, 0x0001
    int 0x33
    ret
.no_mouse:
    ret

draw_mouse:
    mov ax, 0x0003
    int 0x33
    mov ax, 0xA000
    mov es, ax
    mov di, dx
    mov ax, di
    mov bx, 320
    mul bx
    mov di, ax
    add di, cx
    mov byte [es:di], 0x0F
    mov byte [es:di+1], 0x0F
    mov byte [es:di+320], 0x0F
    mov byte [es:di+321], 0x0F
    ret

check_keyboard:
    mov ah, 0x01
    int 0x16
    jz .no_key
    mov ah, 0x00
    int 0x16
    cmp al, 27
    je .exit
    cmp al, ' '
    jne .no_key
    call draw_desktop
    call draw_taskbar
    call draw_icons
.no_key:
    ret
.exit:
    ; return to text mode
    mov ax, 0x0003
    int 0x10
    jmp $

draw_desktop:
    mov ax, 0xA000
    mov es, ax
    xor di, di
    mov cx, 320*200
    mov al, 0x01
.draw_loop:
    mov [es:di], al
    inc di
    test di, 63
    jnz .same_color
    cmp al, 0x23
    jge .same_color
    inc al
.same_color:
    loop .draw_loop
    ret

draw_taskbar:
    mov ax, 0xA000
    mov es, ax
    mov di, 184*320
    mov cx, 16*320
    mov al, 0x08
    rep stosb
    mov di, 184*320 + 5
    mov cx, 12
    mov al, 0x0C
.button_loop:
    mov [es:di], al
    add di, 320
    loop .button_loop
    mov di, 188*320 + 8
    mov si, start_text
    mov ah, 0x00
    call print_graphics
    ret

draw_icons:
    mov ax, 20
    mov bx, 20  
    mov cl, 0x0E
    mov si, icon1_text
    call draw_icon

    mov ax, 20
    mov bx, 50
    mov cl, 0x0B
    mov si, icon2_text
    call draw_icon

    mov ax, 20
    mov bx, 80
    mov cl, 0x0A
    mov si, icon3_text
    call draw_icon

    mov ax, 20
    mov bx, 110
    mov cl, 0x0D
    mov si, icon4_text
    call draw_icon
    ret

draw_icon:
    pusha
    mov dx, 0xA000
    mov es, dx
    xchg ax, bx
    mov dx, 320
    mul dx
    add ax, bx
    mov di, ax
    mov dx, 16
.row_loop:
    push di
    mov ch, 16
.col_loop:
    mov [es:di], cl
    inc di
    dec ch
    jnz .col_loop
    pop di
    add di, 320
    dec dx
    jnz .row_loop
    mov ax, bx
    mov bx, [esp+4]
    add bx, 18
    mov ax, bx
    mov bx, 320
    mul bx
    add ax, [esp+6]
    mov di, ax
    mov ah, 0x0F
    call print_graphics
    popa
    ret

print_graphics:
    pusha
.loop:
    lodsb
    test al, al
    jz .done
    mov [es:di], ah
    inc di
    jmp .loop
.done:
    popa
    ret

start_text db "Start", 0
icon1_text db "My Computer", 0
icon2_text db "Documents", 0  
icon3_text db "Browser", 0
icon4_text db "Settings", 0

times 510-($-$$) db 0
dw 0xAA55
