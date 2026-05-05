;=====================================================
; sales.asm - Updates Inventory AND Sales Tracker
;=====================================================
INCLUDE Irvine32.inc

EXTERN itemCount  : DWORD
EXTERN itemIDs    : DWORD
EXTERN itemQty    : DWORD
EXTERN itemPrice  : DWORD
EXTERN itemSold   : DWORD  ; <--- Import new array

EXTERN msgSaleHeader   : BYTE
EXTERN msgSaleEnterID  : BYTE
EXTERN msgSaleEnterQty : BYTE
EXTERN msgSaleNotFound : BYTE
EXTERN msgSaleNoStock  : BYTE
EXTERN msgSaleOK       : BYTE
EXTERN msgSaleTotal    : BYTE

PUBLIC RecordSale

.code

RecordSale PROC C
    pushad

    mov  edx, OFFSET msgSaleHeader
    call WriteString

    mov  edx, OFFSET msgSaleEnterID
    call WriteString
    call ReadInt
    mov  ebx, eax           

    xor  esi, esi
RS_Search:
    cmp  esi, itemCount
    jge  RS_NotFound
    mov  eax, itemIDs[esi*4]
    cmp  eax, ebx
    je   RS_Found
    inc  esi
    jmp  RS_Search

RS_NotFound:
    mov  edx, OFFSET msgSaleNotFound
    call WriteString
    jmp  RS_Done

RS_Found:
    mov  edx, OFFSET msgSaleEnterQty
    call WriteString
    call ReadInt
    mov  ecx, eax           

    mov  eax, itemQty[esi*4]
    cmp  eax, ecx
    jl   RS_NoStock

    ; ---- The Math Updates ----
    sub  itemQty[esi*4], ecx         ; 1. Deduct from Inventory
    mov  eax, itemSold[esi*4]
    add  eax, ecx
    mov  itemSold[esi*4], eax        ; 2. Add to Sales Tracker

    mov  edx, OFFSET msgSaleOK
    call WriteString

    mov  edx, OFFSET msgSaleTotal
    call WriteString
    mov  eax, itemPrice[esi*4]
    mul  ecx                
    call WriteDec
    call Crlf
    jmp  RS_Done

RS_NoStock:
    mov  edx, OFFSET msgSaleNoStock
    call WriteString

RS_Done:
    popad
    ret
RecordSale ENDP

END