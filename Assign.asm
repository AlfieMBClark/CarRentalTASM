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
    plateTitle DB 'Plate: $'
    mileageTitle DB 'Mileage: $'
    matchesTitle DB ' Cars Found!$'
    positionTitle DB 'Position: $'
    typeTitle DB 'Type: $'
    slotTitle DB 'Vehicle in Slot order: $'
    
    saloonTitle DB 'Saloon$'
    suvTitle DB 'SUV$'
    sportsTitle DB 'Sports Car$'
    truckTitle DB 'Truck$'
    totalVechTitle DB ' Total Vehicles$'
    seperator DB '----------------$'

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
    listPrompt DB 'Enter a number (1-5)$'
    listMenu DW OFFSET listOpt1, OFFSET listOpt2, OFFSET listOpt3, OFFSET listOpt4,OFFSET listOpt5
    listMenuSize DW 5
        
    carArt       DB '            _______', 13, 10
                 DB '           //  ||\ \', 13, 10
                 DB '     _____//___||_\ \___', 13, 10
                 DB '     )  *          *    \', 13, 10
                 DB '     |_/ \________/ \___|', 13, 10
                 DB '    ___\_/________\_/______', 13, 10, '$'
    
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
    

ClearScreen Macro
    ; Save registers
    push ax
    push bx
    push cx
    push dx
    
    mov ah, 00h
    mov al, 03h 
    int 10h
    
    mov ah, 02h
    mov bh, 00h      
    mov dh, 00h      
    mov dl, 00h    
    int 10h
    
    pop dx
    pop cx
    pop bx
    pop ax
EndM


;-----------------------------
; Main
MAIN PROC
    mov ax, @data
    mov ds, ax

startMenu:
    ClearScreen
    PrintString carArt
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
    jne notOption1
    jmp AddVehicle
notOption1:
    cmp bl, 2
    jne notOption2
    jmp ListByType
notOption2:
    cmp bl, 3
    jne notOption3
    jmp ViewByPosition
notOption3:
    cmp bl, 4
    jne notOption4
    jmp RemoveVehicle
notOption4:
    cmp bl, 5
    jne invalidChoice
    jmp ExitProgram
invalidChoice:
    ; Invalid choice
    PrintString wrongInputMsg
    PressKeyToContinue
    jmp startMenu
MAIN ENDP

;-----------------------------
; Subroutines
AddVehicle PROC
    ;capacity
    mov ax, carCount
    cmp ax, MAX_CARS
    jb notFullLot
    jmp fullLot

notFullLot:
    ; Input plate number
    PrintString platePrompt
    lea dx, plateInput
    mov ah, 0Ah
    int 21h
    PrintString CRLF
    
    ; Input mileage
    PrintString mileagePrompt
    lea dx, mileInput
    mov ah, 0Ah
    int 21h
    PrintString CRLF
    
    ; Input vehicle type
    PrintString typePrompt
    mov ah, 01h        
    int 21h
    sub al, '0'        ; Convert ASCII to number
    
    ; Validate vehicle type (1-4)
    cmp al, 1
    jae typeAtLeast1
    jmp invalidType
typeAtLeast1:
    cmp al, 4
    jbe typeValid
    jmp invalidType
typeValid:
    ; Store vehicle type
    mov bl, al
    PrintString CRLF
    ; position to store data
    mov si, carCount
    ; Store car type
    mov di, si
    mov [carType + di], bl
    ; Store car slot/index
    mov [carSlot + di], bl
    
    ; Store mileage - convert ASCII to binary
    xor ax, ax
    xor bx, bx
    mov bl, [mileInput + 1]  ; length of entered string
    mov cx, bx              ; counter to length
    mov si, 2               ; Start at first digit
convertMileage:
    xor bx, bx
    mov bl, [mileInput + si]
    sub bl, '0'             ; Convert ASCII to number
    
    ; Multiply current value by 10 and add new digit
    mov dx, 10
    mul dx
    add ax, bx
    
    inc si
    loop convertMileage
    
    ; Store mileage value
    mov di, carCount
    shl di, 1               ; Multiply by 2 since mileage is word-sized
    mov [carMileage + di], ax
    
    ; Store plate number
    mov si, 2               ; Source: plateInput buffer (skip size and length)
    mov di, carCount        ; Destination: calculated offset
    mov cx, 8               ; Maximum plate length
    mov bx, 0               ; Index counter for destination
    
    ; Calculate beginning position in carPlate array
    mov ax, carCount
    mov dx, 8
    mul dx
    mov di, ax
    
copyPlate:
    ; Check if end of the entered plate
    mov al, [plateInput + 1]    ; Get length of entered text
    cmp bl, al                  ; Compare with current position
    jae padSpace                ; If we're beyond input, pad with spaces
    
    ; Copy character
    mov al, [plateInput + si]
    mov [carPlate + di], al
    inc si
    inc di
    inc bx
    loop copyPlate
    jmp storeDone
    
padSpace:
    ; Pad with spaces
    mov byte ptr [carPlate + di], ' '
    inc di
    loop padSpace
    
storeDone:
    ; Increment car count
    inc carCount
    
    PrintString correctMsg
    jmp addDone
    
fullLot:
    PrintString fullMsg
    jmp addDone
    
invalidType:
    PrintString wrongInputMsg
    
addDone:
    PrintString CRLF
    PressKeyToContinue
    jmp startMenu
AddVehicle ENDP


ListByType PROC
    PrintString CRLF
    DisplayListMenu listMenu, listMenuSize
    PrintString listPrompt
    
    ; Get user selection
    mov ah, 01h
    int 21h
    sub al, '0'
    mov bl, al
    
    mov ah, 01h
    int 21h
   
    ;selection is valid (1-5)
    cmp bl, 1
    jge validMin
    jmp invalidListOption
validMin:
    cmp bl, 5
    jle validOption
    jmp invalidListOption
validOption:
    
    ; Return option 5
    cmp bl, 5
    jne notReturnOption
    jmp returnToMenu
notReturnOption:
    
    ; bl selected vehicle type 
    ; Check if any vehicles exist
    cmp carCount, 0
    jne haveCars
    PrintString CRLF
    PrintString CRLF
    PrintString wrongInputMsg
    PrintString CRLF
    PrintString CRLF
    jmp listDone
    
haveCars:
    ; Display header
    ClearScreen
    PrintString CRLF
    PrintString CRLF
    
    ;counter for matches found
    xor cx, cx
    mov bh, bl      ; Save type in BH 
    
    ; Loop
    mov si, 0
    
carTypeLoop:
    cmp si, carCount
    jb continueTypeLoop
    jmp endTypeLoop
continueTypeLoop:
    
    ; Check if current car matches the requested type
    mov di, si
    mov al, [carType + di]
    cmp al, bh      ; Compare  saved type in BH
    je typeMatches
    jmp nextCar
typeMatches:
    
    ; Match found - increment match counter
    inc cx
    

    lea dx, CRLF
    mov ah, 09h
    int 21h
    
    ; Print "Plate: "
    PrintString plateTitle
    
    ; Print plate number
    push bx         ; BX (contains type)
    push cx         ; CX (match counter)
    push si         ; SI (car index)
    
    mov ax, si
    mov bx, 8
    mul bx
    mov di, ax
    
    mov cx, 8       ; Set loop counter for plate chars
    
printPlate:
    mov dl, [carPlate + di]
    mov ah, 02h
    int 21h
    inc di
    loop printPlate
    
    ; Print ", Mileage: "
    PrintString mileageTitle
    
    
    ; Retrieve car index
    pop si
    push si         ; Keep it on stack
    
    ; Print mileage
    mov di, si
    shl di, 1       ; Multiply by 2 because mileage is a word
    mov ax, [carMileage + di]
    
    ; Convert number to string
    ; First, determine number of digits by dividing by 10 repeatedly
    mov bx, 10
    xor dx, dx
    mov cx, 0       ; Digit counter
    
countDigits:
    xor dx, dx
    div bx
    push dx         
    inc cx
    test ax, ax
    jnz countDigits
    
    ; Save count
    mov bl, cl 
    
    ;pop digit and print
printDigits:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    dec bl
    jnz printDigits
    
    ; Restore 
    pop si          ; Restore SI (car index)
    pop cx          ; Restore CX (match counter)
    pop bx          ; Restore BX (type)
    
nextCar:
    inc si
    jmp carTypeLoop
    
endTypeLoop:
    ; Find matches
    test cx, cx
    jnz matchesFound
    ; No matches found
    PrintString CRLF
    PrintString wrongInputMsg
    jmp listDone
    
matchesFound:
    PrintString CRLF
    PrintString CRLF
    
    ; Convert match count to ASCII digits
    mov ax, cx
    mov bx, 10
    xor cx, cx
    
countDigitsMatch:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz countDigitsMatch
    
printDigitsMatch:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop printDigitsMatch
    
    PrintString matchesTitle
    
    jmp listDone
    
invalidListOption:
    PrintString CRLF
    PrintString wrongInputMsg
    
listDone:
    PrintString CRLF
    PrintString CRLF
    PressKeyToContinue
    
returnToMenu:
    jmp startMenu
ListByType ENDP




ViewByPosition PROC
    ClearScreen
   
    cmp carCount, 0
    jne hasVehicles
    
    PrintString CRLF
    PrintString CRLF
    PrintString wrongInputMsg
    PrintString CRLF
    jmp viewDone
    
hasVehicles:
    PrintString CRLF
    PrintString CRLF
    PrintString slotTitle
    PrintString CRLF
    
    ; Loop through
    mov si, 0
    
displayLoop:
    cmp si, carCount
    jb continueDisplay 
    jmp displayDone    
continueDisplay:
    
  
    PrintString CRLF
    
    PrintString positionTitle
    
    ; Print position number - fix the operand type mismatch
    ; Cannot directly move SI to DL since they're different sizes
    mov ax, si       ; First move SI to AX (same size)
    add al, '0'      ; Convert to ASCII 
    mov dl, al       ; Now move the lower part (AL) to DL
    mov ah, 02h
    int 21h
    
    PrintString CRLF
    
    PrintString plateTitle
    
    push si             
    
    mov ax, si
    mov bx, 8
    mul bx              ;8 for plate offset
    mov di, ax
    
    mov cx, 8           ; 8 plate
printPlatePos:
    mov dl, [carPlate + di]
    mov ah, 02h
    int 21h
    inc di
    loop printPlatePos
    
    PrintString CRLF
    

    PrintString typeTitle
    
    ; Restore position
    pop si
    push si             
    
    ;vehicle type
    mov al, [carType + si]
    ;type text
    cmp al, 1
    jne notType1
    PrintString saloonTitle
    jmp typePrinted
    
notType1:
    cmp al, 2
    jne notType2
    PrintString suvTitle
    jmp typePrinted
    
notType2:
    cmp al, 3
    jne notType3
    PrintString sportsTitle
    jmp typePrinted
    
notType3:
    PrintString truckTitle
    
typePrinted:
    PrintString CRLF
    
    PrintString mileageTitle
    
    ; Restore
    pop si
    ;Get mileage
    mov di, si
    shl di, 1           ; word offset
    mov ax, [carMileage + di]
    ;dec string
    mov bx, 10
    xor cx, cx          ;counter
    
countDigitsPos:
    xor dx, dx
    div bx
    push dx             ; Push remainder
    inc cx
    test ax, ax
    jnz countDigitsPos
    
    ; Print digits
printDigitsPos:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop printDigitsPos
    
    ; Print divider
    PrintString CRLF
    PrintString seperator
    
    ;next vehicle
    inc si
    jmp displayLoop
    
displayDone:
    PrintString CRLF
    PrintString totalVechTitle
    
    ;carCount to decimal string
    mov ax, carCount
    mov bx, 10
    xor cx, cx
    
countDigitsTotal:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz countDigitsTotal
    
printDigitsTotal:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop printDigitsTotal
    
viewDone:
    PrintString CRLF
    PrintString CRLF
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

