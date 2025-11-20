ORG 0x7C00
BITS 16

%define cursor_x    0x7E00
%define cursor_y    0x7E01
%define mouse_x     0x7E02
%define mouse_y     0x7E04
%define mouse_bg    0x7E06
%define curr_col    0x7E07
%define font_off    0x7E08
%define font_seg    0x7E0A

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov ax, 0x0013
    int 0x10

    xor ax, ax
    int 0x33
    mov ax, 1
    int 0x33

    mov ax, 0x1130
    mov bh, 0x03
    int 0x10
    mov [font_off], bp
    mov [font_seg], es

    mov byte [curr_col], 0x28

    mov di, 0
    mov cx, 320
    mov bx, 200
    mov al, 0x01
    call draw_rect

    mov di, 184*320
    mov cx, 320
    mov bx, 16
    mov al, 0x08
    call draw_rect

    mov di, 50*320+100
    mov cx, 120
    mov bx, 100
    mov al, 0x17
    call draw_rect

    call clear_pad
    call draw_col_box

main_loop:
    mov ax, 0x03
    int 0x33
    shr cx, 1
    cmp cx, [mouse_x]
    jne .mov
    cmp dx, [mouse_y]
    je .key
.mov:
    call mouse_upd
.key:
    mov ah, 0x01
    int 0x16
    jz main_loop

    mov ah, 0x00
    int 0x16

    cmp ah, 0x3B
    jl .char
    cmp ah, 0x3F
    jg .char
    sub ah, 0x3A
    mov [curr_col], ah
    call draw_col_box
    jmp main_loop

.char:
    cmp al, 27
    je reboot
    cmp al, 13
    je .ent
    cmp al, 8
    je .bck
    cmp al, 32
    jl main_loop

    call rest_mouse
    call prt_char
    inc byte [cursor_x]
    cmp byte [cursor_x], 14
    jl main_loop
.ent:
    call rest_mouse
    call newline
    jmp main_loop
.bck:
    cmp byte [cursor_x], 0
    je main_loop
    call rest_mouse
    dec byte [cursor_x]
    call clr_char
    jmp main_loop

reboot:
    int 0x19

mouse_upd:
    push cx
    push dx
    call rest_mouse
    pop dx
    pop cx
    mov [mouse_x], cx
    mov [mouse_y], dx
    call get_m_addr
    mov al, [es:di]
    mov [mouse_bg], al
    mov byte [es:di], 0x02
    ret

rest_mouse:
    mov ax, 0xA000
    mov es, ax
    mov cx, [mouse_x]
    mov dx, [mouse_y]
    call get_m_addr_r
    mov al, [mouse_bg]
    mov [es:di], al
    ret

newline:
    mov byte [cursor_x], 0
    inc byte [cursor_y]
    cmp byte [cursor_y], 10
    jl .ok
    call clear_pad
    mov byte [cursor_y], 0
.ok: ret

draw_rect:
    mov si, 0xA000
    mov es, si
.r: push di
    push cx
    rep stosb
    pop cx
    pop di
    add di, 320
    dec bx
    jnz .r
    ret

clear_pad:
    mov di, 60*320+104
    mov cx, 112
    mov bx, 80
    mov al, 0x0F
    jmp draw_rect

draw_col_box:
    mov di, 52*320+105
    mov cx, 10
    mov bx, 6
    mov al, [curr_col]
    jmp draw_rect

clr_char:
    call get_c_addr
    mov cx, 8
    mov bx, 8
    mov al, 0x0F
    jmp draw_rect

prt_char:
    pusha
    mov ax, 0xA000
    mov es, ax
    call get_c_addr

    push ds
    mov ds, [font_seg]
    mov si, [cs:font_off]
    xor bx, bx
    mov bl, al
    shl bx, 3
    add si, bx

    mov ch, 8
.l: mov bl, [ds:si]
    inc si
    push di
    mov cl, 8
.b: shl bl, 1
    jnc .s
    mov dl, [cs:curr_col]
    mov [es:di], dl
.s: inc di
    dec cl
    jnz .b
    pop di
    add di, 320
    dec ch
    jnz .l
    pop ds
    popa
    ret

get_c_addr:
    xor ax, ax
    mov al, [cursor_y]
    mov bl, 8
    mul bl
    add ax, 60
    mov dx, 320
    mul dx
    mov di, ax
    xor ax, ax
    mov al, [cursor_x]
    shl ax, 3
    add ax, 104
    add di, ax
    ret

get_m_addr:
    mov ax, [mouse_y]
    mov bx, 320
    mul bx
    add ax, [mouse_x]
    mov di, ax
    ret
get_m_addr_r:
    mov ax, dx
    mov bx, 320
    mul bx
    add ax, cx
    mov di, ax
    ret

times 510-($-$$) db 0
dw 0xAA55
