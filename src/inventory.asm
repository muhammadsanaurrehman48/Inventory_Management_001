;=====================================================
; inventory.asm - Fixed Register Trashing
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

; ---- Exports with C naming convention ----
PUBLIC AddItem, ViewItems, UpdateItem, DeleteItem

NAME_LEN  = 20
MAX_ITEMS = 10

.data
pipeSep  BYTE " |",0Dh,0Ah,0   
nameBuf  BYTE 21 DUP(0)        

.code

;=====================================================
; PrintPadded
;=====================================================
PrintPadded PROC
    push ebx        ; Save EBX
    push esi        ; Save ESI
    push ecx        ; Save ECX
    push edx        ; Save EDX
    
    mov  esi, edx
    xor  ebx, ebx           
PP_CharLoop:
    mov  al, [esi]
    cmp  al, 0
    je   PP_Pad
    cmp  al, 0Dh            
    je   PP_Skip
    cmp  al, 0Ah            
    je   PP_Skip
    
    call WriteChar
    inc  ebx
PP_Skip:
    inc  esi
    jmp  PP_CharLoop
PP_Pad:
    cmp  ebx, ecx
    jge  PP_Done
    mov  al, ' '
    call WriteChar
    inc  ebx
    jmp  PP_Pad
PP_Done:
    pop  edx        ; Restore in reverse order
    pop  ecx
    pop  esi
    pop  ebx
    ret
PrintPadded ENDP

;=====================================================
; PrintDecPadded
;=====================================================
PrintDecPadded PROC
    push eax        ; Save EAX
    push ebx        ; Save EBX
    push ecx        ; Save ECX
    push edx        ; Save EDX
    push esi        ; Save ESI !!! (This caused the bug)
    push edi        ; Save EDI

    mov  ebx, eax           
    xor  edx, edx
    push eax
    mov  edi, 0             
    cmp  eax, 0
    jne  PDP_Count
    inc  edi
    jmp  PDP_Print
PDP_Count:
    cmp  eax, 0
    je   PDP_Print
    mov  esi, 10
    xor  edx, edx
    div  esi
    inc  edi
    jmp  PDP_Count
PDP_Print:
    pop  eax
    call WriteDec
PDP_Pad:
    cmp  edi, ecx
    jge  PDP_Done
    mov  al, ' '
    call WriteChar
    inc  edi
    jmp  PDP_Pad
PDP_Done:
    pop  edi        ; Restore in reverse order
    pop  esi
    pop  edx
    pop  ecx
    pop  ebx
    pop  eax
    ret
PrintDecPadded ENDP

;=====================================================
; Helper Procs
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

NameOffset PROC
    push ebx
    mov  ebx, NAME_LEN
    imul eax, ebx
    add  eax, OFFSET itemNames
    mov  edx, eax
    pop  ebx
    ret
NameOffset ENDP
   
CopyName PROC
    push eax
    push ebx
    push ecx
    push edx
    mov  eax, esi
    call NameOffset         
    mov  ebx, edx           
    mov  eax, edi
    call NameOffset         
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

ZeroName PROC
    push eax
    push ecx
    push edx
    call NameOffset         
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
AddItem PROC C
    pushad
    mov  eax, itemCount
    cmp  eax, MAX_ITEMS
    jl   AI_GetID
    mov  edx, OFFSET msgFull
    call WriteString
    jmp  AI_Done

AI_GetID:
    mov  edx, OFFSET msgEnterID
    call WriteString
    call ReadInt
    mov  ebx, eax
    cmp  ebx, 0
    jle  AI_BadID
    call FindByID
    jnc  AI_DupID           
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
    mov  esi, itemCount
    mov  itemIDs[esi*4], ebx

    mov  edx, OFFSET msgEnterName
    call WriteString
    mov  edx, OFFSET nameBuf
    mov  ecx, NAME_LEN
    call ReadString
    
    mov  eax, esi
    call NameOffset
    mov  edi, edx           
    mov  esi, OFFSET nameBuf
    mov  ecx, NAME_LEN
AI_CopyLoop:
    mov  al, [esi]
    cmp  al, 0Dh            
    je   AI_FillNull
    cmp  al, 0Ah            
    je   AI_FillNull
    cmp  al, 0
    je   AI_FillNull
    mov  [edi], al
    inc  esi
    inc  edi
    loop AI_CopyLoop
    jmp  AI_GetQty
AI_FillNull:
    mov  BYTE PTR [edi], 0
    inc  edi
    loop AI_FillNull

AI_GetQty:
    mov  esi, itemCount
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
    popad
    ret
AddItem ENDP

;=====================================================
; ViewItems 
;=====================================================
ViewItems PROC C
    pushad
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
    mov  edx, OFFSET msgViewRow1
    call WriteString
    mov  eax, itemIDs[esi*4]
    mov  ecx, 6
    call PrintDecPadded
    mov  edx, OFFSET msgViewRow2
    call WriteString
    mov  eax, esi
    call NameOffset         
    mov  ecx, 20
    call PrintPadded
    mov  edx, OFFSET msgViewRow2
    call WriteString
    mov  eax, itemQty[esi*4]
    mov  ecx, 8
    call PrintDecPadded
    mov  edx, OFFSET msgViewRow2
    call WriteString
    mov  eax, itemPrice[esi*4]
    mov  ecx, 8
    call PrintDecPadded
    mov  edx, OFFSET pipeSep
    call WriteString
    mov  edx, OFFSET msgViewSep
    call WriteString
    inc  esi
    jmp  VI_Loop
VI_End:
VI_Done:
    popad
    ret
ViewItems ENDP

;=====================================================
; UpdateItem 
;=====================================================
UpdateItem PROC C
    pushad
    mov  edx, OFFSET msgUpdHeader
    call WriteString
    mov  edx, OFFSET msgUpdEnterID
    call WriteString
    call ReadInt
    mov  ebx, eax
    call FindByID
    jc   UI_NotFound
    push esi
    mov  edx, OFFSET msgUpdNewName
    call WriteString
    mov  edx, OFFSET nameBuf
    mov  ecx, NAME_LEN
    call ReadString
    pop  eax                
    push eax
    call NameOffset
    mov  edi, edx
    mov  esi, OFFSET nameBuf
    mov  ecx, NAME_LEN
UI_Clean:
    mov  al, [esi]
    cmp  al, 0Dh
    je   UI_Null
    cmp  al, 0Ah
    je   UI_Null
    cmp  al, 0
    je   UI_Null
    mov  [edi], al
    inc  esi
    inc  edi
    loop UI_Clean
    jmp  UI_Qty
UI_Null:
    mov  BYTE PTR [edi], 0
    inc  edi
    loop UI_Null
UI_Qty:
    pop  esi
    mov  edx, OFFSET msgUpdNewQty
    call WriteString
    call ReadInt
    mov  itemQty[esi*4], eax
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
    popad
    ret
UpdateItem ENDP

;=====================================================
; DeleteItem
;=====================================================
DeleteItem PROC C
    pushad
    mov  edx, OFFSET msgDelHeader
    call WriteString
    mov  edx, OFFSET msgDelEnterID
    call WriteString
    call ReadInt
    mov  ebx, eax
    call FindByID
    jc   DI_NotFound
    mov  edx, OFFSET msgDelConfirm
    call WriteString
    call ReadInt
    cmp  eax, 1
    jne  DI_Cancel
    mov  edi, esi           
DI_Shift:
    mov  eax, edi
    inc  eax                
    cmp  eax, itemCount
    jge  DI_ShiftDone
    mov  ebx, itemIDs[eax*4]
    mov  itemIDs[edi*4], ebx
    mov  ebx, itemQty[eax*4]
    mov  itemQty[edi*4], ebx
    mov  ebx, itemPrice[eax*4]
    mov  itemPrice[edi*4], ebx
    push esi
    mov  esi, eax           
    call CopyName
    pop  esi
    inc  edi
    jmp  DI_Shift
DI_ShiftDone:
    mov  eax, itemCount
    dec  eax                
    mov  itemIDs[eax*4],   0
    mov  itemQty[eax*4],   0
    mov  itemPrice[eax*4], 0
    call ZeroName           
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
    popad
    ret
DeleteItem ENDP

END