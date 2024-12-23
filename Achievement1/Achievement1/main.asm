;
; Achievement1.asm
;
; Created: 23.12.2024 21:43:36
; Author : s_chi
;


; Replace with your application code
; Проект для ATmega8
;======================================
; Пример (Assembler для Atmega8)
; С разделёнными векторами прерываний
; =====================================
.include "m8def.inc"   ; Подключаем определения для ATmega8

.def  reg_temp   = r16

;--------------------------------------
; Константы
.equ FREQ_CPU      = 1000000      ; Частота (1 MHz)
.equ BAUD_RATE     = 9600
.equ UBRR_VAL      = (FREQ_CPU/(16*BAUD_RATE))-1

.equ TIMER1_TOP    = 488
.equ TIMER2_TOP    = 244

.cseg

.org 0x0000
    rjmp RESET_PROGRAM

.org OC2addr
    rjmp ISR_TIMER2

.org OC1Aaddr
    rjmp ISR_TIMER1

RESET_PROGRAM:
    ldi reg_temp, 0x00
    out DDRB, reg_temp
    out DDRC, reg_temp
    out DDRD, reg_temp

    ldi reg_temp, UBRR_VAL
    out UBRRL, reg_temp
    ldi reg_temp, 0
    out UBRRH, reg_temp
    ldi reg_temp, (1<<RXEN)|(1<<TXEN)
    out UCSRB, reg_temp
    ldi reg_temp, (1<<URSEL)|(3<<UCSZ0)
    out UCSRC, reg_temp

    ldi reg_temp, high(TIMER1_TOP)
    out OCR1AH, reg_temp
    ldi reg_temp, low(TIMER1_TOP)
    out OCR1AL, reg_temp

    ldi reg_temp, (1<<WGM12)
    out TCCR1B, reg_temp
    ldi reg_temp, (1<<CS12)|(1<<CS10)
    out TCCR1B, reg_temp

    ldi reg_temp, (1<<OCIE1A)
    out TIMSK, reg_temp

    ldi reg_temp, TIMER2_TOP
    out OCR2, reg_temp
    ldi reg_temp, (1<<WGM21)|(1<<CS22)|(1<<CS21)|(1<<CS20)
    out TCCR2, reg_temp
    in reg_temp, TIMSK
    ori reg_temp, (1<<OCIE2)
    out TIMSK, reg_temp

    sei

main_loop:

    rjmp main_loop

send_single_char:
    sbis UCSRA, UDRE
    rjmp send_single_char
    out UDR, r24            
    ret

send_text_string:
next_character:
    lpm r24, Z+
    tst r24
    breq end_string
    rcall send_single_char
    rjmp next_character
end_string:
    ret

msg_ping:
    .db "ping\r\n", 0

msg_pong:
    .db "pong\r\n", 0


ISR_TIMER1:
    push r24
    push r25
    push ZH
    push ZL
    ldi r24, high(msg_ping*2)
    ldi r25, low(msg_ping*2)
    mov ZH, r24
    mov ZL, r25
    rcall send_text_string
    pop ZL
    pop ZH
    pop r25
    pop r24
    reti


ISR_TIMER2:
    push r24
    push r25
    push ZH
    push ZL
    ldi r24, high(msg_pong*2)
    ldi r25, low(msg_pong*2)
    mov ZH, r24
    mov ZL, r25
    rcall send_text_string
    pop ZL
    pop ZH
    pop r25
    pop r24
    reti
