.MODEL SMALL
.STACK 100h
.DATA

    ;Car deets storage
    MAX_CARS     EQU 10
    carCount     DW    0
    carPlate     DB    MAX_CARS*8 DUP(' ')
    carMileage   DW    MAX_CARS DUP(0)
    carType      DB    MAX_CARS DUP(0) 
    carSlot      DB    MAX_CARS DUP(0)    ; insertion index
    carRented    DB    MAX_CARS DUP(0)    ; 1=rented, 0=available

    ;buffer data entry
    plateInput DB 8,0,8 DUP(0)  ;max size, actual size, buffer
    mileInput  DB 5,0,5 DUP(0)  ;max 5 digits

    ;User Interface stuff
    correctMsg      DB 'Operation successful$'
    continueMessage DB 'Press a Key to Continue: $'
    wrongInputMsg   DB 'Invalid selection!$'
    fullMsg         DB 'Inventory full! Cannot add more vehicles.$'
    menuPrompt      DB 'Enter a number (1-5) and press Enter: $'
    platePrompt     DB 'Enter Plate (max 8 chars): $'
    mileagePrompt   DB 'Enter Mileage: $'
    typePrompt      DB 'Enter Type (1=Saloon,2=SUV,3=Sports Car,4=Truck): $'
    rentalPrompt    DB 'Is car rented? (0=Available, 1=Rented): $'
    updatePrompt    DB 'Enter vehicle position to update: $'
    newStatusPrompt DB 'Enter new status (0=Available, 1=Rented): $'
    noVehiclesMsg   DB 'No vehicles in inventory!$'
    invalidPosMsg   DB 'Invalid vehicle position!$'
    invalidMileageMsg DB 'Error: Mileage must contain only numeric digits!$'
    plateTitle DB 'Plate: $'
    mileageTitle DB 'Mileage: $'
    matchesTitle DB ' Cars Found!$'
    positionTitle DB 'Position: $'
    typeTitle DB 'Type: $'
    rentalTitle DB 'Status: $'
    slotTitle DB 'Vehicle in Slot order: $'
    saloonTitle DB 'Saloon$'
    suvTitle DB 'SUV$'
    sportsTitle DB 'Sports Car$'
    truckTitle DB 'Truck$'
    availableTitle DB 'Available$'
    rentedTitle DB 'Rented$'
    totalVechTitle DB ' Total Vehicles$'
    seperator DB '----------------$'
    
    ;Page stuff
    carsPerPage    DB    3                 ; Num to display per page
    currentPage    DB    0                 ; Current page view
    nextPageMsg    DB    'Next page...$'
    prevPageMsg    DB    'Previous page...$'
    noNextPageMsg  DB    'No more pages.$'
    noPrevPageMsg  DB    'Already at first page.$'
    vehiclePrefix    DB 'Vehicle $'
    vehicleOf        DB ' of $'
    vehicleNavPrompt DB '(N)ext vehicle, (P)revious vehicle, (Q)uit: $'
    atFirstVehicle   DB 'Already at first vehicle.$'
    atLastVehicle    DB 'Already at last vehicle.$'
    updateNavPrompt DB '(N)ext, (P)rev, (S)elect this vehicle, (Q)uit: $'
    

    ; Main menu
    menuOption1 DB '1) Add New Vehicle$'
    menuOption2 DB '2) List Vehicles by Type$'
    menuOption3 DB '3) View Vehicle by Position$'
    menuOption4 DB '4) Update Vehicle Availability$'
    menuOption5 DB '5) Exit Program$'
    mainMenu    DW OFFSET menuOption1, OFFSET menuOption2, OFFSET menuOption3, OFFSET menuOption4, OFFSET menuOption5
    mainMenuSize DW 5

    ;Type menu
    listOpt1 DB '1) List Saloons$'
    listOpt2 DB '2) List SUVs$'
    listOpt3 DB '3) List Sports Cars$'
    listOpt4 DB '4) List Trucks$'
    listOpt5 DB '5) Return$'
    listPrompt DB 'Enter a number (1-5)$'
    listMenu DW OFFSET listOpt1, OFFSET listOpt2, OFFSET listOpt3, OFFSET listOpt4,OFFSET listOpt5
    listMenuSize DW 5
    
    ;ASCII Car VROOOM
    carArt       DB '            _______', 13, 10
                 DB '           //  ||\ \', 13, 10
                 DB '     _____//___||_\ \___', 13, 10
                 DB '     )  *          *    \', 13, 10
                 DB '     |_/ \________/ \___|', 13, 10
                 DB '    ___\_/________\_/______', 13, 10, '$'
    
    ;Clear
    CRLF DB 13,10,'$'

.CODE
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

    ; Discard carriage return input buffer
    mov ah,01h
    int 21h
    
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
    jmp UpdateAvailability
notOption4:
    cmp bl, 5
    jne invalidChoice
    jmp ExitProgram
invalidChoice:
    PrintString wrongInputMsg
    PrintString CRLF
    PressKeyToContinue
    jmp startMenu
MAIN ENDP


;------------
; Subroutines
AddVehicle PROC
    ;capacity
    mov ax, carCount
    cmp ax, MAX_CARS
    jb notFullLot
    jmp fullLot

notFullLot:
    ;plate num
    PrintString platePrompt
    lea dx, plateInput
    mov ah, 0Ah
    int 21h
    PrintString CRLF
    
    ;miles
    PrintString mileagePrompt
    lea dx, mileInput
    mov ah, 0Ah
    int 21h
    PrintString CRLF
    
    ;Validate mileage is numeric
    xor bx, bx
    mov bl, [mileInput + 1]  ; length of inpuy
    cmp bl, 0                ; Check if empty
    je mileageError1        
    
    mov cx, bx               
    mov si, 2                ; offset 2
    
validateMileage:
    mov al, [mileInput + si] 
    cmp al, '0'              ; Is character < 0?
    jb mileageError2         
    cmp al, '9'              ; Is character > 9?
    ja mileageError2         
    inc si                   ; next char
    loop validateMileage     ; Process all characters
    jmp mileageValid         
    
mileageError1:
    jmp invalidMileage       
    
mileageError2:
    jmp invalidMileage       
    
mileageValid:
    ;type
    PrintString typePrompt
    mov ah, 01h        
    int 21h
    sub al, '0'        ; Convert ASCII to number
    
    ; Validate 1-4
    cmp al, 1
    jae typeAtLeast1
    jmp invalidType
typeAtLeast1:
    cmp al, 4
    jbe typeValid
    jmp invalidType
typeValid:
    ; Store
    mov bl, al
    PrintString CRLF
    
    ;Status
    PrintString rentalPrompt
    mov ah, 01h
    int 21h
    sub al, '0'        ; Convert ASCII to number
    
    ; Validate 1 or 0
    cmp al, 0
    je rentalValid
    cmp al, 1
    je rentalValid
    jmp invalidRental  
    
rentalValid:
    ; Store stat
    mov bh, al  ; Save rental status in BH (BL already has vehicle type)
    PrintString CRLF
    
    ; position to store
    mov si, carCount
    ; Storetype
    mov di, si
    mov [carType + di], bl
    ; Store car slot
    mov [carSlot + di], bl
    ; Store status
    mov [carRented + di], bh
    
    ; Store mileage -  ASCII to binary
    xor ax, ax
    xor bx, bx
    mov bl, [mileInput + 1]  ; length string
    mov cx, bx              ; counter to len
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
    
    ; Store mileage
    mov di, carCount
    shl di, 1               ; Multiply by 2
    mov [carMileage + di], ax
    
    ; Store plate
    mov si, 2               ; Source: plateInput buffer 
    mov di, carCount        ; Destination: calculated offset
    mov cx, 8               ; Max length
    mov bx, 0               ; Index counter for destination
    
    ; Calc beginning position in carPlate array
    mov ax, carCount
    mov dx, 8
    mul dx
    mov di, ax
    
copyPlate:
    ; Check if end of plate
    mov al, [plateInput + 1]    ; length of  text
    cmp bl, al                  ; Comp with position
    jae padSpace                ; If beyond input, pad with spaces
    
    ; Copy character
    mov al, [plateInput + si]
    mov [carPlate + di], al
    inc si
    inc di
    inc bx
    loop copyPlate
    jmp storeDone
    
padSpace:
    ; Pad
    mov byte ptr [carPlate + di], ' '
    inc di
    loop padSpace
    
storeDone:
    ; Increment car count
    inc carCount
    PrintString CRLF
    PrintString correctMsg
    jmp addDone
    
fullLot:
    PrintString CRLF
    PrintString fullMsg
    jmp addDone
    
invalidMileage:
    PrintString CRLF
    PrintString invalidMileageMsg 
    PrintString CRLF
    jmp addDone
    
invalidType:
    PrintString CRLF
    PrintString wrongInputMsg
    jmp addDone
    
invalidRental:
    PrintString CRLF
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
    
    mov ah, 01h
    int 21h
    sub al, '0'
    mov bl, al
    
    mov ah, 01h
    int 21h
   
    ;validdate 1-5
    cmp bl, 1
    jge validMin
    jmp invalidListOption
validMin:
    cmp bl, 5
    jle validOption
    jmp invalidListOption
validOption:
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
    ClearScreen
    PrintString CRLF
    PrintString CRLF
    
    ;counter for matches
    xor cx, cx
    mov bh, bl      ; Save type in BH 
    
    ; Loop
    mov si, 0
    
carTypeLoop:
    cmp si, carCount
    jb continueTypeLoop
    jmp endTypeLoop
continueTypeLoop:
    
    ; Check if current car matches with type
    mov di, si
    mov al, [carType + di]
    cmp al, bh      ; Comp  saved type in BH
    je typeMatches
    jmp nextCar
typeMatches:
    
    ; Match found - increment match counter
    inc cx
  
    lea dx, CRLF
    mov ah, 09h
    int 21h
    PrintString plateTitle
    
    ; Print plate
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
    
    PrintString CRLF
    PrintString rentalTitle
    
    ; Get rental status
    pop si          ; Restore SI (car index)
    push si         ; Keep it on stack again
    
    mov al, [carRented + si]
    cmp al, 1
    je isRentedList
    PrintString availableTitle
    jmp statusPrintedList
    
isRentedList:
    PrintString rentedTitle
    
statusPrintedList:
    
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
    ; check any vehicle
    cmp carCount, 0
    jne hasVehicles
    
    ClearScreen
    PrintString CRLF
    PrintString CRLF
    PrintString wrongInputMsg
    PrintString CRLF
    jmp viewDone
    
hasVehicles:
    ; Init first vehicle
    mov si, 0            ; vehicle pos 0
    
viewNextVehicle:
    ClearScreen    
    
    ; Check within valid range
    cmp si, carCount
    jb showVehicle       ; If si < carCount, show
    jmp goToEndOfVehicles
    
goToEndOfVehicles:
    jmp endOfVehicles   
    
showVehicle:
    PrintString CRLF
    PrintString CRLF
    PrintString slotTitle
    PrintString CRLF
    
    PrintString CRLF
    PrintString positionTitle 
    
    ; position number
    mov ax, si
    add al, '0'          ; Convert to ASCII
    mov dl, al
    mov ah, 02h
    int 21h
    
    ; Display plate
    PrintString CRLF
    PrintString plateTitle 
    push si              ; Save position
    
    ; Calc plate array pos
    mov ax, si
    mov bx, 8            ; 8 chars per plate
    mul bx
    mov di, ax
    ; Print characters
    mov cx, 8
    
printPlatePos:
    mov dl, [carPlate + di]
    mov ah, 02h
    int 21h
    inc di
    loop printPlatePos
    
   
    PrintString CRLF
    PrintString typeTitle 
    
    pop si
    push si
    
    ;type value and display
    mov al, [carType + si]
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
   
    pop si
    push si
    
    ;mileage convert to decimal
    mov di, si
    shl di, 1            ; Multiply by 2 (word size)
    mov ax, [carMileage + di]
    
    ; Convert num to string
    mov bx, 10
    xor cx, cx
    
countDigitsPos:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz countDigitsPos
    
printDigitsPos:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop printDigitsPos
    
    
    PrintString CRLF
    PrintString rentalTitle 
    pop si
    push si
    
    ; Get status and display
    mov al, [carRented + si]
    cmp al, 1
    je isRented
    PrintString availableTitle
    jmp statusPrinted
    
isRented:
    PrintString rentedTitle
    
statusPrinted:
    PrintString CRLF
    PrintString seperator
    PrintString CRLF
    PrintString CRLF
    
    PrintString vehiclePrefix
    
    ; Current vehicle position (index + 1)
    mov ax, si
    inc ax                    ; 1-based
    mov bx, 10                ;base-10 division
    xor cx, cx                

    ;pos number to digit
    currentPosLoop:
        xor dx, dx            ; Clear DX
        div bx                ; AX = AX / 10, DX = remainder
        push dx               ; Save remainder (current digit)
        inc cx                ; Count
        test ax, ax           ;is quotient zero
        jnz currentPosLoop    ; If not, extract digits

    ; reverse order
    currentPosPrint:
        pop dx                ; Get digit
        add dl, '0'           ; Convert to ASCII
        mov ah, 02h           
        int 21h              
        loop currentPosPrint  ; Repet
    
    PrintString vehicleOf
    
    
    ; Total vehicles
    mov ax, carCount          
    mov bx, 10              
    xor cx, cx                


    totalVehiclesLoop:
        xor dx, dx          
        div bx              
        push dx               
        inc cx                
        test ax, ax           
        jnz totalVehiclesLoop 

    
    totalVehiclesPrint:
        pop dx              
        add dl, '0'           
        mov ah, 02h           
        int 21h               
        loop totalVehiclesPrint 
        
    
    PrintString CRLF
    PrintString CRLF
    PrintString vehicleNavPrompt
    
    ;user choice
    mov ah, 01h         ; Read with echo
    int 21h
    
    ;navigation
    pop si              ; Restore posit
    
    cmp al, 'N'         ; Next?
    je nextVehicle
    cmp al, 'n'         ; Next? (lowercase)
    je nextVehicle
    
    cmp al, 'P'         ; Previous?
    je prevVehicle
    cmp al, 'p'         ; Previous? (lowercase)
    je prevVehicle
    
    ; Any other key
    jmp viewDone
    
nextVehicle:
    ; Check if next vehicle
    mov ax, si
    inc ax
    cmp ax, carCount
    jb vehicleInRange    ; If ax < carCount, vehicle in range
    jmp goToEndOfVehicles
    
vehicleInRange:
    ; Move to next vehicle
    inc si
    jmp viewNextVehicle
    
prevVehicle:
    ; Check
    cmp si, 0
    jne hasPrevVehicle   ; If si != 0, has a previous vehicle
    jmp goToStartOfVehicles
    
goToStartOfVehicles:
    jmp startOfVehicles 
    
hasPrevVehicle:
    ; Move prev vehicle
    dec si
    jmp viewNextVehicle
    
startOfVehicles:
    PrintString CRLF
    PrintString CRLF
    PrintString atFirstVehicle
    PressKeyToContinue
    jmp viewNextVehicle
    
endOfVehicles:
    PrintString CRLF
    PrintString CRLF
    PrintString atLastVehicle
    PressKeyToContinue
    jmp viewDone
    
viewDone:
    PrintString CRLF
    PrintString CRLF
    PressKeyToContinue
    jmp startMenu        
ViewByPosition ENDP


UpdateAvailability PROC
    ;check any vehicles
    cmp carCount, 0
    jne hasVehiclesUpdate
    
    
    PrintString CRLF
    PrintString noVehiclesMsg
    jmp updateDone
    
hasVehiclesUpdate:
    ; Init first vehicle
    mov si, 0            ; pos 0
    
viewNextUpdateVehicle:
    ClearScreen          ; Clear
    
    ; Check within range
    cmp si, carCount
    jb showUpdateVehicle ; If si < carCount, show vehicle
    jmp goToEndOfUpdates 
    
goToEndOfUpdates:
    jmp endOfUpdates     ;
    
showUpdateVehicle:
    PrintString CRLF
    PrintString CRLF
    PrintString slotTitle 
    PrintString CRLF
    
   
    PrintString CRLF
    PrintString positionTitle 
    
    ;pos number
    mov ax, si
    add al, '0'          ; Convert to ASCII
    mov dl, al
    mov ah, 02h
    int 21h
    
    
    PrintString CRLF
    PrintString plateTitle
    
    push si              ; Save position
    
    ; Calc plate arr pos
    mov ax, si
    mov bx, 8            ; 8 chars per plate
    mul bx
    mov di, ax
    
    ; Printcharacters
    mov cx, 8
printPlateUpdate:
    mov dl, [carPlate + di]
    mov ah, 02h
    int 21h
    inc di
    loop printPlateUpdate
    
   
    PrintString CRLF
    PrintString typeTitle
    
    pop si
    push si
    
    mov al, [carType + si]
    cmp al, 1
    jne notUpdateType1
    PrintString saloonTitle
    jmp updateTypePrinted
    
notUpdateType1:
    cmp al, 2
    jne notUpdateType2
    PrintString suvTitle
    jmp updateTypePrinted
    
notUpdateType2:
    cmp al, 3
    jne notUpdateType3
    PrintString sportsTitle
    jmp updateTypePrinted
    
notUpdateType3:
    PrintString truckTitle
    
updateTypePrinted:

    PrintString CRLF
    PrintString mileageTitle
    
    pop si
    push si
    
    ; mileage convert to decimal
    mov di, si
    shl di, 1            ; Multiply by 2 (word size)
    mov ax, [carMileage + di]
    
    ; numb to string
    mov bx, 10
    xor cx, cx
    
updateCountDigits:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz updateCountDigits
    
updatePrintDigits:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop updatePrintDigits
    
    
    PrintString CRLF
    PrintString rentalTitle 
    
    pop si
    push si
    
    ;rental status and display
    mov al, [carRented + si]
    cmp al, 1
    je updateIsRented
    PrintString availableTitle
    jmp updateStatusPrinted
    
updateIsRented:
    PrintString rentedTitle
    
updateStatusPrinted:
    
    PrintString CRLF
    PrintString seperator
    
 
    PrintString CRLF
    PrintString CRLF
    
    
    PrintString vehiclePrefix
    
    ; Current vehicle position (index + 1)
    mov ax, si
    inc ax                    ;1-based
    mov bx, 10                ;same as below
    xor cx, cx                

    ; Convert position number to digits
    positionLoop:
        xor dx, dx            
        div bx                
        push dx               
        inc cx                
        test ax, ax           
        jnz positionLoop      

   
    positionPrint:
        pop dx                
        add dl, '0'           
        mov ah, 02h           ;
        int 21h               
        loop positionPrint    ;
    
    PrintString vehicleOf
    
    ; Total vehicles
    mov ax, carCount          ; Get total vehicles
    mov bx, 10                ; Set up for base-10 division
    xor cx, cx                ; Clear counter for digits

    ; Convert number to digits by repeatedly dividing by 10
    updateTotalVehiclesLoop:
        xor dx, dx            ; Clear DX for division
        div bx                ; AX = AX / 10, DX = remainder
        push dx               ; Save remainder (current digit)
        inc cx                ; Count this digit
        test ax, ax           ; Check if quotient is zero
        jnz updateTotalVehiclesLoop ; If not, extracting digits

    ; Print digits in reverse order (most significant first)
    updateTotalVehiclesPrint:
        pop dx                ; Get digit
        add dl, '0'           ; Convert to ASCII
        mov ah, 02h           ; DOS: print character
        int 21h               ; Print digit
        loop updateTotalVehiclesPrint ; Repeat for all digits
    
    
    PrintString CRLF
    PrintString CRLF
    
    
    PrintString updateNavPrompt
    
    ;user choice
    mov ah, 01h         ; Read w echo
    int 21h
    
    ;Nav
    pop si              ;pos index
    
    cmp al, 'N'         ; Next?
    je nextUpdateVehicle
    cmp al, 'n'         ; Next? (lowercase)
    je nextUpdateVehicle
    
    cmp al, 'P'         ; Previous?
    je prevUpdateVehicle
    cmp al, 'p'         ; Previous? (lowercase)
    je prevUpdateVehicle
    
    cmp al, 'S'         ; Select this vehicle?
    je selectThisVehicle
    cmp al, 's'         ; Select this vehicle? (lowercase)
    je selectThisVehicle
    
    ;quit and return to menu
    jmp updateDone
    
nextUpdateVehicle:
    ; Check if has next vehicle
    mov ax, si
    inc ax
    cmp ax, carCount
    jb updateVehicleInRange ; If ax < carCount, vehicle in range
    jmp goToEndOfUpdates
    
updateVehicleInRange:
    ; Move to next vehicle
    inc si
    jmp viewNextUpdateVehicle
    
prevUpdateVehicle:
    ; Checkhave previous vehicle
    cmp si, 0
    jne hasPrevUpdateVehicle ; If si != 0, have prev vehicle
    jmp goToStartOfUpdates
    
goToStartOfUpdates:
    jmp startOfUpdates      
    
hasPrevUpdateVehicle:
    ;move prev vehicle
    dec si
    jmp viewNextUpdateVehicle
    
startOfUpdates:
    PrintString CRLF
    PrintString CRLF
    PrintString atFirstVehicle
    PrintString CRLF
    PressKeyToContinue
    jmp viewNextUpdateVehicle
    
endOfUpdates:
    PrintString CRLF
    PrintString CRLF
    PrintString atLastVehicle
    PressKeyToContinue
    
    ;give option to select a position
    jmp promptForPosition
    
selectThisVehicle:
    ;cont with this position in SI
    jmp toggleVehicle
    
promptForPosition:
    ClearScreen
    PrintString CRLF
    PrintString CRLF
    PrintString updatePrompt
    
    ; Get the pos
    mov ah, 01h
    int 21h
    sub al, '0'
    
    ; Validate pos (0 to carCount-1)
    cmp al, 0
    jge posAtLeastZero
    jmp invalidPos
    
posAtLeastZero:
    mov bx, carCount
    dec bx
    
    cmp al, bl
    jle posValid
    jmp invalidPos
    
posValid:
    ; Positionvalid - store SI
    mov ah, 0
    mov si, ax
    
toggleVehicle:
    ClearScreen
    PrintString CRLF
    PrintString CRLF
    PrintString plateTitle
    
    push si
    mov ax, si
    mov bx, 8
    mul bx
    mov di, ax
    
    mov cx, 8
printPlateSelected:
    mov dl, [carPlate + di]
    mov ah, 02h
    int 21h
    inc di
    loop printPlateSelected
    
    ; Print current status
    PrintString CRLF
    PrintString rentalTitle
    
    pop si
    
    mov al, [carRented + si]
    mov bl, al
    cmp al, 1
    je currentlyRented
    PrintString availableTitle
    jmp toggleStatus
    
currentlyRented:
    PrintString rentedTitle
    
toggleStatus:
    ; Toggle the rental status
    xor bl, 1                 ; Flip using XOR
    mov [carRented + si], bl  ; Store new status
    
    ; Display new status
    PrintString CRLF
    PrintString rentalTitle
    
    ; Check new status and display
    cmp bl, 1
    je nowRented
    PrintString availableTitle
    jmp statusToggled
    
nowRented:
    PrintString rentedTitle
    
statusToggled:
    ; Success message
    PrintString CRLF
    PrintString correctMsg
    jmp updateDone
    
invalidPos:
    PrintString CRLF
    PrintString invalidPosMsg
    
updateDone:
    PrintString CRLF
    PressKeyToContinue
    jmp startMenu
UpdateAvailability ENDP

ExitProgram PROC
    mov ah, 4Ch
    int 21h
ExitProgram ENDP

END MAIN