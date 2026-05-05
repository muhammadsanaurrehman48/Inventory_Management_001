;=====================================================
; data.asm - Added itemSold tracking
;=====================================================
INCLUDE Irvine32.inc

PUBLIC itemCount, itemIDs, itemQty, itemPrice, itemSold, itemNames
PUBLIC msgEnterID, msgEnterName, msgEnterQty, msgEnterPrice
PUBLIC msgAdded, msgFull, msgDupID, msgBadInput
PUBLIC msgViewHeader, msgViewSep, msgViewEmpty, msgViewRow1, msgViewRow2
PUBLIC msgUpdHeader, msgUpdEnterID, msgUpdNotFound, msgUpdNewName, msgUpdNewQty, msgUpdNewPrice, msgUpdOK
PUBLIC msgDelHeader, msgDelEnterID, msgDelNotFound, msgDelConfirm, msgDelOK, msgDelCancel
PUBLIC msgSaleHeader, msgSaleEnterID, msgSaleEnterQty, msgSaleNotFound, msgSaleNoStock, msgSaleOK, msgSaleTotal

.data
MAX_ITEMS = 10
NAME_LEN  = 20
itemCount DWORD 0
itemIDs   DWORD MAX_ITEMS DUP(0)
itemQty   DWORD MAX_ITEMS DUP(0)
itemPrice DWORD MAX_ITEMS DUP(0)
itemSold  DWORD MAX_ITEMS DUP(0) ; <--- NEW SALES TRACKER
itemNames BYTE MAX_ITEMS * NAME_LEN DUP(0)

; ---- AddItem ----
msgEnterID    BYTE 0Dh,0Ah,"  Enter Item ID    : ",0
msgEnterName  BYTE "  Enter Item Name  : ",0
msgEnterQty   BYTE "  Enter Quantity   : ",0
msgEnterPrice BYTE "  Enter Price (Rs) : ",0
msgAdded      BYTE 0Dh,0Ah,"  [OK] Item added successfully!",0Dh,0Ah,0
msgFull       BYTE 0Dh,0Ah,"  [!] Inventory full (max 10 items).",0Dh,0Ah,0
msgDupID      BYTE 0Dh,0Ah,"  [!] That ID already exists.",0Dh,0Ah,0
msgBadInput   BYTE 0Dh,0Ah,"  [!] ID must be greater than 0.",0Dh,0Ah,0

; ---- ViewItems ----
msgViewHeader BYTE 0Dh,0Ah,\
    "  +--------+----------------------+----------+----------+",0Dh,0Ah,\
    "  |  ID    |  Name                |  Qty     |  Price   |",0Dh,0Ah,\
    "  +--------+----------------------+----------+----------+",0Dh,0Ah,0
msgViewSep    BYTE "  +--------+----------------------+----------+----------+",0Dh,0Ah,0
msgViewEmpty  BYTE 0Dh,0Ah,"  [!] No items in inventory.",0Dh,0Ah,0
msgViewRow1   BYTE "  | ",0
msgViewRow2   BYTE " | ",0

; ---- Update/Delete/Sales ----
msgUpdHeader   BYTE 0Dh,0Ah,"===== Update Product =====",0Dh,0Ah,0
msgUpdEnterID  BYTE "  Enter Item ID to update : ",0
msgUpdNotFound BYTE 0Dh,0Ah,"  [!] Item ID not found.",0Dh,0Ah,0
msgUpdNewName  BYTE "  New Name  : ",0
msgUpdNewQty   BYTE "  New Qty   : ",0
msgUpdNewPrice BYTE "  New Price : ",0
msgUpdOK       BYTE 0Dh,0Ah,"  [OK] Item updated successfully!",0Dh,0Ah,0
msgDelHeader   BYTE 0Dh,0Ah,"===== Delete Product =====",0Dh,0Ah,0
msgDelEnterID  BYTE "  Enter Item ID to delete : ",0
msgDelNotFound BYTE 0Dh,0Ah,"  [!] Item ID not found.",0Dh,0Ah,0
msgDelConfirm  BYTE "  Confirm delete? (1=Yes / 0=No) : ",0
msgDelOK       BYTE 0Dh,0Ah,"  [OK] Item deleted.",0Dh,0Ah,0
msgDelCancel   BYTE 0Dh,0Ah,"  Cancelled.",0Dh,0Ah,0
msgSaleHeader   BYTE 0Dh,0Ah,"===== Record a Sale =====",0Dh,0Ah,0
msgSaleEnterID  BYTE "  Enter Item ID to sell : ",0
msgSaleEnterQty BYTE "  Quantity to sell      : ",0
msgSaleNotFound BYTE 0Dh,0Ah,"  [!] Item ID not found.",0Dh,0Ah,0
msgSaleNoStock  BYTE 0Dh,0Ah,"  [!] Not enough stock.",0Dh,0Ah,0
msgSaleOK       BYTE 0Dh,0Ah,"  [OK] Sale recorded.",0Dh,0Ah,0
msgSaleTotal    BYTE "  Total Sale Value (Rs): ",0

.code
END