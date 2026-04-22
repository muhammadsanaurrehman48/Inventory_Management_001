;=====================================================
; file.asm - Direct Win32 API File I/O Management
;=====================================================
INCLUDE Irvine32.inc

; --- Windows OS API Constants ---
GENERIC_READ          EQU 80000000h
GENERIC_WRITE         EQU 40000000h
CREATE_ALWAYS         EQU 2
OPEN_EXISTING         EQU 3
FILE_ATTRIBUTE_NORMAL EQU 80h
INVALID_HANDLE_VALUE  EQU -1

; ---- Imports from data.asm ----
EXTERN itemCount  : DWORD
EXTERN itemIDs    : DWORD
EXTERN itemQty    : DWORD
EXTERN itemPrice  : DWORD
EXTERN itemNames  : BYTE

; ---- Exports with C naming convention ----
PUBLIC SaveData, LoadData

.data
filename   BYTE "data\inventory.dat",0
msgLoadOK  BYTE 0Dh,0Ah,"  [OK] Previous inventory data loaded successfully.",0Dh,0Ah,0
msgLoadErr BYTE 0Dh,0Ah,"  [!] No previous data found. Starting with a fresh inventory.",0Dh,0Ah,0
msgSaveOK  BYTE 0Dh,0Ah,"  [OK] Inventory data saved safely to disk.",0Dh,0Ah,0
msgSaveErr BYTE 0Dh,0Ah,"  [!] Error saving data.",0Dh,0Ah,0

fileHandle DWORD ?
bytesRw    DWORD ?   ; Variable to store how many bytes were actually read/written

.code

;=====================================================
; SaveData - Dumps arrays to binary file
;=====================================================
SaveData PROC C
    pushad
    
    ; Ask Windows to Create/Overwrite the file
    INVOKE CreateFileA, OFFSET filename, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je SD_Error
    mov fileHandle, eax

    ; 1. Write itemCount (4 bytes)
    INVOKE WriteFile, fileHandle, OFFSET itemCount, 4, OFFSET bytesRw, 0
    
    ; 2. Write itemIDs array (10 items * 4 bytes = 40)
    INVOKE WriteFile, fileHandle, OFFSET itemIDs, 40, OFFSET bytesRw, 0
    
    ; 3. Write itemQty array (40 bytes)
    INVOKE WriteFile, fileHandle, OFFSET itemQty, 40, OFFSET bytesRw, 0
    
    ; 4. Write itemPrice array (40 bytes)
    INVOKE WriteFile, fileHandle, OFFSET itemPrice, 40, OFFSET bytesRw, 0
    
    ; 5. Write itemNames array (10 items * 20 bytes = 200)
    INVOKE WriteFile, fileHandle, OFFSET itemNames, 200, OFFSET bytesRw, 0

    ; Close file handle
    INVOKE CloseHandle, fileHandle

    ; Print Success Message
    mov eax, 10            ; Light Green
    call SetTextColor
    mov edx, OFFSET msgSaveOK
    call WriteString
    mov eax, 7             ; Back to Light Gray
    call SetTextColor
    jmp SD_Done

SD_Error:
    mov eax, 12            ; Light Red
    call SetTextColor
    mov edx, OFFSET msgSaveErr
    call WriteString
    mov eax, 7
    call SetTextColor

SD_Done:
    popad
    ret
SaveData ENDP

;=====================================================
; LoadData - Reads binary file into arrays
;=====================================================
LoadData PROC C
    pushad
    
    ; Ask Windows to Open the existing file
    INVOKE CreateFileA, OFFSET filename, GENERIC_READ, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je LD_Error
    mov fileHandle, eax

    ; 1. Read itemCount
    INVOKE ReadFile, fileHandle, OFFSET itemCount, 4, OFFSET bytesRw, 0
    
    ; 2. Read itemIDs
    INVOKE ReadFile, fileHandle, OFFSET itemIDs, 40, OFFSET bytesRw, 0
    
    ; 3. Read itemQty
    INVOKE ReadFile, fileHandle, OFFSET itemQty, 40, OFFSET bytesRw, 0
    
    ; 4. Read itemPrice
    INVOKE ReadFile, fileHandle, OFFSET itemPrice, 40, OFFSET bytesRw, 0
    
    ; 5. Read itemNames
    INVOKE ReadFile, fileHandle, OFFSET itemNames, 200, OFFSET bytesRw, 0

    ; Close file handle
    INVOKE CloseHandle, fileHandle

    ; Print Success Message
    mov eax, 11            ; Light Cyan
    call SetTextColor
    mov edx, OFFSET msgLoadOK
    call WriteString
    mov eax, 7
    call SetTextColor
    jmp LD_Done

LD_Error:
    ; Print "No Data Found" Message (First time running)
    mov eax, 14            ; Yellow
    call SetTextColor
    mov edx, OFFSET msgLoadErr
    call WriteString
    mov eax, 7
    call SetTextColor

LD_Done:
    popad
    ret
LoadData ENDP

END