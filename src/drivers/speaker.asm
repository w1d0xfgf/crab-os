; ------------------------------------------------------------------
; Драйвер PC Speaker
; ------------------------------------------------------------------

; Воспроизвести звук
;
; Частота: ECX
; Меняет: EAX, DX
play_sound:
	; Настроить PIT канал 2 на правильную частоту
	mov eax, 1193180	; Делитель = 1193180 / Частота в Гц
	mov edx, 0
	div ecx				; Делить
	mov edx, eax		; Сохранить в EDX

	; 0xB6 в порт 0x43
	mov al, 0xB6
	out 0x43, al

	; Нижний байт делителя
	mov al, dl
	out 0x42, al

	; Верхний байт делителя
	shr dx, 8
	mov al, dl
	out 0x42, al

	; Порт 0x61 -> AL
	in al, 0x61
	mov dl, al

	; Если AL != AL | 3 выдать AL | 3 через порт 0x61
	or dl, 3
	cmp al, dl
	jne .not_equal
	jmp .done
.not_equal:
	mov al, dl
	out 0x61, al
.done:
	ret

; ------------------------------------------------------------------

; Остановить звук
;
; Меняет: AL
stop_sound:
	; Порт 0x61 -> AL
	in al, 0x61
	; AL & 0xFC
	and al, 0xFC
	; AL -> Порт 0x61
	out 0x61, al

	ret