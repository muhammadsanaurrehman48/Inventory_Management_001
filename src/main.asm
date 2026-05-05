;=====================================================
; main.asm - Cleaned Entry Point
;=====================================================
INCLUDE Irvine32.inc

; Use standard EXTERN instead of PROTO to prevent Linker clashes
EXTERN showMenu : PROC
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
    call SaveData
    mov  edx, OFFSET msgGoodbye
    call WriteString
    call Crlf
    
    call WaitMsg  ; <--- Adds "Press any key to continue..." before closing
    exit

main ENDP

END main  ; <-- CRITICAL: This tells the linker where the program starts!