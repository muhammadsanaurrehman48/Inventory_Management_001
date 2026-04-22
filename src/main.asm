;=====================================================
; main.asm - Core Loop
;=====================================================
INCLUDE Irvine32.inc

; Match prototypes
showMenu PROTO C
EXTERN LoadData : PROC
EXTERN SaveData : PROC

.data
msgGoodbye BYTE 0Dh,0Ah,\
    "  ========================================",0Dh,0Ah,\
    "     Thank you for using IMS. Goodbye!   ",0Dh,0Ah,\
    "  ========================================",0Dh,0Ah,0
    
.code
main PROC

    ; ---- 1. LOAD PREVIOUS DATA ON STARTUP ----
    call LoadData

mainLoop:
    call showMenu
    call Crlf
    cmp  eax, 1
    je   mainExit
    jmp  mainLoop

mainExit:
    ; ---- 2. SAVE DATA BEFORE QUITTING ----
    call SaveData
    
    mov  edx, OFFSET msgGoodbye
    call WriteString
    call Crlf
    exit

main ENDP

END main