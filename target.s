section	.rodata			; we define (global) read-only variables in .rodata section

section .bss			; we define (global) uninitialized variables in .bss section

section .data			; we define (global) initialized variables in .data section
    next_add:dd 0
    random_help: dd 0
    
section .text
  align 16
    extern resume
    extern CORS
    global target_func
    extern target
    extern seed
    
    
    %macro random_position 3
        mov eax, 0
        mov ebx, 0
        mov bx, [%1]
        mov edx, 16
        %%continue1:
        mov ax, 45 ;2^0+2^2+2^3+2^5
        and ax, bx
        jp %%xor_zero
        shr bx, 1
        add bx, 32768
        dec edx
        cmp edx, 0
        je %%contineu2
        jmp %%continue1
        %%xor_zero:
        shr bx, 1
        dec edx
        cmp edx, 0
        jne %%continue1
        %%contineu2:
        mov dword [seed], ebx
        mov dword [random_help], ebx
        finit
        fild dword [random_help]
        mov dword [random_help], 65535
        fild dword [random_help]
        fdivp
        mov dword [random_help], %2
        fild dword [random_help]
        fmulp
        fstp dword [random_help]
        mov eax, [random_help]
        ffree
        mov ebx, %3
        cmp ebx, 0
        je %%end
        mov ebx, [next_add] ; stores the adrees to the data of the first drone
        mov [ebx], eax ;stores x into the drone array
        add ebx, 4 ; move ebx to point to the next adress
        mov dword [next_add], ebx
        %%end:
    %endmacro

    %macro createTarget 0 ;maybe it should be a macro
        mov ebx, [target]
        mov dword [next_add], ebx ; random position macro uses next_add
        random_position seed, 100, 1
        random_position seed, 100, 1
    %endmacro
    
    
    target_func:
        createTarget
        mov ebx, [CORS] ;the co-rutine of scheduler is the first corutine
        call resume
        jmp target_func ;the return from the call return to the next line
    

        
        
    
        
