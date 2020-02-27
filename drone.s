section	.rodata			; we define (global) read-only variables in .rodata section

section .bss			; we define (global) uninitialized variables in .bss section

section .data			; we define (global) initialized variables in .data section

    global x_loc
	global y_loc
    global alpha
    next_add:dd 0
    random_help: dd 0
    delta_alfa: dd 0
    delta_d:dd 0
    alpha:dd 0
    one_eighty:	dd 	180.0
    one_hundred:dd 	100.0
    zero:dd 	0.0
    two_pi:	dd 	360.0
    ninety:	dd	90.0
    x_loc: dd 0
	y_loc: dd 0
    
    
section .text
  align 16
    extern resume
    extern CORS
    global target_func
    global cant_destroy
    global resume_target
    extern seed
    extern curr_id
    extern mayDestroy
    extern drones
    global drone_func
 
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
    
        %macro adjust_position 1
        finit 
        fld dword [%1]
        fld dword [one_hundred]
        fcomi
        jae %%co3
        fsubp 
        fstp dword [%1]
        jmp %%co4
        %%co3:
        fstp dword [one_hundred]
        fld dword [zero]
        fcomi
        jbe %%co4
        fstp dword [zero]
        fld dword [one_hundred]
        faddp
        fstp dword [%1]
        %%co4:
    %endmacro

   drone_func:
        random_position seed, 120, 0
        ffree
        finit
        fld dword [random_help]
        mov dword [random_help], 60
        fild dword [random_help]
        fsubp
        fstp dword [delta_alfa]
        ffree
        random_position seed, 50, 0
        mov dword [delta_d], eax
        mov ebx, [curr_id] 
        sub ebx, 3 ;now edx is the curr id of the drone, we init the first id to 3 instead 1
        mov eax, 16
        mul ebx 
        add eax, 8
        check_360:
        ; after the 3 rows above eax is the index of the needed alfa (drones+eax points to the needed alfa)
        mov edx, [delta_alfa]
        mov ebx, [drones]
        add ebx, eax 
        mov ecx, [ebx] ;stores alfa
        mov dword [random_help], ecx ;random_help stores alfa
        finit
        fld dword [delta_alfa]
        fld dword [random_help]
        faddp
        fst dword [random_help]
        fld dword [two_pi]
        fcomi
        jb sub_360
        fstp dword [random_help] ;random_help=360
        fst dword [random_help]
        fld dword [zero]
        fcomi
        ja add_360
        fstp dword [random_help] ;random_help=0
        cont2:
        mov ebx, [drones]
        add ebx, eax 
        fstp dword [random_help] ;random_help=delta_alfa+alfa
        mov edx, [random_help]
        mov [ebx], edx ;put the new alfa
        mov dword [alpha], edx ; to store the new alpha
        ;mov drones position (x,y)
        ffree
        finit
        fld dword [alpha] ;load alfa into the float stack
	    fldpi                    ; Convert heading into radians
	    fmulp                  ; multiply by pi
        fld	dword [one_eighty]
        fdivp	      ; and divide by 180.0
        sub eax, 4 ;because eax points to alfa and we want y
        mov edx, [drones]
        add edx, eax
        mov ecx, [edx] ;ecx=value of y
        mov dword [y_loc], ecx ;init y_loc
        sub eax, 4 ;because eax points to y and we want x
        mov edx, [drones]
        add edx, eax
        mov ecx, [edx] ;ecx=value of x 
        mov dword [x_loc], ecx ;init x_loc
	    fsincos      ; Compute vectors in y and x 
        fld	dword [delta_d]
        fmulp;        ; Multiply by distance to get dx
        fld	dword [x_loc]
        faddp			    
        fstp	dword [x_loc]
        fld	dword [delta_d]
        fmulp        ; Multiply by distance to get dy 	
        fld	dword [y_loc]
        faddp
        fstp	dword [y_loc]
        ffree
        mov edx, [drones]
        add edx, eax
        adjust_position x_loc ;check legal x
        mov ecx, 0
        mov dword ecx, [x_loc]
        mov [edx], ecx ;puts the new x in the drones array
        add eax, 4
        mov edx, [drones]
        add edx, eax
        adjust_position y_loc ;check legal y 
        mov ecx, 0
        mov dword ecx, [y_loc]
        
        mov [edx], ecx ;puts the new y in the drones array
        add eax, 4 ;eax points to the alfa again        
        ;mayDestroy - gamma = arctan2(y2-y1, x2-x1) 
                     ;(abs(alpha-gamma) < beta) and sqrt((y2-y1)^2+(x2-x1)^2) < d
        jmp mayDestroy
        cant_destroy: ;if no - resume scheduler co -rutine
            mov ebx, [CORS] ;the co-rutine of scheduler is the first corutine
            call resume
            jmp drone_func ;the return from the call return to the next line
        resume_target:
            mov ebx, [CORS] ;the co-rutine of scheduler is the third corutine
            add ebx, 8
            call resume
            jmp drone_func ;the return from the call return to the next line
            
            
            
        
                	
        add_360:
        ffree
        finit
        fld dword [random_help]
        fld dword [two_pi]
        faddp
        jmp cont2
        
	
        sub_360:
        ffree
        finit
        fld dword [random_help]
        fld dword [two_pi]
        fsubp
        jmp cont2
        


    
    
    
    
