;
; BluetoothHidGamepad.asm
;
; Original Author : mit - https://mitxela.com
; Expansion to 12 buttons and tinkering by Shadowtrance


    ldi r16, 1<<PD1         ; UART Tx
    out DDRD, r16           ; Bluetooth RX -> Attiny2313 PD1 TX

    ldi r16, 0              ; Buttons 1-8
    out DDRB, r16           ; PB0 - PB7

    ldi r16, 0              ; Buttons 9 - 10
    out DDRA, r16           ; PA0 - PA1

    ldi r16, $FF            ; Buttons 1-8
    out PORTB, r16          ; PB0 - PB7

    ldi r16, 0b01111101     ; D-pad and Buttons 11 - 12
    out PORTD, r16          ; PD2 - PD5 / PD0 and PD6

    ldi r16, 0b00000011     ; Buttons 9 - 10
    out PORTA, r16          ; PA0 - PA1

    ldi r16, 8              ; UART 115200bps
    out UBRRL, r16
    ldi r16, 0
    out UBRRH, r16
    ldi r16, 1<<U2X
    out UCSRA, r16
    ldi r16, 1<<TXEN
    out UCSRB, r16

main:
    in r17, PINB            ; Buttons 1-8
    com r17

    in r19, PIND            ; D-pad and Buttons 11 - 12

    in r23, PINA            ; Buttons 9 - 10
    com r23
    andi r23, 0b00000011

    sbrs r19, PD0           ; Button 11
    sbr r23, 0b00000100

    sbrs r19, PD6           ; Button 12
    sbr r23, 0b00001000

    andi r19, 0b01111101    ; D-pad and Buttons 11 - 12
    cp r20, r19             ; Only transmit if input state has changed
    cpc r18, r17
    cpc r24, r23
    breq main

    clr r21                 ; X
    clr r22                 ; Y

    sbrs r19, 2             ; Left
    subi r21, 127
    
    sbrs r19, 3             ; Up
    subi r22, 127
    
    sbrs r19, 4             ; Right
    subi r21, -127
    
    sbrs r19, 5             ; Down
    subi r22, -127

    ldi r16, $FD            ; HID raw report descriptor
    rcall sendByte
    ldi r16, $06            ; Length
    rcall sendByte
    
    mov r16, r21            ; Right X Axis
    rcall sendByte

    mov r16, r22            ; Right Y Axis
    rcall sendByte

    ldi r16, $00            ; Left X Axis
    rcall sendByte

    ldi r16, $00            ; Left Y Axis
    rcall sendByte
    
    mov r16, r17            ; First 8 buttons
    rcall sendByte

    mov r16, r23            ; Last 8 buttons
    rcall sendByte


    mov r18, r17            ; Store input states of last transmit
    mov r20, r19
    mov r24, r23

rjmp main


sendByte:
    sbis UCSRA,UDRE
    rjmp sendByte
    out UDR, r16
    ret
