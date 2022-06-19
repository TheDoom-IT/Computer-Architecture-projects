; void filter(void *img, int width, int height, unsigned char *mtx)

    section .text
    global filter

filter:
; prologue
    push    rbp         ; save callers frame pointer
    mov     rbp, rsp    ; save local frame pointer

    push    rbx
    push    rsi
    push    rdi
    push    r12
    push    r14
    push    r15

; program
    ; arguments are passed via registers !
    ; RDI    void *img
    ; RSI   width
    ; RDX -> R9   height
    ; RCX   char *mtx
    ; R8    variable storing copy of a pixel

    ; I need rdx to multiplication
    ; let's move height to r9
    mov     r9, rdx

    ; RAX       - temporary register
    ; RDI, RSI  - input arguments   img, width
    ; RDX       - temporary register
    ; RCX       - input argument - mtx
    ; R8        - variable storing new value for current pixel
    ; R9        - input argument - height
    ; R10,R11   - loops counter
    ; RBX       - loop counter
    ; R12       - varible storing new value for previous pixel
    ; R13       - not used
    ; R14..R15  - temporary registers


; ----------------------------------------------------------
; --------------------ROW COPY ONTO STACK-------------------
; ----------------------------------------------------------
    
    ; during calculation of new values for current row
    ; I still need unchanged values from previous row
    ; I need to save such a values somewhere
    ; I create place on a stack equal to the width * 3(alligned to 4 bytes)
    mov     rax, rsi     ; width
    lea     rax, [rax+2*rax]    ; width * 3
    mov     rdx, 7
    and     rdx, rax            ; i know now if eax has +1 +2, +3...+7
    sub     rax, rdx
    add     rax, 8              ; padd offset to 8

    sub     rsp, rax            ; esp - width * 3
    ;[rsp] points to the top of the stack, where row copy is stored


    xor     r10, r10        ; set to 0 - hieght counter
    xor     r11, r11        ; set to 0 - width counter

; ----------------------------------------------------------
; ---------------------MAIN LOOP----------------------------
; ----------------------------------------------------------
outer:
    cmp     r10, r9   ; height
    je      end_of_outer

    xor     r11, r11        ; reset inner loop counter
inner:
    cmp     r11, rsi        ; width
    je      end_of_inner

;     ; operation of the program
;     ; 1. calculate new value for current pixel
;     ; 2. save pixel(y-1, x-1) from [esp] to *img
;     ; 3. save previous pixel(y, x-1)r12 to [esp]
;     ; 4. save current pixel to r12
;     ; r10 - y cordinate
;     ; r11 - x cordinate


    xor     rbx, rbx        ; counter for rgb - tells calculate_pixel which color should be calculated

    xor     r8, r8        ; value of current pixel is stored here
; rgb loop
next_byte_of_pixel:
    cmp     rbx, 3
    je      end_pixel

    ; arguments:
    ; r10 - y cordinate
    ; r11 - x cordinate
    ; rbx - red, green or blue
    ; uses eax, edx, r14, r15 as temporary
    call    calculate_pixel             ; calculate r, g or b for given pixel(x, y)

    mov     r8b, al  ; save pixel(r, g or b) byte to the lowest byte of r8
    ror     r8, 8  ; byte goes to the highest byte

    inc     rbx
    jmp     next_byte_of_pixel

end_pixel:
    ror     r8, 40      ; r8 holds new value for current pixel r(byte)-g(byte)-b(byte)-zeros(8 zeros)
                        ; {highest byte}40 zeros-b(byte)-g(byte)-r(byte){lowest byte}
    
    mov     rbx, rsp    ; pointer to copy of the previous row

    ; arguments:
    ; r10 - y cordinate
    ; r11 - x cordinate
    ; rbx - pointer to copy of previous row
    ; uses eax, ecx, edx as temporary
    call    save_from_stack_to_img     ; save new value of pixel(y-1, x-1) to the *img

    mov     rbx, rsp    ; pointer to copy of previous row
    ; arguments:
    ; r10 - y cordinate
    ; r11 - x cordinate
    ; r12 - previous pixel new value
    ; rbx - pointer to copy of previous row
    ; r8 - new value of current pixel      ; if last column then current pixel can also be saved to the stack
    ; uses eax, edx, r14, r15 as temporary
    call    save_previous_to_stack      ; save new value of pixel(y, x-1) to the stack

    mov     r12, r8         ; current pixel as previous

    inc     r11             ; inc inner loop counter
    jmp     inner

end_of_inner:

    inc     r10             ; inc outer loop counter
    jmp     outer

end_of_outer:

    mov     rbx, rsp        ; pointer to row copy

    ; arguments:
    ; rbx - pointer to copy of previous row
    ; uses rax, rdx, r14, r15 as temporary
    call    copy_last_row   ; copy row from stack to the *img

; remove local variables from the stack
    mov     rax, rsi            ; width
    lea     rax, [rax+2*rax]    ; width * 3
    mov     rdx, 7
    and     rdx, rax            ; i know now if eax has +1 +2, +3...+7
    sub     rax, rdx
    add     rax, 8              ; padd offset to 8

    add     rsp, rax            ; esp - width * 3

; epilogue
    pop     rdi
    pop     rsi
    pop     rbx
    pop    r15
    pop    r14
    pop    r12

    pop     rbp     ; restore callers frame pointer
    ret






; ----------------------------------------------------
; -----------------CALCULATE PIXEL--------------------
; ----------------------------------------------------
; calculate new value for given pixel
; ARGUMENTS
; r10 - y cordinate
; r11 - x cordinate
; rcx - matrix
; rdi - *img
; rsi - width    -> RSI
; r9 - height   -> R9
; rbx - red(0), green(1) or blue(2) value
; uses rax, rdx, r14, r15 as temporary
; RETURN
; al(rax) - new value for red, green or blue

calculate_pixel:
    xor     r15, r15    ; hold new value for pixel

    ; calculate offset to *img pointing to top-left pixel(y-1, x-1) from current pixel
    lea     rax, [r10-1]            ; y-1
    mul     rsi                     ; rax = width * (y-1)
    lea     rax, [rax + r11 - 1]    ; rax = width * (y-1) + x-1
    lea     rax, [rax + 2*rax]      ; rax = 3*rax

    lea     r14, [rax + rdi]        ; img pointer + offset
    ; r14 - points to (y-1, x-1)


    ; omit top row(y-1) if y is equal to 0
    test    r10, r10
    jz      second_row 


    ; omit left if x is equal to 0
    test    r11, r11
    jz      r1_c2

; row 1, column 1 (x-1, y-1)
r1_c1:
    ; takes value of top left pixel
    mov     al, byte[r14 + rbx]

    ; takes top left corner value from matrix
    mul     byte[rcx]       ; ax = current pixel * value from the matrix
    movzx   rax, ax
    add     r15, rax        ; add to value to the variable

; pixel above y-1, x
r1_c2:
    ; takes value of top pixel
    mov     al, byte[r14 + 3 + rbx]

    ; takes top value from matrix
    mul     byte[rcx + 1]           ; ax = current pixel * value from the matrix
    movzx   rax, ax
    add     r15, rax                ; add to value to the variable


    ; omit right if x is equal to width - 1
    lea     rax, [rsi-1]
    cmp     r11, rax
    je      second_row

; pixel if top right corner (y-1, x+1)
r1_c3:
    ; takes pixel value from img
    mov     al, byte[r14 + 6 + rbx]

    ; takes top-right corner from the matrix
    mul     byte[rcx + 2]               ; ax = current pixel * value from the matrix
    movzx   rax, ax
    add     r15, rax                    ; add to value to the variable
second_row:
    ;move r14 to next row(y)
    lea     rax, [rsi + 2*rsi]  ; width * 3
    add     r14, rax

    ; omit left if x is equal to 0
    test    r11, r11
    jz      r2_c2

; (y, x-1)
r2_c1:
    ; takes pixel value from img
    mov     al, byte[r14 + rbx]

    ; takes left field from the matrix
    mul     byte[rcx + 3]       ; ax = current pixel * value from the matrix
    movzx   rax, ax
    add     r15, rax            ; add to value to the variable

; ; (y, x)
r2_c2:
    ; takes pixel value from img
    mov     al, byte[r14 + 3 + rbx]

    ; takes center field from the matrix
    mul     byte[rcx + 4]             ; ax = current pixel * value from the matrix
    movzx   rax, ax
    add     r15, rax        ; add to value to the variable

    ; omit right if x is eqaul to width - 1
    lea     rax, [rsi-1]
    cmp     r11, rax
    je      third_row

; (y, x+1)
r2_c3:
    ; takes value of current pixel
    mov     al, byte[r14 + 6 + rbx]

    ; takes right field from the matrix
    mul     byte[rcx + 5]               ; ax = current pixel * value from the matrix
    movzx   rax, ax
    add     r15, rax                ; add to value to the variable

third_row:
    ; omit bottom row if y is eqaul to height - 1
    lea     rax, [r9 - 1]
    cmp     r10, rax
    je      end_calculate_pixel

    ; move r14 to next row
    lea     rax, [rsi + 2*rsi]  ; width * 3
    add     r14, rax

    ; omit left if x is equal to 0
    test    r11, r11
    jz      r3_c2
; (y + 1, x -1)
r3_c1:
    ; takes value of current pixel
    mov     al, byte[r14 + rbx]

    ; takes bottom-left corner from the matrix
    mul     byte[rcx + 6]            ; ax = current pixel * value from the matrix
    movzx   rax, ax
    add     r15, rax        ; add to value to the variable

; ; (y + 1, x)
r3_c2:
    ; takes value of current pixel
    mov     al, byte[r14 + 3 + rbx]

    ; takes bottom field from the matrix
    mul     byte[rcx + 7]              ; ax = current pixel * value from the matrix
    movzx   rax, ax
    add     r15, rax        ; add to value to the variable

    ; omit right if x is eqaul to width - 1
    lea     rax, [rsi - 1]
    cmp     r11, rax
    je      end_calculate_pixel

; (y + 1, x + 1)
r3_c3:
    ; takes value of current pixel
    mov     al, byte[r14 + 6 + rbx]

    ; takes bottom-rigth field from the matrix
    mul     byte[rcx + 8]              ; ax = current pixel * value from the matrix
    movzx   rax, ax
    add     r15, rax        ; add to value to the variable

end_calculate_pixel:
    mov     rax, r15        ; takes new value for pixel from the variable
    shr     rax, 8          ; divide by 256
    ret


; --------------------------------------------
; --------------SAVE FROM STACK---------------
; --------------------------------------------
save_from_stack_to_img:
; ARGUMENTS
; esi - y cordinate     -> r10
; edi - x cordinate     -> r11
; ebx - pointer to the copy of previous row -> rbx
; [ebp + 20] - matrix   -> RCX
; [ebp + 8] - *img      -> RDI
; [ebp + 12] - width    -> RSI
; [ebp + 16] - height   -> R9
; uses eax, edx, r12..r15 as temporary

    ; if first row then there is nothing already on the stack
    test    r10, r10
    jz      end_save_from_stack

    ; nothing to do in first column
    test    r11, r11
    jz      end_save_from_stack

    ; looks for a good place in *img(previous row, previous column)
    ; offset for *img
    lea     rax, [r10 - 1]          ; y-1
    mul     rsi                     ; rax = y-1 * width

    lea     r15, [rax + r11 - 1]    ; r15 = y-1 * width + x - 1
    lea     r15, [r15 + 2*r15]      ; r15 = r15 * 3
    lea     r15, [rdi + r15]        ; img + offset
    ; r15 holds pointer to pixel in *img

    ; offset for pointer to the copy
    lea     rax, [r11 + 2*r11 - 3]  ; (x-1) * 3
    lea     rax, [rbx + rax]    ; points to the pixel, which should be copied

    ; copy pixel
    mov     dx, [rax]       ; 2 bytes
    mov     [r15], dx
    mov     dl, [rax + 2]   ; third byte
    mov     [r15 + 2], dl

    ; if last column then copy also next pixel from row copy
    mov     rdx, rsi
    dec     rdx
    cmp     rdx, r11
    jne     end_save_from_stack

    ; copy next pixel
    mov     dx, [rax + 3]       ; 2 bytes
    mov     [r15 + 3], dx
    mov     dl, [rax + 3 + 2]   ; third byte
    mov     [r15 + 3 + 2], dl

end_save_from_stack:
    ret


; --------------------------------------------
; --------------SAVE PREVIOUS-----------------
; --------------------------------------------
save_previous_to_stack:
; save pixel, which was previously calculated r, c-1
; ARGUMENTS
; [ebp - 16] - copy of a pixel to save      -> r12
; ecx - new value of current pixel          -> r8
; ebx - pointer to the copy of previous row -> rbx
; esi - y cordinate     -> r10
; edi - x cordinate     -> r11
; [ebp + 20] - matrix   -> rcx
; [ebp + 8] - *img      -> rdi
; [ebp + 12] - width    -> rsi
; [ebp + 16] - height   -> r9

    ; there is no previous if first column
    test    r11, r11
    jz      end_save_previous

    ; looks for a good place in the copy of a row(previous row, previous column)
    ; offset for *img
    lea     rdx, [r11 + 2*r11 - 3]  ; (x-1)*3
    lea     rdx, [rbx + rdx]    ; points to the pixel in the copied row

    ; copy pixel
    mov     [rdx], r12w     ; 2 bytes
    shr     r12, 16
    mov     [rdx+2], r12b   ; third byte

    ; if last column save also current pixel
    lea     rax, [rsi - 1]
    cmp     rax, r11
    jne      end_save_previous

    ; copy also current pixel
    mov     [rdx + 3], r8w  ; 2 bytes
    shr     r8, 16
    mov     [rdx+3+2], r8b  ; third byte

end_save_previous:
    ret


; --------------------------------------------
; --------------SAVE PREVIOUS-----------------
; --------------------------------------------
; saves row on the stack into the *img
; ARGUMENTS
; ebx - pointer to the row copy -> rbx
; [ebp + 20] - matrix           -> rcx
; [ebp + 8] - *img              -> rdi
; [ebp + 12] - width            -> rsi
; [ebp + 16] - height           -> r9
copy_last_row:
    ; pointer to img
    lea     rax, [r9 - 1]   ; height - 1
    mul     rsi             ; eax = (height-1)*width

    lea     rdx, [rax + 2*rax]  ; (height-1)*width*3 = offset
    lea     r14, [rdx + rdi]    ; img + offset
    ; r14 points to the last for of *img

    xor     r15, r15
last_row_loop:
    cmp     r15, rsi
    je      last_row_end_loop

    ; find offset
    lea     rax, [r15 + 2*r15]

    mov     dx, [rbx + rax]     ; 2 bytes
    mov     [r14 + rax], dx
    mov     dl, [rbx + rax + 2] ; third byte
    mov     [r14 + rax + 2], dl

    inc     r15
    jmp     last_row_loop

last_row_end_loop:
    ret