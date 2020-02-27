section	.rodata		
    format_target: db "%.2f, %.2f", 10, 0
    format_print: db "%d, %.2f, %.2f, %.2f, %d", 10, 0

section .bss			; we define (global) uninitialized variables in .bss section
    

section .data			; we define (global) initialized variables in .data section
    x_loc: dd 0
	y_loc: dd 0
    random_help: dd 0
    alpha: dd 0
    save_ecx: dd 0

section .text
    align 16
    global print_func
    extern target
    extern printf
    extern resume
    extern drones
    extern N
    extern CORS



    print_func:
        mov ebx, [target]
        add ebx, 4
        mov eax, [ebx]
        sub esp, 8
        mov dword [y_loc], eax
        finit
        fld dword [y_loc]
        fstp qword [esp]
        ffree
        sub esp, 8
        mov ebx, [target]
        mov eax, [ebx]
        mov dword [x_loc], eax
        finit
        fld dword [x_loc]
        fstp qword [esp]
        ffree
        push format_target
        call printf
        add esp, 20
        mov ecx, 0
        mov edx, 12
        print_drones:
            mov dword [random_help], edx
            ;T:
            mov ebx, [drones]
            add ebx, edx
            mov eax, [ebx]
            push eax
            sub esp,8
            ;alpha:
            sub edx, 4
            mov ebx, [drones]
            add ebx, edx
            mov eax, [ebx]
            mov dword [alpha], eax
            finit
            fld dword [alpha]
            fstp qword [esp]
            ffree
            ;y:
            sub esp, 8
            sub edx, 4
            mov ebx, [drones]
            add ebx, edx
            mov eax, [ebx]
            mov dword [y_loc], eax
            finit
            fld dword [y_loc]
            fstp qword [esp]
            ffree
            ;x
            sub esp, 8
            sub edx, 4
            mov ebx, [drones]
            add ebx, edx
            mov eax, [ebx]
            mov dword [x_loc], eax
            finit
            fld dword [x_loc]
            fstp qword [esp]
            ffree
            ;index
             
            inc ecx
            mov dword [save_ecx], ecx
            push ecx 
            push format_print
            call printf
            add esp, 36
            mov edx, [random_help]
            add edx, 16
            mov ecx, [save_ecx]
            cmp ecx, [N] 
            jne print_drones
        mov ebx, [CORS] ;the co-rutine of scheduler is the first corutine
        call resume
        jmp print_func ;the return from the call return to the next line
    
    
