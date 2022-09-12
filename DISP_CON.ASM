; console display

disp_init:
    push ax
    push bx
    push cx
    push dx
    push ds
    mov ah, 40h
    mov bx, CON_STDOUT
    mov cx, s_Init_len
    mov dx, con_strings
    mov ds, dx
    lea dx, [s_Init]
    int 21h
    pop ds
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Writes a string representation of ax to the temporary buffer.
; Parameters:
;   ax: Number to convert
; Returns:
;   Nothing
disp_con_int_to_str:
    push si
    push dx
    push cx
    push bx
    push ax
    mov bx, 5
    xor cx, cx
    disp_con_int_convert_loop:
    push ax
    ; store pow(10, cur_digit_index) in bx
    mov si, bx
    dec si
    push bx
    push ax
    mov bx, 10
    mov ax, 1
    ; Special case: pow(10, 0) is 1
    cmp si, 0
    je disp_con_convert_int_pow_merge
    
    disp_con_convert_int_pow:
    mul bx
    dec si
    cmp si, 0
    jne disp_con_convert_int_pow
    disp_con_convert_int_pow_merge:
    mov bx, ax
    pop ax
    ; remove already processed digits
    sub ax, cx
    ; "shift" current digit into first place
    div bx
    ; Temporarily re-multiply; this is the equivalent of masking
    ; away all other digits
    mul bx
    add cx, ax
    div bx

    pop bx
    ; convert single digit to ascii
    add ax, 48
    mov si, 4
    sub si, bx
    mov [si+CON_INTEGER_PRINT_BUF], al

    dec bx
    pop ax
    cmp bx, 0
    jne disp_con_int_convert_loop 

    pop ax
    pop bx
    pop cx
    pop dx
    pop si
    ret

disp_put:
    push bp
    push ds
    push dx
    push cx
    push bx
    push ax
    mov bp, sp
    mov bx, con_strings
    mov ds, bx    
    
    call disp_con_int_to_str
    
    xor al, al    
    mov ah, 40h
    mov bx, CON_STDOUT
    mov cx, s_Output1_len
    lea dx, [s_Output1]            
    int 21h
    
    xor al, al    
    mov ah, 40h
    mov cx, 5
    lea dx, [CON_INTEGER_PRINT_BUF]
    int 21h
    
    xor al, al    
    mov ah, 40h
    mov cx, s_Output2_len
    lea dx, [s_Output2]
    int 21h
    
    ; bx in parameter list
    ; screen y
    mov ax, [bp+2]
    call disp_con_int_to_str
    
    xor al, al
    mov ah, 40h
    mov cx, 5
    lea dx, [CON_INTEGER_PRINT_BUF]
    int 21h    
    
    xor al, al    
    mov ah, 40h
    mov cx, s_Output3_len
    lea dx, [s_Output3]
    int 21h
    
    xor ah, ah
    ; load cl parameter from stack
    mov al, [bp+4]
    call disp_con_int_to_str
    
    xor al, al
    mov ah, 40h
    mov cx, 5
    lea dx, [CON_INTEGER_PRINT_BUF]
    int 21h
    
    xor al, al    
    mov ah, 40h
    mov cx, s_Output2_len
    lea dx, [s_Output2]
    int 21h
    
    xor ah, ah
    ; load ch parameter from stack
    mov al, [bp+5]
    call disp_con_int_to_str
    
    xor al, al
    mov ah, 40h
    mov cx, 5
    lea dx, [CON_INTEGER_PRINT_BUF]
    int 21h
    
    xor al, al    
    mov ah, 40h
    mov cx, s_Output2_len
    lea dx, [s_Output2]
    int 21h
    
    xor ah, ah
    ; load dl parameter from stack
    mov al, [bp+6]
    call disp_con_int_to_str
    
    xor al, al
    mov ah, 40h
    mov cx, 5
    lea dx, [CON_INTEGER_PRINT_BUF]
    int 21h
    
    xor al, al    
    mov ah, 40h
    mov cx, s_Output4_len
    lea dx, [s_Output4]
    int 21h
    
    pop ax
    pop bx
    pop cx
    pop dx
    pop ds    
    pop bp
    ret

disp_size:
    mov ax, 10
    mov bx, 10
    ret

disp_finish:
    push ax
    push bx
    push cx
    push dx
    push ds
    mov ah, 40h
    mov bx, CON_STDOUT
    mov cx, s_Finish_len
    mov dx, con_strings
    mov ds, dx
    lea dx, [s_Finish]
    int 21h
    pop ds
    pop dx
    pop cx
    pop bx
    pop ax
    ret
