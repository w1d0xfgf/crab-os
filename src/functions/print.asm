; ------------------------------------------------------------------
; Функции для печати на экран
; ------------------------------------------------------------------

; Печать строки на экран с \r и \n
;
; Адрес строки: ESI
; Меняет: EAX, EDX, ESI, EDI
println_str:
	call print_str			; Печать
	mov byte [pos_x], 0		; Возврат каретки
	inc byte [pos_y]		; Следующая линия
	
	ret
	
; ------------------------------------------------------------------
	
; Печать reg32 в шестнадцатеричном формате
;
; Меняет: EAX, EBX, ECX, EDX, ESI, EDI
print_reg32_hex:
	; Конвертация
	mov edi, out_str_reg32_hex
	mov eax, [reg32]
	call hex_str_from_eax
	
	; Печать
	mov esi, out_str_reg32_hex
	call print_str	
	
	ret
reg32 dd 0
out_str_reg32_hex db '00000000', 0

; ------------------------------------------------------------------

; Печать reg32 в шестнадцатеричном формате с \r и \n
;
; Адрес строки: ESI
; Меняет: EAX, EBX, ECX, EDX, ESI, EDI
println_reg32_hex:
	call print_reg32_hex	; Печать
	mov byte [pos_x], 0		; Возврат каретки
	inc byte [pos_y]		; Следующая линия
	
	ret
	
; ------------------------------------------------------------------

; Печать reg8 в шестнадцатеричном формате
;
; Меняет: EAX, EBX, ECX, EDX, ESI, EDI
print_reg8_hex:
	; Конвертация
	mov edi, out_str_reg8_hex
	mov al, byte [reg8]
	call hex_str_from_al
	
	; Печать
	mov esi, out_str_reg8_hex
	call print_str			
	
	ret
reg8 db 0
out_str_reg8_hex db '00', 0
	
; ------------------------------------------------------------------

; Печать reg8 в шестнадцатеричном формате с \r и \n
;
; Адрес строки: ESI
; Меняет: EAX, EBX, ECX, EDX, ESI, EDI
println_reg8_hex:
	call print_reg8_hex		; Печать
	mov byte [pos_x], 0		; Возврат каретки
	inc byte [pos_y]		; Следующая линия
	
	ret

; ------------------------------------------------------------------

; Печать reg32 в десятичном формате
; 
; Меняет: EAX, ECX, EDX, ESI, EDI
print_reg32:
	; Конвертация
	mov edi, out_str_reg32
	mov eax, [reg32]
	call str_from_eax
	
	; Печать
	mov esi, out_str_reg32
	call print_str	
	
	ret
out_str_reg32:
	times 10 db ' '
	db 0

; ------------------------------------------------------------------

; Печать reg32 в десятичном формате с \r и \n
; 
; Меняет: EAX, ECX, EDX, ESI, EDI
println_reg32:
	call print_reg32		; Печать
	mov byte [pos_x], 0		; Возврат каретки
	inc byte [pos_y]		; Следующая линия
	
	ret