;
; Achievement1.asm
;
; Created: 23.12.2024 21:43:36
; Author : s_chi
;


; Replace with your application code
.include "m8def.inc"   ; ���������� ����������� ��� ATmega8
.def  reg_temp   = r16 ; ���������� ������� reg_temp ��� r16

;--------------------------------------
; ���������
.equ FREQ_CPU      = 1000000      ;������� ���������������� 1 MHz
.equ BAUD_RATE     = 9600         ; �������� �������� ������ ��� USART �� 9600
.equ UBRR_VAL      = (FREQ_CPU/(16*BAUD_RATE))-1  ; ������ �������� ��� �������� UBRR, ��������� ��� ��������� USART

.equ TIMER1_TOP    = 488           ; ������������� �������� ��� TOP ������� 1
.equ TIMER2_TOP    = 244           ; ������������� �������� ��� TOP ������� 2

.cseg
.org 0x0000          ; ������ ���������, ��������� ����� (0x0000)
    rjmp RESET_PROGRAM ; ��������� � ��������� ����� ���������

.org OC2addr         ; ����� ���������� ��� ������� 2
    rjmp ISR_TIMER2  ; ��������� � ����������� ���������� ��� ������� 2
.org OC1Aaddr        ; ����� ���������� ��� ������� 1
    rjmp ISR_TIMER1  ; ��������� � ����������� ���������� ��� ������� 1
RESET_PROGRAM:
    ldi reg_temp, 0x00  ; ��������� � reg_temp �������� 0 (������� ����)
    out DDRB, reg_temp  ; ������������� ��� ���� ����� B ��� ������ (DDRB = 0)
    out DDRC, reg_temp  ; ������������� ��� ���� ����� C ��� ������ (DDRC = 0)
    out DDRD, reg_temp  ; ������������� ��� ���� ����� D ��� ������ (DDRD = 0)

    ldi reg_temp, UBRR_VAL  ; ��������� �������������� ������������ �������� ��� �������� UBRR 
    out UBRRL, reg_temp     ; ���������� ������� ���� � ������� UBRRL
    ldi reg_temp, 0         ; ��������� 0 ��� ������� ��� � ������� UBRRH
    out UBRRH, reg_temp    ; ���������� � ������� UBRRH

    ldi reg_temp, (1<<RXEN)|(1<<TXEN)  ;  ����� � �������� ������ ����� USART (RXEN - �������, TXEN - ����������)
    out UCSRB, reg_temp      ; ���������� � ������� ���������� USART (UCSRB)

    ldi reg_temp, (1<<URSEL)|(3<<UCSZ0)  ; ��������� ������� �����: 8 ��� ������ (UCSZ0)
    out UCSRC, reg_temp      ; ���������� � ������� ���������� USART (UCSRC)

    ; ��������� ������� 1
    ldi reg_temp, high(TIMER1_TOP)  ; ��������� ������� 8 ��� �������� TIMER1_TOP
    out OCR1AH, reg_temp           ; ���������� � ������� ���� �������� OCR1A (������� �������� ������� 1)
    ldi reg_temp, low(TIMER1_TOP)  ; ��������� ������� 8 ��� �������� TIMER1_TOP
    out OCR1AL, reg_temp           ; ���������� � ������� ���� �������� OCR1A (������ �������� ������� 1)
    ldi reg_temp, (1<<WGM12)  ; �������� ����� CTC (Clear Timer on Compare Match) ��� ������� 1
    out TCCR1B, reg_temp      ; ���������� � ������� ���������� �������� 1 (TCCR1B)
    ldi reg_temp, (1<<CS12)|(1<<CS10)  ; ������������� ������������ �� 1024
    out TCCR1B, reg_temp      ; ���������� � ������� ���������� �������� 1

    ldi reg_temp, (1<<OCIE1A)  ; �������� ���������� �� ��������� ��� ������� 1
    out TIMSK, reg_temp       ; ���������� � ������� ����� ���������� (TIMSK)
    ; ��������� ������� 2
    ldi reg_temp, TIMER2_TOP  ; ��������� �������� ��� TOP ������� 2
    out OCR2, reg_temp        ; ���������� �������� � ������� OCR2
    ldi reg_temp, (1<<WGM21)|(1<<CS22)|(1<<CS21)|(1<<CS20)  ; �������� ������ 2 �� CTC � ������������� 1024
    out TCCR2, reg_temp       ; ���������� � ������� ���������� �������� 2
    ; ��������� ���������� ��� ������� 2
    in reg_temp, TIMSK        ; ��������� ������� ��������� ����������
    ori reg_temp, (1<<OCIE2)  ; ������������� ��� ��� ���������� �� ��������� ��� ������� 2
    out TIMSK, reg_temp       ; ���������� ���������� ��������� � TIMSK

    sei  ; ���������� ����������

main_loop:
    rjmp main_loop  ; ��������� � ����������� ���� (�������� �����, ���� ��� ����������)
; �������� ������ ������� ����� USART
send_single_char:
    sbis UCSRA, UDRE  ; ���������, ����� �� ����� �������� (UDRE = 1)
    rjmp send_single_char  ; ���� ���, ���
    out UDR, r24         ; ���������� ������ �� �������� r24 � USART
    ret  ; ������������ �� �������

; �������� ������ ����� USART
send_text_string:
next_character:
    lpm r24, Z+         ; ��������� ��������� ������ �� ������ � r24
    tst r24             ; ���������, �� ����� �� ������ (NULL ������)
    breq end_string     ; ���� ��, ��������� � ����������
    rcall send_single_char  ; ����� ���������� ������
    rjmp next_character  ; ��������� � ���������� �������
end_string:
    ret  ; ��������� �������� ������

msg_ping:
    .db "ping\r\n", 0  ; ������ "ping" � �������� ����� ������

msg_pong:
    .db "pong\r\n", 0  ; ������ "pong" � �������� ����� ������

; ���������� ���������� ��� ������� 1
ISR_TIMER1:
    push r24             ; ��������� ��������� �������� r24
    push r25             ; ��������� ��������� �������� r25
    push ZH              ; ��������� ��������� �������� ����� �������� Z
    push ZL              ; ��������� ��������� �������� ����� �������� Z
    ldi r24, high(msg_ping*2)  ; ��������� ������� ���� ������ ������ msg_ping
    ldi r25, low(msg_ping*2)   ; ��������� ������� ���� ������ ������ msg_ping
    mov ZH, r24          ; ��������� ������� ���� ������ � ������� ZH
    mov ZL, r25          ; ��������� ������� ���� ������ � ������� ZL
    rcall send_text_string  ; �������� ������� ��� �������� ������
    pop ZL               ; ��������������� ������� ���� �������� Z
    pop ZH               ; ��������������� ������� ���� �������� Z
    pop r25              ; ��������������� ������� r25
    pop r24              ; ��������������� ������� r24
    reti                 ; ������������ �� ����������

; ���������� ���������� ��� ������� 2
ISR_TIMER2:
    push r24             ; ��������� ��������� �������� r24
    push r25             ; ��������� ��������� �������� r25
    push ZH              ; ��������� ��������� �������� ����� �������� Z
    push ZL              ; ��������� ��������� �������� ����� �������� Z
    ldi r24, high(msg_pong*2)  ; ��������� ������� ���� ������ ������ msg_pong
    ldi r25, low(msg_pong*2)   ; ��������� ������� ���� ������ ������ msg_pong
    mov ZH, r24          ; ��������� ������� ���� ������ � ������� ZH
    mov ZL, r25          ; ��������� ������� ���� ������ � ������� ZL
    rcall send_text_string  ; �������� ������� ��� �������� ������
    pop ZL               ; ��������������� ������� ���� �������� Z
    pop ZH               ; ��������������� ������� ���� �������� Z
    pop r25              ; ��������������� ������� r25
    pop r24              ; ��������������� ������� r24
    reti                 ; ������������ �� ����������
