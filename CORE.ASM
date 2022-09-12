; Core raytracer part, handles key input
; and defines API the rest of modules will work with
format MZ
entry code:_start
include 'DATA.DEF'

segment core_data
CORE_KEYB_SCANCODE_TO_ASCII db \
  0,   0,  49,  50,  51,  52,  53,  54, \
 55,  56,  57,  48,  45,  61,   0,   9, \
113, 119, 101, 114, 116, 121, 117, 105, \
111, 112,  91,  93,   0,   0,  97, 115, \
100, 102, 103, 104, 106, 107, 108,  59, \
 27,   0,   0,  92, 122, 120,  99, 118, \
 89, 110, 109,  44,  46,  47,   0,   0, \
  0,  32,   0,   0,   0,   0,   0,   0, \
  0,   0,   0,   0,   0,   0,   0,   0, \
  0,   0,   0,   0,   0,   0,   0,   0, \
  0,   0,   0,   0,   0,   0,   0,   0, \
  0,   0,   0,   0,   0,   0,   0,   0, \
  0,   0,   0,   0,   0,   0,   0,   0, \
  0,   0,   0,   0,   0,   0,   0,   0, \
  0,   0,   0,   0,   0,   0,   0,   0, \
  0,   0,   0,   0,   0,   0,   0,   0
CORE_KEYB_BUFFER rb 256
CORE_KEYB_READ rb 1
CORE_KEYB_WRITE rb 1
CORE_KEYB_ISR_RESTORE rb 4

segment code
    include 'MODULES.DEF'     

    ; keyboard interrupt handler
    core_keyb_irq:
        push ax
        push bx
        push ds
        ; setup registers and segment
        mov ax, core_data
        mov ds, ax
        xor ah, ah
        xor bh, bh
        ; translate scancode to ascii
        in al, 0x60
        mov bl, al
        mov al, [bx+CORE_KEYB_SCANCODE_TO_ASCII]
        ; write ascii
        mov bl, [CORE_KEYB_WRITE]
        mov [bx+CORE_KEYB_BUFFER], al
        ; increment write pointer
        inc bl
        mov [CORE_KEYB_WRITE], bl

        mov al, 0x20
        out 0x20, al        
        
        pop ds
        pop bx
        pop ax
        iret

    ; General calling convention:
    ; Non-return registers should not be clobbered.
    ; Parameter layout is defined for each function.
    
    ; display functions
    
    ; disp_init: Initialize display
    ; Parameters: None
    ; Returns: nothing

    ; disp_size: Returns display size
    ; Parameters: None
    ; Returns:
    ;   In ax: Width of display in pixels
    ;   In bx: Height of display in pixels

    ; disp_put: Writes a pixel value
    ; Parameters:
    ;   In ax: x coordinate of the pixel
    ;   In bx: y coordinate of the pixel
    ;   In cl: r component of the color (8 bit)
    ;   In ch: g component of the color (8 bit)
    ;   In dl: r component of the color (8 bit)
    ; Returns: nothing
    ;
    ; The color probably will not be represented
    ; exactly. Mode 13h can't display every RGB color by
    ; a long shot.

    ; disp_finish: Uninitialize display
    ; Parameters: None
    ; Returns: nothing

    
    CORE_COLOR_COMPONENT_R equ 0
    CORE_COLOR_COMPONENT_G equ 1
    CORE_COLOR_COMPONENT_B equ 2

    label CORE_L_SCRWIDTH at bp-2
    label CORE_L_SCRHEIGHT at bp-4
    label CORE_L_COLOR_G at bp-8
    label CORE_L_COLOR_R at bp-12
    label CORE_L_STEP_G at bp-16
    label CORE_L_STEP_R at bp-20
    label CORE_L_POSX at bp-22
    label CORE_L_POSY at bp-24

    ; core_step_init: Initialize pattern step values    
    ; Parameters:
    ;   In bx: Screen dimension
    ;   In bp: Offset of the desired placement of the step value
    ; Returns: Nothing, but stores the step in [bp]
    core_step_init:
        push bx
        mov bx, sp
        fld1
        fidiv word [ss:bx]
        fstp dword [bp]
        pop bx
        ret

    ; core_color_add: Adds the step value to the color and stores it.
    ; Parameters:
    ;   In bp: Offset of the step value in the stack segment.
    ;   In bx: Offset of the color value in the stack segment.
    ; Returns:
    ;   In ax: Integer color value
    core_color_add:
        fld dword [ss:bx]
        fld dword [ss:bp]
        faddp
        fst dword [ss:bx]
        
        ; Determine color
        push bp
        ; Store 255.0 (0x437f0000)
        mov ax, 0
        push ax
        mov ax, 0x437f
        push ax
        mov bp, sp
        fld dword [ss:bp]
        ; Multiply and store the result
        fmulp
        add bp, 2
        mov bp, sp
        fistp word [ss:bp]
        pop bp ; extra byte, want to discard
        pop ax
        pop bp
        ret
        

    _start:
        mov ax, core_data
        mov ds, ax        

        mov ah, 35h
        mov al, 9
        int 21h

        mov word [CORE_KEYB_ISR_RESTORE+2], bx
        mov word [CORE_KEYB_ISR_RESTORE], es        

        mov ax, code
        mov ds, ax
        mov al, 9
        mov ah, 25h
        mov dx, core_keyb_irq
        int 21h

        mov ax, core_data
        mov ds, ax
        call disp_init
        
        finit

        start_draw_init:

        mov bp, sp        
        sub sp, 24 ; allocate local vars    
        ; Stack variables:
        ; bp-2: screen width
        ; bp-4: screen height
        ; bp-8: current color G
        ; bp-12: current color R
        ; bp-16: color step Y/G
        ; bp-20: color step X/R
        ; bp-22: pixel counter X
        ; bp-24: pixel counter Y

        call disp_size
        mov word [CORE_L_SCRWIDTH], ax
        mov word [CORE_L_SCRHEIGHT], bx
        
        push bp
        sub bp, 16
        call core_step_init
        sub bp, 4
        mov bx, ax
        call core_step_init
        pop bp
        ; Initialize color float storage to 0
        mov word [bp-6], 0
        mov word [bp-8], 0
        mov word [bp-10], 0
        mov word [bp-12], 0
        
        ; Initialize pixel counters
        mov word [CORE_L_POSX], 0
        mov word [CORE_L_POSY], 0
        
        ; Just show a simple test pattern for now
        start_draw:

        ; get key input (ASCII)
        xor bh, bh
        mov al, [CORE_KEYB_WRITE]
        mov bl, [CORE_KEYB_READ]
        start_key_loop:
        ; have we processed all keys?
        cmp al, bl
        je start_key_end

        mov cl, [bx+CORE_KEYB_BUFFER]
        
        cmp cl, 0x78 ; x
        je start_exit
        
        inc bl
        jmp start_key_loop
        
        start_key_end:
        push bp
        mov bx, bp
        sub bx, 8
        sub bp, 16
        call core_color_add
        mov cx, ax
        
        sub bx, 4
        sub bp, 4
        call core_color_add
        pop bp
        
        mov cl, 255;cl ; r component
        mov ch, al ; g component
        mov dl, 0 ; b component
        
        mov ax, word [CORE_L_POSX]
        mov bx, word [CORE_L_POSY]
        call disp_put
        inc ax
        
        mov cx, word [CORE_L_SCRWIDTH]
        cmp ax, cx
        je start_draw_width_overflow
        jmp start_draw_pos_update

        start_draw_width_overflow:
        mov ax, 0

        ; Load height similarly as width
        mov dx, word [CORE_L_SCRHEIGHT]
        inc bx
        cmp bx, dx
        jne start_draw_pos_update
        mov dx, 0 ; start over
        start_draw_pos_update:
        mov word [CORE_L_POSX], ax
        mov word [CORE_L_POSY], bx
        jmp start_draw
        
        start_exit:
        call disp_finish

        mov dx, word [CORE_KEYB_ISR_RESTORE+2]
        mov ax, word [CORE_KEYB_ISR_RESTORE]
        mov ds, ax
        mov al, 9
        mov ah, 25h
        int 21h
       
        mov ax, 0x4C00
        int 21h        

    
