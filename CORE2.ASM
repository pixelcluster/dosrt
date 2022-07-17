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
       
        ; Initialize pixel counters
        mov ax, 0
        push ax
        push ax
        
        ; Just show a simple test pattern for now
        start_draw:

        mov bx, sp
       
        mov cl, 127 ; r component
        mov ch, 127 ; g component
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
        add bx, 2
        mov bx, [ss:bx] ; bx now contains the screen width

        ; get key input (ASCII)
        mov ax, 0x800
        int 21h
        cmp al, 0x78 ; x
        je start_exit


        pop cx ; pop x in cx for now
        pop ax ; pop y

        inc ax
        cmp ax, bx
        je start_draw_width_overflow
        push ax
        push cx
        jmp start_draw

        start_draw_width_overflow:
        mov ax, 0

        ; Load height similarly as width
        mov bx, bp
        mov bx, [ss:bx]
        inc cx
        cmp cx, bx
        push ax
        push cx
        jne start_draw
        pop cx
        pop ax        
        mov cx, 0 ; start over
        push ax
        push cx

        jmp start_draw
        
        start_exit:
        call disp_finish
       
        mov ax, 0x4C00
        int 21h        
