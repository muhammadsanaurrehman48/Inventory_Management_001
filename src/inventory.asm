;=====================================================
; inventory.asm
; AddItem, ViewItems, UpdateItem, DeleteItem
;=====================================================
INCLUDE Irvine32.inc

; ---- Imports from data.asm ----
EXTERN itemCount  : DWORD
EXTERN itemIDs    : DWORD
EXTERN itemQty    : DWORD
EXTERN itemPrice  : DWORD
EXTERN itemNames  : BYTE

EXTERN msgEnterID    : BYTE
EXTERN msgEnterName  : BYTE
EXTERN msgEnterQty   : BYTE
EXTERN msgEnterPrice : BYTE
EXTERN msgAdded      : BYTE
EXTERN msgFull       : BYTE
EXTERN msgDupID      : BYTE
EXTERN msgBadInput   : BYTE

EXTERN msgViewHeader : BYTE
EXTERN msgViewSep    : BYTE
EXTERN msgViewEmpty  : BYTE
EXTERN msgViewRow1   : BYTE
EXTERN msgViewRow2   : BYTE

EXTERN msgUpdHeader   : BYTE
EXTERN msgUpdEnterID  : BYTE
EXTERN msgUpdNotFound : BYTE
EXTERN msgUpdNewName  : BYTE
EXTERN msgUpdNewQty   : BYTE
EXTERN msgUpdNewPrice : BYTE
EXTERN msgUpdOK       : BYTE

EXTERN msgDelHeader   : BYTE
EXTERN msgDelEnterID  : BYTE
EXTERN msgDelNotFound : BYTE
EXTERN msgDelConfirm  : BYTE
EXTERN msgDelOK       : BYTE
EXTERN msgDelCancel   : BYTE

; ---- Exports ----
PUBLIC AddItem, ViewItems, UpdateItem, DeleteItem

NAME_LEN  = 20
MAX_ITEMS = 10

.data
pipeSep  BYTE " |",0Dh,0Ah,0   ; closes a table row
nameBuf  BYTE 21 DUP(0)        ; temp buffer for ReadString

.code

;=====================================================
; PrintPadded
; Print null-terminated string at edx, pad to ecx chars.
; Trashes: eax only. Caller saves edx/ecx if needed.
;=====================================================
PrintPadded PROC
    push esi
    push ecx
    mov  esi, edx
    xor  eax, eax           ; printed count
PP_CharLoop:
    mov  dl, [esi]
    cmp  dl, 0
    je   PP_Pad
    cmp  dl, 0Dh
    je   PP_Pad
    cmp  dl, 0Ah
    je   PP_Pad
    call WriteChar
    inc  esi
    inc  eax
    jmp  PP_CharLoop
PP_Pad:
    cmp  eax, ecx
    jge  PP_Done
    mov  dl, ' '
    call WriteChar
    inc  eax
    jmp  PP_Pad
PP_Done:
    pop  ecx
    pop  esi
    ret
PrintPadded ENDP

;=====================================================
; PrintDecPadded
; Print DWORD in eax as decimal, pad to ecx chars wide.
; Trashes: edx (Irvine uses it internally for WriteDec)
;=====================================================
PrintDecPadded PROC
    push eax
    push ecx
    push esi

    mov  esi, eax           ; save value

    ; Count digits
    xor  ecx, ecx           ; will hold digit count
    mov  eax, esi
    cmp  eax, 0
    jne  PDP_Count
    inc  ecx
    jmp  PDP_PrintNum
PDP_Count:
    cmp  eax, 0
    je   PDP_PrintNum
    push edx
    xor  edx, edx
    push ecx
    mov  ecx, 10
    div  ecx
    pop  ecx
    pop  edx
    inc  ecx
    jmp  PDP_Count

PDP_PrintNum:
    pop  esi                ; restore: esi had col-width from caller? No —
    ; Actually esi held value. Restore properly:
    ; stack at this point: [eax][ecx-original][esi-original]
    ; We popped esi already, which was the VALUE we stored.
    ; Let's use a cleaner approach: store digit count in edi.
    push esi
    ; undo: the pop esi above fetched wrong thing. Rewrite cleanly below.
    pop  esi
    pop  ecx
    pop  eax
    ; --- clean restart using edi for digit count ---

    push eax
    push ecx
    push esi
    push edi

    mov  esi, eax           ; esi = value to print
    pop  edi
    push edi
    ; col width is in ecx (from caller via stack — but we pushed ecx,
    ; so reload from stack). Actually ecx IS the col width right now.
    ; Save col width in edi.
    mov  edi, ecx           ; edi = column width

    ; Count digits of esi into ebx
    push ebx
    xor  ebx, ebx
    mov  eax, esi
    cmp  eax, 0
    jne  PDP2_Count
    inc  ebx
    jmp  PDP2_Print
PDP2_Count:
    cmp  eax, 0
    je   PDP2_Print
    push edx
    xor  edx, edx
    push ecx
    mov  ecx, 10
    div  ecx
    pop  ecx
    pop  edx
    inc  ebx
    jmp  PDP2_Count
PDP2_Print:
    mov  eax, esi
    call WriteDec
    ; pad (edi - ebx) spaces
PDP2_Pad:
    cmp  ebx, edi
    jge  PDP2_Done
    mov  al, ' '
    call WriteChar
    inc  ebx
    jmp  PDP2_Pad
PDP2_Done:
    pop  ebx
    pop  edi
    pop  esi
    pop  ecx
    pop  eax
    ret

PrintDecPadded ENDP

;=====================================================
; FindByID
; Input : ebx = target ID
; Output: esi = index if found, CF=0
;         CF=1 if not found
;=====================================================
FindByID PROC
    push eax
    xor  esi, esi
FBI_Loop:
    cmp  esi, itemCount
    jge  FBI_Miss
    mov  eax, itemIDs[esi*4]
    cmp  eax, ebx
    je   FBI_Hit
    inc  esi
    jmp  FBI_Loop
FBI_Miss:
    stc
    pop  eax
    ret
FBI_Hit:
    clc
    pop  eax
    ret
FindByID ENDP

;=====================================================
; NameOffset
; Input : eax = slot index
; Output: edx = pointer into itemNames for that slot
; Trashes: eax (multiply), ecx
;=====================================================
NameOffset PROC
    push ebx
    mov  ebx, NAME_LEN
    imul eax, ebx
    add  eax, OFFSET itemNames
    mov  edx, eax
    pop  ebx
    ret
NameOffset ENDP
   
;=====================================================
; CopyName
; Copies NAME_LEN bytes from src slot (esi) to dst slot (edi)
; Trashes: eax, ecx, edx, ebx (all saved/restored)
;=====================================================
CopyName PROC
    push eax
    push ebx
    push ecx
    push edx

    ; src ptr
    mov  eax, esi
    call NameOffset         ; edx = src ptr
    mov  ebx, edx           ; ebx = src

    ; dst ptr
    mov  eax, edi
    call NameOffset         ; edx = dst ptr

    mov  ecx, NAME_LEN
CN_Loop:
    mov  al, [ebx]
    mov  [edx], al
    inc  ebx
    inc  edx
    loop CN_Loop

    pop  edx
    pop  ecx
    pop  ebx
    pop  eax
    ret
CopyName ENDP

;=====================================================
; ZeroName
; Zeroes out NAME_LEN bytes at slot index in eax
;=====================================================
ZeroName PROC
    push eax
    push ecx
    push edx

    call NameOffset         ; edx = ptr to name slot
    mov  ecx, NAME_LEN
ZN_Loop:
    mov  BYTE PTR [edx], 0
    inc  edx
    loop ZN_Loop

    pop  edx
    pop  ecx
    pop  eax
    ret
ZeroName ENDP

;=====================================================
; AddItem
;=====================================================
AddItem:
    push eax
    push ebx
    push ecx
    push edx
    push esi

    mov  eax, itemCount
    cmp  eax, MAX_ITEMS
    jl   AI_Continue
    mov  edx, OFFSET msgFull
    call WriteString
    jmp  AI_Done

AI_Continue:
    mov  esi, itemCount

AI_GetID:
    mov  edx, OFFSET msgEnterID
    call WriteString
    call ReadInt
    mov  ebx, eax

    cmp  ebx, 0
    jle  AI_BadID

    ; Check duplicate
    call FindByID
    jnc  AI_DupID           ; NC = found = duplicate

    jmp  AI_IDOk

AI_BadID:
    mov  edx, OFFSET msgBadInput
    call WriteString
    jmp  AI_GetID

AI_DupID:
    mov  edx, OFFSET msgDupID
    call WriteString
    jmp  AI_GetID

AI_IDOk:
    mov  itemIDs[esi*4], ebx

    mov  edx, OFFSET msgEnterName
    call WriteString
    mov  edx, OFFSET nameBuf
    mov  ecx, NAME_LEN
    call ReadString
    ; eax = number of chars read, strip CR/LF
    mov  edi, OFFSET nameBuf
    add  edi, eax
    mov  BYTE PTR [edi], 0
    inc  edi
    mov  BYTE PTR [edi], 0
    inc  edi
    mov  BYTE PTR [edi], 0
AI_NameDone:
    ; strip CR/LF from nameBuf
    mov  edi, OFFSET nameBuf
    add  edi, eax           ; point to end of string
    dec  edi
SN_Strip:
    mov  bl, [edi]
    cmp  bl, 0Dh
    je   SN_Zero
    cmp  bl, 0Ah
    je   SN_Zero
    jmp  SN_Done
SN_Zero:
    mov  BYTE PTR [edi], 0
    dec  edi
    jmp  SN_Strip
SN_Done:
    ; now copy clean nameBuf to itemNames slot
    mov  eax, esi
    call NameOffset         ; edx = destination in itemNames
    mov  edi, edx
    push esi
    mov  esi, OFFSET nameBuf
    mov  ecx, NAME_LEN
    rep  movsb
    pop  esi

    mov  edx, OFFSET msgEnterQty
    call WriteString
    call ReadInt
    mov  itemQty[esi*4], eax

    mov  edx, OFFSET msgEnterPrice
    call WriteString
    call ReadInt
    mov  itemPrice[esi*4], eax

    inc  itemCount

    mov  edx, OFFSET msgAdded
    call WriteString

AI_Done:
    pop  esi
    pop  edx
    pop  ecx
    pop  ebx
    pop  eax
    ret

;=====================================================
; ViewItems
; Aligned table: | ID(6) | Name(20) | Qty(8) | Price(8) |
;=====================================================
ViewItems:

    push eax
    push ebx
    push ecx
    push edx
    push esi

    mov  eax, itemCount
    cmp  eax, 0
    jne  VI_Show
    mov  edx, OFFSET msgViewEmpty
    call WriteString
    jmp  VI_Done

VI_Show:
    mov  edx, OFFSET msgViewHeader
    call WriteString

    xor  esi, esi

VI_Loop:
    cmp  esi, itemCount
    jge  VI_End

    ; "  | "
    mov  edx, OFFSET msgViewRow1
    call WriteString

    ; ID — 6 wide
    mov  eax, itemIDs[esi*4]
    mov  ecx, 6
    call PrintDecPadded

    ; " | "
    mov  edx, OFFSET msgViewRow2
    call WriteString

    ; Name — 20 wide
    mov  eax, esi
    call NameOffset         ; edx = name ptr
    push edx
    call WriteString
    call Crlf
    pop  edx
    mov  ecx, 20
    call PrintPadded

    ; " | "
    mov  edx, OFFSET msgViewRow2
    call WriteString

    ; Qty — 8 wide
    mov  eax, itemQty[esi*4]
    mov  ecx, 8
    call PrintDecPadded

    ; " | "
    mov  edx, OFFSET msgViewRow2
    call WriteString

    ; Price — 8 wide
    mov  eax, itemPrice[esi*4]
    mov  ecx, 8
    call PrintDecPadded

    ; " |" + CRLF
    mov  edx, OFFSET pipeSep
    call WriteString

    ; separator line
    mov  edx, OFFSET msgViewSep
    call WriteString

    inc  esi
    jmp  VI_Loop

VI_End:
VI_Done:
    pop  esi
    pop  edx
    pop  ecx
    pop  ebx
    pop  eax
    ret

; UpdateItem
; Find by ID, overwrite Name / Qty / Price in place.
;=====================================================
UpdateItem:

    push eax
    push ebx
    push ecx
    push edx
    push esi

    mov  edx, OFFSET msgUpdHeader
    call WriteString

    mov  edx, OFFSET msgUpdEnterID
    call WriteString
    call ReadInt
    mov  ebx, eax

    call FindByID
    jc   UI_NotFound

    ; esi = slot

    ; New Name
    mov  edx, OFFSET msgUpdNewName
    call WriteString
    mov  eax, esi
    call NameOffset
    mov  ecx, NAME_LEN
    call ReadString

    ; New Qty
    mov  edx, OFFSET msgUpdNewQty
    call WriteString
    call ReadInt
    mov  itemQty[esi*4], eax

    ; New Price
    mov  edx, OFFSET msgUpdNewPrice
    call WriteString
    call ReadInt
    mov  itemPrice[esi*4], eax

    mov  edx, OFFSET msgUpdOK
    call WriteString
    jmp  UI_Done

UI_NotFound:
    mov  edx, OFFSET msgUpdNotFound
    call WriteString

UI_Done:
    pop  esi
    pop  edx
    pop  ecx
    pop  ebx
    pop  eax
    ret

; DeleteItem
; Find by ID, confirm, shift remaining items left,
; zero the last slot, decrement itemCount.
;=====================================================
DeleteItem:

    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    mov  edx, OFFSET msgDelHeader
    call WriteString

    mov  edx, OFFSET msgDelEnterID
    call WriteString
    call ReadInt
    mov  ebx, eax

    call FindByID
    jc   DI_NotFound        ; CF=1 → not found

    ; esi = slot index to delete

    ; Confirm
    mov  edx, OFFSET msgDelConfirm
    call WriteString
    call ReadInt
    cmp  eax, 1
    jne  DI_Cancel

    ; --- Shift all slots after esi one position left ---
    mov  edi, esi           ; edi = destination

DI_Shift:
    mov  eax, edi
    inc  eax                ; eax = source slot
    cmp  eax, itemCount
    jge  DI_ShiftDone

    ; Copy DWORD fields: src=eax, dst=edi
    push ebx
    mov  ebx, itemIDs[eax*4]
    mov  itemIDs[edi*4], ebx

    mov  ebx, itemQty[eax*4]
    mov  itemQty[edi*4], ebx

    mov  ebx, itemPrice[eax*4]
    mov  itemPrice[edi*4], ebx
    pop  ebx

    ; Copy Name: CopyName expects src slot in esi, dst slot in edi
    push esi
    mov  esi, eax           ; src slot
    ; edi is already dst slot
    call CopyName
    pop  esi

    inc  edi
    jmp  DI_Shift

DI_ShiftDone:
    ; Zero the last slot (was duplicated by shift)
    mov  eax, itemCount
    dec  eax                ; last index

    mov  itemIDs[eax*4],   0
    mov  itemQty[eax*4],   0
    mov  itemPrice[eax*4], 0
    call ZeroName           ; eax still = last index

    dec  itemCount

    mov  edx, OFFSET msgDelOK
    call WriteString
    jmp  DI_Done

DI_Cancel:
    mov  edx, OFFSET msgDelCancel
    call WriteString
    jmp  DI_Done

DI_NotFound:
    mov  edx, OFFSET msgDelNotFound
    call WriteString

DI_Done:
    pop  edi
    pop  esi
    pop  edx
    pop  ecx
    pop  ebx
    pop  eax
    ret

END
