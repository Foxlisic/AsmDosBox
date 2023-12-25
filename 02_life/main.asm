macro   brk     { int3 }

        org     100h

        ; Инициализация сегментов
        mov     ax, 0013h
        int     10h
        mov     ax, cs
        add     ax, 1000h
        mov     ds, ax
        mov     es, ax

        ; Очистить буфер
        mov     cx, 16000
        xor     eax, eax
        rep     stosw
        mov     ax, $A000
        mov     es, ax

        ; Установка палитры для цвета 1
        mov     dx, $3C8
        mov     al, 1
        out     dx, al
        inc     dx
        mov     al, $1F
        out     dx, al      ; R
        mov     al, $3F
        out     dx, al      ; G
        mov     al, $1F
        out     dx, al      ; B

        ; Заполнить экран мусором
        xor     di, di
        mov     cx, 32000
@@:     add     ax, bx
        mul     bx
        add     ax, cx
        add     bx, ax
        add     ax, dx
        mov     dx, ax
        and     ax, 0101h
        stosw
        mov     ax, dx
        loop    @b

        ; Вычисления кадров
.T0:    mov     di, 1   ; y
        mov     si, 1   ; x

        ; bx = 320*di + 200
        imul    bx, di, 320
        add     bx, si

        mov     dx, 198
.R2:    mov     cx, 318

        ; Вычислить всех соседей у клетки
.R1:    xor     ax, ax
        add     al, [es:bx-320-1]
        add     al, [es:bx-320+0]
        add     al, [es:bx-320+1]
        add     al, [es:bx    -1]
        add     al, [es:bx    +1]
        add     al, [es:bx+320-1]
        add     al, [es:bx+320+0]
        add     al, [es:bx+320+1]

        ; Проверяемая клетка пуста или нет?
        cmp     [es:bx], byte 1
        je      .C1
.C0:    cmp     al, 3           ; Клетка 0, соседей 3 -- будет 1, иначе 0
        je      .S1
        jmp     .S0
.C1:    cmp     al, 2           ; Клетка 1, соседей 2-3 -- продолжает 1, иначе 0
        je      .S1
        cmp     al, 3
        je      .S1
.S0:    mov     [bx], byte 0
        jmp     .NX
.S1:    mov     [bx], byte 1
.NX:    inc     bx
        loop    .R1
        add     bx, 2           ; -318+320
        dec     dx
        jne     .R2

        ; Скопировать новый фрейм
        mov     cx,  16000
        xor     si, si
        xor     di, di
        rep     movsd
        jmp     .T0
