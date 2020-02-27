section	.rodata			; we define (global) read-only variables in .rodata section
    format_decimal: db "%d",0 ;format decimal base output
    format_float: db "%.2f",0 ;format decimal base output
    winner_massage: db "Drone id %d: I am a winner",10,0 ; drone winner


section .bss			; we define (global) uninitialized variables in .bss section
    global CORS
    global drones
    global target
    CORS: resd 1
    COi : resd 1
    STKSIZE  equ 16*1024 		;16 Kb
    STKi: resd 1
    drones: resd 1
    target: resd 1



section .data			; we define (global) initialized variables in .data section
    global K
    global N
    global seed
    N:dd 0
    T:dd 0
    K:dd 0
    B:dd 0
    d:dd 0
    seed:dd 0
    position:dd 0
    next_add:dd 0
    random_help: dd 0
    SPT: dd 0 ;saves ESP
    SPMAIN: dd 0
    SPP equ 4; offset of pointer to co-routine stack in co-routine struct 
    CURR: dd 0
    one_eighty:	dd 	180.0
    two_pi:	dd 	360.0
    gamma: dd 0
    diff_y: dd 0
    diff_x: dd 0

section .text
  align 16
     global main
     extern printf
     extern fflush
     extern malloc
     extern calloc
     extern free
     extern sscanf
     extern scheduler_func
     global resume
     extern curr_id
     global mayDestroy
     extern drone_func
     extern print_func
     extern target_func
     extern cant_destroy
     extern resume_target
     
    extern x_loc
	extern y_loc
    extern alpha


;N – number of drones
;T - number of targest needed to destroy in order to win the game
;K – how many drone steps between game board printings
;β – angle of drone field-of-view
;d – maximum distance that allows to destroy a target
;seed - seed for initialization of LFSR shift register

    %macro init_parm 3
        mov edx, [ebp+12]
        mov ecx, %1
        mov eax,[edx+ecx]	; get function argument1 
        push dword %2
        push dword %3
        push eax
        call sscanf
        add esp, 12
        mov eax, 0
    %endmacro

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
    
main:
    push ebp
	mov ebp, esp	
	pushad
	pushfd
    init_parm 4, N, format_decimal
    init_parm 8, T ,format_decimal	
    init_parm 12, K , format_decimal
    init_parm 16, B , format_decimal
    init_parm 20, d , format_decimal
    init_parm 24, seed, format_decimal
    mov eax, [N]
    add eax, 3 ;N+3 co rutines
    mov ebx, 0
    mov ebx, 4 ; size of adress
    mul ebx ; eax<- eax * ebx (N+3)*4
    mov dword [position], eax 
    push eax       ; size of memory (N+3)*4
    call malloc		; allocate 5 bytes in memory, adrees goes to eax
    add esp, 4                     ;remove pushed arguments
    mov dword [CORS], eax 
    
    init_target:
        push 8       ; size of 8 bytes, to store X and Y
        call malloc		; allocate 5 bytes in memory, adrees goes to eax
        add esp, 4                     ;remove pushed arguments 
        mov dword [target], eax ;eax stores the address to the allocated memory
        createTarget
        

    
    
    CORis:
    mov eax, [position] ;ebx stores (N+3)*4
    mov ebx, 2
    mul ebx     ;(N+3)*4*2
    mov dword [position], eax
    push eax
    call malloc
    add esp, 4                     ;remove pushed arguments
    mov dword [COi], eax 
    
    STKis:
    mov eax, [position] ;ebx stores (N+3)*4*2
    mov ebx, 2048
    mul ebx ;(N+3)*4*2*2*1024
    mov dword [position], eax
    push eax
    call malloc
    add esp, 4                     ;remove pushed arguments
    mov dword [STKi], eax 
    
    
    label_init_cors:
    mov ebx, 0
    mov eax, 0
    mov ecx, [N]
    add ecx, 3
    mov ebx, [CORS]
    mov eax, [COi]
    init_cors:
        mov [ebx], eax
        add eax, 8
        add ebx, 4
        loop init_cors, ecx
    mov ebx, 0
    mov eax, 0
    mov ebx, [COi]
    mov eax, [STKi]
    mov ecx, [N]
    add ecx, 3
    init_Cois:
        mov dword [ebx], drone_func
        add ebx, 4
        mov [ebx], eax
        add eax, STKSIZE
        add ebx, 4
        loop init_Cois, ecx
    mov ebx, [COi]
    mov dword [ebx], scheduler_func
    add ebx, 8
    mov dword [ebx], print_func
    add ebx, 8
    mov dword [ebx], target_func
    drone_init:
        mov ebx, [N]
        mov eax, 16
        mul ebx
        push eax
        call malloc
        add esp, 4                     ;remove pushed arguments
        mov dword [drones], eax
    mov ecx, [N]
    mov ebx, [drones]
    mov dword [next_add], ebx
    init_drones_data:
        random_position seed, 100, 1
        random_position seed, 100, 1
        random_position seed, 360, 1
        mov ebx, [next_add] ; stores the adrees to the data of the first drone
         check1:
        mov dword [ebx], 0 ;stores x into the drone array
        add ebx, 4 ; move ebx to point to the next adress
        mov dword [next_add], ebx
        dec ecx
        cmp ecx, 0
        jne init_drones_data
    
    
    initCo: ;initialize the stack of every co-rutine
        mov ebx, [CORS] ;stores the adress of the first coi
        mov dword [SPT], esp ; saves the current stack pointer
        mov ecx, [N]
        add ecx, 3
        contineu3:
            mov eax, [ebx] ; stores the adress of the function of coi
            mov edx, [eax]
            add eax, 4
            mov esp, [eax] ; esp now points to the stack of the coi
            add esp, STKSIZE
            sub eax, 4
            push edx
            pushfd
            pushad
            add eax, 4
            mov [eax], esp ;save new SPi value (after all the pushes)
            add ebx, 4
            loop contineu3, ecx
        mov esp, [SPT] ;restore esp value
        
        startCo:
            pushad ;saves registers of main()
            mov [SPMAIN], esp
            mov ebx, [CORS] ;the scheduler is the first co rutine in the struct,  gets a pointer to a scheduler struct
            jmp do_resume; resume a scheduler co-routine
            
        endCo:
            mov esp, [SPMAIN]              ; restore ESP of main()
            popad; restore registers of main()

            
        
    resume:; save state of current co-routine
        pushfd
        pushad
        mov edx, [CURR] ; CURR points to the struct of the current co-routine
        mov [edx+SPP], ESP   ; save current ESP
    
    do_resume: ; load ESP for resumed co-routine
        mov eax, [ebx] ;eax now points to the cois struct (2000)
        add eax, 4 ;eax points to the spi (2004) 
        mov esp, [eax] ;esp now points to the stk struct
        sub eax, 4 ;eax now points to the cois struct (2000)
        mov [CURR], eax ;CURR points to the struct of the current co-routine
        popad  ; restore resumed co-routine state
        popfd
        ret        ; "return" to resumed co-routine
            

    
            
        mayDestroy:
            finit
            mov ebx, [target]
            mov eax, [ebx] ;eax stores x2
            add ebx, 4
            mov edx, [ebx] ;edx stores y2
            mov dword [random_help], edx
            fld dword [random_help] ;load y2
            fld dword [y_loc] ;load y1
            fsubp ;y2-y1
            fst dword [diff_y]
            mov dword [random_help], eax
            fld dword [random_help] ;load x2
            fld dword [x_loc] ;x1
            fsubp ;x2-x1
            fst dword [diff_x]
            fpatan ;arctan2 the score is in st(0)? = gamma
            fld dword [one_eighty]
            fmulp
            fldpi
            fdivp
            fst dword [gamma] ;store gamma
            fld dword [alpha] ; load alpha 
            ;adjust the angle
            fsubrp ; alpha-gamma
            ;convert gamma to radians
            fldpi                   
            fmulp                  ; multiply by pi
            fld	dword [one_eighty]
            fdivp	      ; and divide by 180.0
            fldpi   ;load pi
            fcomi 
            jb add_to_smaller_angle; pi<alpha-gamma
            contineu4:
            ffree
            finit
            fld dword [alpha]
            fld dword [gamma]
            fsubp ; alpha- gamma
            fabs ;abs(alpha-gamma)
            fild dword [B] ;load beta
            fcomi 
            jb cant_destroy ;beta < abs(alpha-gamma)
            fld dword [diff_y]
            fld dword [diff_y]
            fmulp ;(y2-y1)^2
            fld dword [diff_x]
            fld dword [diff_x]
            fmulp ;(x2-x1)^2
            faddp ;(y2-y1)^2+(x2-x1)^2
            fsqrt ;sqrt((y2-y1)^2+(x2-x1)^2)
            fild dword [d] ;load d
            fcomi 
            jb cant_destroy ;d<sqrt((y2-y1)^2+(x2-x1)^2)
            ;can destroy!
            mov ebx, [curr_id] 
            sub ebx, 3 ;now ebx is the curr id of the drone, we init the first id to 3 instead 1
            mov eax, 16
            mul ebx 
            add eax, 12 ;now points to the score
            mov ebx, [drones]
            add ebx, eax
            mov edx, [ebx] ;edx stores the score
            inc edx ;increase the score of the drone by one 
            mov [ebx], edx ;update the score
            cmp edx, [T]
            jb resume_target  ;score < T
            ;the drone is the winner
            mov ebx, [curr_id] 
            sub ebx, 2 ;now ebx is the curr id of the drone, we init the first id to 3 instead 1
            push ebx ; push id
            push winner_massage
            call printf
            add esp, 8
            ;exit
            jmp free_and_exit
            
            
            
            
            free_and_exit:
                push dword [STKi]
                call free
                add esp, 4
                push dword [COi]
                call free
                add esp, 4
                push dword [drones]
                call free
                add esp, 4
                push dword [CORS]
                call free
                add esp, 4            
                push dword [target]
                call free
                add esp, 4    
                
                exit:
                mov eax, 1
                mov ebx, 0
                int 0x80
            
            
            
            add_to_smaller_angle:
                ffree
                finit
                fld dword [alpha]
                fld dword [gamma]
                fcomi 
                jb add_gamma ;gamma<alpha
                ffree
                finit
                fld dword [alpha]
                fld dword [two_pi] ;load 360.0
                faddp ;360 +alpha
                fstp dword [alpha]
                jmp contineu4
                
            add_gamma:
                ffree
                finit
                fld dword [gamma]
                fld dword [two_pi] ;load 360.0
                faddp ;360 +gamma
                fstp dword [gamma]
                jmp contineu4
            
            
	
    
    
    
    
    
