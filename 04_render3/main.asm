include     "macro.asm"
; ------------------------------------------------------------------------------

            org     100h
            mov     ax, $0013
            int     10h
            mov     ax, $A000
            mov     es, ax
            call    draw2

            ret

; Нарисовать треугольник 2D
; ------------------------------------------------------------------------------
draw2:
            ; Отсортировать точки треугольника по Y (ASC)
            mov     si, tri2
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
            mov     si, tri2

            ; Вычисление граней (AB, AC, BC)
            sub3a   [AB.x], [_BX], [_AX]    ; ABx = B.x - A.x
            sub3a   [AB.y], [_BY], [_AY]    ; ABy = B.y - A.y
            sub3a   [AC.x], [_CX], [_AX]    ; ACx = C.x - A.x
            sub3a   [AC.y], [_CY], [_AY]    ; ACy = C.y - A.y
            sub3a   [BC.x], [_CX], [_BX]    ; BCx = C.x - B.x
            sub3a   [BC.y], [_CY], [_BY]    ; BCy = C.y - B.y

            ; Проверить лицевую сторону грани
            mov     ax,  [AB.y]
            mul     word [AC.x]             ; ABy*ACx
            xchg    ax, bx
            mov     ax,  [AB.x]
            mul     word [AC.y]             ; ABx*ACy
            cmp     bx, ax
            jg      .END                    ; if AB.y*AC.x > AB.x*AC.y: return

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
            cmp     [AC.y], ax              ; Чтобы не делить на AC.y и AB.y
            jne     .R4
            mov     [AC.y], word 1
.R4:        inc     word [AB.y]
.R5:
brk
            ; Перед рисованием линии: инкрементировать
            incr3   AC.dx, AC.x, AC.y, _AX  ; Сдвиг AC
            incr3   AB.dx, AB.x, AB.y, _BX  ; Сдвиг AB

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
            mov     al, 15
            rep     stosb

            ; Сдвиг точек вниз
.K1:        inc     word [_AY]              ; A.y++
            dec     word [_BY]              ; B.y--
            jns     .R5

            ; Загрузка грани BC
.K2:        ;

.END:       ret

; Секция с данными
; ------------------------------------------------------------------------------

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
.dx:        dw      0

; Рисование 2D-треугольника по 3-м точкам
tri2:       dw     60, 50           ; (x1 y1)
            dw     80, 52           ; (x2 y2)
            dw     20, 130          ; (x3 y3)

