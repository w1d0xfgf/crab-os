#include "types.h"
#include "keyboard.h"
#include "vga.h"
#include "cmos.h"
#include "shell.h"
#include "mouse.h"
#include "print.h"
#include "cmos.h"
#include "kbc.h"
#include "pit.h"
#include "speaker.h"
#include "utils.h"

// Таблицы для перевода сканкодов в CP437 символы

static u8 scancode_to_cp437[256] = {
	0,    0,    '1',  '2',  '3',  '4',  '5',  '6',
	'7',  '8',  '9',  '0',  '-',  '=',  0,    0,
	'q',  'w',  'e',  'r',  't',  'y',  'u',  'i',
	'o',  'p',  '[',  ']',  0,    0,    'a',  's',
	'd',  'f',  'g',  'h',  'j',  'k',  'l',  ';',
	'\'', '`',  0,    '\\', 'z',  'x',  'c',  'v',
	'b',  'n',  'm',  ',',  '.',  '/',  0,    '*',
	0,    ' ',  0,    0,    0,    0,    0,    0,
	0,    0,    0,    0,    0,    0,    0,    '7',
	'8',  '9',  '-',  '4',  '5',  '6',  '+',  '1',
	'2',  '3',  '0',  '.',  0,    0,    0,    0,

	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0
};

static u8 scancode_to_cp437_shift[256] = {
	0,    0,    '!',  '@',  '#',  '$',  '%',  '^',
	'&',  '*',  '(',  ')',  '_',  '+',  0,    0,
	'Q',  'W',  'E',  'R',  'T',  'Y',  'U',  'I',
	'O',  'P',  '{',  '}',  0,    0,    'A',  'S',
	'D',  'F',  'G',  'H',  'J',  'K',  'L',  ':',
	'"',  '~',  0,    '|',  'Z',  'X',  'C',  'V',
	'B',  'N',  'M',  '<',  '>',  '?',  0,    '*',
	0,    ' ',  0,    0,    0,    0,    0,    0,
	0,    0,    0,    0,    0,    0,    0,    '7',
	'8',  '9',  '-',  '4',  '5',  '6',  '+',  '1',
	'2',  '3',  '0',  '.',  0,    0,    0,    0,

	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0
};

// Убрать \r, \n, \0, и пробелы по краям строки
void trim(char* src, char* dest, u32 length) {
	// Найти первый и последний символ который не \r, \n, \0, или пробел
	i32 start = -1;
	i32 end = -1;
	for (i32 i = 0; i < length; i++) {
		char chr = src[i];
		if (!(chr == ' ' || chr == '\r' || chr == '\n' || chr == 0)) {
			start = i;
			break;
		}
	}
	if (start == -1) return;

	for (i32 i = length - 1; i >= 0; i--) {
		char chr = src[i];
		if (!(chr == ' ' || chr == '\r' || chr == '\n' || chr == 0)) {
			end = i;
			break;
		}
	}
	if (end == -1) return;

	// Скопировать найденный участок строки в новую строку
	memcpy(dest, &src[start], end - start + 1);

	// NULL терминация
	if (end < length) dest[end + 1] = 0;
}

// Сравнить строки
bool strcmp(char* str1, char* str2) {
	bool equal = true;

	for (u32 i = 0; ; i++) {
		char chr1 = str1[i];
		char chr2 = str2[i];
		if (chr1 != chr2) {
			equal = false;
			break;
		}
		if (chr1 == 0) {
			break;
		}
	}

	return equal;
}

// Обработать команду
void process_cmd(console_t* con, const char* str, u32 length) {
	// Разделить команду на аргументы
	char buffer[length + 1];

	u32 i = 0;
	u32 j = 0;
	bool in_space = true;

	while (i < length) {
		char c = str[i++];

		if (c == ' ') {
			if (!in_space) {
				buffer[j++] = '\0';
				in_space = true;
			}
		}
		else if (c == '\0') {
			break;
		}
		else
		{
			buffer[j++] = c;
			in_space = false;
		}
	}
	
	if (j > 0 && buffer[j - 1] == '\0') j--;

	buffer[j] = '\0';

	u32 word_count = 0;
	u32 k = 0;

	while (k < j) {
		word_count++;
		while (k < j && buffer[k] != '\0') k++;
		k++;
	}

	if (word_count == 0) return;

	char* words[word_count];

	k = 0;
	u32 w = 0;

	while (k < j) {
		words[w++] = &buffer[k];
		while (k < j && buffer[k] != '\0') k++;
		k++;
	}
	
	// Обработать команду
	console_t con2 = *con;
	con2.attr = VGA_GRAY;
	printf(&con2, "\r\n");

	// Получить имя команды
	char* command = words[0];
	if (strcmp("time", command)) {
		rtc_time_t time = cmos_read_rtc();
		printf(&con2, "Current time: %b:%b:%b %b/%b/%b",
			time.hour, time.minute, time.second, time.day, time.month, time.year
		);
	} else if (strcmp("restart", command)) {
		kbc_cpu_reset();
	} else if (strcmp("beep", command)) {
		if (word_count < 2) {
			printf(&con2, "Usage: beep <time in ms>");
		} else {
			// Сконвертировать текст в число
			u32 time = 0;
			for (u32 i = 0; ; i++) {
				char chr = words[1][i];
				if (chr == 0) break;

				// Если символ 0, 1, 2, 3, 4, 5, 6, 7, 8, или 9
				if (chr >= '0' && chr <= '9') {
					// Сконвертировать в цифру и добавить цифру в число
					time = time * 10 + (chr - '0');
				}
			}
			
			// Включить звук, подождать time миллисекунд, выключить звук
			spkr_set_frequency(500);
			spkr_on();
			pit_sleep_ticks(time * 10);
			spkr_off();
		}
	} else if (strcmp("clear", command)) {
		vga_clear(&con2);
	} else if (strcmp("help", command)) {
		printf(&con2,
			"Available commands:\r\n"
			"beep <time in ms>    | Makes a beep\r\n"
			"time                 | Shows current time and date\r\n"
			"help                 | Shows this list\r\n"
			"restart              | Resets the CPU\r\n"
			"clear                | Clears the screen"
		);
	} else {
		printf(&con2, "Unknown command.");
	}

	// Отобразить на экран и обновить консоль
	vga_flush_buffer();
	vga_update_cursor(&con2);
	con->x = con2.x;
	con->y = con2.y;
}

u32 shell_main(console_t* con) {
	con->attr = VGA_YELLOW;

	printf(con, "----------------\r\n");
	printf(con, " CrabOS v0.1.7  \r\n");
	printf(con, "----------------\r\n");

	con->attr = VGA_GREEN;

	printf(con, "Type `help` for a list of commands\r\n");

	con->attr = VGA_WHITE;

	printf(con, "> ");

	vga_flush_buffer();
	vga_update_cursor(con);

	// Цикл ввода
	char input[128] = {0};
	u32 input_top = 0;
	for (;;) {
		// Получить сканкод
		u16 scancode = kbrd_wait_scancode();
		if (scancode >= 0xFF) continue;

		// Enter
		if (scancode == 0x1C) { 
			// Команда
			char command[sizeof(input)] = {0};

			// Обрезать лишние пробелы, \n, \r
			trim(input, command, input_top);

			// Обработать команду
			process_cmd(con, command, input_top);

			// Сбросить ввод
			input_top = 0;
			memset(input, 0, sizeof(input));

			// Вывести ">"
			printf(con, "\r\n> ");
			vga_flush_buffer();
			vga_update_cursor(con);
		}

		// Backspace
		if (scancode == 0x0E && input_top > 0) { 
			// Затереть символ в input
			input_top--;
			input[input_top] = 0;

			// Затереть символ на экране
			if (con->x > 0) {
				con->x--;
			} else {
				con->y--;
				con->x = 79;
			}

			printf(con, " ");

			if (con->x > 0) {
				con->x--;
			} else {
				con->y--;
				con->x = 79;
			}

			vga_flush_buffer();
			vga_update_cursor(con);
		}

		// Символ
		char chr;
		if (kbrd_get_key_pressed(0x2A) || kbrd_get_key_pressed(0x36)) {
			// Shift
			chr = scancode_to_cp437_shift[scancode];
		} else {
			// Без Shift
			chr = scancode_to_cp437[scancode];
		}
		
		// Напечатать
		if (chr) {
			input[input_top] = chr;
			input_top++;
			printf(con, "%c", chr); 
			vga_flush_buffer();
			vga_update_cursor(con);
		}
	}

	return 0;
}