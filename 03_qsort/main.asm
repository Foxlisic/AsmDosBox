macro   brk     { int3 }

        org     100h
        mov     ax, 0013h
        int     10h
        mov     ax, $A000
        mov     es, ax
        call    random
        push    word $0000
        push    word $ffff
        call    qsort
        xor     ax, ax
        int     16h
        ret

; Заполнить экран мусором
random: xor     di, di
        mov     cx, 32000
@@:     mul     bx
        add     ax, cx
        add     bx, ax
        add     ax, dx
        stosw
        loop    @b
        ret

; ------------------------------------------------------------------------------
; Аргументы +6=L, +4=R
; ------------------------------------------------------------------------------

qsort:  push    bp
        mov     bp, sp
        mov     si, [bp+6]      ; a=L
        mov     di, [bp+4]      ; b=R
        mov     bx, si
        add     bx, di
        rcr     bx, 1           ; bx = (L + R)/2
        ; ----------------------
        mov     al, [es:bx]     ; pivot = arr[bx]
.K1:    inc     si
        cmp     [es:si-1], al   ; while (arr[a] < pivot) a++
        jb      .K1
.K2:    dec     di
        cmp     [es:di+1], al   ; while (arr[b] > pivot) b--
        ja      .K2
        dec     si
        inc     di
        cmp     si, di          ; if a <= b: swap arr[a++], arr[b--]
        ja      .K3
        mov     ah, [es:si]
        xchg    ah, [es:di]
        xchg    ah, [es:si]
        inc     si
        dec     di
        cmp     si, di          ; while a <= b
        jbe     .K1
        ; ----------------------
.K3:    cmp     [bp+6], di      ; if l < b: qsort(l, b)
        jnb     @f
        push    word [bp+6]
        push    di
        call    qsort
@@:     cmp     si, [bp+4]      ; if a < r: qsort(a, r)
        jnb     @f
        push    si
        push    word [bp+4]
        call    qsort
@@:     pop     bp
        ret     4
