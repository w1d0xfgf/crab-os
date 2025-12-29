	; Скрыть курсор
	mov ah, 00010000b
	call set_cursor
	
	; Сбросить значения
	mov byte [p1_paddle_pos], 12
	mov byte [p2_paddle_pos], 12
	mov byte [p1_paddle_pos_prev], 12
	mov byte [p2_paddle_pos_prev], 12
	mov byte [ball_pos_x], 30
	mov byte [ball_pos_y], 10
	mov byte [ball_pos_x_prev], 30
	mov byte [ball_pos_y_prev], 10
	mov byte [ball_dir], 0
	mov dword [last_update_ticks], 0

	; Очистить экран
	call clear_screen
	
	; Цикл обновлений
.update:
	; Подождать 900 тиков PIT
	hlt
	cli
	mov eax, [pit_ticks]
	sti
	sub eax, [last_update_ticks]
	cmp eax, 900
	jb .skip
	cli
	mov edx, [pit_ticks]
	sti
	mov [last_update_ticks], edx

	; Если нажат Escape выйти
	cmp byte [keys_pressed + 0x01], 1
	je .return

	; Очистить очередь нажатий
	mov byte [key_queue_top], 0

	; Когда клавиши вверх/вниз нажаты перемещать ракетку игрока 1
	cmp byte [keys_pressed + (0x48 | 0x80)], 1
	je .p1_up
	cmp byte [keys_pressed + (0x50 | 0x80)], 1
	je .p1_down
	jmp .p1_done
.p1_up:
	cmp byte [p1_paddle_pos], 2
	jbe .p1_done
	dec byte [p1_paddle_pos]
	jmp .p1_done
.p1_down:
	cmp byte [p1_paddle_pos], 22
	jae .p1_done
	inc byte [p1_paddle_pos]
.p1_done:

	; Когда клавиши W/S нажаты перемещать ракетку игрока 2
	cmp byte [keys_pressed + 0x11], 1
	je .p2_up
	cmp byte [keys_pressed + 0x1F], 1
	je .p2_down
	jmp .p2_done
.p2_up:
	; Переместить вверх
	cmp byte [p2_paddle_pos], 2
	jbe .p2_done
	dec byte [p2_paddle_pos]
	jmp .p2_done
.p2_down:
	; Переместить вниз
	cmp byte [p2_paddle_pos], 22
	jae .p2_done
	inc byte [p2_paddle_pos]
.p2_done:

	; Переместить мячик
	cmp byte [ball_dir], 0
	je .ball_move_0
	cmp byte [ball_dir], 1
	je .ball_move_1
	cmp byte [ball_dir], 2
	je .ball_move_2
	cmp byte [ball_dir], 3
	je .ball_move_3
.ball_move_0:
	; Влево вверх
	dec byte [ball_pos_x]
	dec byte [ball_pos_y]
	jmp .ball_move_done
.ball_move_1:
	; Вправо вверх
	inc byte [ball_pos_x]
	dec byte [ball_pos_y]
	jmp .ball_move_done
.ball_move_2:
	; Влево вниз
	dec byte [ball_pos_x]
	inc byte [ball_pos_y]
	jmp .ball_move_done
.ball_move_3:
	; Вправо вниз
	inc byte [ball_pos_x]
	inc byte [ball_pos_y]
	jmp .ball_move_done
.ball_move_done:

	; Коллизия мячика с ракеткой игрока 1
	; Мячик перед ракеткой?
	cmp byte [ball_pos_x], 6
	jne .ball_p1_collision_endif
	; Мячик не выше ракетки?
	mov al, [p1_paddle_pos]
	dec al
	cmp byte [ball_pos_y], al
	jb .ball_p1_collision_endif
	; Мячик не ниже ракетки?
	add al, 3
	cmp byte [ball_pos_y], al
	ja .ball_p1_collision_endif
.ball_p1_collision_if:
	call .ball_left_collide
.ball_p1_collision_endif:

	; Коллизия мячика с ракеткой игрока 2
	; Мячик перед ракеткой?
	cmp byte [ball_pos_x], 73
	jne .ball_p2_collision_endif
	; Мячик не выше ракетки?
	mov al, [p2_paddle_pos]
	dec al
	cmp byte [ball_pos_y], al
	jb .ball_p2_collision_endif
	; Мячик не ниже ракетки?
	add al, 3
	cmp byte [ball_pos_y], al
	ja .ball_p2_collision_endif
.ball_p2_collision_if:
	call .ball_right_collide
.ball_p2_collision_endif:

	; Коллизия мячика с верхней стеной
	cmp byte [ball_pos_y], 0
	jne .ball_up_collision_endif
.ball_up_collision_if:
	call .ball_up_collide
.ball_up_collision_endif:

	; Коллизия мячика с нижней стеной
	cmp byte [ball_pos_y], 24
	jne .ball_down_collision_endif
.ball_down_collision_if:
	call .ball_down_collide
.ball_down_collision_endif:

	; Коллизия мячика с правой стеной
	cmp byte [ball_pos_x], 79
	jne .ball_right_collision_endif
.ball_right_collision_if:
	call .ball_right_collide
.ball_right_collision_endif:

	; Коллизия мячика с левой стеной
	cmp byte [ball_pos_x], 0
	jne .ball_left_collision_endif
.ball_left_collision_if:
	call .ball_left_collide
.ball_left_collision_endif:

	; Затереть предыдущую отрисовку ракетки игрока 1

	; Позиция
	mov byte [pos_x], 5
	mov al, [p1_paddle_pos_prev]
	mov byte [pos_y], al

	; Затереть символом пробела
	mov al, ' '

	; Печать верхнего символа
	dec byte [pos_y]
	call print_char
	dec byte [pos_x]
	; Печать среднего символа
	inc byte [pos_y]
	call print_char
	dec byte [pos_x]
	; Печать нижнего символа
	inc byte [pos_y]
	call print_char

	; Отрисовать ракетку игрока 1

	; Позиция
	mov byte [pos_x], 5
	mov al, [p1_paddle_pos]
	mov byte [pos_y], al

	; Символ "█" (код в CP437 это 0xDB)
	mov al, 0xDB

	; Печать верхнего символа
	dec byte [pos_y]
	call print_char
	dec byte [pos_x]
	; Печать среднего символа
	inc byte [pos_y]
	call print_char
	dec byte [pos_x]
	; Печать нижнего символа
	inc byte [pos_y]
	call print_char

	; Затереть предыдущую отрисовку ракетки игрока 2

	; Позиция
	mov byte [pos_x], 74
	mov al, [p2_paddle_pos_prev]
	mov byte [pos_y], al

	; Затереть символом пробела
	mov al, ' '

	; Печать верхнего символа
	dec byte [pos_y]
	call print_char
	dec byte [pos_x]
	; Печать среднего символа
	inc byte [pos_y]
	call print_char
	dec byte [pos_x]
	; Печать нижнего символа
	inc byte [pos_y]
	call print_char

	; Отрисовать ракетку игрока 2

	; Позиция
	mov byte [pos_x], 74
	mov al, [p2_paddle_pos]
	mov byte [pos_y], al

	; Символ "█" (код в CP437 это 0xDB)
	mov al, 0xDB

	; Печать верхнего символа
	dec byte [pos_y]
	call print_char
	dec byte [pos_x]
	; Печать среднего символа
	inc byte [pos_y]
	call print_char
	dec byte [pos_x]
	; Печать нижнего символа
	inc byte [pos_y]
	call print_char

	; Затереть предыдущую отрисовку мячика

	; Позиция по X
	mov al, [ball_pos_x_prev]
	mov byte [pos_x], al
	
	; Позиция по Y
	mov al, [ball_pos_y_prev]
	mov byte [pos_y], al

	; Затереть символом пробела
	mov al, ' '
	call print_char

	; Отрисовать мячик

	; Позиция по X
	mov al, [ball_pos_x]
	mov byte [pos_x], al
	
	; Позиция по Y
	mov al, [ball_pos_y]
	mov byte [pos_y], al

	; Символ маленького квадрата (код в CP437 это 0xFE)
	mov al, 0xFE
	call print_char

	; Отобразить
	call flush_buffer

	; Проверить выиграл ли игрок 1
	cmp byte [ball_pos_x], 79
	je .end_p1

	; Проверить выиграл ли игрок 2
	cmp byte [ball_pos_x], 0
	je .end_p2

	; Обновить предыдущие позиции

	mov al, [ball_pos_x]
	mov [ball_pos_x_prev], al
	mov al, [ball_pos_y]
	mov [ball_pos_y_prev], al

	mov al, [p1_paddle_pos]
	mov [p1_paddle_pos_prev], al
	mov al, [p2_paddle_pos]
	mov [p2_paddle_pos_prev], al
.skip:
	jmp .update

.end_p1:
	; Вывести p1_won_msg на экран
	mov byte [pos_x], 29
	mov byte [pos_y], 8
	mov esi, p1_won_msg
	call print_str
	jmp .end
.end_p2:
	; Вывести p2_won_msg на экран
	mov byte [pos_x], 29
	mov byte [pos_y], 8
	mov esi, p2_won_msg
	call print_str
.end:
	; Очистить очередь нажатий
	mov byte [key_queue_top], 0

	; Вывести key_press_msg на экран
	mov byte [pos_x], 28
	mov byte [pos_y], 10
	mov esi, key_press_msg
	call print_str

	; Подождать нажатие клавиши и после нажатия очистить очередь
	call wait_key
	mov byte [key_queue_top], 0	
.return:
	; Вернуть курсор
	mov ah, 00000000b
	call set_cursor

	; Вернуть GUI 
	call init_gui

	ret

.ball_up_collide:
	; Если мячик движется влево
	cmp byte [ball_dir], 0
	je .ball_up_collide_left

	; Если мячик движется вправо
	cmp byte [ball_dir], 1 
	je .ball_up_collide_right

	; Если мячик движется от стены (вниз) пропустить
	jmp .ball_up_collide_done
.ball_up_collide_left:
	; Влево вниз 
	mov byte [ball_dir], 2
	jmp .ball_up_collide_done
.ball_up_collide_right:
	; Вправо вниз	
	mov byte [ball_dir], 3
.ball_up_collide_done:
	ret

.ball_down_collide:
	; Если мячик движется влево
	cmp byte [ball_dir], 2
	je .ball_down_collide_left

	; Если мячик движется вправо
	cmp byte [ball_dir], 3
	je .ball_down_collide_right

	; Если мячик движется от стены (вверх) пропустить
	jmp .ball_down_collide_done
.ball_down_collide_left:
	; Влево вверх
	mov byte [ball_dir], 0
	jmp .ball_down_collide_done
.ball_down_collide_right:
	; Вправо вверх
	mov byte [ball_dir], 1
.ball_down_collide_done:
	ret

.ball_right_collide:
	; Если мячик движется вверх
	cmp byte [ball_dir], 1
	je .ball_right_collide_up

	; Если мячик движется вниз
	cmp byte [ball_dir], 3
	je .ball_right_collide_down

	; Если мячик движется от стены (влево) пропустить
	jmp .ball_down_collide_done
.ball_right_collide_up:
	; Ввлево вверх
	mov byte [ball_dir], 0
	jmp .ball_right_collide_done
.ball_right_collide_down:
	; Влево вниз
	mov byte [ball_dir], 2
.ball_right_collide_done:
	ret

.ball_left_collide:
	; Если мячик движется вверх
	cmp byte [ball_dir], 0
	je .ball_left_collide_up

	; Если мячик движется вниз
	cmp byte [ball_dir], 2
	je .ball_left_collide_down

	; Если мячик движется от стены (влево) пропустить
	jmp .ball_left_collide_done
.ball_left_collide_up:
	; Ввлево вверх
	mov byte [ball_dir], 1
	jmp .ball_left_collide_done
.ball_left_collide_down:
	; Влево вниз
	mov byte [ball_dir], 3
.ball_left_collide_done:
	ret