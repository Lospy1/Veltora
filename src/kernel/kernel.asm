; kernel.asm
ORG 0x8000
BITS 16

%define safe_cursor_x 0x9000
%define safe_cursor_y 0x9001
%define safe_curr_col 0x9007
%define safe_font_off 0x9008 
%define safe_font_seg 0x900A 
%define win_x         0x900C 
%define win_y         0x900E 
%define buffer_ptr    0x9010 

%define active_win    0x9020 
%define is_calc_open  0x9021 
%define calc_buf_ptr  0x9022 
%define calc_screen_x 0x9024 
%define calc_win_x    0x9030 
%define calc_win_y    0x9032 
%define calc_op       0x9034 
%define calc_num1     0x9036 

%define mouse_x       0x9040
%define mouse_y       0x9042
%define mouse_bg_buf  0x9600 
%define mouse_cycle   0x9046 
%define mouse_packet  0x9050 
%define mouse_visible 0x9060

%define dragging_win  0x9080 
%define drag_off_x    0x9082 
%define drag_off_y    0x9084 

%define text_buffer   0x9300 
%define calc_buffer   0x9500 
%define cmd_buffer    0x9100

start:
    cli
    cld
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov ax, 0x0013
    int 0x10

    mov ax, 0x1130
    mov bh, 0x03
    int 0x10
    mov [safe_font_off], bp
    mov [safe_font_seg], es

    mov byte [safe_cursor_x], 0
    mov byte [safe_cursor_y], 0
    mov byte [safe_curr_col], 0x00 
    
    mov word [win_x], 20           
    mov word [win_y], 30 
    mov word [calc_win_x], 160
    mov word [calc_win_y], 30
    
    mov byte [active_win], 0       
    mov byte [is_calc_open], 0     
    mov byte [calc_buf_ptr], 0     
    mov byte [calc_screen_x], 0    
    mov word [buffer_ptr], 0   
    mov byte [calc_op], 0
    mov word [calc_num1], 0

    mov word [mouse_x], 160
    mov word [mouse_y], 100
    mov byte [mouse_cycle], 0
    mov byte [mouse_visible], 0
    
    mov byte [dragging_win], 0
    mov word [drag_off_x], 0
    mov word [drag_off_y], 0

    push si
    mov si, text_buffer
    mov byte [si], 0x00
    mov si, calc_buffer
    mov byte [si], 0x00
    pop si
    
    call redraw_all 
    call clear_notepad_content 

    call mouse_init_safe
    call save_mouse_bg
    call draw_mouse_cursor
    mov byte [mouse_visible], 1

flush_start:
    mov ah, 0x01
    int 0x16
    jz main_loop

    mov ah, 0x00
    int 0x16
    jmp flush_start

main_loop: 
    xor ax, ax
    mov ds, ax
    mov es, ax

    call mouse_handler_safe

    mov ah, 0x01
    int 0x16
    jz main_loop

    mov ah, 0x00
    int 0x16

    cmp ah, 0x0F 
    je switch_window
    cmp ah, 0x53 
    je hard_reset_current
    
    cmp ah, 0x48 
    je dispatch_move_up
    cmp ah, 0x50 
    je dispatch_move_down
    cmp ah, 0x4B 
    je dispatch_move_left
    cmp ah, 0x4D 
    je dispatch_move_right
    
    cmp ah, 0x3B 
    je set_red
    cmp ah, 0x3C 
    je set_blue
    cmp ah, 0x3D 
    je set_yellow
    cmp ah, 0x3E 
    je set_green
    cmp ah, 0x3F 
    je set_black

    cmp byte [active_win], 1
    je input_calculator
    jmp input_notepad

input_calculator:
    cmp al, 27 
    je .close_calc
    cmp al, 8
    je calc_bs_logic
    cmp al, 13 
    je calc_do_logic
    
    cmp al, '0'
    jl .check_ops
    cmp al, '9'
    jg .check_ops
    jmp calc_add_digit

.check_ops:
    cmp al, '+'
    je .op_add
    cmp al, '-'
    je .op_sub
    cmp al, '*'
    je .op_mul
    cmp al, '/'
    je .op_div
    cmp al, '='
    je calc_do_logic
    cmp al, 'c'
    je calc_clear_logic
    cmp al, 'C'
    je calc_clear_logic
    jmp main_loop

.op_add:
    mov byte [calc_op], '+'
    jmp calc_set_op_logic
.op_sub:
    mov byte [calc_op], '-'
    jmp calc_set_op_logic
.op_mul:
    mov byte [calc_op], '*'
    jmp calc_set_op_logic
.op_div:
    mov byte [calc_op], '/'
    jmp calc_set_op_logic

.close_calc:
    mov byte [is_calc_open], 0
    mov byte [active_win], 0
    call redraw_all
    jmp main_loop

calc_add_digit:
    cmp byte [calc_screen_x], 10
    jge main_loop
    push ax
    call add_char_to_calc_ram
    pop ax
    inc byte [calc_screen_x] 
    call draw_all_calc_text
    call restore_mouse_bg
    call save_mouse_bg
    call draw_mouse_cursor
    jmp main_loop

calc_set_op_logic:
    call calc_parse_int
    mov [calc_num1], ax
    call clear_calc_screen_vars
    call draw_calculator_frame
    call restore_mouse_bg
    call save_mouse_bg
    call draw_mouse_cursor
    jmp main_loop

calc_do_logic:
    call calc_parse_int
    mov bx, ax
    mov ax, [calc_num1]
    cmp byte [calc_op], '+'
    je .do_add
    cmp byte [calc_op], '-'
    je .do_sub
    cmp byte [calc_op], '*'
    je .do_mul
    cmp byte [calc_op], '/'
    je .do_div
    jmp main_loop

.do_add:
    add ax, bx
    jmp .finish
.do_sub:
    sub ax, bx
    jmp .finish
.do_mul:
    imul bx
    jmp .finish
.do_div:
    cmp bx, 0
    je calc_clear_logic
    xor dx, dx
    cwd
    idiv bx
.finish:
    call clear_calc_screen_vars
    call draw_calculator_frame 
    call calc_int_to_string
    call draw_all_calc_text
    mov word [calc_num1], 0
    mov byte [calc_op], 0
    call restore_mouse_bg
    call save_mouse_bg
    call draw_mouse_cursor
    jmp main_loop

calc_clear_logic:
    call clear_calc_screen_vars
    mov word [calc_num1], 0
    mov byte [calc_op], 0
    call draw_calculator_frame
    call restore_mouse_bg
    call save_mouse_bg
    call draw_mouse_cursor
    jmp main_loop

calc_bs_logic:
    cmp byte [calc_screen_x], 0
    je main_loop
    dec byte [calc_screen_x]
    pusha
    mov si, calc_buffer
    xor bx, bx
    mov bl, [calc_screen_x]
    add si, bx
    mov byte [si], 0x00 
    popa
    call draw_calculator_frame
    call draw_all_calc_text
    call restore_mouse_bg
    call save_mouse_bg
    call draw_mouse_cursor
    jmp main_loop

handle_click_logic:
    pusha
    mov cx, [mouse_x]
    mov dx, [mouse_y]
    
    
    cmp byte [is_calc_open], 1
    jne .check_np_drag
    
    mov ax, [calc_win_x]
    cmp cx, ax
    jl .check_np_drag
    add ax, 120
    cmp cx, ax
    jg .check_np_drag
    mov ax, [calc_win_y]
    sub ax, 10 
    cmp dx, ax
    jl .check_np_drag
    add ax, 10 
    cmp dx, ax
    jg .check_np_drag
    
    mov byte [active_win], 1
    mov byte [dragging_win], 2 
    mov ax, [mouse_x]
    sub ax, [calc_win_x]
    mov [drag_off_x], ax
    mov ax, [mouse_y]
    sub ax, [calc_win_y]
    mov [drag_off_y], ax
    call redraw_all
    popa
    ret

.check_np_drag:
    mov ax, [win_x]
    cmp cx, ax
    jl .check_content_click
    add ax, 220
    cmp cx, ax
    jg .check_content_click
    mov ax, [win_y]
    sub ax, 10
    cmp dx, ax
    jl .check_content_click
    add ax, 10
    cmp dx, ax
    jg .check_content_click
    
    mov byte [active_win], 0
    mov byte [dragging_win], 1 
    mov ax, [mouse_x]
    sub ax, [win_x]
    mov [drag_off_x], ax
    mov ax, [mouse_y]
    sub ax, [win_y]
    mov [drag_off_y], ax
    call redraw_all
    popa
    ret

.check_content_click:
    
    mov ax, [calc_win_x]
    cmp cx, ax
    jl .chk_np_body
    add ax, 120
    cmp cx, ax
    jg .chk_np_body
    mov ax, [calc_win_y]
    cmp dx, ax
    jl .chk_np_body
    add ax, 160
    cmp dx, ax
    jg .chk_np_body
    
    mov byte [active_win], 1
    call redraw_all
    
    cmp byte [is_calc_open], 1
    jne .restore_mouse_exit

    sub cx, [calc_win_x]
    sub dx, [calc_win_y]
    sub cx, 10
    sub dx, 40
    
    cmp cx, 0
    jl .restore_mouse_exit
    cmp dx, 0
    jl .restore_mouse_exit
    
    mov ax, dx
    mov bl, 25
    div bl
    mov dh, al 
    mov ax, cx
    mov bl, 25
    div bl
    mov dl, al 
    
    cmp dl, 3
    jg .restore_mouse_exit
    cmp dh, 3
    jg .restore_mouse_exit
    
    cmp dh, 0
    je .row0
    cmp dh, 1
    je .row1
    cmp dh, 2
    je .row2
    cmp dh, 3
    je .row3
    jmp .restore_mouse_exit

.row0: 
    cmp dl, 0
    je .b7
    cmp dl, 1
    je .b8
    cmp dl, 2
    je .b9
    jmp .bDiv
.row1: 
    cmp dl, 0
    je .b4
    cmp dl, 1
    je .b5
    cmp dl, 2
    je .b6
    jmp .bMul
.row2: 
    cmp dl, 0
    je .b1
    cmp dl, 1
    je .b2
    cmp dl, 2
    je .b3
    jmp .bSub
.row3: 
    cmp dl, 0
    je .bClr
    cmp dl, 1
    je .b0
    cmp dl, 2
    je .bEq
    jmp .bAdd

.b7: mov al, '7' 
     jmp .send
.b8: mov al, '8' 
     jmp .send
.b9: mov al, '9' 
     jmp .send
.bDiv: jmp .op_div_jmp
.b4: mov al, '4' 
     jmp .send
.b5: mov al, '5' 
     jmp .send
.b6: mov al, '6' 
     jmp .send
.bMul: jmp .op_mul_jmp
.b1: mov al, '1' 
     jmp .send
.b2: mov al, '2' 
     jmp .send
.b3: mov al, '3' 
     jmp .send
.bSub: jmp .op_sub_jmp
.bClr: jmp .op_clr_jmp
.b0: mov al, '0' 
     jmp .send
.bEq: jmp .op_eq_jmp
.bAdd: jmp .op_add_jmp

.send:
    call calc_add_digit
    jmp .restore_mouse_exit
.op_div_jmp: jmp calc_set_op_div
.op_mul_jmp: jmp calc_set_op_mul
.op_sub_jmp: jmp calc_set_op_sub
.op_add_jmp: jmp calc_set_op_add
.op_eq_jmp: jmp calc_do_logic_proxy
.op_clr_jmp: jmp calc_clear_logic_proxy

.restore_mouse_exit:
    call restore_mouse_bg
    call save_mouse_bg
    call draw_mouse_cursor
    popa
    ret

.chk_np_body:
    mov ax, [win_x]
    cmp cx, ax
    jl .restore_mouse_exit
    add ax, 220
    cmp cx, ax
    jg .restore_mouse_exit
    mov ax, [win_y]
    cmp dx, ax
    jl .restore_mouse_exit
    add ax, 110
    cmp dx, ax
    jg .restore_mouse_exit
    
    mov byte [active_win], 0
    call redraw_all
    jmp .restore_mouse_exit

calc_set_op_div:
    mov byte [calc_op], '/'
    jmp calc_set_op_logic
calc_set_op_mul:
    mov byte [calc_op], '*'
    jmp calc_set_op_logic
calc_set_op_sub:
    mov byte [calc_op], '-'
    jmp calc_set_op_logic
calc_set_op_add:
    mov byte [calc_op], '+'
    jmp calc_set_op_logic
calc_do_logic_proxy:
    jmp calc_do_logic
calc_clear_logic_proxy:
    jmp calc_clear_logic

mouse_handler_safe:
    pusha
    mov ax, 0xA000
    mov es, ax
    in al, 0x64
    test al, 0x01
    jz .exit_mh
    in al, 0x60
    cmp byte [mouse_cycle], 0
    jne .save_byte
    test al, 0x08
    jz .reset_cycle
.save_byte:
    mov bl, [mouse_cycle]
    xor bh, bh
    mov [mouse_packet + bx], al
    inc byte [mouse_cycle]
    cmp byte [mouse_cycle], 3
    jne .exit_mh
    
    mov byte [mouse_cycle], 0
    call restore_mouse_bg
    
    mov bl, [mouse_packet + 1]
    xor bh, bh
    test byte [mouse_packet + 0], 0x10
    jz .x_pos
    mov bh, 0xFF
.x_pos:
    mov ax, [mouse_x]
    add ax, bx
    cmp ax, 0
    jge .x_ok
    mov ax, 0
.x_ok:
    cmp ax, 308
    jle .x_ok2
    mov ax, 308
.x_ok2:
    mov [mouse_x], ax
    mov bl, [mouse_packet + 2]
    xor bh, bh
    test byte [mouse_packet + 0], 0x20
    jz .y_pos
    mov bh, 0xFF
.y_pos:
    mov ax, [mouse_y]
    sub ax, bx
    cmp ax, 0
    jge .y_ok
    mov ax, 0
.y_ok:
    cmp ax, 180
    jle .y_ok2
    mov ax, 180
.y_ok2:
    mov [mouse_y], ax

    mov al, [mouse_packet + 0]
    test al, 1 
    jnz .left_btn_down
    
    mov byte [dragging_win], 0
    jmp .draw_cursor_exit

.left_btn_down:
    cmp byte [dragging_win], 0
    jne .process_drag 
    
    call handle_click_logic
    jmp .exit_mh 

.process_drag:
    cmp byte [dragging_win], 1
    je .drag_notepad
    cmp byte [dragging_win], 2
    je .drag_calc
    jmp .draw_cursor_exit

.drag_notepad:
    mov ax, [mouse_x]
    sub ax, [drag_off_x] 
    cmp ax, 0
    jl .np_x_fix
    cmp ax, 250 
    jg .np_x_fix
    mov [win_x], ax
    jmp .np_y_calc
.np_x_fix:
.np_y_calc:
    mov ax, [mouse_y]
    sub ax, [drag_off_y]
    cmp ax, 20 
    jl .np_y_fix
    cmp ax, 180
    jg .np_y_fix
    mov [win_y], ax
.np_y_fix:
    call redraw_all 
    jmp .exit_mh 

.drag_calc:
    mov ax, [mouse_x]
    sub ax, [drag_off_x]
    cmp ax, 0
    jl .cl_x_fix
    cmp ax, 250
    jg .cl_x_fix
    mov [calc_win_x], ax
    jmp .cl_y_calc
.cl_x_fix:
.cl_y_calc:
    mov ax, [mouse_y]
    sub ax, [drag_off_y]
    cmp ax, 20
    jl .cl_y_fix
    cmp ax, 180
    jg .cl_y_fix
    mov [calc_win_y], ax
.cl_y_fix:
    call redraw_all
    jmp .exit_mh

.draw_cursor_exit:
    call save_mouse_bg
    call draw_mouse_cursor
    jmp .exit_mh

.reset_cycle:
    mov byte [mouse_cycle], 0
.exit_mh:
    popa
    ret

mouse_init_safe:
    pusha
    call mouse_wait_w
    mov al, 0xA8
    out 0x64, al
    call mouse_wait_w
    mov al, 0xD4
    out 0x64, al
    call mouse_wait_w
    mov al, 0xF4
    out 0x60, al
    popa
    ret
mouse_wait_w:
    push cx
    mov cx, 1000
.l: in al, 0x64
    test al, 0x02
    jz .ok
    loop .l
.ok: pop cx
    ret

save_mouse_bg:
    pusha
    mov ax, 0xA000
    mov es, ax
    mov si, mouse_bg_buf
    mov ax, [mouse_y]
    mov bx, 320
    mul bx
    add ax, [mouse_x]
    mov di, ax
    mov cx, 16
.row:
    push cx
    push di
    mov cx, 12
.pix:
    mov al, [es:di]
    mov [ds:si], al
    inc di
    inc si
    loop .pix
    pop di
    add di, 320
    pop cx
    loop .row
    popa
    ret

restore_mouse_bg:
    pusha
    mov ax, 0xA000
    mov es, ax
    mov si, mouse_bg_buf
    mov ax, [mouse_y]
    mov bx, 320
    mul bx
    add ax, [mouse_x]
    mov di, ax
    mov cx, 16
.row:
    push cx
    push di
    mov cx, 12
.pix:
    mov al, [ds:si]
    mov [es:di], al
    inc di
    inc si
    loop .pix
    pop di
    add di, 320
    pop cx
    loop .row
    popa
    ret

draw_mouse_cursor:
    pusha
    mov ax, 0xA000
    mov es, ax
    mov ax, [mouse_y]
    mov bx, 320
    mul bx
    add ax, [mouse_x]
    mov di, ax
    mov byte [es:di], 0
    add di, 320
    mov byte [es:di], 0
    mov byte [es:di+1], 15
    mov byte [es:di+2], 0
    add di, 320
    mov byte [es:di], 0
    mov byte [es:di+1], 15
    mov byte [es:di+2], 15
    mov byte [es:di+3], 0
    add di, 320
    mov byte [es:di], 0
    mov byte [es:di+1], 15
    mov byte [es:di+2], 0
    add di, 320
    mov byte [es:di], 0
    mov byte [es:di+1], 0
    popa
    ret

draw_calculator_frame:
    pusha
    mov ax, [calc_win_x]
    mov di, ax
    mov ax, [calc_win_y]
    sub ax, 8 
    mov bx, 320
    mul bx
    add di, ax
    mov cx, 120
    mov bx, 8
    cmp byte [active_win], 1
    je .active
    mov al, 0x08 
    jmp .draw_h
.active:
    mov al, 0x28 
.draw_h:
    call draw_rect_dynamic
    mov ax, [calc_win_x]
    mov di, ax
    mov ax, [calc_win_y]
    mov bx, 320
    mul bx
    add di, ax
    mov cx, 120
    mov bx, 150
    mov al, 0x18 
    call draw_rect_dynamic
    mov ax, [calc_win_x]
    add ax, 10
    mov di, ax
    mov ax, [calc_win_y]
    add ax, 10
    mov bx, 320
    mul bx
    add di, ax
    mov cx, 100
    mov bx, 20
    mov al, 0x0F 
    call draw_rect_dynamic
    
    call draw_btn_7
    call draw_btn_8
    call draw_btn_9
    call draw_btn_div
    call draw_btn_4
    call draw_btn_5
    call draw_btn_6
    call draw_btn_mul
    call draw_btn_1
    call draw_btn_2
    call draw_btn_3
    call draw_btn_sub
    call draw_btn_c
    call draw_btn_0
    call draw_btn_eq
    call draw_btn_add
    popa
    ret

draw_btn_7:
    mov ax, 0
    mov bx, 0
    mov cl, '7'
    call draw_single_btn_impl
    ret
draw_btn_8:
    mov ax, 25
    mov bx, 0
    mov cl, '8'
    call draw_single_btn_impl
    ret
draw_btn_9:
    mov ax, 50
    mov bx, 0
    mov cl, '9'
    call draw_single_btn_impl
    ret
draw_btn_div:
    mov ax, 75
    mov bx, 0
    mov cl, '/'
    call draw_single_btn_impl
    ret
draw_btn_4:
    mov ax, 0
    mov bx, 25
    mov cl, '4'
    call draw_single_btn_impl
    ret
draw_btn_5:
    mov ax, 25
    mov bx, 25
    mov cl, '5'
    call draw_single_btn_impl
    ret
draw_btn_6:
    mov ax, 50
    mov bx, 25
    mov cl, '6'
    call draw_single_btn_impl
    ret
draw_btn_mul:
    mov ax, 75
    mov bx, 25
    mov cl, '*'
    call draw_single_btn_impl
    ret
draw_btn_1:
    mov ax, 0
    mov bx, 50
    mov cl, '1'
    call draw_single_btn_impl
    ret
draw_btn_2:
    mov ax, 25
    mov bx, 50
    mov cl, '2'
    call draw_single_btn_impl
    ret
draw_btn_3:
    mov ax, 50
    mov bx, 50
    mov cl, '3'
    call draw_single_btn_impl
    ret
draw_btn_sub:
    mov ax, 75
    mov bx, 50
    mov cl, '-'
    call draw_single_btn_impl
    ret
draw_btn_c:
    mov ax, 0
    mov bx, 75
    mov cl, 'C'
    call draw_single_btn_impl
    ret
draw_btn_0:
    mov ax, 25
    mov bx, 75
    mov cl, '0'
    call draw_single_btn_impl
    ret
draw_btn_eq:
    mov ax, 50
    mov bx, 75
    mov cl, '='
    call draw_single_btn_impl
    ret
draw_btn_add:
    mov ax, 75
    mov bx, 75
    mov cl, '+'
    call draw_single_btn_impl
    ret

draw_single_btn_impl:
    pusha
    push ax 
    push bx 
    mov dx, [calc_win_x]
    add dx, 10
    add dx, ax
    mov di, dx 
    mov dx, [calc_win_y]
    add dx, 40
    add dx, bx 
    mov ax, dx
    mov dx, 320
    mul dx
    add di, ax
    mov cx, 20
    mov bx, 20
    mov al, 0x07
    call draw_rect_dynamic
    pop bx 
    pop ax 
    mov ch, cl 
    mov dx, [calc_win_x]
    add dx, 10
    add dx, ax
    add dx, 6 
    push dx 
    mov dx, [calc_win_y]
    add dx, 40
    add dx, bx
    add dx, 6 
    push dx 
    mov al, ch 
    pop dx 
    pop cx 
    call draw_char_pixel_direct
    popa
    ret

draw_char_pixel_direct:
    pusha
    push ax
    
    mov ax, 0xA000
    mov es, ax
    
    mov ax, dx
    mov bx, 320
    mul bx
    add ax, cx
    mov di, ax 
    pop ax 
    
    push ds 
    
    mov dx, [safe_font_seg] 
    mov si, [safe_font_off]
    mov ds, dx 
    
    mov bh, al     
    xor ax, ax     
    mov al, bh     
    mov cl, 3      
    shl ax, cl     
    add si, ax     
    
    mov ch, 8 
.l: 
    mov bl, [ds:si]
    inc si
    push di
    mov cl, 8
.b: 
    shl bl, 1
    jnc .s
    mov byte [es:di], 0 
.s: 
    inc di
    dec cl
    jnz .b
    pop di
    add di, 320
    dec ch
    jnz .l
    
    pop ds 
    popa
    ret

draw_rect_dynamic: 
    pusha
    mov dx, 0xA000
    mov es, dx
.r2: push di
    push cx
    rep stosb
    pop cx
    pop di
    add di, 320
    dec bx
    jnz .r2
    popa
    ret

redraw_all:
    pusha
    mov di, 0
    mov cx, 320
    mov bx, 200
    mov al, 0x01 
    call draw_rect_fixed
    mov di, 184*320
    mov cx, 320
    mov bx, 16
    mov al, 0x08 
    call draw_rect_fixed
    cmp byte [active_win], 0
    je .draw_notepad_top
    call draw_notepad_frame 
    cmp byte [is_calc_open], 1
    jne .done_draw
    call draw_calculator_frame 
    jmp .done_draw
.draw_notepad_top:
    cmp byte [is_calc_open], 1
    jne .only_np
    call draw_calculator_frame
.only_np:
    call draw_notepad_frame 
.done_draw:
    call draw_all_notepad_text
    cmp byte [is_calc_open], 1
    jne .skip_calc_text
    call draw_all_calc_text
.skip_calc_text:
    popa
    ret

draw_rect_fixed:
    pusha
    mov dx, 0xA000
    mov es, dx
.r: push di
    push cx
    rep stosb
    pop cx
    pop di
    add di, 320
    dec bx
    jnz .r
    popa
    ret

draw_notepad_frame:
    pusha 
    mov ax, [win_x]
    mov di, ax
    mov ax, [win_y]
    sub ax, 10
    mov bx, 320
    mul bx
    add di, ax
    mov cx, 220
    mov bx, 10
    cmp byte [active_win], 0
    je .np_active
    mov al, 0x08 
    jmp .dr_np_head
.np_active:
    mov al, 0x02 
.dr_np_head:
    call draw_rect_dynamic
    mov ax, [win_x]
    mov di, ax        
    mov ax, [win_y]   
    mov bx, 320
    mul bx            
    add di, ax        
    mov cx, 220       
    mov bx, 100       
    mov al, 0x07      
    call draw_rect_dynamic
    mov ax, [win_x]
    add ax, 5        
    mov di, ax
    mov ax, [win_y]
    add ax, 5       
    mov bx, 320
    mul bx
    add di, ax
    mov cx, 210       
    mov bx, 90        
    mov al, 0x0F      
    call draw_rect_dynamic 
    popa 
    ret

clear_notepad_content:
    pusha
    mov ax, [win_x]
    add ax, 5        
    mov di, ax
    mov ax, [win_y]
    add ax, 5       
    mov bx, 320
    mul bx
    add di, ax
    mov cx, 210       
    mov bx, 90        
    mov al, 0x0F     
    call draw_rect_dynamic
    popa
    ret

draw_all_notepad_text:
    pusha
    mov si, text_buffer 
    mov bl, [safe_cursor_x] 
    mov bh, [safe_cursor_y] 
    mov byte [safe_cursor_x], 0 
    mov byte [safe_cursor_y], 0 
.loop_draw:
    mov al, [si]
    cmp al, 0x00      
    je .done_draw_text
    cmp al, 13         
    je .handle_newline
    call prt_char_notepad 
    inc byte [safe_cursor_x]
    cmp byte [safe_cursor_x], 24
    jl .continue
.handle_newline:
    mov byte [safe_cursor_x], 0
    inc byte [safe_cursor_y]
.continue:
    inc si
    jmp .loop_draw
.done_draw_text:
    mov [safe_cursor_x], bl 
    mov [safe_cursor_y], bh 
    popa
    ret

prt_char_notepad:
    pusha 
    push ax 
    mov ax, 0xA000
    mov es, ax
    call get_c_addr_np
    pop ax 
    
    mov dl, [safe_curr_col] 
    
    push ds 
    
    mov cx, [safe_font_seg] 
    mov si, [safe_font_off] 
    mov ds, cx 
    
    mov bh, al     
    xor ax, ax     
    mov al, bh     
    mov cl, 3      
    shl ax, cl     
    add si, ax     
    
    mov ch, 8 
.l: 
    mov bl, [ds:si] 
    inc si
    push di
    mov cl, 8 
.b: 
    shl bl, 1
    jnc .s
    
    mov [es:di], dl 
.s: 
    inc di
    dec cl
    jnz .b
    pop di
    add di, 320
    dec ch
    jnz .l
    
    pop ds 
    popa
    ret

get_c_addr_np:
    push cx 
    push bx
    push dx
    push si
    xor ax, ax
    mov al, [safe_cursor_y]
    mov bl, 8
    mul bl          
    add ax, [win_y] 
    add ax, 5       
    mov bx, 320     
    mul bx          
    mov di, ax      
    xor ax, ax
    mov al, [safe_cursor_x]
    shl ax, 3       
    add ax, [win_x]
    add ax, 5
    add di, ax      
    pop si
    pop dx
    pop bx
    pop cx
    ret

clear_calc_screen_vars:
    mov byte [calc_screen_x], 0
    pusha
    mov si, calc_buffer
    mov cx, 16
.cl: mov byte [si], 0
     inc si
     loop .cl
    popa
    ret

calc_parse_int:
    push bx
    push cx
    push si
    push dx
    mov si, calc_buffer
    xor ax, ax 
    xor cx, cx 
    mov bx, 10
.p_loop:
    mov cl, [si]
    cmp cl, 0
    je .p_done
    cmp cl, '0'
    jl .p_done
    cmp cl, '9'
    jg .p_done
    sub cl, '0'
    mul bx     
    add ax, cx 
    inc si
    jmp .p_loop
.p_done:
    pop dx
    pop si
    pop cx
    pop bx
    ret

calc_int_to_string:
    pusha
    mov si, calc_buffer
    mov cx, 0 
    mov bx, 10
    cmp ax, 0
    jge .conv_loop
    neg ax      
    mov byte [si], '-'
    inc si
    inc byte [calc_screen_x]
.conv_loop:
    xor dx, dx
    div bx      
    push dx     
    inc cx
    cmp ax, 0
    jne .conv_loop
.write_loop:
    pop dx
    add dl, '0'
    mov [si], dl
    inc si
    inc byte [calc_screen_x]
    loop .write_loop
    mov byte [si], 0 
    popa
    ret

add_char_to_calc_ram:
    pusha
    mov si, calc_buffer
    xor bx, bx
    mov bl, [calc_screen_x]
    add si, bx
    mov [si], al
    inc si
    mov byte [si], 0x00 
    popa
    ret

draw_all_calc_text:
    pusha
    mov si, calc_buffer
    mov bl, [calc_screen_x] 
    mov byte [calc_screen_x], 0 
.cloop:
    mov al, [si]
    cmp al, 0x00
    je .cdone
    call prt_char_calc 
    inc byte [calc_screen_x]
    inc si
    jmp .cloop
.cdone:
    mov [calc_screen_x], bl 
    popa
    ret

prt_char_calc:
    pusha
    push ax 
    mov ax, 0xA000
    mov es, ax
    mov ax, [calc_win_y]
    add ax, 15 
    mov bx, 320
    mul bx
    add ax, [calc_win_x]
    add ax, 15
    mov di, ax
    xor ax, ax
    mov al, [calc_screen_x]
    shl ax, 3 
    add di, ax
    pop ax 
    
    push ds 
    
    mov dx, [safe_font_seg]
    mov si, [safe_font_off]
    mov ds, dx 
    
    mov bh, al     
    xor ax, ax     
    mov al, bh     
    mov cl, 3      
    shl ax, cl     
    add si, ax     
    
    mov ch, 8
.lc: 
    mov bl, [ds:si]
    inc si
    push di
    mov cl, 8
.bc: 
    shl bl, 1
    jnc .sc
    mov dl, 0x00 
    mov [es:di], dl
.sc: 
    inc di
    dec cl
    jnz .bc
    pop di
    add di, 320
    dec ch
    jnz .lc
    
    pop ds 
    popa
    ret

hard_reset_current:
    cmp byte [active_win], 1
    je .reset_calc
    mov word [buffer_ptr], 0
    push si
    mov si, text_buffer
    mov byte [si], 0x00 
    pop si
    call clear_notepad_content 
    mov byte [safe_cursor_x], 0
    mov byte [safe_cursor_y], 0
    mov byte [calc_buf_ptr], 0 
    jmp main_loop
.reset_calc:
    call clear_calc_screen_vars
    mov word [calc_num1], 0
    mov byte [calc_op], 0
    call draw_calculator_frame
    call restore_mouse_bg
    call save_mouse_bg
    call draw_mouse_cursor
    jmp main_loop
switch_window:
    cmp byte [is_calc_open], 0
    je main_loop
    xor byte [active_win], 1
    call redraw_all 
    jmp main_loop

set_red:
    mov byte [safe_curr_col], 0x28
    jmp main_loop
set_blue:
    mov byte [safe_curr_col], 0x09
    jmp main_loop
set_yellow:
    mov byte [safe_curr_col], 0x2C
    jmp main_loop
set_green:
    mov byte [safe_curr_col], 0x02
    jmp main_loop
set_black:
    mov byte [safe_curr_col], 0x00
    jmp main_loop

dispatch_move_up:
    cmp byte [active_win], 1
    je calc_move_up
    jmp np_move_up
dispatch_move_down:
    cmp byte [active_win], 1
    je calc_move_down
    jmp np_move_down
dispatch_move_left:
    cmp byte [active_win], 1
    je calc_move_left
    jmp np_move_left
dispatch_move_right:
    cmp byte [active_win], 1
    je calc_move_right
    jmp np_move_right

np_move_up:
    cmp word [win_y], 20
    jl main_loop
    sub word [win_y], 5
    call redraw_all
    jmp main_loop
np_move_down:
    cmp word [win_y], 90
    jg main_loop
    add word [win_y], 5
    call redraw_all
    jmp main_loop
np_move_left:
    cmp word [win_x], 5
    jl main_loop
    sub word [win_x], 5
    call redraw_all
    jmp main_loop
np_move_right:
    cmp word [win_x], 100
    jg main_loop
    add word [win_x], 5
    call redraw_all
    jmp main_loop

calc_move_up:
    cmp word [calc_win_y], 20
    jl main_loop
    sub word [calc_win_y], 2
    call redraw_all
    jmp main_loop
calc_move_down:
    cmp word [calc_win_y], 40
    jg main_loop
    add word [calc_win_y], 2
    call redraw_all
    jmp main_loop
calc_move_left:
    cmp word [calc_win_x], 5
    jl main_loop
    sub word [calc_win_x], 2
    call redraw_all
    jmp main_loop
calc_move_right:
    cmp word [calc_win_x], 195
    jg main_loop
    add word [calc_win_x], 2
    call redraw_all
    jmp main_loop

buffer_add_char:
    push bx
    xor bx, bx
    mov bl, [calc_buf_ptr]
    mov [cmd_buffer + bx], al 
    inc byte [calc_buf_ptr]
    pop bx
    ret
check_calc_cmd:
    mov si, cmd_buffer
    cmp byte [si], '/'
    jne .fail
    cmp byte [si+1], 'c'
    jne .fail
    cmp byte [si+2], 'a'
    jne .fail
    cmp byte [si+3], 'l'
    jne .fail
    cmp byte [si+4], 'c'
    jne .fail
    mov byte [is_calc_open], 1
    mov byte [active_win], 1
    call draw_calculator_frame
    call redraw_all
.fail:
    ret
newline:
    mov byte [safe_cursor_x], 0
    inc byte [safe_cursor_y]
    cmp byte [safe_cursor_y], 10
    jl .ok
    call clear_notepad_content 
    mov byte [safe_cursor_x], 0
    mov byte [safe_cursor_y], 0
.ok: 
    mov byte [calc_buf_ptr], 0
    ret
input_notepad:
    cmp al, 27   
    je reboot
    cmp al, 13   
    je np_process_enter 
    cmp al, 8    
    je .backspace_single_delete 
    cmp byte [safe_cursor_x], 23 
    jge .auto_newline 
    push ax
    call add_char_to_ram      
    call buffer_add_char      
    pop ax
    call prt_char_notepad 
    inc byte [safe_cursor_x]
    call draw_mouse_cursor
    jmp main_loop
.auto_newline:
    call newline
    push ax
    call add_char_to_ram
    call buffer_add_char
    pop ax
    call prt_char_notepad
    inc byte [safe_cursor_x]
    jmp main_loop
.backspace_single_delete:
    cmp word [buffer_ptr], 0 
    je main_loop
    cmp byte [safe_cursor_x], 0
    je main_loop
    dec word [buffer_ptr] 
    pusha
    mov si, text_buffer
    add si, [buffer_ptr]
    mov byte [si], 0x00 
    popa
    dec byte [safe_cursor_x]
    call clear_notepad_content
    call draw_all_notepad_text
    call draw_mouse_cursor
    cmp byte [calc_buf_ptr], 0
    je main_loop
    dec byte [calc_buf_ptr]
    jmp main_loop

np_process_enter:
    push ax
    mov al, 13
    call add_char_to_ram
    pop ax
    call newline 
    call check_calc_cmd
    mov byte [calc_buf_ptr], 0 
    jmp main_loop
add_char_to_ram:
    pusha
    mov si, text_buffer
    add si, [buffer_ptr]
    mov [si], al 
    inc word [buffer_ptr]
    mov si, text_buffer
    add si, [buffer_ptr] 
    mov byte [si], 0x00
    popa
    ret
reboot:
    int 0x19
