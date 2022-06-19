; void filter(void *img, int width, int height, unsigned char *mtx)

    section .text
    global filter

filter:
; prologue
    push    ebp         ; save callers frame pointer
    mov     ebp, esp    ; save local frame pointer

    push    ebx
    push    esi
    push    edi

; program
    ; [ebp+8] void *img
    ; [ebp+12] width
    ; [ebp+16] height
    ; [ebp+20] char *mtx
    ; [ebp-16] variable storing copy of a pixel

    ; EAX   - temporary register
    ; ECX   - temporary register
    ; EDX   
    ; EBX
    ; ESI   - outer loop counter
    ; EDI   - inner loop counter

; ----------------------------------------------------------
; --------------------STACK VARIABLES-----------------------
; ----------------------------------------------------------

    push    0           ; variable storing copy of one pixel [ebp - 16]

    ; during calculation of ew values for current row
    ; I still need unchanged values from previous row
    ; I need to save such a values somewhere
    ; I create place on a stack equal to the width * 3(alligned to 4 bytes)
    mov     eax, [ebp + 12]     ; width
    lea     eax, [eax+2*eax]    ; width * 3
    mov     ecx, 3
    and     ecx, eax            ; i know now if eax has +1 +2 or +3
    sub     eax, ecx
    add     eax, 4              ; padd offset to 4

    sub     esp, eax            ; esp - width * 3
    ; [esp] points to the top of the stack, where row copy is stored


    xor     esi, esi        ; set to 0 - hieght counter
    xor     edi, edi        ; set to 0 - width counter

; ----------------------------------------------------------
; ---------------------MAIN LOOP----------------------------
; ----------------------------------------------------------
outer:
    cmp     esi, [ebp+16]   ; height
    je      end_of_outer

    xor     edi, edi        ; reset inner loop counter
inner:
    cmp     edi, [ebp+12]   ; width
    je      end_of_inner

    ; operation of the program
    ; 1. calculate new value for current pixel
    ; 2. save pixel(y-1, x-1) from [esp] to *img
    ; 3. save previous pixel(y, x-1)[ebp - 16] to [esp]
    ; 4. save new pixel to [ebp-16]
    ; esi - y cordinate
    ; edi - x cordinate


    xor     ebx, ebx        ; counter for rgb - tells calculate_pixel which color should be calculated

    xor     ecx, ecx        ; value of current pixel is stored here
; rgb loop
next_byte_of_pixel:
    cmp     ebx, 3
    je      end_pixel

    push    ecx     ; save pixel
    ; arguments:
    ; esi - y cordinate
    ; edi - x cordinate
    ; ebx - red, green or blue
    ; uses eax, ecx, edx as temporary
    call    calculate_pixel             ; calculate r, g or b for given pixel(x, y)
    pop     ecx     ; restore pixel
  
    mov     cl, al  ; save pixel(r, g or b) byte to the lowest byte of ecx
    ror     ecx, 8  ; byte goes to the highest byte

    inc     ebx
    jmp     next_byte_of_pixel

end_pixel:
    ror     ecx, 8      ; ecx holds new value for current pixel r(byte)-g(byte)-b(byte)-zeros(8 zeros)
                        ; {highest byte}8 zeros-b(byte)-g(byte)-r(byte){lowest byte}
    
    mov     ebx, esp    ; pointer to copy of the previous row
    push    ecx
    ; arguments:
    ; esi - y cordinate
    ; edi - x cordinate
    ; ebx - pointer to copy of previous row
    ; uses eax, ecx, edx as temporary
    call    save_from_stack_to_img     ; save new value of pixel(y-1, x-1) to the *img
    pop     ecx

    mov     ebx, esp
    ; arguments:
    ; esi - y cordinate
    ; edi - x cordinate
    ; ebx - pointer to copy of previous row
    ; ecx - new value of current pixel      ; if last column then current pixel can also be saved to the stack
    ; uses eax, edx as temporary
    call    save_previous_to_stack      ; save new value of pixel(y, x-1) to the stack

    mov     [ebp - 16], ecx             ; save current pixel to the variable

    inc     edi             ; inc inner loop counter
    jmp     inner

end_of_inner:

    inc     esi             ; inc outer loop counter
    jmp     outer

end_of_outer:

; copy row saved on stack to the *img
    mov     ebx, esp        ; pointer to copy
    ; arguments:
    ; ebx - pointer to copy of previous row
    ; uses eax, ecx, edx, esi, edi as temporary
    call    copy_last_row   ; copy row from stack to the *img

; remove local variables from the stack
    ; row copy
    mov     eax, [ebp + 12]     ; width
    lea     eax, [eax+2*eax]    ; width * 3
    mov     ecx, 3
    and     ecx, eax            ; i know now if eax has +1 +2 or +3
    sub     eax, ecx
    add     eax, 4              ; padd offset to 4

    lea     esp, [esp + eax]            ; esp - width * 3

    ; local variable holding copy of one pixel
    add     esp, 4

; epilogue
    pop     edi
    pop     esi
    pop     ebx

    pop     ebp     ; restore callers frame pointer
    ret




; ----------------------------------------------------
; -----------------CALCULATE PIXEL--------------------
; ----------------------------------------------------
; calculate new value for given pixel
; ARGUMENTS
; esi - y cordinate
; edi - x cordinate
; [ebp + 20] - matrix
; [ebp + 8] - *img
; [ebp + 12] - width
; [ebp + 16] - height
; ebx - red(0), green(1) or blue(2) value
; RETURN
; al(eax) - new value for red, green or blue
calculate_pixel:
    push    0         ; hold new value for pixel
    ; [esp] - hold new value for pixel

    ; calculate offset to *img pointing to top-left pixel(y-1, x-1) from current pixel
    lea     eax, [esi-1]            ; y-1
    mul     dword[ebp + 12]              ; eax = width * (y-1)
    lea     eax, [eax + edi - 1]    ; eax = width * (y-1) + x-1
    lea     eax, [eax + 2*eax]      ; eax = 3*eax

    mov     ecx, [ebp + 8]          ; img pointer
    lea     ecx, [eax + ecx]        ; img pointer + offset
    ; ecx - points to (y-1, x-1)


    ; omit top row(y-1) if y is equal to 0
    test    esi, esi
    jz      second_row 


    ; omit left if x is equal to 0
    test    edi, edi
    jz      r1_c2

; row 1, column 1 (x-1, y-1)
r1_c1:
    ; takes value of top left pixel
    mov     al, byte[ecx + ebx]

    ; takes top left corner value from matrix
    mov     edx, [ebp+20]    
    mul     byte[edx]       ; ax = current pixel * value from the matrix
    movzx   eax, ax
    add     [esp], eax      ; add to value on the stack

; pixel above y-1, x
r1_c2:
    ; takes value of top pixel
    mov     al, byte[ecx + 3 + ebx]

    ; takes top value from matrix
    mov     edx, [ebp+20]
    mul     byte[edx + 1]   ; ax = current pixel * value from the matrix
    movzx   eax, ax
    add     [esp], eax      ; add to value on the stack


    ; omit right if x is equal to width - 1
    mov     eax, [ebp+12]
    dec     eax
    cmp     edi, eax
    je      second_row

; pixel if top right corner (y-1, x+1)
r1_c3:
    ; takes pixel value from img
    mov     al, byte[ecx + 6 + ebx]

    ; takes top-right corner from the matrix
    mov     edx, [ebp+20]
    mul     byte[edx + 2]   ; ax = current pixel * value from the matrix
    movzx   eax, ax
    add     [esp], eax      ; add to value on the stack
second_row:
    ;move ecx to next row(y)
    mov     eax, [ebp+12]
    lea     eax, [eax + 2*eax]
    add     ecx, eax

    ; omit left if x is equal to 0
    test    edi, edi
    jz      r2_c2
; (y, x-1)
r2_c1:
    ; takes pixel value from img
    mov     al, byte[ecx + ebx]

    ; takes left field from the matrix
    mov     edx, [ebp+20]
    mul     byte[edx + 3]   ; ax = current pixel * value from the matrix
    movzx   eax, ax
    add     [esp], eax      ; add to value on the stack

; (y, x)
r2_c2:
    ; takes pixel value from img
    mov     al, byte[ecx + 3 + ebx]


    ; takes center field from the matrix
    mov     edx, [ebp+20]
    mul     byte[edx + 4]   ; ax = current pixel * value from the matrix
    movzx   eax, ax
    add     [esp], eax      ; add to value on the stack

    ; omit right if x is eqaul to width - 1
    mov     eax, [ebp+12]
    dec     eax
    cmp     edi, eax
    je      third_row

; (y, x+1)
r2_c3:
    ; takes value of current pixel
    mov     al, byte[ecx + 6 + ebx]

    ; takes right field from the matrix
    mov     edx, [ebp+20]

    mul     byte[edx + 5]   ; ax = current pixel * value from the matrix
    movzx   eax, ax
    add     [esp], eax      ; add to value on the stack

third_row:
    ; omit bottom row if y is eqaul to height - 1
    mov     eax, [ebp + 16]
    dec     eax
    cmp     esi, eax
    je      end_calculate_pixel

    ; move ecx to next row
    mov     eax, [ebp+12]
    lea     eax, [eax + 2*eax]
    add     ecx, eax

    ; omit left if x is equal to 0
    test    edi, edi
    jz      r3_c2
; (y + 1, x -1)
r3_c1:
    ; takes value of current pixel
    mov     al, byte[ecx + ebx]


    ; takes bottom-left corner from the matrix
    mov     edx, [ebp+20]
    mul     byte[edx + 6]   ; ax = current pixel * value from the matrix
    movzx   eax, ax
    add     [esp], eax      ; add to value on the stack

; (y + 1, x)
r3_c2:
    ; takes value of current pixel
    mov     al, byte[ecx + 3 + ebx]


    ; takes bottom field from the matrix
    mov     edx, [ebp+20]
    mul     byte[edx + 7]   ; ax = current pixel * value from the matrix
    movzx   eax, ax
    add     [esp], eax      ; add to value on the stack

    ; omit right if x is eqaul to width - 1
    mov     eax, [ebp+12]
    dec     eax
    cmp     edi, eax
    je      end_calculate_pixel

; (y + 1, x + 1)
r3_c3:
    ; takes value of current pixel
    mov     al, byte[ecx + 6 + ebx]

    ; takes bottom-rigth field from the matrix
    mov     edx, [ebp+20]
    mul     byte[edx + 8]   ; ax = current pixel * value from the matrix
    movzx   eax, ax
    add     [esp], eax      ; add to value on the stack

end_calculate_pixel:
    pop     eax             ; takes new value for pixel from the stack
    shr     eax, 8          ; divide by 256
    ret

; --------------------------------------------
; --------------SAVE FROM STACK---------------
; --------------------------------------------
save_from_stack_to_img:
; ARGUMENTS
; esi - y cordinate
; edi - x cordinate
; ebx - pointer to the copy of previous row
; [ebp + 20] - matrix
; [ebp + 8] - *img
; [ebp + 12] - width
; [ebp + 16] - height

    ; if first row then there is nothing already on the stack
    test    esi, esi
    jz      end_save_from_stack

    ; nothing to do in first column
    test    edi, edi
    jz      end_save_from_stack

    ; looks for a good place in *img(previous row, previous column)
    ; offset for *img
    lea     eax, [esi - 1]      ; y-1
    mul     dword[ebp + 12]     ; eax = y-1 * width

    lea     ecx, [eax + edi - 1]; eax = y-1 * width + x - 1
    lea     ecx, [ecx + 2*ecx]  ; eax = y-1 * width * 3
    mov     eax, [ebp + 8]      ; *img
    lea     ecx, [eax + ecx]    ; points to the pixel in *img
    ; ecx holds pointer to pixel in *img

    ; offset for pointer to the copy
    lea     eax, [edi - 1]      ; x-1
    lea     eax, [eax + 2*eax]  ; (x-1) * 3
    lea     eax, [ebx + eax]    ; points to the pixel, which should be copied

    ; copy pixel
    mov     dx, [eax]       ; 2 bytes
    mov     [ecx], dx
    mov     dl, [eax + 2]   ; third byte
    mov     [ecx + 2], dl

    ; if last column then copy also next pixel from row copy
    mov     edx, [ebp + 12]
    dec     edx
    cmp     edx, edi
    jne     end_save_from_stack

    ; copy next pixel
    mov     dx, [eax + 3]       ; bytes
    mov     [ecx + 3], dx
    mov     dl, [eax + 3 + 2]   ; third byte
    mov     [ecx + 3 + 2], dl

end_save_from_stack:
    ret


; --------------------------------------------
; --------------SAVE PREVIOUS-----------------
; --------------------------------------------
save_previous_to_stack:
; save pixel, which was previously calculated r, c-1
; ARGUMENTS
; [ebp - 16] - copy of a pixel to save
; ecx - new value of current pixel
; ebx - pointer to the copy of previous row
; esi - y cordinate
; edi - x cordinate
; [ebp + 20] - matrix
; [ebp + 8] - *img
; [ebp + 12] - width
; [ebp + 16] - height

    ; there is no previous if first column
    test    edi, edi
    jz      end_save_previous

    ; looks for a good place in the copy of a row(previous row, previous column)
    ; offset for *img
    lea     edx, [edi-1]    ; x-1
    lea     edx, [edx + 2*edx]  ; (x-1)*3
    lea     edx, [ebx + edx]    ; points to the pixel in the copied row

    ; copy pixel
    mov     ax, [ebp-16]        ; 2 bytes
    mov     [edx], ax
    mov     al, [ebp-16+2]      ; third byte
    mov     [edx+2], al

    ; if last column save also current pixel
    mov     eax, [ebp + 12]
    dec     eax
    cmp     eax, edi
    jne      end_save_previous

    ; copy also current pixel
    mov     [edx + 3], cx       ; 2 bytes
    shr     ecx, 16
    mov     [edx+3+2], cl       ; third byte

end_save_previous:
    ret



; --------------------------------------------
; --------------SAVE PREVIOUS-----------------
; --------------------------------------------
; saves row on the stack into the *img
; ARGUMENTS
; ebx - pointer to the row copy
; [ebp + 20] - matrix
; [ebp + 8] - *img
; [ebp + 12] - width
; [ebp + 16] - height
copy_last_row:
    ; pointer to img
    mov     eax, [ebp + 16] ; height
    dec     eax             ; height - 1
    mul     dword[ebp + 12] ; eax = (height-1)*width

    lea     ecx, [eax + 2*eax]  ; offset
    mov     eax, [ebp + 8]      ; *img
    lea     ecx, [ecx + eax]    ; img last row pointer

    xor     edi, edi            ; loop counter
last_row_loop:
    cmp     edi, [ebp + 12]
    je      last_row_end_loop

    ; find offset
    lea     eax, [edi + 2*edi]

    mov     dx, [ebx + eax]         ; 2 bytes
    mov     [ecx + eax], dx
    mov     dl, [ebx + eax + 2]     ; third byte
    mov     [ecx + eax + 2], dl

    inc     edi
    jmp     last_row_loop

last_row_end_loop:
    ret