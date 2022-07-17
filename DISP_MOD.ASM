%include "MODE13.DEF"
MODE13_SHIFT_R equ MODE13_BITS_G + MODE13_BITS_B
MODE13_SHIFT_G equ MODE13_BITS_B
; adjustment factor for palette values - has to be shifted by this so
; the max value corresponds to the max color
MODE13_ADJUST_R equ 6 - MODE13_BITS_R
MODE13_ADJUST_G equ 6 - MODE13_BITS_G
MODE13_ADJUST_B equ 6 - MODE13_BITS_B
; adjustment factor for color values supplied by app
MODE13_COLORADJUST_R equ 8 - MODE13_BITS_R
MODE13_COLORADJUST_G equ 8 - MODE13_BITS_G
MODE13_COLORADJUST_B equ 8 - MODE13_BITS_B

section .text

    disp_init:
        push ax
        push cx
        push dx
        mov ax, 0x13
        int 10h

        mov dx, 0x3C6
        mov al, 0xFF
        out dx, al
        mov dx, 0x3C8
        mov ax, 0
        out dx, al
        mov dx, 0x3C9
        mov cx, 0
        disp_init_palette_loop:
        ; r component
        mov al, cl
        shr al, MODE13_SHIFT_R
        and al, MODE13_MASK_R
        shl al, MODE13_ADJUST_R
        mov al, cl
        out dx, al
        ; g component
        mov al, cl
        shr al, MODE13_SHIFT_G
        and al, MODE13_MASK_G
        shl al, MODE13_ADJUST_G
        out dx, al        
        ; b component
        mov al, cl
        and al, MODE13_MASK_B
        shl al, MODE13_ADJUST_B
        out dx, al
        
        inc cl
        cmp cl, 0
        je disp_init_palette_done
        jmp disp_init_palette_loop

        disp_init_palette_done:
        pop dx
        pop cx
        pop ax
        ret

    disp_size:
        mov ax, 320
        mov bx, 200
        ret

    disp_put:
        push ax
        push bx
        push cx
        push es
        ; build pixel index: idx = width * y + x
        mov cx, ax
        mov ax, bx
        mov bx, 320
        mul bx
        mov bx, ax
        mov ax, 0xA000
        mov es, ax
        mov cx, 0

        ; build palette index out of integer components
        ; r component
        mov al, byte [ss:bp]        
        shr al, MODE13_COLORADJUST_R
        shl al, MODE13_SHIFT_R
        mov cl, al
        ; g component
        add bp, 1
        mov al, byte [ss:bp]
        shr al, MODE13_COLORADJUST_G
        shl al, MODE13_SHIFT_G
        or cl, al
        ; b component
        add bp, 1
        mov al, byte [ss:bp]
        shr al, MODE13_COLORADJUST_B
        or cl, al
        sub bp, 1
        mov byte [es:bx], cl

        pop es
        pop cx
        pop bx
        pop ax
        ret 

    disp_finish:
        mov ax, 3
        int 10h
        ret        