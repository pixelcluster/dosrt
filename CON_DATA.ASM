segment con_strings

CON_STDOUT equ 1
CON_STDERR equ 2

s_Init db 'Initializing console display.', 13, 10
s_Init_len equ 31

s_Output1 db 'Putting pixel at location ('
s_Output1_len equ 27

s_Output2 db ', '
s_Output2_len equ 2

s_Output3 db '), color = ('
s_Output3_len equ 12

s_Output4 db ')', 13, 10
s_Output4_len equ 3

s_Finish db 'Shutting down.'
s_Finish_len equ 14

CON_INTEGER_PRINT_BUF rb 5
