.MODEL SMALL
.STACK 100h
.DATA

    ;Car deets
    MAX_CARS     EQU 15
    carCount     DW    0
    carPlate     DB    MAX_CARS*8 DUP(' ')
    carMileage   DW    MAX_CARS DUP(0)
    carType      DB    MAX_CARS DUP(0) 
    carSlot      DB    MAX_CARS DUP(0)    ; insertion index

    ;buffer
    plateInput DB 8,0,8 DUP(0)
    mileInput  DB 5,0,5 DUP(0)

    ;prompt
    correctMsg      DB 'Operation successful$'
    continueMessage DB 'Press a Key to Continue: $'
    wrongInputMsg   DB 'Invalid selection!$'
    fullMsg         DB 'Inventory full! Cannot add more vehicles.$'
    menuPrompt      DB 'Enter a number (1-5) and press Enter: $'
    platePrompt     DB 'Enter Plate (max 8 chars): $'
    mileagePrompt   DB 'Enter Mileage: $'
    typePrompt      DB 'Enter Type (1=Saloon,2=SUV,3=Sports Car,4=Truck): $'
    

    ; Main menu definitions
    menuOption1 DB '1) Add New Vehicle$'
    menuOption2 DB '2) List Vehicles by Type$'
    menuOption3 DB '3) View Vehicle by Position$'
    menuOption4 DB '4) Remove Vehicle$'
    menuOption5 DB '5) Exit Program$'
    mainMenu    DW OFFSET menuOption1, OFFSET menuOption2, OFFSET menuOption3, OFFSET menuOption4, OFFSET menuOption5
    mainMenuSize DW 5

    ; List-by-type menu definitions
    listOpt1 DB '1) List Saloons$'
    listOpt2 DB '2) List SUVs$'
    listOpt3 DB '3) List Sports Cars$'
    listOpt4 DB '4) List Trucks$'
    listOpt5 DB '5) Return$'
    listPrompt DB 'Enter a number (1-5) and press Enter:(1-5)$'
    listMenu DW OFFSET listOpt1, OFFSET listOpt2, OFFSET listOpt3, OFFSET listOpt4,OFFSET listOpt5,OFFSET listPrompt
    listMenuSize DW 6
    
    CRLF DB 13,10,'$'

.CODE
;-----------------------------
; Macros
DisplayMenu Macro array, count
    LOCAL loopLabel
    mov cx, count
    xor si, si
loopLabel:
    mov bx, si
    shl bx, 1
    mov dx, [array + bx]
    mov ah, 09h
    int 21h
    lea dx, CRLF
    mov ah, 09h
    int 21h
    inc si
    loop loopLabel
EndM

PressKeyToContinue Macro
    mov ah, 09h
    lea dx, continueMessage
    int 21h
    mov ah, 01h
    int 21h
EndM

PrintString Macro msg
    lea dx, msg
    mov ah, 09h
    int 21h
EndM

DisplayListMenu Macro array, count
    LOCAL loopLab
    mov cx, count
    xor si, si
loopLab:
    mov bx, si
    shl bx, 1
    mov dx, [array + bx]
    mov ah, 09h
    int 21h
    lea dx, CRLF
    mov ah, 09h
    int 21h
    inc si
    loop loopLab
EndM

printPlateInput Macro msg
    lea dx,msg
    mov ah,09
    int 21h
EndM
    

;-----------------------------
; Main
MAIN PROC
    mov ax, @data
    mov ds, ax

startMenu:
    DisplayMenu mainMenu, mainMenuSize
    PrintString menuPrompt
    mov ah,01h        
    int 21h           
    sub al,'0'        
    mov bl, al        

    ; Discard the carriage return from input buffer
    mov ah,01h
    int 21h

    ; jump to routines based on input
    cmp bl, 1
    je AddVehicle
    cmp bl, 2
    je ListByType
    cmp bl, 3
    je ViewByPosition
    cmp bl, 4
    je RemoveVehicle
    cmp bl, 5
    jmp ExitProgram

    ; Invalid choice
    PrintString wrongInputMsg
    jmp startMenu
MAIN ENDP

;-----------------------------
; Subroutines
AddVehicle PROC
    ; Check car capacity
    mov ax,carCount
    cmp ax,MAX_CARS
    ;jae fullLot
    
    ;input plate
    printPlateInput platePrompt
    lea dx,plateInput
    mov ah,0Ah
    int 21h
    
    
    
    PrintString correctMsg
    PressKeyToContinue
    jmp startMenu
AddVehicle ENDP

ListByType PROC
    DisplayListMenu listMenu, listMenuSize
    ;-
    PressKeyToContinue
    jmp startMenu
ListByType ENDP

ViewByPosition PROC
    ;-
    PrintString correctMsg
    PressKeyToContinue
    jmp startMenu
ViewByPosition ENDP

RemoveVehicle PROC
    ;-
    PrintString correctMsg
    PressKeyToContinue
    jmp startMenu
RemoveVehicle ENDP

ExitProgram PROC
    mov ah, 4Ch
    int 21h
ExitProgram ENDP

END MAIN

