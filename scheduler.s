section	.rodata			; we define (global) read-only variables in .rodata section
    format_decimal: db "%d",0 ;format decimal base output


section .bss			; we define (global) uninitialized variables in .bss section


section .data			; we define (global) initialized variables in .data section
    global curr_id
    curr_id: dd 0
    K_counter: dd 0



section .text
  align 16
     extern main
     extern printf
     extern resume
     global scheduler_func
     extern K
     extern N
     extern CORS
     
     
scheduler_func:
    mov ecx, 3
    mov eax, 0
    while:
    mov edx, 0
        mov eax, ecx
        mov dword [curr_id], eax
        mov ebx, 4
        mul ebx
        mov ebx, [CORS]
        add ebx, eax
        call resume 
        break:
        inc ecx
        inc dword [K_counter]
        mov edx, [K_counter]
        cmp edx, [K]
        jne co1
        mov ebx, [CORS] ;the co-rutine of print is the second corutine
        add ebx, 4
        call resume
        mov dword [K_counter], 0
        co1:
        mov edx, [N]
        add edx, 3
        cmp ecx, edx
        jne co2
        mov ecx,3
        co2:
        jmp while
        
