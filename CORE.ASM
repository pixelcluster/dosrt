; Core raytracer part, handles key input
; and defines API the rest of modules will work with

segment .text
    ;entrypoint
    jmp _start

    %include "MODULES.DEF"     

    ; General calling convention:
    ; Non-return registers should not be clobbered.
    ; Parameter layout is defined for each function.
    
    ; display functions
    
    ; disp_init: Initialize display
    ; Parameters:
    ;   In es: display data segment
    ; Returns: nothing

    ; disp_size: Returns display size
    ; Parameters:
    ;   In es: display data segment
    ; Returns:
    ;   In ax: Width of display in pixels
    ;   In bx: Height of display in pixels

    ; disp_put: Writes a pixel value
    ; Parameters:
    ;   In es: display data segment
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
    ; Parameters:
    ;   In es: display data segment
    ; Returns: nothing

    ; Segment assignment (may change)
    CORE_SEG    equ 0
    DISPLAY_SEG equ 1    

    CORE_COLOR_COMPONENT_R equ 0
    CORE_COLOR_COMPONENT_G equ 1
    CORE_COLOR_COMPONENT_B equ 2

    ; core_step_init: Initialize pattern step values    
    ; Parameters:
    ;   In bp: Offset of the screen size in the stack segment
    ;   In bx: Offset of the desired placement of the step value
    ; Returns: Nothing, but stores the step in [ss:bx]
    core_step_init:
        fldz
        fild dword [ss:bp]
        fdivp
        fstp dword [ss:bx]
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
        pop ax
        pop bp
        ret
        

    global _start
    _start:
        mov ax, DISPLAY_SEG
        mov es, ax
        call disp_init

        finit

        start_draw_init:
        call disp_size
        ; store ax, bx (screen size) on stack
        push ax
        push bx
        mov bp, sp
        add bp, 2

        sub sp, 16 ; allocate step and color floats
        mov bx, sp
        add bx, 12 ; 8 bytes for the two color floats,
                   ; 4 bytes for one step float =
                   ; [ss:bx] points at the first step float
    
        call core_step_init        
        sub bp, 2
        sub bx, 4
        call core_step_init
        sub bp, 2
        sub bx, 8

        ; Initialize color float storage to 0
        mov cx, 0
        start_loop_color_init:
        cmp cx, 2
        je start_loop_color_init_done
        mov word [ss:bx], 0
        add bx, 2
        mov word [ss:bx], 0
        add bx, 2
        inc cx
        start_loop_color_init_done:
        
        ; bx now points to the first byte after the color
        ; floats, while bp points to the first byte after the
        ; step floats. bx = bp - 8

        ; Initialize pixel counters
        mov ax, 0
        push ax
        push ax
        
        ; Just show a simple test pattern for now
        start_draw:

        ; get key input (ASCII)
        mov ax, 0x800
        int 21h
        cmp al, 0x78 ; x
        je start_exit

        mov bx, bp
        sub bx, 12 ; 8 bytes (see above) + 4 bytes: bp points
                   ; at first color float
        sub bp, 4
        call core_color_add
        mov cx, ax
        
        sub bx, 4
        sub bp, 4
        call core_color_add
        ; Restore pointer position from before loop   
        add bp, 8
        ; Do not restore bx, it is recalculated at the top of the loop
        ; and used for other purposes here
        mov bx, sp ; bx points to current pixel indices
        
        mov cl, 255 ; r component
        mov ch, al ; g component
        mov dl, 0 ; b component
        
        add bx, 2 ; bx points to horizontal pixel index
        mov ax, word [ss:bx]
        sub bx, 2
        mov bx, word [ss:bx]
        call disp_put
        
        ; The screen dimensions are located right above the step floats
        ; on stack (+ 8 bytes). Adding two bytes skips the height dimension
        ; and makes bx point to the width.
        mov bx, bp
        add bx, 10
        mov bx, [ss:bx] ; bx now contains the width instead of its pointer
        
        pop cx ; pop width in cx for now
        pop ax ; pop height
        
        inc ax
        cmp ax, bx
        je start_draw_width_overflow
        jmp start_draw

        start_draw_width_overflow:
        mov ax, 0

        ; Load height similarly as width
        mov bx, bp
        add bx, 8
        mov bx, [ss:bx]
        inc cx
        cmp cx, bx
        jne start_draw
        mov cx, 0 ; start over
        jmp start_draw
        
        start_exit:
        call disp_finish
       
        mov ax, 0x4C00
        int 21h        
