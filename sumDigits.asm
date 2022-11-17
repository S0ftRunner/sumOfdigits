ZERO_ASCII EQU 0x30 ; Определяем константу ZERO_ASCII. Она будет равна 0x30('0')

NINE_ASCII EQU 0x39 ; Определяем константу NINE_ASCII. Она будет равна 0x39('9')

STD_INPUT_HANDLE EQU -10
STD_OUTPUT_HANDLE EQU -11

lpReserved EQU 0

EXIT_CODE EQU 0

extern GetStdHandle ; GetStdHandle извлекает дескриптор для стандартного ввода данных, стандартного вывода или стандартной ошибки устройств

extern WriteConsoleA ; WriteConsoleA функция, которая выводит сообщение в консоль

extern ExitProcess ; ExitProcess завершает текущий процесс

extern ReadConsoleA ; ReadConsoleA читает введеную строку и записывает в указанный буфер

section .txt
	global _start
	
_start:
	push STD_OUTPUT_HANDLE ; Передаем аргумент для функции GetStdHandle, который вернет нам то, что ожидается вывод
	call GetStdHandle
	mov ebx, eax ; Перемещаем в ebx результат GetStdHandle
	
	; BOOL WriteConsoleA(
	; HANDLE hConsoleOutput, // дескриптор экранного буфера
	; CONST VOID lpBuffer, // буфер записи
	; DWORD nNumberOfCharWritten, // число записанных символов
	; LPVOID lpReserved // зарезервированно
	; )
	
	push lpReserved ; передаем последний аргумент в WriteConsoleA
	push 0 ; Передаем предпоследний аргумент в WriteConsoleA
	push message_len ; Передаем третий аргумент nNumberOfCharWritten
	push message ; Передаем второй аргумент 
	push ebx ; Передаем первый аргумент hConsoleOutput
	call WriteConsoleA
	
	push STD_INPUT_HANDLE ; Передаем аргумент для функции GetStdHandle, который понимает, что надо извлечь дескприптор для чтения
	call GetStdHandle
	
	; BOOL ReadConsole(
	; HANDLE _hConsoleInput, // дескриптор буфера ввода консоли
	; LPVOID _lpBuffer_, // буфер данных
	; DWORD _nNumberOfCharsToRead_, // число символов для чтения
	; LPDWORD _lpNumberOfCharsRead_, // указатель на число прочитанных символов
	; LPVOID _lpReserved_, // зарезервированно 
	; )
	
	push lpReserved ; Передаем последний аргумент в ReadConsole
	push read ; Передаем предпоследний аргумент
	push 10 ; Передаем третий аргумент, который ожидает, что будет записано десять чисел
	push BUF ; Передаем второй аргумент
	push eax ; Передаем первый аргумент
	; Когда все аргументы переданы, то теперь можем вызвать функцию для чтения
	call ReadConsoleA
	
	mov ecx, -1 ; Перемещаем в ecx число -1. Это будет наш счетчик в my_atoi
	jmp my_atoi
	
my_atoi: ; Выполняем отсев чисел, которые ниже 0x30. Также из нее можно попасть в to_decimal, если введенных чисел больше не осталось
	xor eax, eax ; Обнуляем eax
	inc ecx ; увеличиваем ecx на 1
	mov ebx, BUF ; Перемещаем в ebx адрес BUF
	mov al, [ebx + ecx] ; Перемещаем в al значение из ячейки памяти по адресу ebx+ecx(BUF+ecx). Это значение - это один из введенных нами символов
	cmp eax, ZERO_ASCII ; сравниваем код введенного символа в al с 0x30 
	jae check_below ; Переходим в check_below, если код введенного символа больше или равен 0x30
	cmp eax, 0 ; Еслим в eax 0, то все числа закончились
	jz to_decimal ; Переходим в to_decimal
	jmp exit ; Если не перешли в to_decimal, то выходим из программы
	
to_decimal: ; выводит результат сложения чисел
	mov ax, [RES]
	mov dl, 10
	div dl ; Делим ax на dl. Частное будет сохранено в al, а остаток в ah
	cmp al, 0 ; Сравниваем частное в al с нулем
	jz print_whole
	
	add ah, 0x30 ; Добавляем к остатку число 0x30, результат будет равен ASCII символу
	add al, 0x30 ; Аналогично, только работаем с частным
	mov [to_print], al ; Перемещаем в ячейку памяти ASCII символа
	mov [to_print + 1], ah ; Перемещаем код ASCII
	mov [to_print + 2], byte 0xA ; Перемещаем код символа новой строки - \n
	
	push STD_OUTPUT_HANDLE
	call GetStdHandle
	mov ebx, eax ; Перемещаем в ebx результат дескриптора
	
	push lpReserved ; Передаем последний аргумент
	push 0 ; Передаем предпоследний аргумент
	push 3 ; Передаем третий аргумент в nNumberOfChasToWrite. 3 - это длина to_print в байтах
	push to_print ; Передаем второй аргумент
	push ebx ; Передаем первый аргумент 
	call WriteConsoleA
	
	jmp exit;
	
print_whole: ; Выводит результат в промежутке от [0;9] из RES
	add ah, 0x30 ; Преобразование в ASCII для вывода на экран
	mov [to_print], ah
	mov [to_print + 1], byte 0xA
	push STD_OUTPUT_HANDLE
	call GetStdHandle
	mov ebx, eax
	push lpReserved
	push 0
	push 3
	push to_print
	push ebx
	call WriteConsoleA
	jmp exit

check_below: ; отсеивает числа, которые больше 9
	cmp eax, NINE_ASCII
	jbe to_int ; Если число в eax <=9, то переходим в to_int
	
exit:
	push EXIT_CODE
	call ExitProcess
	
to_int:
	sub eax, 0x30
	add [RES], eax 
	jmp my_atoi
	
section .data
	message db 'Enter a 10 digit number. We will calculate the sum of its digits. If you write something other than numbers, the program will not calculate anything.', 0xA
	message_len EQU $-message
	BUF db 0,0,0,0,0,0,0,0,0,0,0,0 ; Определяем массив BUF, состоящий из 12 байт(10 байт - для наших цифр, 11- й байт для 0x0, а 12 - й просто навсякий случай:)). Он нужен для записи введенной строки с символами
	RES db 0 ; Хранит сумму введенных чисел
	to_print db 0,0,0 ; Опредеяем to_print размером 3 байт. В ней будет храниться строка для вывода с результатом из RES
	read db 0 ; Она хранит количество символов, которое было прочитано программой до выхова ReadConsole
