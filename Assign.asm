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
    listPrompt DB 'Enter a number (1-5)$'
    listMenu DW OFFSET listOpt1, OFFSET listOpt2, OFFSET listOpt3, OFFSET listOpt4,OFFSET listOpt5
    listMenuSize DW 5
    
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
    jmp ListByType
    cmp bl, 3
    jmp ViewByPosition
    cmp bl, 4
    jmp RemoveVehicle
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
    
    ; Add newline after input
    PrintString CRLF
    
    ; Input mileage
    PrintString mileagePrompt
    lea dx, mileInput
    mov ah, 0Ah
    int 21h
    
    ; Add newline after input
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
    
    ; Add newline after input
    PrintString CRLF
    
    ; Calculate position to store data
    mov si, carCount
    
    ; Store car type
    mov di, si
    mov [carType + di], bl
    
    ; Store car slot/index
    mov [carSlot + di], bl
    
    ; Store mileage - convert ASCII to binary
    xor ax, ax
    xor bx, bx
    mov bl, [mileInput + 1]  ; Get length of entered string
    mov cx, bx              ; Set counter to length
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
    ; Check if we've reached the end of the entered plate
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
    
    ; Discard the carriage return
    mov ah, 01h
    int 21h
    
    ; Check if selection is valid (1-5)
    cmp bl, 1
    jge validMin
    jmp invalidListOption
validMin:
    cmp bl, 5
    jle validOption
    jmp invalidListOption
validOption:
    
    ; Return to main menu if option 5
    cmp bl, 5
    jne notReturnOption
    jmp returnToMenu
notReturnOption:
    
    ; bl now contains the selected vehicle type (1-4)
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
    PrintString CRLF
    PrintString CRLF
    
    ; Initialize counter for matches found
    xor cx, cx
    
    ; Loop through all vehicles
    mov si, 0
    
carTypeLoop:
    cmp si, carCount
    jb continueTypeLoop
    jmp endTypeLoop
continueTypeLoop:
    
    ; Check if current car matches the requested type
    mov di, si
    mov al, [carType + di]
    cmp al, bl
    je typeMatches
    jmp nextCar
typeMatches:
    
    ; Match found - increment match counter
    inc cx
    
    ; Display details
    ; Format: Plate: [plate], Mileage: [mileage]
    
    ; Print newline
    lea dx, CRLF
    mov ah, 09h
    int 21h
    
    ; Print "Plate: "
    mov dl, 'P'
    mov ah, 02h
    int 21h
    mov dl, 'l'
    int 21h
    mov dl, 'a'
    int 21h
    mov dl, 't'
    int 21h
    mov dl, 'e'
    int 21h
    mov dl, ':'
    int 21h
    mov dl, ' '
    int 21h
    
    ; Print plate number
    mov ax, si
    mov bx, 8
    mul bx
    mov di, ax
    
    ; Save match counter and current vehicle index
    push cx   ; Save match counter
    push si   ; Save current vehicle index
    
    mov cx, 8       ; Set loop counter for plate chars
    
printPlate:
    mov dl, [carPlate + di]
    mov ah, 02h
    int 21h
    inc di
    loop printPlate
    
    ; Print ", Mileage: "
    mov dl, ','
    mov ah, 02h
    int 21h
    mov dl, ' '
    int 21h
    mov dl, 'M'
    int 21h
    mov dl, 'i'
    int 21h
    mov dl, 'l'
    int 21h
    mov dl, 'e'
    int 21h
    mov dl, 'a'
    int 21h
    mov dl, 'g'
    int 21h
    mov dl, 'e'
    int 21h
    mov dl, ':'
    int 21h
    mov dl, ' '
    int 21h
    
    ; Restore vehicle index to get mileage
    pop si
    push si   ; Save it again for later
    
    ; Print mileage
    mov di, si
    shl di, 1       ; Multiply by 2 because mileage is a word
    mov ax, [carMileage + di]
    
    ; Convert number to string
    ; First, determine number of digits by dividing by 10 repeatedly
    mov bx, 10
    xor dx, dx
    
    ; Save match counter again (it's still on the stack)
    xor cx, cx      ; Reset cx for digit counting
    
countDigits:
    xor dx, dx
    div bx
    push dx         ; Push remainder (digit)
    inc cx
    test ax, ax
    jnz countDigits
    
    ; Now pop digits and print them
printDigits:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop printDigits
    
    ; Restore vehicle index and match counter
    pop si    ; Restore vehicle index
    pop cx    ; Restore match counter
    
nextCar:
    inc si
    jmp carTypeLoop
    
endTypeLoop:
    ; Check if any matches were found
    test cx, cx
    jz noMatchesFound
    jmp listDone
    
noMatchesFound:
    ; No matches found
    PrintString CRLF
    PrintString wrongInputMsg
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

