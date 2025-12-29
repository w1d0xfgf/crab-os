	mov byte [pos_x], 0
	mov byte [pos_y], 2

	; Проверить, доступно ли CPUID
	pushfd
	pop eax
	mov ecx, eax

	xor eax, 1 << 21
	push eax
	popfd

	pushfd
	pop eax

	xor eax, ecx
	and eax, 1 << 21

	jz .not_available

	; Получить строку продавца
	xor eax, eax
	cpuid

	; Копировать строку из EBX, EDX, ECX
	mov esi, vendor_str
	mov dword [esi], ebx
	add esi, 4

	mov dword [esi], edx
	add esi, 4

	mov dword [esi], ecx
	add esi, 4

	; Печать cpu_msg
	mov byte [vga_attr], 0xA0
	mov esi, cpu_msg
	call println_str
	mov byte [vga_attr], 0x07

	; Печать строки продавца
	mov esi, vendor_str_msg
	call print_str
	mov esi, vendor_str
	call println_str

	; Получение и печать Stepping ID
	mov esi, stepping_id_msg
	call print_str
	mov eax, 0x01
	cpuid
	push ax
	and al, 00001111b
	movzx edx, al
	mov [reg32], edx
	call println_reg32

	; Получение и печать модели
	mov esi, model_msg
	call print_str
	pop ax
	and al, 11110000b
	shr al, 4
	movzx edx, al
	mov [reg32], edx
	call println_reg32

	; Получение и печать семьи
	mov esi, family_msg
	call print_str
	and ah, 00001111b
	movzx edx, ah
	mov [reg32], edx
	call println_reg32
	
	; Вывести fpu_msg
	mov esi, fpu_msg
	call print_str
	; Получение информации про FPU
	mov eax, 1
	cpuid
	; Первый бит DL 1 -> FPU есть
	and dl, 00000001b
	test dl, dl
	jz .fpu_not_present
.fpu_present:
	; Вывести yes_msg если FPU есть
	mov byte [vga_attr], 0x02
	mov esi, yes_msg
	call println_str
	jmp .fpu_endif
.fpu_not_present:	
	; Вывести no_msg если FPU нет
	mov byte [vga_attr], 0x04
	mov esi, no_msg
	call println_str
.fpu_endif:
	; Печать mem_msg
	mov byte [vga_attr], 0xC0
	mov esi, mem_msg
	call println_str
	mov byte [vga_attr], 0x07

	; Печать mem_amount_msg
	mov esi, mem_amount_msg
	call print_str
	
	; Печать количества памяти в МБ в десятичном формате
	mov eax, dword [total_ram]
	mov ebx, dword [total_ram + 4]
	shrd eax, ebx, 10
	mov dword [reg32], eax
	call print_reg32
	inc byte [pos_x]

	; 'MB'
	mov al, 'M'
	call print_char
	mov al, 'B'
	call print_char

	jmp .end

.not_available:
	mov byte [vga_attr], 0x04
	mov esi, cpuid_not_available
	call print_str
.end:
	mov byte [vga_attr], 0x07
	ret