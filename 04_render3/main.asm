include     "macro.asm"
; ------------------------------------------------------------------------------

            org     100h
            mov     ax, $0013
            int     10h
            mov     ax, $A000
            mov     es, ax
            call    draw2

            mov     eax, [T1]
            mov     [tri2], eax
            mov     eax, [T1+4]
            mov     [tri2+4], eax
            mov     eax, [T1+8]
            mov     [tri2+8], eax
            mov     [CLRT], byte 13
            call    draw2

            xor     ax, ax
            int     16h
            ret

T1:         dw     80, 10
            dw     100, 50
            dw     60, 30

; Нарисовать треугольник 2D
; ------------------------------------------------------------------------------
draw2:      ; Проверка лицевой стороны
            mov     si, tri2
            call    .DIFAC
            mov     ax,  [AB.y]
            mul     word [AC.x]             ; ABy*ACx
            xchg    ax, bx
            mov     ax,  [AB.x]
            mul     word [AC.y]             ; ABx*ACy
            cmp     bx, ax
            jg      .END                    ; if AB.y*AC.x > AB.x*AC.y: return

            ; Отсортировать точки треугольника по Y (ASC)
.R2:        lea     di, [si+4]
.R1:        mov     ax, [si+2]              ; if tri2[si] > tri2[di]:
            cmp     ax, [di+2]
            jle     .R3
            mov     eax, [si]
            xchg    eax, [di]               ; swap tri2[si], tri2[di]
            xchg    eax, [si]
.R3:        add     di, 4
            cmp     di, tri2+3*4
            jne     .R1
            add     si, 4
            cmp     si, tri2+2*4
            jne     .R2

            ; Заново пересчитать грани
            mov     si, tri2
            call    .DIFAC
            sub3a   [BC.x], [_CX], [_BX]    ; BCx = C.x - B.x
            sub3a   [BC.y], [_CY], [_BY]    ; BCy = C.y - B.y

            ; Предзагрузка грани
            mov     ax, [_AX]
            mov     bx, [_AY]
            mov     cx, [_BY]
            mov     [_BX], ax               ; B.x  = A.x
            sub     [_BY], bx               ; B.y -= A.y
            sub     [_CY], cx               ; C.y -= B.y
            xor     ax, ax
            mov     [AC.dx], ax             ; AC.dx = 0
            mov     [AB.dx], ax             ; AB.dx = 0
            mov     [.CHL], byte 2
            inc     word [AB.y]
            inc     word [BC.y]
            inc     word [AC.y]             ; Рисуется Y3-Y1+1 строк

.MAIN:      ; Перед рисованием линии: инкрементировать
            incr3   AC.dx, AC.x, AC.y, _AX  ; Сдвиг AC
            call    .INCAB

            ; Рисование половины треугольника
            mov     di, [_AY]
            cmp     di, 200
            jg      .END                    ; A.y >= 200
            jnb     .K1                     ; A.y < 0 (т.к. отрицательные > 320)
            mov     ax, [_AX]               ; x1 = A.x; x2 = B.x
            mov     cx, [_BX]
            cmp     ax, cx
            jle     .L1                     ; if x1 > x2:
            xchg    ax, cx                  ; swap x1, x2
.L1:        cmp     ax, 320
            jge     .K1                     ; x1 >= 320: пропуск
            cmp     cx, 0
            jl      .K1                     ; x2 < 0: пропуск
            cmp     ax, 0                   ; x1,x2 = [0..319]
            jge     .L2                     ; x1 = max(x1, 0)
            xor     ax, ax
.L2:        cmp     cx, 320                 ; x2 = min(x2, 319)
            jl      .L3
            mov     cx, 319

            ; Вычисление количества точек
.L3:        imul    di, [_AY], 320          ; di=A.y*320
            add     di, ax
            sub     cx, ax
            inc     cx

            ; Растеризация
            mov     al, [CLRT]
            rep     stosb

            ; Сдвиг точек вниз
.K1:        inc     word [_AY]              ; A.y++
            dec     word [_BY]              ; B.y--
            jns     .MAIN
            dec     byte [.CHL]             ; Проверка что это рисуется BC
            je      .END
            mov     ax, [_CY]
            dec     ax
            js      .END                    ; Если C.y=B.y: выход
            mov     [_BY], ax               ; Копировать BC.x, BC.y -> AB.x, AB.y
            mov     eax, [BC]               ; AB.dx все равно равен 0
            mov     [AB], eax               ; _BX указывает на точку B.x
            call    .INCAB                  ; Сдвиг AB (синхронизация)
            jmp     .MAIN
.END:       ret

; Расчет разностей точек
.DIFAC:     sub3a   [AB.x], [_BX], [_AX]    ; ABx = B.x - A.x
            sub3a   [AB.y], [_BY], [_AY]    ; ABy = B.y - A.y
            sub3a   [AC.x], [_CX], [_AX]    ; ACx = C.x - A.x
            sub3a   [AC.y], [_CY], [_AY]    ; ACy = C.y - A.y
            ret

; Инкремент AB или BC
.INCAB:     incr3   AB.dx, AB.x, AB.y, _BX  ; Сдвиг AB
            ret

; Счетчик полутреугольника
.CHL:       db      0

; ------------------------------------------------------------------------------
; Секция с данными
; ------------------------------------------------------------------------------

; Цвет треугольника
CLRT:       db      14

; Грани треугольника
AB:
.x:         dw      0
.y:         dw      0
.dx:        dw      0

AC:
.x:         dw      0
.y:         dw      0
.dx:        dw      0

BC:
.x:         dw      0
.y:         dw      0

; Рисование 2D-треугольника по 3-м точкам: временные данные
tri2:       dw     60,  30          ; (x1 y1)
            dw     100, 50          ; (x2 y2)
            dw     20, 160          ; (x3 y3)

