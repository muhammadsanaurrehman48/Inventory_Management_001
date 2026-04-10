;=====================================================
; sales.asm
; RecordSale — search by ID, validate stock,
; deduct qty, print total.
;=====================================================
INCLUDE Irvine32.inc

EXTERN itemCount  : DWORD
EXTERN itemIDs    : DWORD
EXTERN itemQty    : DWORD
EXTERN itemPrice  : DWORD

EXTERN msgSaleHeader   : BYTE
EXTERN msgSaleEnterID  : BYTE
EXTERN msgSaleEnterQty : BYTE
EXTERN msgSaleNotFound : BYTE
EXTERN msgSaleNoStock  : BYTE
EXTERN msgSaleOK       : BYTE
EXTERN msgSaleTotal    : BYTE

PUBLIC RecordSale

.code

RecordSale:

    push eax
    push ebx
    push ecx
    push edx
    push esi

    mov  edx, OFFSET msgSaleHeader
    call WriteString

    ; Ask for product ID
    mov  edx, OFFSET msgSaleEnterID
    call WriteString
    call ReadInt
    mov  ebx, eax           ; ebx = target ID

    ; Search itemIDs[] for match
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
    ; Ask for quantity
    mov  edx, OFFSET msgSaleEnterQty
    call WriteString
    call ReadInt
    mov  ecx, eax           ; ecx = qty to sell

    ; Check stock
    mov  eax, itemQty[esi*4]
    cmp  eax, ecx
    jl   RS_NoStock

    ; Deduct stock
    sub  itemQty[esi*4], ecx

    ; Print success
    mov  edx, OFFSET msgSaleOK
    call WriteString

    ; Print total = qty * price
    mov  edx, OFFSET msgSaleTotal
    call WriteString
    mov  eax, itemPrice[esi*4]
    mul  ecx                ; eax = price * qty
    call WriteDec
    call Crlf
    jmp  RS_Done

RS_NoStock:
    mov  edx, OFFSET msgSaleNoStock
    call WriteString

RS_Done:
    pop  esi
    pop  edx
    pop  ecx
    pop  ebx
    pop  eax
    ret

END