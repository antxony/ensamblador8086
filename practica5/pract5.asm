    name "p5"                     ; nombre de programa
    include 'emu8086.inc'         ; Incluimos libreria emu8086
    org  0x100
    DEFINE_GET_STRING             ; definimos la funcion get_string de emu8086
    jmp start                     ; brincamos las variables
    cadena db 5 dup(0)            ; declaración de cadena de entrada
    cadenaSize equ $-cadena       ; tamaño de la cadena de entrada
    cadenaSalida db "     ", 0    ; cadena de salida
    salidaSize equ $-cadenaSalida ; tamaño de cadena de entrada
    numero dw 0x0000              ; número de salida
    cadenaInicio dw 0x0000        ; dirección de inicio de la cadena
    msg1 db "Ingrese un numero en formato hexadecimal", 0 ; mesanje 1
    msg1Size equ $-msg1                                   ; Tamaño de msg1
    msgFinal db "Decimal: ", 0    ; texto de respuesta
    msgFinalSize equ $-msgFinal   ; tamaño de texto de respuesta
start:
    lea bp, msg1                  ; cargar mensaje 1
    mov cx, msg1Size              ; tamaño de msg1
    call printn                   ; imprimir cadena
    mov dx, cadenaSize            ; pasamos el tamaño de la cadena de entrada
    lea di, cadena                ; cargamos la dreccion de memeoria de la cadena de entrada
    mov cadenaInicio, di          ; guardamos esa direccion
    dec [cadenaInicio]            ; le restamos un byte
    call get_string               ; llamamos a la funcion para leer la cadena
    mov bx, cadenaSize            ; bx = cadenaSize
    lea si, cadena + [bx]         ; cargamos a si la direccion del ultimo caracter de la cadena
    call convert                  ; llamamos a convert
    mov bx, salidaSize            ; bx = tamaño del buffer de salida
    lea di, cadenaSalida + [bx]   ; di apunta al final del buffer de salida
    dec di                        ; di--
    dec di                        ; di--
    mov ax, [numero]              ; ax = numero convertido
    call numToBCD                 ; llamar a funcion para convertir entero a cadena
    call newLine                  ; imprimir salto de linea
    lea bp, msgFinal              ; cargar mensaje final
    mov cx, msgFinalSize          ; cx = tamaño msgFinal
    call print                    ; imprimir texto final
    lea bp, cadenaSalida          ; cargar numero en BCD
    mov cx, salidaSize            ; cx = tamaño de salidaSize
    call printn                   ; imprimir salida con salto de linea
exit:
    int 0x20                      ; finalizamos el programa
; funcion para convertir string a entero de 16 bits
convert:
    push si                       ; respaldamos si
    push di                       ; respaldamos di
    push ax                       ; respaldamos ax
    push cx                       ; respaldamos cx
    xor cx, cx                    ; limpiamos cx
    lea di, numero                ; cargamos la direccion del numero final en di
convert_start:
    dec si                        ; si--
    cmp si, cadenaInicio          ; comparamos si con la direccion de la cadena
    jz convert_finish             ; si si == cadenaInicio brincamos a convert_finish
    cmp [si], 0x00                ; comparamos el valor de [si] con 0x00
    jz convert_start              ; si [si] == 0x00 brincamos a convert_start para seguir leyendo
    mov al, [si]                  ; guardamos el valor de [si] en al
convert_tohex:
    cmp cl, 0x01                  ; comparamos cl con 0x01
    jz convert_second             ; si cl == 0x01 brincamos a convert_second
    call charToHex                ; al = (int)al
    mov cl, 0x01                  ; cl = 0x01
    mov ch, al                    ; ch = al
    jmp convert_start             ; brincamos a convert_start para leer otro caracter
convert_second:
    call charToHex                ; llamamos a charToHex (al debe ser el caracter a convertir)
    mov cl, 0x00                  ; cl = 0x00
    rol al, 0x04                  ; rotamos 4 bits a la izquierda
    add ch, al                    ; ch = ch + al
convert_write:
    mov [di], ch                  ; [di] = ch
    inc di                        ; di++
    cmp cl, 0x01                  ; comparamos cl con 0x01
    jz convert_exit               ; si no hay mas numeros brincamos a convert_exit
    jmp convert_start             ; brincamos a convert_start
convert_finish:
    cmp cl, 0x01                  ; comparamos cl con 0x01
    jz convert_write              ; si cl == 0x01 brincamos a convert_write
convert_exit:
    pop cx                        ; recuperamos cx
    pop ax                        ; recuperamos ax
    pop di                        ; recuperamos di
    pop si                        ; recuperamos si
    ret                           ; volvemos al codigo principal
; convertir caracter a entero de 4 bits
charToHex:
    sub al, 0x30                  ; al = al - 0x30
    cmp al, 0x09                  ; comparamos al con 0x09
    jle charToHex_finish          ; si es menor o igual ya terminamos
    sub al, 0x07                  ; al = al - 0x07
    cmp al, 0x0f                  ; comparamos al con 0x0f
    jle charToHex_finish          ; si es menor o igual ya terminamos
    sub al, 0x20                  ; al = al - 0x20
charToHex_finish:
    ret                           ; vovlemos al codigo principal
; imprimir numero
numToBCD:
    push bx                       ; respaldar bx
    push dx                       ; respaldar dx
    mov bx, 0x000a                ; bx = 10
numToBCD_start:
    xor dx, dx                    ; limpiar dx
    div bx                        ; ax / bx, dx % bx
    add dl, 0x30                  ; dl + 0x30
    mov [di], dl                  ; [di] = dl
    dec di                        ; di--
    cmp al, 0x00                  ; comparar al con 0
    jne numToBCD_start            ; si no es 0, brincamos a numToBCD_start
    pop dx                        ; recuperar dx
    pop bx                        ; recuperar bx
    ret                           ; volver al codigo principal
; imprimir salto de linea
newLine:
    mov ah, 0x0e                  ; opcion teletype
    mov al, 0x0d                  ; retorno de carro
    int 0x10                      ; ejecutar interrupcion
    mov al, 0x0a                  ; salto de linea
    int 0x10                      ; ejecutar interrupcion
    ret                           ; volver al coigo anterior
; imprimir string
print:
    push ax                       ; respaldar ax
    push bx                       ; respaldar bx
    push cx                       ; respaldar cx
    mov ah, 0x03                  ; opcion 0x03 para conseguir posicion de cursor (en dx)
    mov bh, 0x00                  ; pagina 0
    int 0x10                      ; interrupcion 0x10
    pop cx                        ; recuperamos cx ya que cambio con la interrupcion anterior
    push cx                       ; volvemos a respaldarlo
    mov ah, 0x13                  ; opcion 0x13 para imprimir cadena
    mov al, 1                     ; atributos
    mov bh, 0x00                  ; pagina
    mov bl, 0x0f                  ; fondo negro y texto blanca
    int 0x10                      ; interrupcion 0x10
    pop cx                        ; recuperar cx
    pop bx                        ; recuperar bx
    pop ax                        ; recuperar ax
    ret                           ; volver al codigo
; imprimir con salto de linea
printn:
    call print                    ; imprimir texto
    call newLine                  ; imprimir salto de linea
    ret                           ; volver al codigo