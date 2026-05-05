;=====================================================
; file.asm - Sales Data integrated into I/O and CSV
;=====================================================
INCLUDE Irvine32.inc

GENERIC_READ          EQU 80000000h
GENERIC_WRITE         EQU 40000000h
CREATE_ALWAYS         EQU 2
OPEN_EXISTING         EQU 3
FILE_ATTRIBUTE_NORMAL EQU 80h
INVALID_HANDLE_VALUE  EQU -1

EXTERN itemCount  : DWORD
EXTERN itemIDs    : DWORD
EXTERN itemQty    : DWORD
EXTERN itemPrice  : DWORD
EXTERN itemSold   : DWORD   ; <--- Import new array
EXTERN itemNames  : BYTE

PUBLIC SaveData, LoadData, ExportCSV

.data
filename     BYTE "data\inventory_data.dat",0
msgLoadOK    BYTE 0Dh,0Ah,"  [OK] Previous inventory data loaded successfully.",0Dh,0Ah,0
msgLoadErr   BYTE 0Dh,0Ah,"  [!] No previous data found. Starting fresh.",0Dh,0Ah,0
msgSaveOK    BYTE 0Dh,0Ah,"  [OK] Inventory data saved safely to disk.",0Dh,0Ah,0
msgSaveErr   BYTE 0Dh,0Ah,"  [!] Error saving data.",0Dh,0Ah,0

csvFilename  BYTE "data\export.csv",0
; ---- Updated Header to include Units Sold ----
csvHeader    BYTE "ID,Item Name,Quantity,Price,Units Sold",0Dh,0Ah
csvHeaderLen EQU $ - csvHeader
commaStr     BYTE ","
crlfStr      BYTE 0Dh,0Ah
msgExportOK  BYTE 0Dh,0Ah,"  [OK] Data exported successfully to data\export.csv!",0Dh,0Ah,0
msgExportErr BYTE 0Dh,0Ah,"  [!] Error exporting CSV. Does the 'data' folder exist?",0Dh,0Ah,0

numBuf       BYTE 12 DUP(0) 
fileHandle   DWORD ?
bytesRw      DWORD ?

.code

IntToStr PROC
    push eax
    push ebx
    push edx
    push edi
    mov edi, OFFSET numBuf
    mov ebx, 10
    xor ecx, ecx        
ITS_DivLoop:
    xor edx, edx
    div ebx
    push edx            
    inc ecx
    test eax, eax
    jnz ITS_DivLoop
    mov ebx, ecx        
ITS_PopLoop:
    pop edx
    add dl, '0'         
    mov [edi], dl
    inc edi
    loop ITS_PopLoop
    mov ecx, ebx        
    pop edi
    pop edx
    pop ebx
    pop eax
    ret
IntToStr ENDP

GetStrLen PROC
    push eax
    push esi
    mov esi, edx
    xor ecx, ecx
GSL_Loop:
    mov al, [esi]
    cmp al, 0
    je GSL_Done
    inc ecx
    inc esi
    jmp GSL_Loop
GSL_Done:
    pop esi
    pop eax
    ret
GetStrLen ENDP

ExportCSV PROC C
    pushad
    INVOKE CreateFileA, OFFSET csvFilename, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je EX_Error
    mov fileHandle, eax
    INVOKE WriteFile, fileHandle, OFFSET csvHeader, csvHeaderLen, OFFSET bytesRw, 0

    xor esi, esi
EX_Loop:
    cmp esi, itemCount
    jge EX_Success

    ; Write ID
    mov eax, itemIDs[esi*4]
    call IntToStr
    INVOKE WriteFile, fileHandle, OFFSET numBuf, ecx, OFFSET bytesRw, 0
    INVOKE WriteFile, fileHandle, OFFSET commaStr, 1, OFFSET bytesRw, 0

    ; Write Name
    mov eax, esi
    mov ebx, 20
    mul ebx
    add eax, OFFSET itemNames
    mov edx, eax
    call GetStrLen
    INVOKE WriteFile, fileHandle, edx, ecx, OFFSET bytesRw, 0
    INVOKE WriteFile, fileHandle, OFFSET commaStr, 1, OFFSET bytesRw, 0

    ; Write Qty
    mov eax, itemQty[esi*4]
    call IntToStr
    INVOKE WriteFile, fileHandle, OFFSET numBuf, ecx, OFFSET bytesRw, 0
    INVOKE WriteFile, fileHandle, OFFSET commaStr, 1, OFFSET bytesRw, 0

    ; Write Price
    mov eax, itemPrice[esi*4]
    call IntToStr
    INVOKE WriteFile, fileHandle, OFFSET numBuf, ecx, OFFSET bytesRw, 0
    INVOKE WriteFile, fileHandle, OFFSET commaStr, 1, OFFSET bytesRw, 0

    ; Write Units Sold (The New Addition!)
    mov eax, itemSold[esi*4]
    call IntToStr
    INVOKE WriteFile, fileHandle, OFFSET numBuf, ecx, OFFSET bytesRw, 0
    INVOKE WriteFile, fileHandle, OFFSET crlfStr, 2, OFFSET bytesRw, 0

    inc esi
    jmp EX_Loop

EX_Success:
    INVOKE CloseHandle, fileHandle
    mov eax, 10
    call SetTextColor
    mov edx, OFFSET msgExportOK
    call WriteString
    jmp EX_Done

EX_Error:
    mov eax, 12
    call SetTextColor
    mov edx, OFFSET msgExportErr
    call WriteString

EX_Done:
    mov eax, 7
    call SetTextColor
    popad
    ret
ExportCSV ENDP

SaveData PROC C
    pushad
    INVOKE CreateFileA, OFFSET filename, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je SD_Error
    mov fileHandle, eax
    INVOKE WriteFile, fileHandle, OFFSET itemCount, 4, OFFSET bytesRw, 0
    INVOKE WriteFile, fileHandle, OFFSET itemIDs, 40, OFFSET bytesRw, 0
    INVOKE WriteFile, fileHandle, OFFSET itemQty, 40, OFFSET bytesRw, 0
    INVOKE WriteFile, fileHandle, OFFSET itemPrice, 40, OFFSET bytesRw, 0
    INVOKE WriteFile, fileHandle, OFFSET itemSold, 40, OFFSET bytesRw, 0 ; <--- Save Sales
    INVOKE WriteFile, fileHandle, OFFSET itemNames, 200, OFFSET bytesRw, 0
    INVOKE CloseHandle, fileHandle
    mov eax, 10
    call SetTextColor
    mov edx, OFFSET msgSaveOK
    call WriteString
    mov eax, 7
    call SetTextColor
    jmp SD_Done
SD_Error:
    mov eax, 12
    call SetTextColor
    mov edx, OFFSET msgSaveErr
    call WriteString
    mov eax, 7
    call SetTextColor
SD_Done:
    popad
    ret
SaveData ENDP

LoadData PROC C
    pushad
    INVOKE CreateFileA, OFFSET filename, GENERIC_READ, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je LD_Error
    mov fileHandle, eax
    INVOKE ReadFile, fileHandle, OFFSET itemCount, 4, OFFSET bytesRw, 0
    INVOKE ReadFile, fileHandle, OFFSET itemIDs, 40, OFFSET bytesRw, 0
    INVOKE ReadFile, fileHandle, OFFSET itemQty, 40, OFFSET bytesRw, 0
    INVOKE ReadFile, fileHandle, OFFSET itemPrice, 40, OFFSET bytesRw, 0
    INVOKE ReadFile, fileHandle, OFFSET itemSold, 40, OFFSET bytesRw, 0  ; <--- Load Sales
    INVOKE ReadFile, fileHandle, OFFSET itemNames, 200, OFFSET bytesRw, 0
    INVOKE CloseHandle, fileHandle
    mov eax, 11
    call SetTextColor
    mov edx, OFFSET msgLoadOK
    call WriteString
    mov eax, 7
    call SetTextColor
    jmp LD_Done
LD_Error:
    mov eax, 14
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